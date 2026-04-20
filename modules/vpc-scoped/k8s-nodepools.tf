locals {
  # base nodepool
  nodepool_base_default = {
    apiVersion = "karpenter.sh/v1"
    kind       = "NodePool"
    metadata = {
      name = ""
    }
    spec = {
      template = {
        metadata = {
          labels = {}
        }
        spec = {
          terminationGracePeriod = "30s"
          expireAfter            = "720h"
          nodeClassRef = {
            group = "karpenter.k8s.aws"
            kind  = "EC2NodeClass"
            name  = "bottlerocket-v2"
          }
          requirements = [
            {
              key      = "karpenter.sh/capacity-type"
              operator = "In"
              values   = ["on-demand", "spot"]
            },
            {
              key      = "karpenter.k8s.aws/instance-hypervisor"
              operator = "In"
              values   = ["nitro"]
            },
            {
              key      = "karpenter.k8s.aws/instance-family"
              operator = "NotIn"
              values   = ["a1", "g6f"]
            },
            {
              key      = "karpenter.k8s.aws/instance-memory"
              operator = "Gt"
              values   = ["4000"]
            },
            {
              key      = "karpenter.k8s.aws/instance-cpu"
              operator = "Gt"
              values   = ["1"]
            }
          ]
        }
      }
      limits = {
        cpu                     = "512"
        memory                  = "1536Gi"
        "nvidia.com/gpu"        = 0
        "aws.amazon.com/neuron" = 0
        "amd.com/gpu"           = 0
      }
      disruption = {
        consolidationPolicy = "WhenEmpty"
        consolidateAfter    = "30s"
      }
      weight = 10
    }
  }

  # arch requirements
  amd64_requirement_default = {
    key      = "kubernetes.io/arch"
    operator = "In"
    values   = ["amd64"]
  }
  arm64_requirement_default = {
    key      = "kubernetes.io/arch"
    operator = "In"
    values   = ["arm64"]
  }

  # nodepools definition
  nodepools_default = merge(
    {
      for env in ["prod", "nonprod"] : "amd64-${env}" => merge(local.nodepool_base_default, {
        metadata = {
          name = "platform-ops-amd64-${env}"
        }
        spec = merge(local.nodepool_base_default.spec, {
          template = merge(local.nodepool_base_default.spec.template, {
            metadata = {
              labels = {
                env = env
              }
            }
            spec = merge(local.nodepool_base_default.spec.template.spec, {
              taints = [
                {
                  key    = "env"
                  value  = env
                  effect = "NoSchedule"
                }
              ]
              requirements = concat(
                local.nodepool_base_default.spec.template.spec.requirements,
                [local.amd64_requirement_default]
              )
            })
          })
        })
      })
    },
    {
      for env in ["prod", "nonprod"] : "arm64-${env}" => merge(local.nodepool_base_default, {
        metadata = {
          name = "platform-ops-arm64-${env}"
        }
        spec = merge(local.nodepool_base_default.spec, {
          template = merge(local.nodepool_base_default.spec.template, {
            metadata = {
              labels = {
                env = env
              }
            }
            spec = merge(local.nodepool_base_default.spec.template.spec, {
              taints = [
                {
                  key    = "env"
                  value  = env
                  effect = "NoSchedule"
                }
              ]
              requirements = concat(
                local.nodepool_base_default.spec.template.spec.requirements,
                [local.arm64_requirement_default]
              )
            })
          })
        })
      })
    }
  )

  nodepools = merge(local.nodepools_default, var.nodepools)
}

resource "kubectl_manifest" "this" {
  for_each = var.create_nodepool ? local.nodepools : {}

  yaml_body = yamlencode(each.value)
}