# AWS RDS

locals {
  default_rds_parameter_groups = {
    oracle_se2_19_t3_medium = {
      name        = "pg-oracle-se2-19-t3-medium"
      family      = "oracle-se2-19"
      description = "Parameter group for pg-oracle-se2-19-t3-medium"
      parameters = [
        { name = "cursor_sharing", value = "EXACT" },
        { name = "db_cache_advice", value = "ON" },
        { name = "db_cache_size", value = "1156579328" },
        { name = "_fix_control", value = "17376322:OFF" },
        { name = "java_pool_size", value = "83886080" },
        { name = "max_string_size", value = "EXTENDED" },
        { name = "plsql_ccflags", value = "HAS_IDIOGRAM:TRUE" },
        { name = "memory_max_target", value = "0", apply_method = "pending-reboot" },
        { name = "recyclebin", value = "OFF", apply_method = "pending-reboot" },
        { name = "memory_target", value = "0", apply_method = "pending-reboot" },
        { name = "nls_length_semantics", value = "CHAR" },
        { name = "open_cursors", value = "5000" },
        { name = "optimizer_index_caching", value = "70" },
        { name = "optimizer_index_cost_adj", value = "1" },
        { name = "optimizer_mode", value = "ALL_ROWS" },
        { name = "pga_aggregate_target", value = "734003200" },
        { name = "processes", value = "300", apply_method = "pending-reboot" },
        { name = "sga_max_size", value = "2569011200", apply_method = "pending-reboot" },
        { name = "sga_target", value = "2569011200" },
        { name = "temp_undo_enabled", value = "TRUE", apply_method = "pending-reboot" },
        { name = "session_cached_cursors", value = "1500", apply_method = "pending-reboot" },
        { name = "optimizer_adaptive_plans", value = "FALSE" },
        { name = "optimizer_adaptive_statistics", value = "FALSE" },
        { name = "log_checkpoint_interval", value = "600" },
        { name = "log_checkpoint_timeout", value = "30" },
        { name = "shared_pool_size", value = "1156579328" },
        { name = "sqlnetora.sqlnet.allowed_logon_version_client", value = "11" },
        { name = "sqlnetora.sqlnet.allowed_logon_version_server", value = "11" },
        { name = "job_queue_processes", value = "100" },
        { name = "streams_pool_size", value = "33554432" }
      ]
    }

    oracle_se2_19_t3_large = {
      name        = "pg-oracle-se2-19-t3-large"
      family      = "oracle-se2-19"
      description = "Parameter group for pg-oracle-se2-19-t3-large"
      parameters = [
        { name = "cursor_sharing", value = "EXACT" },
        { name = "db_cache_advice", value = "ON" },
        { name = "db_cache_size", value = "2464153600" },
        { name = "plsql_ccflags", value = "HAS_IDIOGRAM:TRUE" },
        { name = "recyclebin", value = "OFF", apply_method = "pending-reboot" },
        { name = "_fix_control", value = "17376322:OFF" },
        { name = "java_pool_size", value = "125829120" },
        { name = "large_pool_size", value = "83886080" },
        { name = "max_string_size", value = "EXTENDED" },
        { name = "memory_max_target", value = "0", apply_method = "pending-reboot" },
        { name = "memory_target", value = "0", apply_method = "pending-reboot" },
        { name = "nls_length_semantics", value = "CHAR" },
        { name = "open_cursors", value = "3000" },
        { name = "optimizer_index_caching", value = "70" },
        { name = "optimizer_index_cost_adj", value = "1" },
        { name = "optimizer_mode", value = "ALL_ROWS" },
        { name = "pga_aggregate_target", value = "1468006400" },
        { name = "processes", value = "300", apply_method = "pending-reboot" },
        { name = "sga_max_size", value = "5368709120", apply_method = "pending-reboot" },
        { name = "sga_target", value = "5368709120" },
        { name = "temp_undo_enabled", value = "TRUE", apply_method = "pending-reboot" },
        { name = "session_cached_cursors", value = "1500", apply_method = "pending-reboot" },
        { name = "optimizer_adaptive_plans", value = "FALSE" },
        { name = "optimizer_adaptive_statistics", value = "FALSE" },
        { name = "log_checkpoint_interval", value = "600" },
        { name = "log_checkpoint_timeout", value = "30" },
        { name = "shared_pool_size", value = "2181038080" },
        { name = "sqlnetora.sqlnet.allowed_logon_version_client", value = "11" },
        { name = "sqlnetora.sqlnet.allowed_logon_version_server", value = "11" },
        { name = "job_queue_processes", value = "100" },
        { name = "streams_pool_size", value = "67108864" }
      ]
    }

    oracle_se2_19_t3_xlarge = {
      name        = "pg-oracle-se2-19-t3-xlarge"
      family      = "oracle-se2-19"
      description = "Parameter group for pg-oracle-se2-19-t3-xlarge"
      parameters = [
        { name = "cursor_sharing", value = "EXACT" },
        { name = "db_cache_advice", value = "ON" },
        { name = "db_cache_size", value = "5368709120" },
        { name = "_fix_control", value = "17376322:OFF" },
        { name = "java_pool_size", value = "167772160" },
        { name = "large_pool_size", value = "125829120" },
        { name = "max_string_size", value = "EXTENDED" },
        { name = "memory_max_target", value = "0", apply_method = "pending-reboot" },
        { name = "memory_target", value = "0", apply_method = "pending-reboot" },
        { name = "nls_length_semantics", value = "CHAR" },
        { name = "open_cursors", value = "3000" },
        { name = "optimizer_index_caching", value = "70" },
        { name = "optimizer_index_cost_adj", value = "1" },
        { name = "optimizer_mode", value = "ALL_ROWS" },
        { name = "pga_aggregate_target", value = "2726297600" },
        { name = "plsql_ccflags", value = "HAS_IDIOGRAM:TRUE" },
        { name = "recyclebin", value = "OFF", apply_method = "pending-reboot" },
        { name = "processes", value = "600", apply_method = "pending-reboot" },
        { name = "sga_max_size", value = "10800332800", apply_method = "pending-reboot" },
        { name = "sga_target", value = "10800332800" },
        { name = "temp_undo_enabled", value = "TRUE", apply_method = "pending-reboot" },
        { name = "session_cached_cursors", value = "1500", apply_method = "pending-reboot" },
        { name = "optimizer_adaptive_plans", value = "FALSE" },
        { name = "optimizer_adaptive_statistics", value = "FALSE" },
        { name = "log_checkpoint_interval", value = "600" },
        { name = "log_checkpoint_timeout", value = "30" },
        { name = "shared_pool_size", value = "4831838208" },
        { name = "sqlnetora.sqlnet.allowed_logon_version_client", value = "11" },
        { name = "sqlnetora.sqlnet.allowed_logon_version_server", value = "11" },
        { name = "job_queue_processes", value = "100" },
        { name = "streams_pool_size", value = "83886080" }
      ]
    }

    oracle_se2_19_t3_2xlarge = {
      name        = "pg-oracle-se2-19-t3-2xlarge"
      family      = "oracle-se2-19"
      description = "Parameter group for pg-oracle-se2-19-t3-2xlarge"
      parameters = [
        { name = "cursor_sharing", value = "EXACT" },
        { name = "db_cache_advice", value = "ON" },
        { name = "db_cache_size", value = "9985589248" },
        { name = "_fix_control", value = "17376322:OFF" },
        { name = "java_pool_size", value = "178257920" },
        { name = "large_pool_size", value = "125829120" },
        { name = "max_string_size", value = "EXTENDED" },
        { name = "memory_max_target", value = "0", apply_method = "pending-reboot" },
        { name = "memory_target", value = "0", apply_method = "pending-reboot" },
        { name = "nls_length_semantics", value = "CHAR" },
        { name = "plsql_ccflags", value = "HAS_IDIOGRAM:TRUE" },
        { name = "recyclebin", value = "OFF", apply_method = "pending-reboot" },
        { name = "open_cursors", value = "3000" },
        { name = "optimizer_index_caching", value = "70" },
        { name = "optimizer_index_cost_adj", value = "1" },
        { name = "optimizer_mode", value = "ALL_ROWS" },
        { name = "pga_aggregate_target", value = "5368709120" },
        { name = "processes", value = "600", apply_method = "pending-reboot" },
        { name = "sga_max_size", value = "20535312384", apply_method = "pending-reboot" },
        { name = "sga_target", value = "20535312384" },
        { name = "temp_undo_enabled", value = "TRUE", apply_method = "pending-reboot" },
        { name = "session_cached_cursors", value = "1500", apply_method = "pending-reboot" },
        { name = "optimizer_adaptive_plans", value = "FALSE" },
        { name = "optimizer_adaptive_statistics", value = "FALSE" },
        { name = "log_checkpoint_interval", value = "600" },
        { name = "log_checkpoint_timeout", value = "30" },
        { name = "shared_pool_size", value = "8939110400" },
        { name = "sqlnetora.sqlnet.allowed_logon_version_client", value = "11" },
        { name = "sqlnetora.sqlnet.allowed_logon_version_server", value = "11" },
        { name = "job_queue_processes", value = "100" },
        { name = "streams_pool_size", value = "125829120" }
      ]
    }

    oracle_se2_19_m5_large = {
      name        = "pg-oracle-se2-19-m5-large"
      family      = "oracle-se2-19"
      description = "Parameter group for pg-oracle-se2-19-m5-large"
      parameters = [
        { name = "cursor_sharing", value = "EXACT" },
        { name = "db_cache_advice", value = "ON" },
        { name = "db_cache_size", value = "2464153600" },
        { name = "plsql_ccflags", value = "HAS_IDIOGRAM:TRUE" },
        { name = "recyclebin", value = "OFF", apply_method = "pending-reboot" },
        { name = "_fix_control", value = "17376322:OFF" },
        { name = "java_pool_size", value = "125829120" },
        { name = "large_pool_size", value = "83886080" },
        { name = "max_string_size", value = "EXTENDED" },
        { name = "memory_max_target", value = "0", apply_method = "pending-reboot" },
        { name = "memory_target", value = "0", apply_method = "pending-reboot" },
        { name = "nls_length_semantics", value = "CHAR" },
        { name = "open_cursors", value = "3000" },
        { name = "optimizer_index_caching", value = "70" },
        { name = "optimizer_index_cost_adj", value = "1" },
        { name = "optimizer_mode", value = "ALL_ROWS" },
        { name = "pga_aggregate_target", value = "1468006400" },
        { name = "processes", value = "300", apply_method = "pending-reboot" },
        { name = "sga_max_size", value = "5368709120", apply_method = "pending-reboot" },
        { name = "sga_target", value = "5368709120" },
        { name = "temp_undo_enabled", value = "TRUE", apply_method = "pending-reboot" },
        { name = "session_cached_cursors", value = "1500", apply_method = "pending-reboot" },
        { name = "optimizer_adaptive_plans", value = "FALSE" },
        { name = "optimizer_adaptive_statistics", value = "FALSE" },
        { name = "log_checkpoint_interval", value = "600" },
        { name = "log_checkpoint_timeout", value = "30" },
        { name = "shared_pool_size", value = "2181038080" },
        { name = "sqlnetora.sqlnet.allowed_logon_version_client", value = "11" },
        { name = "sqlnetora.sqlnet.allowed_logon_version_server", value = "11" },
        { name = "job_queue_processes", value = "100" },
        { name = "streams_pool_size", value = "67108864" }
      ]
    }

    oracle_se2_19_m5_xlarge = {
      name        = "pg-oracle-se2-19-m5-xlarge"
      family      = "oracle-se2-19"
      description = "Parameter group for pg-oracle-se2-19-m5-xlarge"
      parameters = [
        { name = "cursor_sharing", value = "EXACT" },
        { name = "db_cache_advice", value = "ON" },
        { name = "db_cache_size", value = "5368709120" },
        { name = "_fix_control", value = "17376322:OFF" },
        { name = "java_pool_size", value = "167772160" },
        { name = "large_pool_size", value = "125829120" },
        { name = "max_string_size", value = "EXTENDED" },
        { name = "memory_max_target", value = "0", apply_method = "pending-reboot" },
        { name = "memory_target", value = "0", apply_method = "pending-reboot" },
        { name = "nls_length_semantics", value = "CHAR" },
        { name = "open_cursors", value = "3000" },
        { name = "optimizer_index_caching", value = "70" },
        { name = "optimizer_index_cost_adj", value = "1" },
        { name = "optimizer_mode", value = "ALL_ROWS" },
        { name = "pga_aggregate_target", value = "2726297600" },
        { name = "plsql_ccflags", value = "HAS_IDIOGRAM:TRUE" },
        { name = "recyclebin", value = "OFF", apply_method = "pending-reboot" },
        { name = "processes", value = "600", apply_method = "pending-reboot" },
        { name = "sga_max_size", value = "10800332800", apply_method = "pending-reboot" },
        { name = "sga_target", value = "10800332800" },
        { name = "temp_undo_enabled", value = "TRUE", apply_method = "pending-reboot" },
        { name = "session_cached_cursors", value = "1500", apply_method = "pending-reboot" },
        { name = "optimizer_adaptive_plans", value = "FALSE" },
        { name = "optimizer_adaptive_statistics", value = "FALSE" },
        { name = "log_checkpoint_interval", value = "600" },
        { name = "log_checkpoint_timeout", value = "30" },
        { name = "shared_pool_size", value = "4831838208" },
        { name = "sqlnetora.sqlnet.allowed_logon_version_client", value = "11" },
        { name = "sqlnetora.sqlnet.allowed_logon_version_server", value = "11" },
        { name = "job_queue_processes", value = "100" },
        { name = "streams_pool_size", value = "83886080" }
      ]
    }

    oracle_se2_19_m5_2xlarge = {
      name        = "pg-oracle-se2-19-m5-2xlarge"
      family      = "oracle-se2-19"
      description = "Parameter group for pg-oracle-se2-19-m5-2xlarge"
      parameters = [
        { name = "cursor_sharing", value = "EXACT" },
        { name = "db_cache_advice", value = "ON" },
        { name = "db_cache_size", value = "9985589248" },
        { name = "_fix_control", value = "17376322:OFF" },
        { name = "java_pool_size", value = "178257920" },
        { name = "large_pool_size", value = "125829120" },
        { name = "max_string_size", value = "EXTENDED" },
        { name = "memory_max_target", value = "0", apply_method = "pending-reboot" },
        { name = "memory_target", value = "0", apply_method = "pending-reboot" },
        { name = "nls_length_semantics", value = "CHAR" },
        { name = "open_cursors", value = "3000" },
        { name = "optimizer_index_caching", value = "70" },
        { name = "optimizer_index_cost_adj", value = "1" },
        { name = "plsql_ccflags", value = "HAS_IDIOGRAM:TRUE" },
        { name = "recyclebin", value = "OFF", apply_method = "pending-reboot" },
        { name = "optimizer_mode", value = "ALL_ROWS" },
        { name = "pga_aggregate_target", value = "5368709120" },
        { name = "processes", value = "600", apply_method = "pending-reboot" },
        { name = "sga_max_size", value = "20535312384", apply_method = "pending-reboot" },
        { name = "sga_target", value = "20535312384" },
        { name = "temp_undo_enabled", value = "TRUE", apply_method = "pending-reboot" },
        { name = "session_cached_cursors", value = "1500", apply_method = "pending-reboot" },
        { name = "optimizer_adaptive_plans", value = "FALSE" },
        { name = "optimizer_adaptive_statistics", value = "FALSE" },
        { name = "log_checkpoint_interval", value = "600" },
        { name = "log_checkpoint_timeout", value = "30" },
        { name = "shared_pool_size", value = "8939110400" },
        { name = "sqlnetora.sqlnet.allowed_logon_version_client", value = "11" },
        { name = "sqlnetora.sqlnet.allowed_logon_version_server", value = "11" },
        { name = "job_queue_processes", value = "100" },
        { name = "streams_pool_size", value = "125829120" }
      ]
    }

    oracle_se2_19_m5_4xlarge = {
      name        = "pg-oracle-se2-19-m5-4xlarge"
      family      = "oracle-se2-19"
      description = "Parameter group for pg-oracle-se2-19-m5-4xlarge"
      parameters = [
        { name = "cursor_sharing", value = "EXACT" },
        { name = "db_cache_advice", value = "ON" },
        { name = "db_cache_size", value = "9985589248" },
        { name = "_fix_control", value = "17376322:OFF" },
        { name = "java_pool_size", value = "178257920" },
        { name = "large_pool_size", value = "125829120" },
        { name = "max_string_size", value = "EXTENDED" },
        { name = "memory_max_target", value = "0", apply_method = "pending-reboot" },
        { name = "memory_target", value = "0", apply_method = "pending-reboot" },
        { name = "nls_length_semantics", value = "CHAR" },
        { name = "plsql_ccflags", value = "HAS_IDIOGRAM:TRUE" },
        { name = "recyclebin", value = "OFF", apply_method = "pending-reboot" },
        { name = "open_cursors", value = "5000" },
        { name = "optimizer_index_caching", value = "70" },
        { name = "optimizer_index_cost_adj", value = "1" },
        { name = "optimizer_mode", value = "ALL_ROWS" },
        { name = "pga_aggregate_target", value = "10737418240" },
        { name = "processes", value = "600", apply_method = "pending-reboot" },
        { name = "sga_max_size", value = "37580963840", apply_method = "pending-reboot" },
        { name = "sga_target", value = "37580963840" },
        { name = "temp_undo_enabled", value = "TRUE", apply_method = "pending-reboot" },
        { name = "session_cached_cursors", value = "1500", apply_method = "pending-reboot" },
        { name = "optimizer_adaptive_plans", value = "FALSE" },
        { name = "optimizer_adaptive_statistics", value = "FALSE" },
        { name = "log_checkpoint_interval", value = "600" },
        { name = "log_checkpoint_timeout", value = "30" },
        { name = "shared_pool_size", value = "8939110400" },
        { name = "sqlnetora.sqlnet.allowed_logon_version_client", value = "11" },
        { name = "sqlnetora.sqlnet.allowed_logon_version_server", value = "11" },
        { name = "job_queue_processes", value = "100" },
        { name = "streams_pool_size", value = "125829120" }
      ]
    }

    oracle_se2_19_version_update = {
      name        = "pg-oracle-se2-19-version-update"
      family      = "oracle-se2-19"
      description = "Parameter Group used during Application update - JOB_QUEUE_PROCESS set to 0"
      parameters = [
        { name = "cursor_sharing", value = "EXACT" },
        { name = "db_cache_advice", value = "ON" },
        { name = "plsql_ccflags", value = "HAS_IDIOGRAM:TRUE" },
        { name = "recyclebin", value = "OFF", apply_method = "pending-reboot" },
        { name = "_fix_control", value = "17376322:OFF" },
        { name = "max_string_size", value = "EXTENDED" },
        { name = "memory_max_target", value = "IF({DBInstanceClassHugePagesDefault}, 0, {DBInstanceClassMemory*3/4})", apply_method = "pending-reboot" },
        { name = "memory_target", value = "IF({DBInstanceClassHugePagesDefault}, 0, {DBInstanceClassMemory*3/4})", apply_method = "pending-reboot" },
        { name = "nls_length_semantics", value = "CHAR" },
        { name = "open_cursors", value = "5000" },
        { name = "optimizer_index_caching", value = "70" },
        { name = "optimizer_index_cost_adj", value = "1" },
        { name = "optimizer_mode", value = "ALL_ROWS" },
        { name = "temp_undo_enabled", value = "TRUE", apply_method = "pending-reboot" },
        { name = "session_cached_cursors", value = "1500", apply_method = "pending-reboot" },
        { name = "optimizer_adaptive_plans", value = "FALSE" },
        { name = "optimizer_adaptive_statistics", value = "FALSE" },
        { name = "log_checkpoint_interval", value = "600" },
        { name = "log_checkpoint_timeout", value = "30" },
        { name = "sqlnetora.sqlnet.allowed_logon_version_client", value = "11" },
        { name = "sqlnetora.sqlnet.allowed_logon_version_server", value = "11" },
        { name = "job_queue_processes", value = "0" }
      ]
    }

    oracle_se2_19_t3_medium_dbreplica = {
      name        = "pg-oracle-se2-19-t3-medium-dbreplica"
      family      = "oracle-se2-19"
      description = "Parameter Group used by replica database - JOB_QUEUE_PROCESS set to 0"
      parameters = [
        { name = "cursor_sharing", value = "EXACT" },
        { name = "db_cache_advice", value = "ON" },
        { name = "plsql_ccflags", value = "HAS_IDIOGRAM:TRUE" },
        { name = "recyclebin", value = "OFF", apply_method = "pending-reboot" },
        { name = "_fix_control", value = "17376322:OFF" },
        { name = "max_string_size", value = "EXTENDED" },
        { name = "memory_max_target", value = "IF({DBInstanceClassHugePagesDefault}, 0, {DBInstanceClassMemory*3/4})", apply_method = "pending-reboot" },
        { name = "memory_target", value = "IF({DBInstanceClassHugePagesDefault}, 0, {DBInstanceClassMemory*3/4})", apply_method = "pending-reboot" },
        { name = "nls_length_semantics", value = "CHAR" },
        { name = "open_cursors", value = "5000" },
        { name = "optimizer_index_caching", value = "70" },
        { name = "optimizer_index_cost_adj", value = "1" },
        { name = "optimizer_mode", value = "ALL_ROWS" },
        { name = "temp_undo_enabled", value = "TRUE", apply_method = "pending-reboot" },
        { name = "session_cached_cursors", value = "1500", apply_method = "pending-reboot" },
        { name = "optimizer_adaptive_plans", value = "FALSE" },
        { name = "optimizer_adaptive_statistics", value = "FALSE" },
        { name = "log_checkpoint_interval", value = "600" },
        { name = "log_checkpoint_timeout", value = "30" },
        { name = "sqlnetora.sqlnet.allowed_logon_version_client", value = "11" },
        { name = "sqlnetora.sqlnet.allowed_logon_version_server", value = "11" },
        { name = "job_queue_processes", value = "0" }
      ]
    }
  }

  rds_parameter_groups = merge(local.default_rds_parameter_groups, var.rds_parameter_groups)
}

module "parameter_group" {
  for_each = var.create_rds_parameter_groups ? local.rds_parameter_groups : {}

  source          = "terraform-aws-modules/rds/aws//modules/db_parameter_group"
  version         = "7.1.0"
  use_name_prefix = false
  name            = each.value.name
  family          = each.value.family
  description     = each.value.description

  parameters = each.value.parameters
}
