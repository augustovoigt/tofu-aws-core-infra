import boto3
import os
import json
import logging
import botocore
from datetime import datetime

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Create RDS client
client = boto3.client('rds', region_name=os.environ.get('AWS_REGION', boto3.Session().region_name))

def response_handler(body, step_functions_time=0, db_instance_deleted_status=None, status_code='200', final_db_snapshot_identifier=None):
    return {
        'status_code': status_code,
        'step_functions_time': step_functions_time,
        'db_instance_deleted_status': db_instance_deleted_status,
        'body': json.dumps(body),
        'final_db_snapshot_identifier': final_db_snapshot_identifier
    }

def lambda_handler(event, context):
    """
    Lambda that deletes the destination RDS database informed via payload.
    """
    # Initialize variables
    describe_db_instance = None
    body = None
    final_db_snapshot_identifier = None

    # Events from Terraform
    db_instance_identifier = event.get('db_instance_identifier_destination')

    # Event sent by the step functions - LambdaRDSDeleteInstance
    step_functions_time = event.get('LambdaRDSDeleteInstance', {}).get('Payload', {}).get('step_functions_time', 0)

    if not db_instance_identifier:
        logger.error("db_instance_identifier_destination not provided in the event")
        raise ValueError("db_instance_identifier_destination not provided in the event")

    try:
        if 'LambdaRDSDeleteInstance' in event:
            describe_db_instance = client.describe_db_instances(DBInstanceIdentifier=db_instance_identifier)
            db_instance_deleted_status = describe_db_instance['DBInstances'][0]['DBInstanceStatus']
            body = f'RDS: {db_instance_identifier} not deleted yet - Status: {db_instance_deleted_status}'
            logger.info(body)

            # Ensure final_db_snapshot_identifier is preserved across step function executions
            final_db_snapshot_identifier = event.get('LambdaRDSDeleteInstance', {}).get('Payload', {}).get('final_db_snapshot_identifier')

        else:
            current_time = datetime.now().strftime('%H-%M')
            current_date = datetime.today().strftime('%d-%b-%Y')
            final_db_snapshot_identifier = f'{db_instance_identifier}-final-snapshot-{current_date}-{current_time}-by-Lambda'

            delete_db_instance = client.delete_db_instance(
                DBInstanceIdentifier=db_instance_identifier,
                SkipFinalSnapshot=False,
                FinalDBSnapshotIdentifier=final_db_snapshot_identifier,
                DeleteAutomatedBackups=False
            )

        step_functions_time += 1

        # Create values to return lambda results - Status
        if 'LambdaRDSDeleteInstance' in event:
            db_instance_deleted_status = describe_db_instance['DBInstances'][0]['DBInstanceStatus']
        else:
            db_instance_deleted_status = "first run wait for new check"

        # Create values to return lambda results - Body Message
        body = f'Deleting RDS in progress: {db_instance_identifier} - Status: {db_instance_deleted_status}'
        logger.info(body)

        if step_functions_time <= 60:
            return response_handler(
                body, step_functions_time, db_instance_deleted_status, '200', final_db_snapshot_identifier
            )
        else:
            logger.error("Timeout - The Lambda function rds-delete has reached the execution limit. The RDS snapshot process may have taken longer than 60 minutes.")
            raise TimeoutError("Timeout - The Lambda function rds-delete has reached the execution limit. The RDS snapshot process may have taken longer than 60 minutes.")

    except botocore.exceptions.ClientError as e:
        error_code = e.response['Error']['Code']
        if error_code == 'DBInstanceNotFound':
            body = f"RDS: '{db_instance_identifier}' does not exist or is already deleted."
            logger.info(body)

            # If this is the first iteration, set final_db_snapshot_identifier to None
            if step_functions_time == 0:
                final_db_snapshot_identifier = None
                db_instance_deleted_status = "skipped-rds-not-found"
            else:
                final_db_snapshot_identifier = event.get('LambdaRDSDeleteInstance', {}).get('Payload', {}).get('final_db_snapshot_identifier')
                db_instance_deleted_status = "deleted"

            return response_handler(
                body, step_functions_time, db_instance_deleted_status, '200', final_db_snapshot_identifier
            )
        else:
            logger.error(f"Client error: {e}")
            raise

    except botocore.exceptions.ParamValidationError as e:
        logger.error(f"Parameter validation error: {e}")
        raise ValueError(f"The parameters you provided are incorrect: {str(e)}") 
    except Exception as e:
        logger.error(f"Unhandled exception: {e}")
        raise

# For local testing
if __name__ == "__main__":
    mock_event = {
        "db_instance_identifier_destination": "your-db-instance-identifier",
        "LambdaRDSDeleteInstance": True
    }
    lambda_handler(mock_event, {})