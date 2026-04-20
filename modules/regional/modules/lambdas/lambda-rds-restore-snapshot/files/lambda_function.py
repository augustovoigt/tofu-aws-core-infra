import boto3
import os
import json
import logging
import botocore

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients
client = boto3.client('rds', region_name=os.environ.get('AWS_REGION'))

def response_handler(body, step_functions_time, db_instance_identifier, db_instance_restored_status, status_code):
    """
    Return formatted response.
    """
    return {
        'status_code': status_code,
        'step_functions_time': step_functions_time,
        'db_instance_identifier': db_instance_identifier,
        'db_instance_restored_status': db_instance_restored_status,
        'body': json.dumps(str(body))
    }

def format_tags(tags_dict):
    """
    Convert dictionary of tags into the required format for AWS API.
    """
    return [{'Key': k, 'Value': v} for k, v in tags_dict.items()]

def lambda_handler(event, context):
    """
    Lambda that restores the base RDS snapshot informed via payload.
    """
    # Initialize variables
    describe_db_instance = None
    body = None

    # Events from Terraform
    db_instance_auto_minor_version_upgrade = json.loads(event.get('db_instance_auto_minor_version_upgrade', 'false'))
    db_instance_class = event.get('db_instance_class')
    db_instance_copy_tags_to_snapshot = json.loads(event.get('db_instance_copy_tags_to_snapshot', 'false'))
    db_instance_delete_protection = json.loads(event.get('db_instance_delete_protection', 'false'))
    db_instance_identifier = event.get('db_instance_identifier_destination')
    db_instance_multiaz = json.loads(event.get('db_instance_multiaz', 'false'))
    db_instance_name = event.get('db_instance_name')
    db_instance_og = event.get('db_instance_og')
    db_instance_pg = event.get('db_instance_pg')
    db_instance_publicly_accessible = json.loads(event.get('db_instance_publicly_accessible', 'false'))
    db_instance_sg = event.get('db_instance_sg', [])
    db_instance_storage_type = event.get('db_instance_storage_type')
    db_instance_subnet_id = event.get('db_instance_subnet_id')
    db_instance_tags = format_tags(event.get('db_instance_tags', {}))
    
    # Event sent by the step functions - LambdaRDSCreateSnapshot
    db_instance_snapshot_name = event.get('LambdaRDSCreateSnapshot', {}).get('Payload', {}).get('db_instance_snapshot_name', '')

    step_functions_time = event.get('LambdaRDSRestoreSnapshot', {}).get('Payload', {}).get('step_functions_time', 0)

    try:
        if 'LambdaRDSRestoreSnapshot' in event:
            # Validate DB instance
            describe_db_instance = client.describe_db_instances(DBInstanceIdentifier=db_instance_identifier)
        else:
            # Restore the DB instance from snapshot
            db_instance_restored = client.restore_db_instance_from_db_snapshot(
                AutoMinorVersionUpgrade=db_instance_auto_minor_version_upgrade,
                CopyTagsToSnapshot=db_instance_copy_tags_to_snapshot,
                DBInstanceClass=db_instance_class,
                DBInstanceIdentifier=db_instance_identifier,
                DBName=db_instance_name,
                DBParameterGroupName=db_instance_pg,
                DBSnapshotIdentifier=db_instance_snapshot_name,
                DBSubnetGroupName=db_instance_subnet_id,
                DeletionProtection=db_instance_delete_protection,
                MultiAZ=db_instance_multiaz,
                OptionGroupName=db_instance_og,
                PubliclyAccessible=db_instance_publicly_accessible,
                StorageType=db_instance_storage_type,
                Tags=db_instance_tags,
                VpcSecurityGroupIds=db_instance_sg
            )
            
        step_functions_time += 1

        # Create values to return lambda results - Status
        if 'LambdaRDSRestoreSnapshot' in event:
            db_instance_restored_status = describe_db_instance['DBInstances'][0]['DBInstanceStatus']
        else:
            #db_instance_restored_status = db_instance_restored['DBInstance']['DBInstanceStatus']
            db_instance_restored_status = "first run wait for new check"
            
        
        # Create values to return lambda results - Body Message
        body = f'Restoring RDS from snapshot in progress: {db_instance_identifier} - Status: {db_instance_restored_status}'
        logger.info(body)
            
        if step_functions_time <= 120:
            return response_handler(body, step_functions_time, db_instance_identifier, db_instance_restored_status, '200')
        else:
            logger.error("Timeout - The Lambda RDS snapshot restore reached the execution limit. The RDS restore snapshot process may have taken longer than 60 minutes.")
            raise Exception("Timeout - The Lambda RDS snapshot restore reached the execution limit. The RDS restore snapshot process may have taken longer than 60 minutes.")
    except Exception as e:
        logger.error(f"Unhandled exception: {e}")
        raise Exception(f"Unhandled exception: {e}")