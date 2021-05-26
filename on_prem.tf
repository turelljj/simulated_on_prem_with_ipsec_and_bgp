provider "aws" {
  region     = "ap-northeast-1"
  secret_key = var.AWS_SECRET_ID
  access_key = var.AWS_KEY_ID
}

provider "null" {}
provider "local" {}

resource "aws_instance" "on-prem" {
  ami                    = "ami-00f65b9dfc6773444"
  instance_type          = "t2.micro"
  key_name               = "macbook"
  subnet_id              = module.vpc-on-prem.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.for-ipsec.id]
  connection {
    host = self.public_ip
    user = "centos"
    private_key = file("~/.ssh/id_rsa")
  }
  provisioner "remote-exec" {
    inline = [
      "echo lala"
    ]
  }
}

resource "aws_security_group" "for-ipsec" {
  vpc_id = module.vpc-on-prem.vpc_id
  name   = "for-ipsec"
  ingress = [{
    cidr_blocks      = ["0.0.0.0/0"]
    description      = "allow-ssh"
    from_port        = 22
    ipv6_cidr_blocks = null
    prefix_list_ids  = null
    protocol         = "tcp"
    security_groups  = null
    self             = false
    to_port          = 22
    }, {
    cidr_blocks      = ["0.0.0.0/0"]
    description      = "allow-ipsec-1"
    from_port        = 500
    ipv6_cidr_blocks = null
    prefix_list_ids  = null
    protocol         = "udp"
    security_groups  = null
    self             = false
    to_port          = 500
    }, {
    cidr_blocks      = ["0.0.0.0/0"]
    description      = "allow-icmp"
    from_port        = 0
    ipv6_cidr_blocks = null
    prefix_list_ids  = null
    protocol         = -1
    security_groups  = null
    self             = false
    to_port          = 0
    }, {
    cidr_blocks      = ["0.0.0.0/0"]
    description      = "allow-ipsec-2"
    from_port        = 4500
    ipv6_cidr_blocks = null
    prefix_list_ids  = null
    protocol         = "udp"
    security_groups  = null
    self             = false
    to_port          = 4500
  }]
  egress = [{
    cidr_blocks      = ["0.0.0.0/0"]
    description      = "value"
    from_port        = 0
    ipv6_cidr_blocks = null
    prefix_list_ids  = null
    protocol         = "-1"
    security_groups  = null
    self             = false
    to_port          = 0
  }]

  tags = {
    "Name" = "allow-ipsec"
  }
}

module "vpc-on-prem" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.0.0"

  name = "vpc-on-prem"
  cidr = "172.16.0.0/16"

  azs             = ["ap-northeast-1a"]
  public_subnets  = ["172.16.1.0/24"]

  enable_nat_gateway = false
  enable_vpn_gateway = false
  create_igw         = true

  tags = {
    Terraform   = "true"
    Environment = "On-prem"
  }
}

data "aws_subnet" "on-prem-subnet" {
  id = aws_instance.on-prem.subnet_id
}

resource "local_file" "ansible_inventory" {
  content  = templatefile("${path.module}/ansible/inventory.tmpl", { public_ip = aws_instance.on-prem.public_ip })
  filename = "${path.module}/ansible/inventory"
}

resource "local_file" "ansible_variables" {
  content = templatefile("${path.module}/ansible/variables.tmpl", {
    "aws_instance_on-prem_private_ip" = aws_instance.on-prem.private_ip,
    "aws_instance_on-prem_public_ip" = aws_instance.on-prem.public_ip,
    "tunnel1_public_ip" = var.tunnel1_public_ip,
    "tunnel1_shared_key" = var.tunnel1_shared_key,
    "aws_tunnel_1_insde_ip" = var.aws_tunnel_1_insde_ip,
    "on_prem_tunnel_1_inside_ip" = var.on_prem_tunnel_1_inside_ip,
    "tunnel2_public_ip" = var.tunnel2_public_ip,
    "tunnel2_shared_key" = var.tunnel2_shared_key,
    "aws_tunnel_2_insde_ip" = var.aws_tunnel_2_insde_ip,
    "on_prem_tunnel_2_inside_ip" = var.on_prem_tunnel_2_inside_ip
  })
  filename = "${path.module}/ansible/variables.yml"
}

resource "null_resource" "echolala" {
  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i ${path.module}/ansible/inventory --private-key /Users/ture/.ssh/id_rsa ${path.module}/ansible/play.yml"
  }
  depends_on = [
    local_file.ansible_inventory,
    local_file.ansible_variables
  ]
  triggers = {
    always_run = "${timestamp()}"
  }
}