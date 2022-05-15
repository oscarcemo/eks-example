variable "region" {
  default = "eu-west-1"
}

variable "vpc_name" {
  default = "vpc_test"
}

variable "cluster_name" {
  type = string
  description = "EKS cluster name."
  default = "eks-test"
}
variable "eks_tags" {
  description = "(Optional) A mapping of tags to assign to the resource."
  type        = map(string)
  default = {
    "Project" = "Test",
    "Environment" = "Development",
    "Resource" = "EKS"
  }
}
variable "eks_managed_tags" {
  description = "(Optional) A mapping of tags to assign to the resource."
  type        = map(string)
  default = {
    "Node" = "managed"
  }
}

variable "eks_timeouts" {
  description = "(Optional) A mapping of tags to assign to the resource."
  type        = map(string)
  default = {
    "create" = "20m"
  }
}

variable "eks_cluster_version" {
  type = string
  description = "EKS cluster version."
  default = "1.21"
}