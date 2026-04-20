import boto3
import os
import json
from datetime import datetime, timedelta, timezone
import logging

# Setup logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Create RDS client
client = boto3.client('rds', region_name=os.environ.get('AWS_REGION'))

def response_handler(body, db_instance_snapshot_name, db_instance_snapshot_status, step_functions_time, status_code):
    """
    Return a formatted response for Step Functions.
    """
    return {
        'status_code': status_code,
        'db_instance_snapshot_name': db_instance_snapshot_name,
        'db_instance_snapshot_status': db_instance_snapshot_status,
        'step_functions_time': step_functions_time,
        'body': json.dumps(str(body))
    }

def find_recent_snapshot(db_instance_identifier_source, within_minutes=15):
    """
    Find the most recent manual snapshot created by this Lambda within the last `within_minutes`.
    Filters by suffix '-by-lambda'.
    Returns the snapshot if found, otherwise None.
    """
    try:
        response = client.describe_db_snapshots(
            DBInstanceIdentifier=db_instance_identifier_source,
            SnapshotType='manual'
        )
        now = datetime.now(timezone.utc)
        for snapshot in sorted(response['DBSnapshots'], key=lambda x: x['SnapshotCreateTime'], reverse=True):
            identifier = snapshot['DBSnapshotIdentifier']
            created_at = snapshot['SnapshotCreateTime']
            age = now - created_at
            if age <= timedelta(minutes=within_minutes) and identifier.endswith('-by-lambda'):
                logger.info(f"Found recent snapshot by Lambda: {identifier} created {age} ago")
                return snapshot
    except Exception as e:
        logger.warning(f"Could not list snapshots: {e}")
    return None

def lambda_handler(event, context):
    """
    Lambda function used in Step Functions to create or check the status of an RDS snapshot.
    """
    db_instance_identifier_source = (
        event.get("db_instance_identifier_source")
        or event.get("db_instance_identifier")
    )

    if not db_instance_identifier_source:
        logger.error("db_instance_identifier_source or db_instance_identifier not provided in the event")
        raise Exception("db_instance_identifier_source or db_instance_identifier not provided in the event")

    try:
        if 'LambdaRDSCreateSnapshot' in event:
            # Step Function is checking the status of an existing snapshot
            db_instance_snapshot_name  = event['LambdaRDSCreateSnapshot']['Payload']['db_instance_snapshot_name']
            step_functions_time        = event['LambdaRDSCreateSnapshot']['Payload']['step_functions_time']
            describe_snapshot_db_instance = client.describe_db_snapshots(DBSnapshotIdentifier=db_instance_snapshot_name)
        else:
            # First execution: try to find a recent Lambda-generated snapshot
            recent_snapshot = find_recent_snapshot(db_instance_identifier_source)
            if recent_snapshot:
                db_instance_snapshot_name = recent_snapshot['DBSnapshotIdentifier']
                db_instance_snapshot_status = recent_snapshot['Status']
                step_functions_time = 0
            else:
                # Check if the RDS instance is currently backing up
                db_instance_desc = client.describe_db_instances(DBInstanceIdentifier=db_instance_identifier_source)
                db_status = db_instance_desc['DBInstances'][0]['DBInstanceStatus']
                
                if db_status == 'backing-up':
                    logger.info(f"DB instance '{db_instance_identifier_source}' is currently backing up. Skipping snapshot creation.")
                    db_instance_snapshot_name = None
                    db_instance_snapshot_status = "first run wait for new check"
                    step_functions_time = 0
                else:
                    # Create a new snapshot
                    current_time = datetime.now().strftime('%H-%M')
                    current_date = datetime.today().strftime('%d-%b-%Y')
                    snapshotName = f'{db_instance_identifier_source}-{current_date}-{current_time}-by-lambda'

                    create_snapshot_db_instance = client.create_db_snapshot(
                        DBSnapshotIdentifier=snapshotName,
                        DBInstanceIdentifier=db_instance_identifier_source
                    )
                    db_instance_snapshot_name = create_snapshot_db_instance['DBSnapshot']['DBSnapshotIdentifier']
                    db_instance_snapshot_status = "first run wait for new check"
                    step_functions_time = 0

        if 'LambdaRDSCreateSnapshot' in event:
            # Check the status of the snapshot in progress
            db_instance_snapshot_status = describe_snapshot_db_instance['DBSnapshots'][0]['Status']

        body = f'RDS snapshot: {db_instance_snapshot_name} - Status: {db_instance_snapshot_status}'
        logger.info(body)

        step_functions_time = int(step_functions_time) + 1

        if step_functions_time <= 60:
            return response_handler(body, db_instance_snapshot_name, db_instance_snapshot_status, step_functions_time, '200')
        else:
            error_msg = (
                "Timeout - The lambda rds-snapshot-create reached the execution limit, "
                "run the step functions again or call an admin"
            )
            logger.error(error_msg)
            raise Exception(error_msg)

    except Exception as e:
        logger.error(f"Unhandled exception: {e}")
        raise Exception(e)

# For local testing
if __name__ == "__main__":
    lambda_handler({}, {})
