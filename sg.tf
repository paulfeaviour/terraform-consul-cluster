#--------------------------------------------------------------
# AWS Security Group (Web)
#--------------------------------------------------------------
resource "aws_security_group" "web" {
    name = "security_group_web"
    description = "Allow incoming HTTP connections."

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    // Your network's public IP address range should be here
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 8500
        to_port = 8500
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }    

    // // MongoDB
    // egress { 
    //     from_port = 27017
    //     to_port = 27017
    //     protocol = "tcp"
    //     cidr_blocks = ["10.0.1.0/24","10.0.2.0/24","10.0.3.0/24"]
    // }
      
    vpc_id = "${aws_vpc.main.id}"

    tags {
        Name = "WebServerSG"
    }
}

#--------------------------------------------------------------
# AWS Security Group (NAT)
#--------------------------------------------------------------
resource "aws_security_group" "nat" {
    name = "security_group_nat"
    description = "Allow traffic to pass from the private subnet to the internet"

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["10.0.1.0/24","10.0.2.0/24","10.0.3.0/24"]
    }

    // Docker pull requires https
    ingress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["10.0.1.0/24","10.0.2.0/24","10.0.3.0/24"]
    }

    // Your network's public IP address range should be here
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = -1
        to_port = -1
        protocol = "icmp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    // Open as NAT is acting as a Bastion Host
    egress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["${aws_vpc.main.cidr_block}"]
    }

    egress {
        from_port = -1
        to_port = -1
        protocol = "icmp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    vpc_id = "${aws_vpc.main.id}"

    tags {
        Name = "NATSG"
    }
}