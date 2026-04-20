locals {
  namespaces_default = {
    platform_ops = {
      create = var.create_namespace_platform_ops
      metadata = {
        name = "platform-ops"
      }
    }
    platform_ops_addons = {
      create = var.create_namespace_platform_ops_addons
      metadata = {
        name = "platform-ops-addons"
      }
    }
    platform_ops_customers = {
      create = var.create_namespace_platform_ops_customers
      metadata = {
        name = "platform-ops-customers"
      }
    }
    platform_ops_internal = {
      create = var.create_namespace_platform_ops_internal
      metadata = {
        name = "platform-ops-internal"
      }
    }
  }

  namespaces = merge(local.namespaces_default, var.namespaces)
}

resource "kubernetes_namespace_v1" "namespaces" {
  for_each = { for k, v in local.namespaces : k => v if try(v.create, true) }

  metadata {
    name        = try(each.value.metadata.name, each.key)
    labels      = try(each.value.metadata.labels, null)
    annotations = try(each.value.metadata.annotations, null)
  }
}