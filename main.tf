# eks vpc

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"

    }
  }
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  name   = "myvpc" # ya name cha kahi use nay bydefault Name ghete + tyachi value console var deta and tags mde pan dete
  cidr   = var.vpc_cidr

  azs                     = data.aws_availability_zones.az.names
  public_subnets          = var.public_subnets
  private_subnets         = var.private_subnets
  map_public_ip_on_launch = "false"
  enable_dns_hostnames    = "true"
  enable_nat_gateway      = "true"
  single_nat_gateway      = "true"

  tags = {
    "kubernetes.io/cluster/my-eks-cluster" = "shared"
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/my-eks-cluster" = "shared"
    "kubernetes.io/role/elb"               = 1
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/my-eks-cluster" = "shared"
    "kubernetes.io/role/internal-elb"      = 1
  }

}




#eks cluster


module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "eks-cluster"
  cluster_version = "1.29"





  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # EKS Managed Node Group(s)


  eks_managed_node_groups = {
    example = {
      min_size     = 1
      max_size     = 3
      desired_size = 1

      instance_types = ["t3.micro"]

    }
  }



  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}


#data block
data "aws_availability_zones" "az" {}