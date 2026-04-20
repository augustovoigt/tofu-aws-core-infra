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
client_ssm = boto3.client(service_name='ssm', region_name=os.environ.get('AWS_REGION'))

# Max number of Step Functions checks
MAX_RETRIES = 60


def response_handler(body, step_functions_time=0, db_instance_modified_status=None, status_code='200'):
    return {
        'body': body,
        'step_functions_time': step_functions_time,
        'db_instance_modified_status': db_instance_modified_status,
        'status_code': status_code
    }


def get_rds_config_from_ssm(parameter_name):
    """Retrieve RDS config from AWS SSM Parameter Store and return as dict."""
    logger.info(f"Retrieving RDS config from SSM: {parameter_name}")
    response = client_ssm.get_parameter(
        Name=parameter_name,
        WithDecryption=False
    )
    config = json.loads(response['Parameter']['Value'])
    logger.info(f"Retrieved config: {config}")

    required_keys = ["db_instance_class", "db_instance_parameter_group"]
    for key in required_keys:
        if key not in config:
            logger.error(f"Missing key '{key}' in SSM parameter value")
            raise KeyError(f"Missing key '{key}' in SSM parameter value")

    return config


def modify_rds_instance(identifier, instance_class=None, param_group=None):
    """Modify an RDS instance with given class and/or parameter group."""
    modify_args = {
        "ApplyImmediately": True,
        "DBInstanceIdentifier": identifier
    }
    
    if instance_class:
        modify_args["DBInstanceClass"] = instance_class
    if param_group:
        modify_args["DBParameterGroupName"] = param_group

    # Log behavior based on parameters
    if instance_class and param_group:
        logger.info(f"Modifying BOTH instance class to '{instance_class}' and parameter group to '{param_group}' for RDS {identifier}.")
    elif instance_class and not param_group:
        logger.info(f"Modifying ONLY instance class to '{instance_class}' for RDS {identifier}.")
    elif not instance_class and param_group:
        logger.info(f"Modifying ONLY parameter group to '{param_group}' for RDS {identifier}.")
    else:
        logger.info(f"No modifications requested for RDS {identifier}.")

    logger.info(f"Modifying RDS with args: {modify_args}")
    return client_rds.modify_db_instance(**modify_args)


def get_vcpu_count_for_instance_class(instance_class):
    """Return vCPU count based on instance class family."""
    # Mapping can be expanded as needed
    vcpu_map = {
        "db.m5.large": 2,
        "db.m5.xlarge": 4,
        "db.m5.2xlarge": 8,
        "db.m5.4xlarge": 16,
        "db.m5.8xlarge": 32
    }
    return vcpu_map.get(instance_class, 0)

def to_bool(value, default=True):
    if isinstance(value, bool):
        return value
    if isinstance(value, str):
        if value.lower() in ("true", "yes", "y"):
            return True
        if value.lower() in ("false", "no", "n"):
            return False
    if isinstance(value, (int, float)):
        return bool(value)
    return default

