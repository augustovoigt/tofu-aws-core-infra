import boto3
import json
import oracledb
import os
import logging

# Setup logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Create Secrets Manager client
session = boto3.session.Session()
client = session.client(service_name='secretsmanager', region_name=os.environ['AWS_REGION'])

def response_handler(body, status_code):
    """
    Return formatted response.
    """
    logger.info(f"Response: {body}, Status Code: {status_code}")
    return {
        'status_code': status_code,
        'body': json.dumps(str(body))
    }

def get_secret_content(sm):
    """
    Get secret from SM to access RDS instance
    """
    try:
        logger.info(f"Fetching secret: {sm}")
        get_secret_value_response = client.get_secret_value(SecretId=sm)
        secret = get_secret_value_response['SecretString']
        rds_credentials = json.loads(secret)
        return rds_credentials
    except Exception as e:
        logger.error(f"Error fetching secret {sm}: {e}")
        raise Exception(f"Error fetching secret {sm}: {e}")

def check_rds_users(secret_master, user_secrets):
    """
    Connect to the RDS instance and ensure required users exist or update passwords.
    """
    try:
        logger.info("Connecting to RDS Oracle instance")

        dsn = f"{secret_master['host']}:{secret_master['port']}/{secret_master['dbname']}"
        con = oracledb.connect(
            user=secret_master['username'],
            password=secret_master['password'],
            dsn=dsn
        )
        cur = con.cursor()

        for username, secret in user_secrets.items():
            logger.info(f"Processing user: {username}")
            cur.callproc("dbms_output.enable")

            # Use DBMS_ASSERT to safely enquote the username
            escaped_username = cur.callfunc("sys.DBMS_ASSERT.enquote_name", str, [username.upper()])

            # Check if user exists
            cur.execute("SELECT COUNT(*) FROM dba_users WHERE username = UPPER(:1)", [username])
            user_exists = cur.fetchone()[0] > 0

            if user_exists:
                sql = f"ALTER USER {escaped_username} IDENTIFIED BY \"{secret['password']}\""
                logger.info(f"User {username} exists. Updating password.")
            else:
                sql = f"CREATE USER {escaped_username} IDENTIFIED BY \"{secret['password']}\""
                logger.info(f"User {username} does not exist. Creating user.")

            cur.execute(sql)

            # Grant CREATE SESSION privilege
            grant_sql = f"GRANT CREATE SESSION TO {escaped_username}"
            logger.info(f"Granting CREATE SESSION to user {username}")
            cur.execute(grant_sql)

        con.commit()
        body = "Successfully ensured existence, updated passwords, and granted CREATE SESSION for all users."
        logger.info(body)
        return body

    except Exception as e:
        logger.error(f"Error ensuring RDS users: {e}")
        raise Exception(f"Error ensuring RDS users: {e}")

def lambda_handler(event, context):
    """
    Lambda function handler to connect to RDS Oracle DB instance and manage users.
    """

    logger.info(f"Received event: {json.dumps(event)}")
    if event.get("tf", {}).get("action") == "delete":
        logger.info("Terraform destroy detected, bypassing main logic.")
        return response_handler({"message": "Bypassed during terraform destroy"}, "200")

    db_instance_identifier_destination = event.get('db_instance_identifier_destination')
    if not db_instance_identifier_destination:
        logger.error("db_instance_identifier_destination not found in event")
        raise Exception("db_instance_identifier_destination not found in event")

    try:
        # Check if app_rds_users was provided in the event
        app_rds_users = event.get('app_rds_users')
        if not app_rds_users:
            logger.error("app_rds_users not found or empty in event")
            raise Exception("app_rds_users not found or empty in event")

        # Parse, clean, and exclude 'master' user
        db_usernames = [u.strip() for u in app_rds_users if u.strip().lower() != "master"]

        # If the list is empty after filtering, skip user creation
        if not db_usernames:
            logger.info("No valid users to process after filtering. Skipping user management.")
            return response_handler({"message": "No users to process. Skipped user management."}, "200")

        logger.info(f"Users from event: {db_usernames}")

        master_secret_name = event.get('master_secret_name')
        if not master_secret_name:
            raise Exception("Required parameter 'master_secret_name' is missing")
        secret_master = get_secret_content(master_secret_name)

        secret_base_path = master_secret_name.rsplit('/', 1)[0]
        user_secrets = {}
        for username in db_usernames:
            secret_path = f"{secret_base_path}/{username}"
            user_secrets[username] = get_secret_content(secret_path)

    except Exception as e:
        logger.error(f"Error fetching secrets or parsing input: {e}")
        raise Exception(str(e))

    try:
        body = check_rds_users(secret_master, user_secrets)
        return response_handler(body, '200')
    except Exception as e:
        logger.error(f"Unhandled exception: {e}")
        raise Exception(e)
