import boto3
import os
import json
from datetime import datetime, timezone
import logging

# Setup logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Create RDS client
client = boto3.client('rds', region_name=os.environ.get('AWS_REGION'))

# Max number of Step Functions checks
MAX_RETRIES = 60


def response_handler(body, step_functions_time=0, db_instance_status=None, status_code='200'):
    return {
        'body': body,
        'step_functions_time': step_functions_time,
        'db_instance_status': db_instance_status,
        'status_code': status_code
    }


def lambda_handler(event, context):
    """
    Lambda function used in Step Functions to check RDS instance status.
    """
    db_instance_identifier = event.get("db_instance_identifier_source") or event.get("db_instance_identifier")
    
    if not db_instance_identifier:
        logger.error("db_instance_identifier_source or db_instance_identifier not provided in the event")
        raise Exception("db_instance_identifier_source or db_instance_identifier not provided in the event")

    step_functions_time = int(event.get("step_functions_time", 0))

    try:
        if 'LambdaRDSCheckStatus' in event:
            describe_db_instance = client.describe_db_instances(DBInstanceIdentifier=db_instance_identifier)
            db_instance_status = describe_db_instance['DBInstances'][0]['DBInstanceStatus']
            logger.info(f"DB instance '{db_instance_identifier}' current status: {db_instance_status}")
            body = {
                "db_instance_identifier": db_instance_identifier,
                "db_instance_status": db_instance_status
            }
        else:
            describe_db_instance = client.describe_db_instances(DBInstanceIdentifier=db_instance_identifier)
            db_instances = describe_db_instance.get("DBInstances", [])

            if not db_instances:
                logger.error(f"RDS instance '{db_instance_identifier}' not found (empty DBInstances list). step_functions_time={step_functions_time}")
                return response_handler(
                    {"error": f"RDS instance '{db_instance_identifier}' not found."},
                    step_functions_time,
                    db_instance_status="not-found",
                    status_code="404"
                )

            db_instance_status = db_instances[0]['DBInstanceStatus']
            logger.info(f"DB instance '{db_instance_identifier}' current status: {db_instance_status}")

        # Check if DB is stopped
        if db_instance_status == 'stopped':
            logger.info(f"DB instance '{db_instance_identifier}' is stopped. Starting it...")
            client.start_db_instance(DBInstanceIdentifier=db_instance_identifier)
            db_instance_status = 'starting'

        body = {
            "db_instance_identifier": db_instance_identifier,
            "db_instance_status": db_instance_status
        }

        # Increment step function counter
        step_functions_time += 1

        if step_functions_time <= MAX_RETRIES:
            return response_handler(body, step_functions_time, db_instance_status, '200')
        else:
            raise TimeoutError(f"Timeout - Lambda reached {MAX_RETRIES} retries.")

    except botocore.exceptions.ParamValidationError as e:
        logger.error(f"Parameter validation error: {e}")
        raise ValueError(f"The parameters you provided are incorrect: {str(e)}")
    except Exception:
        logger.exception("Unhandled exception")
        raise
