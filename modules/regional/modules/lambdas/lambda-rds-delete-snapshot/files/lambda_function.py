import boto3
import os
import json
import logging

# Setup logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Create RDS client
client = boto3.client('rds', region_name=os.environ.get('AWS_REGION'))

def response_handler(body, deleted_snapshots, status_code):
    """
    Return response formatted.
    """
    return {
        'status_code': status_code,
        'deleted_snapshots': deleted_snapshots,
        'body': json.dumps(str(body))
    }

def lambda_handler(event, context):
    """
    Lambda that deletes RDS snapshots if they exist.
    """
    deleted_snapshots = []
    
    try:
        # Check if there's a snapshot from LambdaRDSCreateSnapshot
        db_instance_snapshot_name = event.get('LambdaRDSCreateSnapshot', {}).get('Payload', {}).get('db_instance_snapshot_name')
        
        # Check if there's a final_db_snapshot_identifier from lambda-rds-delete
        final_db_snapshot_identifier = event.get('LambdaRDSDeleteInstance', {}).get('Payload', {}).get('final_db_snapshot_identifier')
        
        snapshots_to_delete = [db_instance_snapshot_name, final_db_snapshot_identifier]
        
        for snapshot in snapshots_to_delete:
            if snapshot:
                try:
                    client.delete_db_snapshot(DBSnapshotIdentifier=snapshot)
                    body_message = f"RDS snapshot '{snapshot}' has been successfully deleted."
                    deleted_snapshots.append(snapshot)
                    logger.info(body_message)
                except client.exceptions.DBSnapshotNotFoundFault:
                    body_message = f"RDS snapshot '{snapshot}' not found."
                    logger.error(body_message)
                
        if deleted_snapshots:
            return response_handler(f"Deleted snapshots: {deleted_snapshots}", deleted_snapshots, '200')
        else:
            return response_handler("No valid snapshots to delete.", deleted_snapshots, '404')

    except Exception as e:
        logger.error(f"Unhandled exception: {e}")
        raise Exception(e)

# For local testing
if __name__ == "__main__":
    lambda_handler({}, {})