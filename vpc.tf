#--------------------------------------------------------------
# AWS VPC 
#--------------------------------------------------------------
resource "aws_vpc" "main" {
    cidr_block = "${var.vpc_cidr}"
    tags { 
        Name = "${var.vpc_name}" 
    }
}

#--------------------------------------------------------------
# AWS Internet Gateway (Public subnet)
#--------------------------------------------------------------
resource "aws_internet_gateway" "main" {
    vpc_id = "${aws_vpc.main.id}"
}

#--------------------------------------------------------------
# AWS Subnet (Private)
#--------------------------------------------------------------
resource "aws_subnet" "private" {
    vpc_id = "${aws_vpc.main.id}"
    cidr_block = "${element(split(",", var.vpc_private_subnets), count.index)}"
    availability_zone = "${element(split(",", var.aws_availability_zones), count.index)}"
    
    count = "${length(split(",", var.vpc_private_subnets))}"
    
    tags { 
        Name = "${var.vpc_name}-private" 
    }
}

/* Routing table for private subnet */
resource "aws_route_table" "private" {
    vpc_id = "${aws_vpc.main.id}"
    route {
        cidr_block = "0.0.0.0/0"
        instance_id = "${aws_instance.nat.id}"
    }    
    tags { 
        Name = "${var.vpc_name}-private" 
    }
}

/* Associate the routing table to private subnet */
resource "aws_route_table_association" "private" {
    count = "${length(split(",", var.vpc_private_subnets))}"
    subnet_id = "${element(aws_subnet.private.*.id, count.index)}"
    route_table_id = "${aws_route_table.private.id}"
}

#--------------------------------------------------------------
# AWS Subnet (Public)
#--------------------------------------------------------------
resource "aws_subnet" "public" {
    vpc_id = "${aws_vpc.main.id}"
    cidr_block = "${element(split(",", var.vpc_public_subnets), count.index)}"
    availability_zone = "${element(split(",", var.aws_availability_zones), count.index)}"
    
    count = "${length(split(",", var.vpc_public_subnets))}"
    
    tags { 
        Name = "${var.vpc_name}-public" 
    }

    map_public_ip_on_launch = true
}

/* Routing table for public subnet */
resource "aws_route_table" "public" {
    vpc_id = "${aws_vpc.main.id}"
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.main.id}"
    }
    tags { 
        Name = "${var.vpc_name}-public" 
    }
}

/* Associate the routing table to public subnet */
resource "aws_route_table_association" "public" {
    count = "${length(split(",", var.vpc_public_subnets))}"
    subnet_id = "${element(aws_subnet.public.*.id, count.index)}"
    route_table_id = "${aws_route_table.public.id}"
}

#--------------------------------------------------------------
# AWS NAT settings (also using as a bastion host)
#--------------------------------------------------------------
resource "aws_instance" "nat" {
    ami = "ami-30913f47" # this is a special ami preconfigured to do NAT
    availability_zone = "eu-west-1a"
    instance_type = "m1.small"
    key_name = "${var.aws_key_name}"
    security_groups = ["${aws_security_group.nat.id}"]
    // We only want the one NAT instance - for now
    subnet_id = "${element(aws_subnet.public.*.id, "0")}"
    associate_public_ip_address = true
    source_dest_check = false

    tags {
        Name = "VPC NAT"
    }
}

/* This enables instances in the private subnet to send requests 
   to the Internet (for example, for software updates) */
resource "aws_eip" "nat" {
    instance = "${aws_instance.nat.id}"
    vpc = true
}
