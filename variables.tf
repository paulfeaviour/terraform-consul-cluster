
//variable "consul_bootstrap_expect" { default = "3" }

#--------------------------------------------------------------
# AWS settings
#--------------------------------------------------------------
variable "access_key" {}

variable "secret_key" {}

variable "aws_region" {
    default = "eu-west-1"
    description = "The region of AWS"
}

variable "aws_key_name" {
    description = "SSH key name in your AWS account for AWS instances."    
}

variable "aws_key_path" {
    description = "Path to SSH private key."    
}

variable "aws_instance_type" {
    default = "m1.small"
    description = "Name of the AWS instance type"
}

variable "aws_instance_user" {}

#--------------------------------------------------------------
# AWS VPC settings
#--------------------------------------------------------------

variable "vpc_name" { 
    default = "my-vpc"
    description = "Name of the AWS VPC"
}

variable "vpc_cidr" { 
    description = "CIDR for the whole VPC"
    default = "10.0.0.0/16"
}

variable "vpc_public_subnets" { 
    description = "CIDR for the Public Subnet"
    default = "10.0.101.0/24,10.0.102.0/24,10.0.103.0/24"
}

variable "vpc_private_subnets" { 
    description = "CIDR for the Private Subnet"
    default = "10.0.1.0/24,10.0.2.0/24,10.0.3.0/24"
}



/* ECS optimized AMIs per region */
variable "aws_amis" {
    default = {
        eu-west-1 = "ami-69b9941e"
        //Amazon ECS-Optimized Amazon Linux AMI (ami-6b12271c)
        // eu-west-1 = "ami-0da6937a"
    }
}

variable "aws_availability_zones" {
    default = "eu-west-1a,eu-west-1b,eu-west-1c"
    description = "Comma separated list of EC2 availability zones to launch instances, must be withing region"
}

variable "user_data" {
    default = ""
    description = "The path to a file with user_data for the instances"
}

