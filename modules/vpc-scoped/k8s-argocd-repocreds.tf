locals {
  argocd_repocreds_default = {
    for repo_name in var.argocd_addons_repo_list_names : repo_name => {
      create = var.create_argocd_repocreds

      metadata = {
        name      = "argocd-repo-creds-http-creds-${repo_name}"
        namespace = "argocd"

        annotations = {
          "meta.helm.sh/release-name"      = "argocd"
          "meta.helm.sh/release-namespace" = "argocd"
        }

        labels = {
          "app.kubernetes.io/instance"     = "argocd"
          "app.kubernetes.io/managed-by"   = "Helm"
          "app.kubernetes.io/part-of"      = "argocd"
          "app.kubernetes.io/version"      = "v2.14.8"
          "argocd.argoproj.io/secret-type" = "repo-creds"
          "helm.sh/chart"                  = "argo-cd-7.8.14"
        }
      }

      data = {
        githubAppID             = var.argocd_addons_repo_creds_app_id
        githubAppInstallationID = var.argocd_addons_repo_creds_app_installation_id
        githubAppPrivateKey     = var.argocd_addons_repo_creds_private_key
        name                    = repo_name
        url                     = "https://github.com/augustovoigt/${repo_name}"
      }

      type = "Opaque"
    }
  }

  argocd_repocreds = merge(local.argocd_repocreds_default, var.argocd_repocreds)

  argocd_repocreds_enabled = {
    for key, repocreds in local.argocd_repocreds : key => repocreds
    if try(repocreds.create, true)
  }
}

resource "kubernetes_secret_v1" "repocreds" {
  for_each = local.argocd_repocreds_enabled

  metadata {
    name        = try(each.value.metadata.name, "argocd-repo-creds-http-creds-${each.key}")
    namespace   = try(each.value.metadata.namespace, "argocd")
    labels      = try(each.value.metadata.labels, null)
    annotations = try(each.value.metadata.annotations, null)
  }

  data = each.value.data
  type = try(each.value.type, "Opaque")
}