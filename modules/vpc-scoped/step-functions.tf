locals {
  step_functions_default = {
    dump_rds = {
      create            = var.create_step_function_dump_rds
      name              = "${var.resource_prefix}-dump-rds"
      type              = "standard"
      create_role       = false
      use_existing_role = true
      role_key          = "step_functions_dump_rds"

      definition = jsonencode(
        {
          Comment = "State Machine - Responsible to execute Dump RDS Process"
          StartAt = "Lambda Invoke - RDS Create Snapshot"
          States = {
            Fail = {
              CausePath = "$.Cause.Cause.Cause"
              Type      = "Fail"
            }
            "Lambda Invoke - RDS Create Snapshot" = {
              Catch = [
                {
                  Comment = "Lambda - Exception Error"
                  ErrorEquals = [
                    "Exception",
                  ]
                  Next       = "Fail"
                  ResultPath = "$.Cause.Cause"
                },
              ]
              Next = "Wait 15 Seconds - RDS Create Snapshot"
              Parameters = {
                FunctionName = var.lambda_rds_create_snapshot_arn
                "Payload.$"  = "$"
              }
              Resource   = "arn:aws:states:::lambda:invoke"
              ResultPath = "$.LambdaRDSCreateSnapshot"
              Retry = [
                {
                  BackoffRate = 2
                  ErrorEquals = [
                    "Lambda.ServiceException",
                    "Lambda.AWSLambdaException",
                    "Lambda.SdkClientException",
                    "Lambda.TooManyRequestsException",
                  ]
                  IntervalSeconds = 1
                  MaxAttempts     = 3
                },
              ]
              Type = "Task"
            }
            "Wait 15 Seconds - RDS Create Snapshot" = {
              Comment = "Pausing for 15 seconds before re-running the Lambda function"
              Next    = "Validate Lambda Return - RDS Create Snapshot"
              Seconds = 15
              Type    = "Wait"
            }
            "Validate Lambda Return - RDS Create Snapshot" = {
              Choices = [
                {
                  Comment = "Validate lambda execution result"
                  Next    = "Lambda Invoke - RDS Create Snapshot"
                  Not = {
                    StringEquals = "available"
                    Variable     = "$.LambdaRDSCreateSnapshot.Payload.db_instance_snapshot_status"
                  }
                },
              ]
              Default = "Lambda Invoke - RDS Delete Instance"
              Type    = "Choice"
            }
            "Lambda Invoke - RDS Delete Instance" = {
              Catch = [
                {
                  Comment = "Lambda - Exception Error"
                  ErrorEquals = [
                    "Exception",
                  ]
                  Next       = "Fail"
                  ResultPath = "$.Cause.Cause"
                },
              ]
              Next = "Wait 15 Seconds - RDS Delete Instance"
              Parameters = {
                FunctionName = var.lambda_rds_delete_instance_arn
                "Payload.$"  = "$"
              }
              Resource   = "arn:aws:states:::lambda:invoke"
              ResultPath = "$.LambdaRDSDeleteInstance"
              Retry = [
                {
                  BackoffRate = 2
                  ErrorEquals = [
                    "Lambda.ServiceException",
                    "Lambda.AWSLambdaException",
                    "Lambda.SdkClientException",
                    "Lambda.TooManyRequestsException",
                  ]
                  IntervalSeconds = 1
                  MaxAttempts     = 3
                },
              ]
              Type = "Task"
            }
            "Wait 15 Seconds - RDS Delete Instance" = {
              Comment = "Pausing for 15 seconds before re-running the Lambda function"
              Next    = "Validate Lambda Return - RDS Delete Instance"
              Seconds = 15
              Type    = "Wait"
            }
            "Validate Lambda Return - RDS Delete Instance" : {
              "Type" : "Choice",
              "Comment" : "Checks if the RDS instance deletion was successful. If the status is 'deleted' or 'skipped-rds-not-found', proceed to restoring the snapshot. Otherwise, retry deletion.",
              "Choices" : [
                {
                  "Or" : [
                    {
                      "Variable" : "$.LambdaRDSDeleteInstance.Payload.db_instance_deleted_status",
                      "StringEquals" : "deleted"
                    },
                    {
                      "Variable" : "$.LambdaRDSDeleteInstance.Payload.db_instance_deleted_status",
                      "StringEquals" : "skipped-rds-not-found"
                    }
                  ],
                  "Next" : "Lambda Invoke - RDS Restore Snapshot"
                }
              ],
              "Default" : "Lambda Invoke - RDS Delete Instance"
            }
            "Lambda Invoke - RDS Restore Snapshot" = {
              Catch = [
                {
                  Comment = "Lambda - Exception Error"
                  ErrorEquals = [
                    "Exception",
                  ]
                  Next       = "Fail"
                  ResultPath = "$.Cause.Cause"
                },
              ]
              Next = "Wait 15 Seconds - RDS Restore Snapshot"
              Parameters = {
                FunctionName = var.lambda_rds_restore_snapshot_arn
                "Payload.$"  = "$"
              }
              Resource   = "arn:aws:states:::lambda:invoke"
              ResultPath = "$.LambdaRDSRestoreSnapshot"
              Retry = [
                {
                  BackoffRate = 2
                  ErrorEquals = [
                    "Lambda.ServiceException",
                    "Lambda.AWSLambdaException",
                    "Lambda.SdkClientException",
                    "Lambda.TooManyRequestsException",
                  ]
                  IntervalSeconds = 1
                  MaxAttempts     = 3
                },
              ]
              Type = "Task"
            }
            "Wait 15 Seconds - RDS Restore Snapshot" = {
              Comment = "Pausing for 15 seconds before re-running the Lambda function"
              Next    = "Validate Lambda Return - RDS Restore Snapshot"
              Seconds = 15
              Type    = "Wait"
            }
            "Validate Lambda Return - RDS Restore Snapshot" = {
              Choices = [
                {
                  Comment = "Validate lambda execution result"
                  Next    = "Lambda Invoke - RDS Restore Snapshot"
                  Not = {
                    StringEquals = "available"
                    Variable     = "$.LambdaRDSRestoreSnapshot.Payload.db_instance_restored_status"
                  }
                },
              ]
              Default = "Lambda Invoke - RDS Modify Instance"
              Type    = "Choice"
            }
            "Lambda Invoke - RDS Modify Instance" = {
              Catch = [
                {
                  Comment = "Lambda - Exception Error"
                  ErrorEquals = [
                    "Exception",
                  ]
                  Next       = "Fail"
                  ResultPath = "$.Cause.Cause"
                },
              ]
              Next = "Wait 15 Seconds - RDS Modify Instance"
              Parameters = {
                FunctionName = var.lambda_rds_modify_instance_arn
                "Payload.$"  = "$"
              }
              Resource   = "arn:aws:states:::lambda:invoke"
              ResultPath = "$.LambdaRDSModifyInstance"
              Retry = [
                {
                  BackoffRate = 2
                  ErrorEquals = [
                    "Lambda.ServiceException",
                    "Lambda.AWSLambdaException",
                    "Lambda.SdkClientException",
                    "Lambda.TooManyRequestsException",
                  ]
                  IntervalSeconds = 1
                  MaxAttempts     = 3
                },
              ]
              Type = "Task"
            }
            "Wait 15 Seconds - RDS Modify Instance" = {
              Comment = "Pausing for 15 seconds before re-running the Lambda function"
              Next    = "Validate Lambda Return - RDS Modify Instance"
              Seconds = 15
              Type    = "Wait"
            }
            "Validate Lambda Return - RDS Modify Instance" = {
              Choices = [
                {
                  Comment = "Validate lambda execution result"
                  Next    = "Lambda Invoke - RDS Modify Instance"
                  Not = {
                    StringEquals = "available"
                    Variable     = "$.LambdaRDSModifyInstance.Payload.db_instance_modified_status"
                  }
                },
              ]
              Default = "Lambda Invoke - RDS Oracle Update Users Credentials"
              Type    = "Choice"
            }
            "Lambda Invoke - RDS Oracle Update Users Credentials" = {
              Catch = [
                {
                  Comment = "Lambda - Exception Error"
                  ErrorEquals = [
                    "Exception",
                  ]
                  Next       = "Fail"
                  ResultPath = "$.Cause.Cause"
                },
              ]
              Next = "Lambda Invoke - RDS Oracle Execute SQL Statements"
              Parameters = {
                FunctionName = module.lambda_rds_oracle_update_users_credentials.lambda_rds_oracle_update_users_credentials.lambda_function_arn
                "Payload.$"  = "$"
              }
              Resource   = "arn:aws:states:::lambda:invoke"
              ResultPath = "$.LambdaRDSOracleUpdateUsersCredentials"
              Retry = [
                {
                  BackoffRate = 2
                  ErrorEquals = [
                    "Lambda.ServiceException",
                    "Lambda.AWSLambdaException",
                    "Lambda.SdkClientException",
                    "Lambda.TooManyRequestsException",
                  ]
                  IntervalSeconds = 15
                  MaxAttempts     = 3
                },
              ]
              Type = "Task"
            }
            "Lambda Invoke - RDS Oracle Execute SQL Statements" = {
              Catch = [
                {
                  Comment = "Lambda - Exception Error"
                  ErrorEquals = [
                    "Exception",
                  ]
                  Next       = "Fail"
                  ResultPath = "$.Cause.Cause"
                },
              ]
              Next = "Lambda Invoke - Valkey Clear Cache"
              Parameters = {
                FunctionName = module.lambda_rds_oracle_execute_sql_statements.lambda_rds_oracle_execute_sql_statements.lambda_function_arn
                "Payload.$"  = "$"
              }
              Resource   = "arn:aws:states:::lambda:invoke"
              ResultPath = "$.LambdaRDSOracleExecuteSQLStatements"
              Retry = [
                {
                  BackoffRate = 2
                  ErrorEquals = [
                    "Lambda.ServiceException",
                    "Lambda.AWSLambdaException",
                    "Lambda.SdkClientException",
                    "Lambda.TooManyRequestsException",
                  ]
                  IntervalSeconds = 1
                  MaxAttempts     = 3
                },
              ]
              Type = "Task"
            }
            "Lambda Invoke - Valkey Clear Cache" = {
              Catch = [
                {
                  Comment = "Lambda - Exception Error"
                  ErrorEquals = [
                    "Exception",
                  ]
                  Next       = "Fail"
                  ResultPath = "$.Cause.Cause"
                },
              ]
              Next = "Lambda Invoke - RDS Delete Snapshot"
              Parameters = {
                FunctionName = module.lambda_valkey_clear_cache.lambda_valkey_clear_cache.lambda_function_arn
                "Payload.$"  = "$"
              }
              Resource   = "arn:aws:states:::lambda:invoke"
              ResultPath = "$.LambdaValkeyClearCache"
              Retry = [
                {
                  BackoffRate = 2
                  ErrorEquals = [
                    "Lambda.ServiceException",
                    "Lambda.AWSLambdaException",
                    "Lambda.SdkClientException",
                    "Lambda.TooManyRequestsException",
                  ]
                  IntervalSeconds = 1
                  MaxAttempts     = 3
                },
              ]
              Type = "Task"
            }
            "Lambda Invoke - RDS Delete Snapshot" = {
              Catch = [
                {
                  Comment = "Lambda - Exception Error"
                  ErrorEquals = [
                    "Exception",
                  ]
                  Next       = "Fail"
                  ResultPath = "$.Cause.Cause"
                },
              ]
              Next = "Success"
              Parameters = {
                FunctionName = var.lambda_rds_delete_snapshot_arn
                "Payload.$"  = "$"
              }
              Resource   = "arn:aws:states:::lambda:invoke"
              ResultPath = "$.LambdaRDSDeleteSnapshot"
              Retry = [
                {
                  BackoffRate = 2
                  ErrorEquals = [
                    "Lambda.ServiceException",
                    "Lambda.AWSLambdaException",
                    "Lambda.SdkClientException",
                    "Lambda.TooManyRequestsException",
                  ]
                  IntervalSeconds = 1
                  MaxAttempts     = 3
                },
              ]
              Type = "Task"
            }
            Success = {
              Type = "Succeed"
            }
          }
        }
      )

      logging_configuration = {
        "include_execution_data" : false
        "level" : "OFF"
      }

      sfn_state_machine_timeouts = {
        create = "30m"
        delete = "50m"
        update = "30m"
      }
    }

    version_update = {
      create            = var.create_step_function_version_update
      name              = "${var.resource_prefix}-version-update"
      type              = "standard"
      create_role       = false
      use_existing_role = true
      role_key          = "step_functions_version_update"

      definition = jsonencode(
        {
          Comment = "State Machine - Responsible to execute Version Update Process"
          StartAt = "Lambda Invoke - RDS Status Check"
          States = {
            "Lambda Invoke - RDS Status Check" = {
              Catch = [
                {
                  Comment = "Lambda - Exception Error"
                  ErrorEquals = [
                    "Exception",
                  ]
                  Next       = "Fail"
                  ResultPath = "$.Cause.Cause"
                },
              ]
              Next = "Wait 15 Seconds - RDS Status Check"
              Parameters = {
                FunctionName = var.lambda_rds_status_check_arn
                "Payload.$"  = "$"
              }
              Resource   = "arn:aws:states:::lambda:invoke"
              ResultPath = "$.LambdaRDSCheckStatus"
              Retry = [
                {
                  BackoffRate = 2
                  ErrorEquals = [
                    "Lambda.ServiceException",
                    "Lambda.AWSLambdaException",
                    "Lambda.SdkClientException",
                    "Lambda.TooManyRequestsException",
                  ]
                  IntervalSeconds = 1
                  MaxAttempts     = 3
                },
              ]
              Type = "Task"
            }
            "Wait 15 Seconds - RDS Status Check" = {
              Comment = "Pausing for 15 seconds before re-running the Lambda function"
              Next    = "Validate Lambda Return - RDS Status Check"
              Seconds = 15
              Type    = "Wait"
            }
            "Validate Lambda Return - RDS Status Check" = {
              Choices = [
                {
                  Comment = "Validate lambda execution result"
                  Next    = "Lambda Invoke - RDS Status Check"
                  Not = {
                    StringEquals = "available"
                    Variable     = "$.LambdaRDSCheckStatus.Payload.db_instance_status"
                  }
                },
              ]
              Default = "Check Action"
              Type    = "Choice"
            }
            "Check Action" = {
              Type = "Choice"
              Choices = [
                {
                  Variable     = "$.action"
                  StringEquals = "prepare-update"
                  Next         = "Lambda Invoke - RDS Create Snapshot"
                },
                {
                  Variable     = "$.action"
                  StringEquals = "finish-update"
                  Next         = "Lambda Invoke - RDS Modify Instance Version Update"
                }
              ]
              Default = "Fail"
            }
            Fail = {
              CausePath = "$.Cause.Cause.Cause"
              Type      = "Fail"
            }
            "Lambda Invoke - RDS Create Snapshot" = {
              Catch = [
                {
                  Comment = "Lambda - Exception Error"
                  ErrorEquals = [
                    "Exception",
                  ]
                  Next       = "Fail"
                  ResultPath = "$.Cause.Cause"
                },
              ]
              Next = "Wait 15 Seconds - RDS Create Snapshot"
              Parameters = {
                FunctionName = var.lambda_rds_create_snapshot_arn
                "Payload.$"  = "$"
              }
              Resource   = "arn:aws:states:::lambda:invoke"
              ResultPath = "$.LambdaRDSCreateSnapshot"
              Retry = [
                {
                  BackoffRate = 2
                  ErrorEquals = [
                    "Lambda.ServiceException",
                    "Lambda.AWSLambdaException",
                    "Lambda.SdkClientException",
                    "Lambda.TooManyRequestsException",
                  ]
                  IntervalSeconds = 1
                  MaxAttempts     = 3
                },
              ]
              Type = "Task"
            }
            "Wait 15 Seconds - RDS Create Snapshot" = {
              Comment = "Pausing for 15 seconds before re-running the Lambda function"
              Next    = "Validate Lambda Return - RDS Create Snapshot"
              Seconds = 15
              Type    = "Wait"
            }
            "Validate Lambda Return - RDS Create Snapshot" = {
              Choices = [
                {
                  Comment = "Validate lambda execution result"
                  Next    = "Lambda Invoke - RDS Create Snapshot"
                  Not = {
                    StringEquals = "available"
                    Variable     = "$.LambdaRDSCreateSnapshot.Payload.db_instance_snapshot_status"
                  }
                },
              ]
              Default = "Lambda Invoke - RDS Modify Instance Version Update"
              Type    = "Choice"
            }
            "Lambda Invoke - RDS Modify Instance Version Update" = {
              Catch = [
                {
                  Comment = "Lambda - Exception Error"
                  ErrorEquals = [
                    "Exception",
                  ]
                  Next       = "Fail"
                  ResultPath = "$.Cause.Cause"
                },
              ]
              Next = "Wait 15 Seconds - RDS Modify Instance Version Update"
              Parameters = {
                FunctionName = var.lambda_rds_modify_instance_version_update_arn
                "Payload.$"  = "$"
              }
              Resource   = "arn:aws:states:::lambda:invoke"
              ResultPath = "$.LambdaRDSModifyInstance"
              Retry = [
                {
                  BackoffRate = 2
                  ErrorEquals = [
                    "Lambda.ServiceException",
                    "Lambda.AWSLambdaException",
                    "Lambda.SdkClientException",
                    "Lambda.TooManyRequestsException",
                  ]
                  IntervalSeconds = 1
                  MaxAttempts     = 3
                },
              ]
              Type = "Task"
            }
            "Wait 15 Seconds - RDS Modify Instance Version Update" = {
              Comment = "Pausing for 15 seconds before re-running the Lambda function"
              Next    = "Validate Lambda Return - RDS Modify Instance Version Update"
              Seconds = 15
              Type    = "Wait"
            }
            "Validate Lambda Return - RDS Modify Instance Version Update" = {
              Choices = [
                {
                  Comment = "Validate lambda execution result"
                  Next    = "Lambda Invoke - RDS Modify Instance Version Update"
                  Not = {
                    StringEquals = "available"
                    Variable     = "$.LambdaRDSModifyInstance.Payload.db_instance_modified_status"
                  }
                },
              ]
              Default = "Check Post-Modify Action"
              Type    = "Choice"
            }
            "Check Post-Modify Action" = {
              Type = "Choice"
              Choices = [
                {
                  Variable     = "$.action"
                  StringEquals = "finish-update"
                  Next         = "Lambda Invoke - Valkey Clear Cache"
                }
              ]
              Default = "Success"
            }
            "Lambda Invoke - Valkey Clear Cache" = {
              Catch = [
                {
                  Comment = "Lambda - Exception Error"
                  ErrorEquals = [
                    "Exception",
                  ]
                  Next       = "Fail"
                  ResultPath = "$.Cause.Cause"
                },
              ]
              Next = "Success"
              Parameters = {
                FunctionName = module.lambda_valkey_clear_cache.lambda_valkey_clear_cache.lambda_function_arn
                "Payload.$"  = "$"
              }
              Resource   = "arn:aws:states:::lambda:invoke"
              ResultPath = "$.LambdaValkeyClearCache"
              Retry = [
                {
                  BackoffRate = 2
                  ErrorEquals = [
                    "Lambda.ServiceException",
                    "Lambda.AWSLambdaException",
                    "Lambda.SdkClientException",
                    "Lambda.TooManyRequestsException",
                  ]
                  IntervalSeconds = 1
                  MaxAttempts     = 3
                },
              ]
              Type = "Task"
            }
            Success = {
              Type = "Succeed"
            }
          }
        }
      )

      logging_configuration = {
        "include_execution_data" : false
        "level" : "OFF"
      }

      sfn_state_machine_timeouts = {
        create = "30m"
        delete = "50m"
        update = "30m"
      }
    }
  }

  step_functions = merge(local.step_functions_default, var.step_functions)
}

module "step_functions" {
  source  = "terraform-aws-modules/step-functions/aws"
  version = "5.1.0"

  for_each = { for k, v in local.step_functions : k => v if try(v.create, true) }

  create            = each.value.create
  name              = each.value.name
  type              = try(each.value.type, "standard")
  create_role       = try(each.value.create_role, false)
  use_existing_role = try(each.value.use_existing_role, true)
  role_arn          = module.iam_roles[each.value.role_key].arn

  definition = each.value.definition

  logging_configuration      = try(each.value.logging_configuration, null)
  sfn_state_machine_timeouts = try(each.value.sfn_state_machine_timeouts, null)
}