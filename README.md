terraform-playground
====================
## Overview
This is simple PoC using Terraform to bring up a number of EC2 servers to run Docker with a contrived containerized RESTful API. Nothing particularly original here, just a combination of various tutorials/projects to help me get familiar with these technologies. The intention is this project will grow in size and complexity as I work through various techniques.

## Preparations
Get an AWS account.

Ensure your workstations has Terraform installed.

You can install terraform using **Homebrew** on a Mac using `brew update && brew install terraform`.

Terraform e.g. `brew install terraform`.
See [Terraform Getting Started Guide](https://terraform.io/intro/getting-started/install.html) for more details.

### Extra requirements for AWS provisioning

You need an SSH key to access AWS EC2 instances. 
Use the chmod command to make sure your private key file isn't publicly viewable. For example, if the name of your private key file is my-key-pair.pem, use the following command:

```chmod 400 /path/my-key-pair.pem```

Once Terraform has done it's job you'll be able to use the ssh command to connect to EC2 instances. You'll specify the private key (.pem) file and user_name@public_dns_name. For Amazon Linux, the user name is `ec2-user`. For RHEL5, the user name is either `root` or `ec2-user`. For Ubuntu, the user name is `ubuntu`. For Fedora, the user name is either `fedora` or `ec2-user`. For SUSE Linux, the user name is either `root` or `ec2-user`. Otherwise, if `ec2-user` and `root` don't work, check with your AMI provider.

The terraform provider for AWS will need credentials, these can be read from the following environment variables:

`AWS_ACCESS_KEY_ID`
`AWS_SECRET_ACCESS_KEK`

We will set these as specific variables in `terraform.tfvars`


## Running Terraform
Copy terraform.tfvars.example to terraform.tfvars and set the variables to specific values for your AWS account and applicaiton details, as appropriate.

I am using an Amazon ECS-Optimized Amazon Linux AMI - EC2 charges for Micro instances are free for up to 750 hours a month if you [qualify for the AWS Free Tier](http://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/billing-free-tier.html)

To check what resources will be created:

```$ terraform plan```

To create EC2 instances and their dependencies:

```$ terraform apply```

To destroy all:

```$ terraform destroy```

If you run into issues the output can often be a little opaque -_well it is when you're starting out_. Terraform has detailed logs which can be enabled by setting the `TF_LOG` environmental variable to any value. This will cause detailed logs to appear on stderr.

You can set `TF_LOG` to one of the log levels `TRACE`, `DEBUG`, `INFO`, `WARN` or `ERROR` to change the verbosity of the logs. `TRACE` is the most verbose and it is the default if `TF_LOG` is set to something other than a log level name_

## VPC configuration
Borrowing from the configuration found in [Scenario 2: VPC with Public and Private Subnets (NAT)](http://docs.aws.amazon.com/AmazonVPC/latest/UserGuide/VPC_Scenario2.html)

With the following configuration:

![VPC with Public and Private Subnets (NAT)](http://docs.aws.amazon.com/AmazonVPC/latest/UserGuide/images/nat-instance-diagram.png)

The diagram above (from AWS docs) is the easiset way of describing the intention of this implementation as it stands currently.  I expect this will develop with the inclusion of Autoscaling Group, Launch Configurations and Elastic Load Balancers, to name a few. 

Opperating within the EU West 1 region (Ireland) and across the 3 availability zones (eu-west-1a, eu-west-1b, eu-west-1c) with:

+ Virtual private cloud (VPC) of size /16 (example CIDR: 10.0.0.0/16) with 65,536 private IP addresses.
+ 3 public subnets (one for each AZ) of size /24 (CIDR: 10.0.101.0/24, 10.0.102.0/24, 10.0.103.0/24). providing 256 private IP addresses in each subnet.
+ 3 private subnet (one for each AZ) of size /24 (CIDR: 10.0.1.0/24, 10.0.2.0/24, 10.0.3.0/24) providing 256 private IP addresses in each subtnet. The private subnet is inaccessible to the internet.
+ An Internet gateway. This connects the VPC to the Internet and to other AWS products.

### Public/private access
Public and private access is controlled via the VPC configruation using public/private subnets and relevant security groups (e.g. enabling http(s) access). The following are the key points:

+ Instances with private IP addresses in the subnet range (examples: 10.0.1.5, 10.0.1.79) are able to communicate with each other within the VPC. 

+ Instances in the public subnet have Elastic IP addresses (example: 198.51.100.1) enabling access from the Internet. 

+ For security purposes back-end servers that don't need to accept incoming traffic from the Internet will be placed within the private subnet; they can send requests to the Internet using the NAT instance.

+ A network address translation (NAT) instance with its own Elastic IP address. This enables instances in the private subnet to send requests to the Internet.

+ A custom route table associated with the public subnet. This route table contains an entry that enables instances in the subnet to communicate with other instances in the VPC, and an entry that enables instances in the subnet to communicate directly with the Internet.

+ The main route table associated with the private subnet. The route table contains an entry that enables instances in the subnet to communicate with other instances in the VPC, and an entry that enables instances in the subnet to communicate with the Internet through the NAT instance

In summary: _Private subnet is routed through the NAT instance. Public subnet is routed directly to the internet gateway._


### Configure ssh-agent on a Mac
The first step in using SSH agent forwarding with EC2 instances is to configure a bastion in your VPC (I haven't implemented a true bastion host and am using any of the public instances to get access to the private subnet - this needs hardening). Recommendations is that there is an instance that is purpose-built and that is only used as a bastion and not for anything else. The bastion should also be set up with a security group that's configured to listen only on the SSH port (TCP/22). 

For Mac users, ssh-agent is already installed as part of the OS. You can add your private keys to the keychain application by using the ssh-add command with the -K option and the .pem file for the key, as shown in the following example. The agent prompts you for your passphrase, if there is one, and stores the private key in memory and the passphrase in your keychain.

```ssh-add -K /path/my-key-pair.pem```

After the key is added to your keychain, you can connect to the bastion instance with SSH using the –A option. This option enables SSH agent forwarding and lets the local SSH agent respond to a public-key challenge when you use SSH to connect from the bastion to a target instance in your VPC.

```ssh –A ec2-user@bastion-ip```

TODO: 
+ Write up EC2 insance provisioning using user_data and setting up the Consul cluster
+ Move bash scripts to a consul.d for restart
+ Appropriate IAM for instance.
+ Look at ECS and an ECS optimised AMI so I don't have to install docker etc.
+ Implement services to take advantage of Consul service discovery and ECS

+ Write up fault finding Check /var/log/cloud-init-output.log and docker logs {container_id}
```If your directives did not accomplish the tasks you were expecting them to, or if you just want to verify that your directives completed without errors, examine the cloud-init log file at /var/log/cloud-init.log and look for error messages in the output.```

/var/lib/cloud/instance/scripts/part-001

+ Use of gliderlabs/registrator and progrium/consul 


**Paul Feaviour 2015**
