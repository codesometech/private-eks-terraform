variable "name" {
  description = "Name of the VPC and EKS Cluster"
  default     = "private-eks"
  type        = string
}

variable "region" {
  description = "region"
  type        = string
  default     = "us-east-1"
}

variable "eks_cluster_version" {
  description = "EKS Cluster version"
  default     = "1.23"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR"
  type        = string
}

variable "public_subnets" {
  description = "Public Subnets CIDRs. 4094 IPs per Subnet"
  type        = list(string)
}

variable "private_subnets" {
  description = "Private Subnets CIDRs. 16382 IPs per Subnet"
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC Id"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private Subnets IDs"
  type        = list(string)
}

#-------------------------------
# EKS Cluster Security Groups
#-------------------------------
variable "cluster_security_group_additional_rules" {
  description = "List of additional security group rules to add to the cluster security group created. Set `source_node_security_group = true` inside rules to set the `node_security_group` as source"
  type        = any
  default     = {
    ingress_from_cloud9_host = {
      description = "Ingress from  Cloud9 Host"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      cidr_blocks = ["10.2.0.0/16"]
    }
  }
}

variable "opensearch_arn" {
  description = "OpenSearch arn"
  type        = string
}

variable "opensearch_endpoint" {
  description = "OpenSearch endpoint"
  type        = string
}

#-------------#
# Panoptica   #
#-------------#
variable "access_key" {
  description = "Panoptica access key"
  type = string
  sensitive   = true
}

variable "secret_key" {
  description = "Panoptica secret key"
  type = string
  sensitive   = true
}