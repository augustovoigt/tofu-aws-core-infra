# AWS RDS

locals {
  rds_timezones = {
    "america-chihuahua"   = "America/Chihuahua"
    "america-matamoros"   = "America/Matamoros"
    "america-mexico-city" = "America/Mexico_City"
    "america-monterrey"   = "America/Monterrey"
    "america-sao-paulo"   = "America/Sao_Paulo"
    "america-tijuana"     = "America/Tijuana"
  }

  default_rds_option_groups = {
    for k, tz in local.rds_timezones : k => {
      name                 = "og-oracle-se2-19-${k}"
      description          = "og-oracle-se2-19-${k}"
      engine_name          = "oracle-se2"
      major_engine_version = "19"
      options = [
        {
          option_name = "Timezone"
          option_settings = [
            {
              name  = "TIME_ZONE"
              value = tz
            }
          ]
        },
        { option_name = "JVM" },
        { option_name = "STATSPACK" },
        {
          option_name = "S3_INTEGRATION"
          version     = "1.0"
        }
      ]
    }
  }

  rds_option_groups = merge(local.default_rds_option_groups, var.rds_option_groups)
}

module "option_group" {
  for_each = var.create_rds_option_groups ? local.rds_option_groups : {}

  source                   = "terraform-aws-modules/rds/aws//modules/db_option_group"
  version                  = "7.1.0"
  use_name_prefix          = false
  name                     = each.value.name
  option_group_description = try(each.value.description, each.value.name)
  engine_name              = each.value.engine_name
  major_engine_version     = each.value.major_engine_version

  options = each.value.options
}