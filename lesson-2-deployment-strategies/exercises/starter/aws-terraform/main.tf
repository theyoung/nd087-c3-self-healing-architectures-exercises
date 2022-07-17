locals {
   account_id = data.aws_caller_identity.current.account_id

   name   = "udacity"
   region = "us-east-2"
   tags = {
     Name      = local.name
     Terraform = "true"
   }
 }

data "aws_caller_identity" "current" {}

 data "aws_ami" "amazon_linux_2" {
   most_recent = true
   owners      = ["amazon"]

   filter {
     name   = "owner-alias"
     values = ["amazon"]
   }


   filter {
     name   = "name"
     values = ["amzn2-ami-hvm*"]
   }
 }
 
 module "vpc" {
   source     = "./vpc"
   cidr_block = "10.100.0.0/16"

   account_owner = local.name
   name          = "${local.name}-project"
   azs           = ["us-east-2a","us-east-2b","us-east-2c"]
   private_subnet_tags = {
     "kubernetes.io/role/internal-elb" = 1
   }
   public_subnet_tags = {
     "kubernetes.io/role/elb" = 1
   }
 }

 provider "kubernetes" {
   config_path            = "~/.kube/config"
   host                   = data.aws_eks_cluster.cluster.endpoint
   cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
   token                  = data.aws_eks_cluster_auth.cluster.token
 }

 data "aws_eks_cluster" "cluster" {
   name = module.project_eks.cluster_id
 }

 data "aws_eks_cluster_auth" "cluster" {
   name = module.project_eks.cluster_id
 }

 module "project_eks" {
   source             = "./eks"
   name               = local.name
   account            = data.aws_caller_identity.current.account_id
   private_subnet_ids = module.vpc.private_subnet_ids
   vpc_id             = module.vpc.vpc_id
   nodes_desired_size = 1
   nodes_max_size     = 2
   nodes_min_size     = 1

   depends_on = [
    module.vpc,
   ]
 }