def lambda_handler(event, context):
    """Lambda that modifies the RDS database informed via payload."""
    body = None

    logger.info(f"Received event: {json.dumps(event)}")

    action = event.get('action')
    db_upgrade = to_bool(event.get("db_upgrade"), default=True)
    db_instance_identifier = event.get('db_instance_identifier')
    db_instance_class_update = "db.m5.2xlarge"
    db_instance_parameter_group_update = "pg-oracle-se2-19-version-update"

    db_instance_id_parts = db_instance_identifier.split('-')
    ssm_parameter_store_rds_config = event.get(
        'ssm_parameter_store_rds_config',
        f"/{db_instance_id_parts[0]}/{db_instance_id_parts[2]}/rds/app/config"
    )

    logger.info(f"action: {action}")
    logger.info(f"db_upgrade: {db_upgrade}")
    logger.info(f"db_instance_identifier: {db_instance_identifier}")
    logger.info(f"ssm_parameter_store_rds_config: {ssm_parameter_store_rds_config}")

    step_functions_time = event.get('LambdaRDSModifyInstance', {}).get('Payload', {}).get('step_functions_time', 0)

    if not action:
        raise Exception("action not provided in the payload, must be 'prepare-update' or 'finish-update'.")
    if not db_instance_identifier:
        raise Exception("db_instance_identifier not provided in the payload, must be the client RDS name.")
    if action not in ['prepare-update', 'finish-update']:
        raise ValueError(f"Invalid action: {action}. Must be 'prepare-update' or 'finish-update'.")

    try:
        if 'LambdaRDSModifyInstance' in event:
            describe_db_instance = client_rds.describe_db_instances(DBInstanceIdentifier=db_instance_identifier)
            db_instance_info = describe_db_instance['DBInstances'][0]
            db_instance_modified_status = db_instance_info['DBInstanceStatus']

            # Check if a reboot is required to apply parameter group
            needs_reboot = any(pg['ParameterApplyStatus'] == 'pending-reboot' for pg in db_instance_info['DBParameterGroups'])

            if db_instance_modified_status == "available" and needs_reboot:
                logger.info(f"RDS {db_instance_identifier} is available but requires a reboot (pending-reboot). Rebooting now...")
                client_rds.reboot_db_instance(DBInstanceIdentifier=db_instance_identifier, ForceFailover=False)
                body = f"RDS {db_instance_identifier} reboot requested..."
                db_instance_modified_status = "rebooting"
            elif db_instance_modified_status == "available" and not needs_reboot:
                body = f"RDS {db_instance_identifier} is available and does not require a reboot."
            else:
                body = f'RDS: {db_instance_identifier} not modified yet - Status: {db_instance_modified_status}'

            logger.info(body)
        else:
            db_instance_modified_status = "first-run"
            describe_db_instance = client_rds.describe_db_instances(DBInstanceIdentifier=db_instance_identifier)
            db_instances = describe_db_instance.get("DBInstances", [])

            if not db_instances:
                logger.error(f"RDS instance '{db_instance_identifier}' not found (empty DBInstances list). step_functions_time={step_functions_time}")
                return response_handler(
                    {"error": f"RDS instance '{db_instance_identifier}' not found."},
                    step_functions_time,
                    db_instance_modified_status="not-found",
                    status_code="404"
                )
                
            db_instance_info = db_instances[0]
            current_class = db_instance_info['DBInstanceClass']
            current_param_group = db_instance_info['DBParameterGroups'][0]['DBParameterGroupName']

            if action == 'prepare-update':
                target_class = None
                target_param = db_instance_parameter_group_update

                logger.info(f"Action '{action}' started for RDS {db_instance_identifier}. db_upgrade={db_upgrade}")

                if db_upgrade:
                    current_vcpus = get_vcpu_count_for_instance_class(current_class)
                    if current_class.startswith('db.t3'):
                        logger.info(f"Upgrading t3 instance {current_class} to {db_instance_class_update}.")
                        target_class = db_instance_class_update
                    elif current_vcpus < 8:
                        logger.info(f"Upgrading {current_class} ({current_vcpus} vCPUs) to {db_instance_class_update}.")
                        target_class = db_instance_class_update
                    else:
                        logger.info(f"Instance {current_class} already has {current_vcpus} vCPUs. Skipping class change.")
                else:
                    logger.info(f"Skipping class upgrade for {db_instance_identifier}, it will only be updating parameter group.")

                modify_rds_instance(db_instance_identifier, target_class, target_param)
                db_instance_modified_status = "modifying"

            elif action == 'finish-update':
                config = get_rds_config_from_ssm(ssm_parameter_store_rds_config)
                needs_modify_class = current_class != config['db_instance_class']
                needs_modify_param = current_param_group != config['db_instance_parameter_group']

                logger.info(f"Action '{action}' started for RDS {db_instance_identifier}. db_upgrade={db_upgrade}")

                if needs_modify_class or needs_modify_param:
                    logger.info(
                        f"Modifying RDS {db_instance_identifier} to match SSM config. "
                        f"old_instance_class={current_class}, old_parameter_group={current_param_group}, "
                        f"new_instance_class={config['db_instance_class']}, new_parameter_group={config['db_instance_parameter_group']}"
                    )
                    modify_rds_instance(
                        db_instance_identifier,
                        config['db_instance_class'] if needs_modify_class else None,
                        config['db_instance_parameter_group'] if needs_modify_param else None
                    )
                    db_instance_modified_status = "modifying"
                else:
                    logger.info(
                        f"Finish update skipped — Instance class ({current_class}) and parameter group ({current_param_group}) "
                        f"already match SSM config."
                    )

            body = {
                "action": action,
                "db_upgrade": db_upgrade,
                "db_instance_identifier": db_instance_identifier,
                "db_instance_modified_status": db_instance_modified_status,
            }

            logger.info(f"First-run response body: {json.dumps(body)}")

        step_functions_time += 1

        if step_functions_time <= MAX_RETRIES:
            return response_handler(body, step_functions_time, db_instance_modified_status, '200')
        else:
            raise TimeoutError(f"Timeout - Lambda reached {MAX_RETRIES} retries.")

    except botocore.exceptions.ParamValidationError as e:
        logger.error(f"Parameter validation error: {e}")
        raise ValueError(f"The parameters you provided are incorrect: {str(e)}")
    except Exception:
        logger.exception("Unhandled exception")
        raise