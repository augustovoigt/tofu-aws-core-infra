import boto3
import os
import json
import logging
import botocore

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients
session    = boto3.session.Session()
client_rds = boto3.client(service_name='rds', region_name=os.environ.get('AWS_REGION'))
client_sm  = session.client(service_name='secretsmanager', region_name=os.environ.get('AWS_REGION'))

def response_handler(body, step_functions_time=0, db_instance_modified_status=None, status_code='200'):
    """
    Return formatted response.
    """
    return {
        'status_code': status_code,
        'step_functions_time': step_functions_time,
        'db_instance_modified_status': db_instance_modified_status,
        'body': json.dumps(body)
    }

def lambda_handler(event, context):
    """
    Lambda that modifies the RDS database informed via payload.
    """
    describe_db_instance = None
    body = None

    # Events from Terraform
    db_instance_backup_retention_period = event.get('db_instance_backup_retention_period')
    db_instance_ca_cert_identifier = event.get('db_instance_ca_cert_identifier')
    db_instance_identifier = event.get('db_instance_identifier_destination')
    db_instance_monitoring_interval = event.get('db_instance_monitoring_interval')
    db_instance_performance_insights_enabled = json.loads(event.get('db_instance_performance_insights_enabled', 'true'))
    db_instance_monitoring_role_arn = event.get('db_instance_monitoring_role_arn')
    db_instance_s3_integration_role_arn = event.get('db_instance_s3_integration_role_arn')
    db_instance_id = db_instance_identifier.split('-')
    secret_user_master_content = f"{db_instance_id[0]}/{db_instance_id[2]}/rds/app/user/master"

    # Event sent by the step functions - LambdaRDSModifyInstance
    step_functions_time = event.get('LambdaRDSModifyInstance', {}).get('Payload', {}).get('step_functions_time', 0)

    if not db_instance_identifier:
        logger.error("db_instance_identifier_destination not provided in the event")
        raise Exception("db_instance_identifier_destination not provided in the event")
    
    try:
        if 'LambdaRDSModifyInstance' in event:
            describe_db_instance = client_rds.describe_db_instances(DBInstanceIdentifier=db_instance_identifier)
            db_instance_modified_status = describe_db_instance['DBInstances'][0]['DBInstanceStatus']
            body = f'RDS: {db_instance_identifier} not modified yet - Status: {db_instance_modified_status}'
            logger.info(body)
        else:
            # Get SM secret content
            get_secret_value = client_sm.get_secret_value(SecretId=secret_user_master_content)
            secret = get_secret_value['SecretString']
            rds_credentials = json.loads(secret)
        
            # Get master password to edit credential in RDS
            db_instance_master_user_password = rds_credentials['password']

            # Convert string parameters to integers where necessary
            db_instance_backup_retention_period = int(db_instance_backup_retention_period)
            db_instance_monitoring_interval = int(db_instance_monitoring_interval)

            params = {
                "ApplyImmediately": True,
                "BackupRetentionPeriod": db_instance_backup_retention_period,
                "CACertificateIdentifier": db_instance_ca_cert_identifier,
                "DBInstanceIdentifier": db_instance_identifier,
                "EnablePerformanceInsights": db_instance_performance_insights_enabled,
                "MasterUserPassword": db_instance_master_user_password,
                "MonitoringInterval": db_instance_monitoring_interval,
            }

            if db_instance_monitoring_interval != 0:
                params["MonitoringRoleArn"] = db_instance_monitoring_role_arn

            modify_db_instance = client_rds.modify_db_instance(**params)

            # Add S3 integration role to the RDS instance if provided
            if db_instance_s3_integration_role_arn:
                client_rds.add_role_to_db_instance(
                    DBInstanceIdentifier=db_instance_identifier,
                    RoleArn=db_instance_s3_integration_role_arn,
                    FeatureName='S3_INTEGRATION'
                )
                logger.info(f"Added S3 integration role {db_instance_s3_integration_role_arn} to RDS instance {db_instance_identifier}")

        step_functions_time += 1

        # Create values to return lambda results - Status
        if 'LambdaRDSModifyInstance' in event:
            db_instance_modified_status = describe_db_instance['DBInstances'][0]['DBInstanceStatus']
        else:
            db_instance_modified_status = "first run wait for new check"

        # Create values to return lambda results - Body Message
        body = f'Modifying RDS in progress: {db_instance_identifier} - Status: {db_instance_modified_status}'
        logger.info(body)

        if step_functions_time <= 60:
            return response_handler(
                body, step_functions_time, db_instance_modified_status, '200'
            )
        else:
            logger.error("Timeout - The Lambda function rds-modify has reached the execution limit. The RDS modify process may have taken longer than 60 minutes.")
            raise TimeoutError("Timeout - The Lambda function rds-modify has reached the execution limit. The RDS modify process may have taken longer than 60 minutes.")

    except botocore.exceptions.ParamValidationError as e:
        logger.error(f"Parameter validation error: {e}")
        raise ValueError(f"The parameters you provided are incorrect: {str(e)}") 
    except Exception as e:
        logger.error(f"Unhandled exception: {e}")
        raise

# For local testing
if __name__ == "__main__":
    lambda_handler({}, {})
