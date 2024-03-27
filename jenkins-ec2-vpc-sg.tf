# PROVIDER

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"

    }
  }
}



# VPC-JENKINS

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  name   = "myvpc" # ya name cha kahi use nay bydefault Name ghete + tyachi value console var deta and tags mde pan dete
  cidr   = var.vpc_cidr

  azs                     = data.aws_availability_zones.az.names
  public_subnets          = var.public_subnets
  map_public_ip_on_launch = "true"
  enable_dns_hostnames    = "true"
  tags = {
    Name        = "jenkins-vpc" # jat ithe Name asel tar hech name var pan apanach replace karte console var(tag +name same yatat)
    Terraform   = "true"
    Environment = "dev"
  }
}


#   SECURITY-GROUP

resource "aws_security_group" "allow_ports" {
  #name   = var.sgname # define this variable
  vpc_id = module.vpc.vpc_id# define this variable

  # Ingress rules
  dynamic "ingress" {
    for_each = var.port # define this variable
    content {
      description = "sg from VPC"
      from_port   = ingress.value #ingress.value-gave value from (ingress) meaning dynamic block name and (value) taken from for_each = var.port   
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  # Egress rule
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = var.sg-tag # define this variable
  }
}

# JENKINS-EC2

resource "aws_instance" "jenkins-ec2" {
  instance_type   = "t2.micro"
  ami             = "ami-0cd59ecaf368e5ccf"
  subnet_id = module.vpc.public_subnets[0]
  key_name = "chavi"
  vpc_security_group_ids = [aws_security_group.allow_ports.id]
  user_data       = <<-EOF
#!/bin/bash

# Update package list
sudo apt-get update -y

# Install fontconfig and OpenJDK 17
sudo apt-get install -y fontconfig openjdk-17-jre

# Install Jenkins
sudo wget -O /usr/share/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key


  echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null


sudo apt-get update -y
sudo apt-get install -y jenkins

# Ensure Jenkins service is started
sudo systemctl start jenkins
sudo systemctl enable jenkins
EOF

tags ={
Name="jenkins_ec2"
}
}



#JENKINS VPC VARIABLES


variable "public_subnets" {
  type = list(string)
  default= ["10.0.1.0/24"]
}

variable "vpc_cidr" {
  type = string
  default= "10.0.0.0/16"
}




#JENKINS EC2 VARIABLES
variable "instance_type" {
  type    = string
  default = "t2.micro"
}

#DATA BLOCKS FOR JENKINS-EC2
data "aws_availability_zones" "az"{}


#OUTPUT BLOCK FOR JENKINS EC2
output "subnet_ids" {
  value = module.vpc.public_subnets
}


#######################################variables
variable "sg-tag" {
  type = string
  default = "Name=security_group_with_22_443_8080_9000_80"
}
#variable "sgname" {}
#variable "vpc_id" {}
variable "port" {
  type    = list(number)
  default = [443, 80, 8080,9000,22] # Example values, adjust as needed.
}
