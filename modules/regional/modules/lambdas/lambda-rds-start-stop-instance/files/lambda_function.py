import boto3
import json
import os

# Create RSD client
session = boto3.session.Session() 
client = boto3.client('rds', region_name=os.environ['AWS_REGION'])

def exception_handler(e, status_code):
    """
    Handle exceptions and return a formatted response.
    """
    print(e)
    return {
        'status_code': status_code,
        'body': json.dumps(str(e))
    }

def rds_validation_status(db_identifier):
    """
    Validate the current status of the rds found
    """
    try:
        db_describe = client.describe_db_instances(DBInstanceIdentifier=db_identifier)
        for db in db_describe['DBInstances']:
            print(f"Found this instances: {db['DBInstanceIdentifier']}")
            
            db_status = db['DBInstanceStatus']
            print(f"Instance: {db['DBInstanceIdentifier']} - Status: {db_status}")
    except Exception as e:
        return exception_handler(e, 400)

    if db_status == 'available' or db_status == 'stopped':
        return db_status
    else:
        return exception_handler(f'RDS status: {db_status} - RDS status available or stopped is required', 400)    

def rds_stop(db_identifier, db_status):
    """
    Stop RDS
    """
    try:
        if db_status == 'available':
            client.stop_db_instance(DBInstanceIdentifier=db_identifier)   
            print('RDS Stopped: ' +db_identifier)
        else:
           return exception_handler(f'RDS status: {db_status} - RDS status available is required')
    except Exception as e:
        return exception_handler(e)
        
    return f"The RDS instance {db_identifier} was stopped"

def rds_start(db_identifier, db_status):
    """
    Start RDS
    """
    try:
        if db_status == 'stopped':
            client.start_db_instance(DBInstanceIdentifier=db_identifier)  
            print('RDS Started: ' +db_identifier)
        else:
           return exception_handler(f'RDS Status: {db_status} - RDS status stopped is required')
    except Exception as e:
        return exception_handler(e)
    
    return f"The RDS instance {db_identifier} was started"

def lambda_handler(event, context):
    """
    Lambda function handler to list all rds instances of the desired client TST environment
    Start or stop all listed RDS
    """
    # Event sent by payload
    db_identifier = event['db_identifier']
    action        = event['action']

    # Check the status of the reported database instance
    db_status = rds_validation_status(db_identifier)
    
    if action == "start":
        response = rds_start(db_identifier, db_status)
    elif action == "stop":
        response = rds_stop(db_identifier, db_status)
    else:
        exception_handler(f"Action: {action} - Action start or stop is required")

    return response

# For local testing
if __name__ == "__main__":
    lambda_handler({}, {})