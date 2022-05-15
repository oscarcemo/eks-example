locals {
  eks_tags = var.eks_tags
  eks_managed_tags = var.eks_managed_tags
  eks_cluster_version = var.eks_cluster_version
}

resource "aws_kms_key" "eks_kms" {
  description             = "KMS for EKS"
}
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "18.7.2"

  cluster_name    = "${local.cluster_name}"
  cluster_version = "${local.eks_cluster_version}"
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  subnet_ids = module.vpc.private_subnets
  vpc_id  = module.vpc.vpc_id

  cluster_security_group_additional_rules = {
    egress_nodes_ephemeral_ports_tcp = {
      description                = "To node 1025-65535"
      protocol                   = "tcp"
      from_port                  = 1025
      to_port                    = 65535
      type                       = "egress"
      source_node_security_group = true
    }
  }

  # Extend node-to-node security group rules
  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    egress_all = {
      description      = "Node all egress"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  }


  cluster_addons = {
    coredns = {
      resolve_conflicts = "OVERWRITE"
    }
    kube-proxy = {}
  }
  
  ## Enable if you want alb o network balancer ingress controller
  enable_irsa = false
  cluster_encryption_config = [{
    provider_key_arn = aws_kms_key.eks_kms.arn
    resources        = ["secrets"]
  }]
  # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    ami_type               = "AL2_x86_64"
    disk_size              = 20
    instance_types         = ["t3.medium"]
    capacity_type          = "SPOT"
    vpc_id                 = module.vpc.vpc_id
    vpc_security_group_ids = [aws_security_group.worker_group_mgmt_one.id]
  }
  eks_managed_node_groups = {
    green = {
      min_size     = 1
      max_size     = 2
      desired_size = 1
      capacity_type  = "SPOT"
      instance_types = ["t3.medium"]
      labels = {
        Environment = "test"
      }
      tags = local.eks_managed_tags
    }
  }  
  tags = local.eks_tags
  cluster_timeouts = var.eks_timeouts
}

resource "null_resource" "kubectl" {
  depends_on = [module.eks]
  provisioner "local-exec" {
    command = "aws eks --region eu-west-1 update-kubeconfig --name test-cluster"
    }
}