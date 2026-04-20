locals {
  apps_namespace      = try(kubernetes_namespace_v1.namespaces["platform_ops"].metadata[0].name, null)
  customers_namespace = try(kubernetes_namespace_v1.namespaces["platform_ops_customers"].metadata[0].name, null)
  internal_namespace  = try(kubernetes_namespace_v1.namespaces["platform_ops_internal"].metadata[0].name, null)
  aws_cluster_id      = var.eks_oidc_provider != null ? basename(trimsuffix(var.eks_oidc_provider, "/")) : null

  addons_monitoring_role_names = {
    finops_cronjob          = try(module.iam_roles["finops_cronjob"].name, "")
    cloudwatch_exporter     = try(module.iam_roles["cloudwatch_exporter"].name, "")
    prometheus_rds_exporter = try(module.iam_roles["prometheus_rds_exporter"].name, "")
  }

  projects = {
    "platform-ops" : {
      namespace : "argocd"
      description : "Platform Ops Applications"
      destinations : [
        {
          server : "https://kubernetes.default.svc"
          name : "in-cluster"
          namespace : "argocd"
        },
        {
          server : "https://kubernetes.default.svc"
          name : "in-cluster"
          namespace : "platform-ops-addons"
        },
        {
          server : "https://kubernetes.default.svc"
          name : "in-cluster"
          namespace : local.apps_namespace
        }
      ]
      additionalLabels : {
        "app.kubernetes.io/managed-by" : "Helm"
      }
      additionalAnnotations : {
        "meta.helm.sh/release-name" : "cluster-apps"
        "meta.helm.sh/release-namespace" : local.apps_namespace
      }
      finalizers : ["resources-finalizer.argocd.argoproj.io"]
      sourceRepos : compact([
        "https://github.com/augustovoigt/platform-ops-charts",
      ])
      clusterResourceBlacklist : []
      clusterResourceWhitelist : [{
        kind : "*"
        group : "*"
      }]
      namespaceResourceBlacklist : []
      namespaceResourceWhitelist : [{
        kind : "*"
        group : "*"
      }]
      orphanedResources : null
      roles : []
      signatureKeys : null
      sourceNamespaces : [
        "argocd",
        local.apps_namespace,
      ]
      syncWindows : var.sync_windows_ops
    }

    "platform-ops-customers" : {
      namespace : "argocd"
      description : "Platform Ops Customers"
      destinations : [
        {
          server : "https://kubernetes.default.svc"
          name : "in-cluster"
          namespace : "argocd"
        },
        {
          server : "https://kubernetes.default.svc"
          name : "in-cluster"
          namespace : local.customers_namespace
        },
        {
          server : "https://kubernetes.default.svc"
          name : "in-cluster"
          namespace : "customer-*"
        }
      ]
      additionalLabels : {
        "app.kubernetes.io/managed-by" : "Helm"
      }
      additionalAnnotations : {
        "meta.helm.sh/release-name" : "cluster-apps"
        "meta.helm.sh/release-namespace" : local.apps_namespace
      }
      finalizers : ["resources-finalizer.argocd.argoproj.io"]
      sourceRepos : compact([
        "https://github.com/augustovoigt/argocd-infra",
        "https://github.com/augustovoigt/platform-ops-charts",
        "https://github.com/augustovoigt/platform-charts",
      ])
      clusterResourceBlacklist : []
      clusterResourceWhitelist : [{
        kind : "*"
        group : "*"
      }]
      namespaceResourceBlacklist : []
      namespaceResourceWhitelist : [{
        kind : "*"
        group : "*"
      }]
      orphanedResources : null
      roles : []
      signatureKeys : null
      sourceNamespaces : [
        "argocd",
        local.customers_namespace,
      ]
      syncWindows : var.sync_windows_ops_customers
    }

    "platform-ops-internal" : {
      namespace : "argocd"
      description : "Platform Ops Internal"
      destinations : [
        {
          server : "https://kubernetes.default.svc"
          name : "in-cluster"
          namespace : "argocd"
        },
        {
          server : "https://kubernetes.default.svc"
          name : "in-cluster"
          namespace : local.internal_namespace
        },
        {
          server : "https://kubernetes.default.svc"
          name : "in-cluster"
          namespace : "internal-*"
        }
      ]
      additionalLabels : {
        "app.kubernetes.io/managed-by" : "Helm"
      }
      additionalAnnotations : {
        "meta.helm.sh/release-name" : "cluster-apps"
        "meta.helm.sh/release-namespace" : local.apps_namespace
      }
      finalizers : ["resources-finalizer.argocd.argoproj.io"]
      sourceRepos : compact([
        "https://github.com/augustovoigt/argocd-infra",
        "https://github.com/augustovoigt/platform-ops-charts",
        "https://github.com/augustovoigt/platform-charts",
      ])
      clusterResourceBlacklist : []
      clusterResourceWhitelist : [{
        kind : "*"
        group : "*"
      }]
      namespaceResourceBlacklist : []
      namespaceResourceWhitelist : [{
        kind : "*"
        group : "*"
      }]
      orphanedResources : null
      roles : []
      signatureKeys : null
      sourceNamespaces : [
        "argocd",
        local.internal_namespace,
      ]
      syncWindows : var.sync_windows_ops_internal
    }
  }

  apps = {
    "addons" = var.addons_enable ? {
      namespace : local.apps_namespace
      project : "platform-ops"
      source : {
        repoURL : "https://github.com/augustovoigt/platform-ops-charts"
        targetRevision : var.addons_revision
        path : "charts/addons"
        helm : {
          valuesObject : {
            revision : var.addons_revision
            general : {
              aws : {
                accountID : var.aws_account_id
                clusterID : local.aws_cluster_id
                region : var.aws_region
                resourcePrefix : var.resource_prefix
              }
            }
            crossplaneProviders : merge(
              {
                enabled : var.addons_crossplane_providers.enabled
              },
              var.addons_crossplane_providers.upboundProviderAwsEC2 != null ? {
                upboundProviderAwsEC2 : {
                  enabled = var.addons_crossplane_providers.upboundProviderAwsEC2.enabled
                }
              } : {}
            )
            githubRunners : {
              enabled : var.addons_enable_github_runners
            }
            kubernetesEventExporter : {
              enabled : var.addons_enable_kubernetes_event_exporter
            }
            monitoring : {
              enabled : var.addons_enable_monitoring
              finopsCronjob : {
                roleName : local.addons_monitoring_role_names.finops_cronjob
              }
              cloudwatchExporter : {
                roleName : local.addons_monitoring_role_names.cloudwatch_exporter
              }
              prometheusRdsExporter : {
                roleName : local.addons_monitoring_role_names.prometheus_rds_exporter
              }
            }
            stakaterReloader : {
              enabled : var.addons_enable_stakater_reloader
            }
            pciAddons : {
              enabled : var.addons_enable_pci_addons
              patches : {
                ingressNginxController : {
                  enabled : var.addons_enable_pci_addons_patches
                  bucket : "nlb-access-logs-${var.aws_account_id}-${var.aws_region}"
                  prefix : "${var.resource_prefix}-ingress"
                }
              }
              utilities : {
                efsCsiDriver : {
                  enabled : var.addons_enable_pci_addons_efs_csi_driver
                }
              }
            }
          }
        }
      }
      destination : {
        server : "https://kubernetes.default.svc"
        namespace : local.apps_namespace
      }
      finalizers : ["resources-finalizer.argocd.argoproj.io"]
      additionalLabels : {
        "app.kubernetes.io/managed-by" : "Helm"
      }
      additionalAnnotations : {
        "meta.helm.sh/release-name" : "cluster-apps"
        "meta.helm.sh/release-namespace" : local.apps_namespace
        "argocd.argoproj.io/manifest-generate-paths" : "./addons"
        "argocd.argoproj.io/sync-wave" : "1"
      }
      syncPolicy : {
        automated : {
          selfHeal : true
          prune : true
          preserveResourcesOnDeletion : true
        }
        syncOptions : compact([
          "CreateNamespace=true",
          "PruneLast=true"
        ])
      }
      ignoreDifferences : []
      info : []
    } : null,

    "customers" : {
      namespace : local.customers_namespace
      project : "platform-ops-customers"
      source : {
        repoURL : "https://github.com/augustovoigt/argocd-infra"
        targetRevision : var.customers_revision
        path : "argocd/customers/${var.aws_account_id}/${var.aws_region}/${var.resource_prefix}"
        directory : {
          recurse : true
          jsonnet : {}
        }
      }
      destination : {
        server : "https://kubernetes.default.svc"
        namespace : local.customers_namespace
      }
      finalizers : ["resources-finalizer.argocd.argoproj.io"]
      additionalLabels : {
        "app.kubernetes.io/managed-by" : "Helm"
      }
      additionalAnnotations : {
        "meta.helm.sh/release-name" : "cluster-apps"
        "meta.helm.sh/release-namespace" : local.apps_namespace
        "argocd.argoproj.io/manifest-generate-paths" : "argocd/customers/${var.aws_account_id}/${var.aws_region}/${var.resource_prefix}"
        "argocd.argoproj.io/sync-wave" : "2"
      }
      syncPolicy : {
        automated : {
          selfHeal : true
          prune : true
          preserveResourcesOnDeletion : true
        }
        syncOptions : compact([
          "CreateNamespace=true",
          "PruneLast=true"
        ])
      }
      ignoreDifferences : [
        {
          group : "*"
          kind : "*"
          jsonPointers : ["/spec/destination/retry"]
        }
      ]
      info : []
    }

    "internal" : {
      namespace : local.internal_namespace
      project : "platform-ops-internal"
      source : {
        repoURL : "https://github.com/augustovoigt/argocd-infra"
        targetRevision : var.internal_revision
        path : "argocd/internal/${var.aws_account_id}/${var.aws_region}/${var.resource_prefix}"
        directory : {
          recurse : true
          jsonnet : {}
        }
      }
      destination : {
        server : "https://kubernetes.default.svc"
        namespace : local.internal_namespace
      }
      finalizers : ["resources-finalizer.argocd.argoproj.io"]
      additionalLabels : {
        "app.kubernetes.io/managed-by" : "Helm"
      }
      additionalAnnotations : {
        "meta.helm.sh/release-name" : "cluster-apps"
        "meta.helm.sh/release-namespace" : local.apps_namespace
        "argocd.argoproj.io/manifest-generate-paths" : "argocd/internal/${var.aws_account_id}/${var.aws_region}/${var.resource_prefix}"
        "argocd.argoproj.io/sync-wave" : "3"
      }
      syncPolicy : {
        automated : {
          selfHeal : true
          prune : true
          preserveResourcesOnDeletion : true
        }
        syncOptions : compact([
          "CreateNamespace=true",
          "PruneLast=true"
        ])
      }
      ignoreDifferences : [
        {
          group : "*"
          kind : "*"
          jsonPointers : ["/spec/destination/retry"]
        }
      ]
      info : []
    }
  }

  apps_enabled = { for k, v in local.apps : k => v if v != null }
}

resource "helm_release" "cluster_apps" {
  count            = var.create_argocd_apps ? 1 : 0
  name             = "cluster-apps"
  namespace        = local.apps_namespace
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argocd-apps"
  version          = var.apps_chart_version
  max_history      = 10
  create_namespace = true

  # granular blocks to have better diffs
  values = [
    yamlencode({
      projects = local.projects
    }),
    yamlencode({
      applications = local.apps_enabled
    }),
  ]

}

/* output "projects_yaml_debug" {
  value = yamlencode({ projects = local.projects })
}

output "apps_yaml_debug" {
  value = yamlencode({ applications = local.apps_enabled })
} */