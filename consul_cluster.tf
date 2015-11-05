#--------------------------------------------------------------
# Consul instances
#--------------------------------------------------------------
resource "aws_instance" "consul_server" {
    count = 1
    ami = "${lookup(var.aws_amis, var.aws_region)}"
    availability_zone = "${element(var.aws_availability_zones, count.index)}"
    subnet_id = "${element(aws_subnet.private.*.id, count.index)}"
    instance_type = "${var.aws_instance_type}"
    key_name  = "${var.aws_key_name}"
    security_groups = ["${aws_security_group.consul.id}"]
 
    user_data = "${template_file.server.rendered}"

    tags { 
        Name = "consul_server${count.index}" 
    }
}

resource "aws_instance" "consul_client" {
    depends_on = "aws_instance.consul_server"
    count = 2
    ami = "${lookup(var.aws_amis, var.aws_region)}"
    availability_zone = "${element(var.aws_availability_zones, count.index)}"
    subnet_id = "${element(aws_subnet.private.*.id, count.index)}"
    instance_type = "${var.aws_instance_type}"
    key_name  = "${var.aws_key_name}"
    security_groups = ["${aws_security_group.consul.id}"]
 
    user_data = "${template_file.client.rendered}"

    tags { 
        Name = "consul_client${count.index}" 
    }
}

// In public subnet
resource "aws_instance" "consul_ui" {
    depends_on = "aws_instance.consul_server"
    count = 1
    ami = "${lookup(var.aws_amis, var.aws_region)}"
    availability_zone = "${element(var.aws_availability_zones, count.index)}"
    subnet_id = "${element(aws_subnet.public.*.id, count.index)}"
    instance_type = "${var.aws_instance_type}"
    key_name  = "${var.aws_key_name}"
    security_groups = ["${aws_security_group.consul.id}", "${aws_security_group.web.id}"]
    associate_public_ip_address = true
    user_data = "${template_file.ui.rendered}"

    tags { 
        Name = "consul_ui${count.index}" 
    }
}


#--------------------------------------------------------------
# Consul Security Group rules
#--------------------------------------------------------------
// - Default egress to 0.0.0.0/0 to talk to SCADA
//
// - Servers can talk to other Servers on tcp/8300, tcp/8301, udp/8301, tcp/8302, udp/8302
// - Servers can talk to Clients on tcp/8301, udp/8301
//
// - Clients can talk to Servers on tcp/8300, tcp/8301, udp/8301
// - Clients can talk to other Clients on tcp/8301, udp/8301
resource "aws_security_group" "consul" {
    name        = "security_group_consul"
    description = "For Consul"

    ingress {
        from_port = 8300
        to_port = 8600
        protocol = "udp"
        self = true
    }

    ingress {
        from_port = 8300
        to_port = 8600
        protocol = "tcp"
        self = true
    }

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["${aws_vpc.main.cidr_block}"]
    }

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["${aws_vpc.main.cidr_block}"]
    }

    ingress {
        from_port = -1
        to_port = -1
        protocol = "icmp"
        cidr_blocks = ["${aws_vpc.main.cidr_block}"]
    }

    // Allow All - need to close this down to specifics!
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    // ingress {
    //     from_port = 8600
    //     to_port = 8600
    //     protocol = "udp"
    //     cidr_blocks = ["${aws_vpc.main.cidr_block}"]
    // }

    // ingress {
    //     from_port = 8600
    //     to_port = 8600
    //     protocol = "tcp"
    //     cidr_blocks = ["${aws_vpc.main.cidr_block}"]
    // }

    // ingress {
    //     from_port = 8500
    //     to_port = 8500
    //     protocol = "tcp"
    //     self = true
    // }

    // ingress {
    //     from_port = 8400
    //     to_port = 8400
    //     protocol = "tcp"
    //     cidr_blocks = ["${aws_vpc.main.cidr_block}"]
    // }


    vpc_id = "${aws_vpc.main.id}"

    tags { 
        Name = "Consul" 
    }
}


resource "template_file" "server" {
    filename = "user_data_consul_server.txt"
    vars {}
}

resource "template_file" "client" {
    filename = "user_data_consul_client.txt"
    vars {
        server_private_ip = "${aws_instance.consul_server.private_ip}" 
    }
}

resource "template_file" "ui" {
    filename = "user_data_consul_ui.txt"
    vars {
        server_private_ip = "${aws_instance.consul_server.private_ip}" 
    }
}
