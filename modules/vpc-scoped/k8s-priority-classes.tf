############################################################
# Kubernetes - Application Priority Class                        🇧🇷
############################################################

locals {
  priority_classes_default = {
    # Top-level priority for critical deployments
    top_priority = {
      metadata          = { name = "top-priority" }
      value             = 3000000
      global_default    = false
      preemption_policy = "Never"
      description       = "Used to give priority on deployments with top-level priority."
    }

    # High priority for secrets-related objects
    secrets_objects = {
      metadata          = { name = "secrets-objects" }
      value             = 2000000
      global_default    = false
      preemption_policy = "Never"
      description       = "Used to give priority on csi-secrets-store and secrets-provider-aws objects."
    }

    # Priority for production workloads
    prod = {
      metadata          = { name = "prod" }
      value             = 1000000
      global_default    = false
      preemption_policy = "Never"
      description       = "Used to give priority on prod environments."
    }

    # Lower priority for non-production workloads
    nonprod = {
      metadata          = { name = "nonprod" }
      value             = 500000
      global_default    = false
      preemption_policy = "Never"
      description       = "Used to give priority on nonprod environments."
    }
  }

  priority_classes = merge(local.priority_classes_default, var.priority_classes)
}

resource "kubernetes_priority_class_v1" "priority_classes" {
  for_each = var.create_priority_class ? local.priority_classes : {}

  metadata {
    name = try(each.value.metadata.name, each.key)
  }

  value             = each.value.value
  global_default    = try(each.value.global_default, false)
  preemption_policy = try(each.value.preemption_policy, "Never")
  description       = try(each.value.description, null)
}