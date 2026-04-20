import boto3
import json
import oracledb
import os
import logging
import re
from tabulate import tabulate

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Create Secrets Manager client
session = boto3.session.Session()
client = session.client(service_name='secretsmanager', region_name=os.environ.get('AWS_REGION'))

def retrieve_rds_credentials(secret_id):
    """
    Retrieve RDS credentials from Secrets Manager.
    """
    try:
        get_secret_value_response = client.get_secret_value(SecretId=secret_id)
        secret = get_secret_value_response['SecretString']
        return json.loads(secret)
    except Exception as e:
        logger.error(f"Failed to retrieve RDS credentials: {e}")
        raise

def connect_to_oracle(rds_credentials):
    
    """
    Connect to the RDS Oracle database instance using python-oracledb in thin mode.
    """
    try:
        dsn = f"{rds_credentials['host']}:{rds_credentials['port']}/{rds_credentials['dbname']}"
        logger.info(f"Connecting to Oracle at DSN: {dsn}")

        connection = oracledb.connect(
            user=rds_credentials['username'],
            password=rds_credentials['password'],
            dsn=dsn,            
        )
        logger.info("Oracle connection established successfully.")
        return connection

    except Exception as e:
        logger.error(f"Failed to connect to Oracle DB using oracledb: {e}")
        raise

def lambda_handler(event, context, **kwargs):        
    db_instance_identifier_destination = event.get('db_instance_identifier_destination')
    db_instance_sql_updates_statements = event.get('db_instance_sql_updates_statements')    
    
    if not db_instance_identifier_destination:
        error_message = "Required parameters are missing: 'db_instance_identifier_destination'"
        logger.error(error_message)
        raise Exception(error_message)
    
    # Decode the payload properly
    decoded_db_instance_sql_updates_statements = db_instance_sql_updates_statements.encode().decode('unicode-escape')
    cleaned_query = re.sub(r'^"|"$', '', decoded_db_instance_sql_updates_statements)
    logger.info(f"Decoded variable:\n {cleaned_query}")
    
    # Retrieve RDS credentials from Secrets Manager
    master_secret_name = event.get('master_secret_name')
    if not master_secret_name:
        raise Exception("Required parameter 'master_secret_name' is missing")
    rds_credentials = retrieve_rds_credentials(master_secret_name)
    
    try:                
        # Connect to the RDS Oracle database instance
        conn = connect_to_oracle(rds_credentials)
        cursor = conn.cursor()
        
        formatted_results = []        
        
        if cleaned_query.casefold().startswith('update') or cleaned_query.casefold().startswith('delete'):
            sql = f"""
            BEGIN
            {cleaned_query}
            END;
            """
            logger.info(f"SQL variable:\n {sql}")
            cursor.execute(sql)        
        elif cleaned_query.casefold().startswith('declare'):
            sql = f"""
            {cleaned_query}
            """
            logger.info(f"SQL variable:\n {sql}")
            cursor.execute(sql)
        elif db_instance_sql_updates_statements.casefold().startswith('select'):
            statements = db_instance_sql_updates_statements.split(";")
            for statement in statements:
                if statement.strip():  # Check if statement is not empty
                    cursor.execute(statement.strip())
                    rows = cursor.fetchall()
        
                    # Get column names
                    col_names = [row[0] for row in cursor.description]
        
                    # Format the results using tabulate
                    formatted_result = tabulate(rows, headers=col_names, tablefmt='github')
                    logger.info(f"Resultado Formatado:\n{formatted_result}")
                    formatted_results.append(formatted_result)
        else:
            logger.info(f"Wrong query, please check if it is correct")
			
        conn.commit()
        conn.close()        
        
        for formatted_result in formatted_results:
            return formatted_result
    except Exception as e:
        logger.error(f"Unhandled exception: {e}")
        raise Exception(e)
    
# For local testing
if __name__ == "__main__":
    lambda_handler({}, {})