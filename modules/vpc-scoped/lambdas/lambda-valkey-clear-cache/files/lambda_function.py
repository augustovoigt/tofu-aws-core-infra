import redis
import json
import requests
import logging

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def response_gh(body, gh_issue_api, gh_token, gh_issue_prefix_body):
    """
    Return formatted response to GitHub issue and log the response.
    """
    headers = {'Content-Type': 'application/json', 'Authorization': f'Bearer {gh_token}'}
    new_comment_body = {'body': f'{gh_issue_prefix_body} \n\n {body}'}  
    try:
        response = requests.patch(gh_issue_api, json=new_comment_body, headers=headers)
        response_data = response.json()
        logger.info(f"GitHub response: {response_data}")
        return response_handler(response_data, str(response.status_code))
    except Exception as e:
        logger.error(f"Error posting to GitHub: {e}")
        return response_handler(str(e), '500')
        
def response_handler(body, status_code):
    """
    Return formatted response.
    """
    return {
        'status_code': status_code,
        'body': json.dumps(body)
    }

def lambda_handler(event, context):
    """
    Lambda function to find and delete Redis keys with a specific prefix used for customer.
    """
    logger.info("Lambda function started")
    
    # Event sent by payload
    redis_base_key_prefix = event.get('redis_base_key')
    redis_primary_endpoint_address = event.get('redis_primary_endpoint_address')
    redis_skip_process = event.get('redis_skip_process', False) # Default is False, this is used only by lambda-dump-replica-rds-step-functions
    gh_issue_prefix_body = event.get('gh_issue_prefix_body')
    gh_issue_api = event.get('gh_issue_api')
    gh_token = event.get('gh_token')

    if redis_skip_process:
        logger.info("Skipping Redis process as redis_skip_process is true")
        return response_handler("Process skipped", '200')
        
    if not redis_base_key_prefix:
        logger.error("redis_base_key not provided in the event")
        return response_handler("redis_base_key not provided in the event", '400')
        
    if not redis_primary_endpoint_address:
        logger.error("redis_primary_endpoint_address not provided in the event")
        return response_handler("redis_primary_endpoint_address not provided in the event", '400')
        
    try:
        # Connect to Redis
        logger.info(f"Connecting to Redis at {redis_primary_endpoint_address}")
        r = redis.from_url(f'rediss://{redis_primary_endpoint_address}')
        
        # Use scan to find all keys with the specified prefix
        cursor = '0'
        keys_to_delete = []
        
        while True:
            cursor, keys = r.scan(cursor=cursor, match=f'{redis_base_key_prefix}*')
            keys_to_delete.extend(keys)
            if cursor == 0:
                break
        
        if keys_to_delete:
            deleted_count = r.delete(*keys_to_delete)
            message = f"Keys with prefix '{redis_base_key_prefix}' found and removed successfully. Total keys deleted: {deleted_count}"
            logger.info(message)
        else:
            message = f"Keys with prefix '{redis_base_key_prefix}' not found in Redis."
            logger.info(message)

        if gh_token: 
            gh_response = response_gh(message, gh_issue_api, gh_token, gh_issue_prefix_body)
            logger.info(f"GitHub response handler returned: {gh_response}")
        
        return response_handler(message, '200')
    except Exception as e:
        logger.error(f"Unhandled exception: {e}")
        return response_handler(str(e), '500')