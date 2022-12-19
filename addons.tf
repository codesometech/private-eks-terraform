module "eks_blueprints_kubernetes_addons" {
  source = "github.com/aws-ia/terraform-aws-eks-blueprints//modules/kubernetes-addons?ref=v4.18.0"

  eks_cluster_id       = module.eks_blueprints.eks_cluster_id
  eks_cluster_endpoint = module.eks_blueprints.eks_cluster_endpoint
  eks_oidc_provider    = module.eks_blueprints.oidc_provider
  eks_cluster_version  = module.eks_blueprints.eks_cluster_version

  #---------------------------------------------------------------
  # Amazon EKS Managed Add-ons
  #---------------------------------------------------------------
  # EKS Addons
  enable_amazon_eks_vpc_cni            = true
  enable_amazon_eks_coredns            = true
  enable_amazon_eks_kube_proxy         = true
  enable_amazon_eks_aws_ebs_csi_driver = true

  #---------------------------------------------------------------
  # Cluster Autoscaler
  #---------------------------------------------------------------
  enable_cluster_autoscaler = true
  cluster_autoscaler_helm_config = {
    name       = "cluster-autoscaler"
    repository = "https://kubernetes.github.io/autoscaler" # (Optional) Repository URL where to locate the requested chart.
    chart      = "cluster-autoscaler"
    version    = "9.21.1"
    namespace  = "kube-system"
    timeout    = "300"
    values = [templatefile("${path.module}/helm-values/cluster-autoscaler-values.yaml", {
      aws_region       = var.region,
      eks_cluster_id   = local.name,
      operating_system = "linux"
      node_group_type  = "core"
    })]
  }
  
  #---------------------------------------------------------------
  # Fluentbit
  #---------------------------------------------------------------

  #enable_aws_for_fluentbit        = true
  #aws_for_fluentbit_irsa_policies = [aws_iam_policy.fluentbit_opensearch_access.arn]
  #aws_for_fluentbit_helm_config = {
  #  name             = "aws-for-fluent-bit"
  #  chart            = "aws-for-fluent-bit"
  #  repository       = "https://aws.github.io/eks-charts"
  #  version          = "0.1.21"
  #  namespace        = "logging"
  #  create_namespace = true
  #  values = [templatefile("${path.module}/helm-values/aws-for-fluentbit-values.yaml", {
  #    aws_region = var.region
  #    host       = var.opensearch_endpoint
  #  })]
  #}
  
  #---------------------------------------------------------------
  # AWS Load Balance Controller
  #---------------------------------------------------------------
  enable_aws_load_balancer_controller = true
  
  #---------------------------------------------------------------
  # External Secrets Operator
  #---------------------------------------------------------------
  enable_external_secrets = true
  
  tags = local.tags

}

#---------------------------------------------------------------
# GP3 Storage Class
#---------------------------------------------------------------
resource "kubectl_manifest" "gp3_sc" {
  yaml_body = <<-YAML
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
  name: gp3
parameters:
  type: gp3
  encrypted: "true"
allowVolumeExpansion: true
provisioner: ebs.csi.aws.com
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer
YAML

  depends_on = [module.eks_blueprints.eks_cluster_id]
}

#---------------------------------------------------------------
# MongoDB Community Operator
# - https://github.com/mongodb/mongodb-kubernetes-operator
# - https://artifacthub.io/packages/helm/mongodb-helm-charts/community-operator
#---------------------------------------------------------------

resource "helm_release" "mongodb_operator" {
  name             = "mongodb-operator"
  repository       = "https://mongodb.github.io/helm-charts"
  chart            = "community-operator"
  version          = "0.7.6"
  namespace        = "mongodb"
  create_namespace = true

  depends_on = [module.eks_blueprints.eks_cluster_id]
}

resource "kubectl_manifest" "mongodb-namespace" {
  yaml_body          = file("./manifests/mongodb-ns.yaml")
  
  depends_on = [helm_release.mongodb_operator]
}

resource "kubectl_manifest" "mongodb-secret" {
  yaml_body          = file("./manifests/mongodb-secret.yaml")
  override_namespace = "mongodb"
  
  depends_on = [helm_release.mongodb_operator, kubectl_manifest.mongodb-secret]
}

resource "kubectl_manifest" "mongodb" {
  yaml_body          = file("./manifests/mongodb-statefulset.yaml")
  override_namespace = "mongodb"
  
  depends_on = [helm_release.mongodb_operator, kubectl_manifest.mongodb-secret]
}


#---------------------------------------------------------------
# SecureCN plugin (https://panoptica.readme.io/docs/terraform)
#---------------------------------------------------------------

resource "securecn_k8s_cluster" "terraform_cluster" {
  name                       = "${var.name}"
  kubernetes_cluster_context = "arn:aws:eks:${var.region}:${data.aws_caller_identity.current.account_id}:cluster/${var.name}"
  orchestration_type         = "KUBERNETES"
  ci_image_validation = false
  cd_pod_template = false
  connections_control = true
  multi_cluster_communication_support = false
  inspect_incoming_cluster_connections = false
  fail_close = false
  persistent_storage = false
  minimum_replicas = 2
  
  depends_on = [module.eks_blueprints.eks_cluster_id]
}

resource "securecn_environment" "demo" {
  name = "demo"
  description = "our demo environment"
  
  kubernetes_environment {
    cluster_name = securecn_k8s_cluster.terraform_cluster.name

    namespaces_by_labels = {
      env = "demo"
    }
  }
}

