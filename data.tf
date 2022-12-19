data "aws_eks_cluster_auth" "this" {
  name = module.eks_blueprints.eks_cluster_id
}

data "aws_availability_zones" "available" {}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

#---------------------------------------------------------------
# Example IAM policy for OpenSearch
#---------------------------------------------------------------

#data "aws_iam_policy_document" "fluentbit_opensearch_access" {
#  statement {
#    sid       = "OpenSearchAccess"
#    effect    = "Allow"
#    resources = ["${var.opensearch_arn}/*"]
#    actions   = ["es:ESHttp*"]
#  }
#}

#data "aws_iam_policy_document" "opensearch_access_policy" {
#  statement {
#    effect    = "Allow"
#    resources = ["${var.opensearch_arn}/*"]
#    actions   = ["es:ESHttp*"]
#    principals {
#      type        = "*"
#      identifiers = ["*"]
#    }
#  }
#}

