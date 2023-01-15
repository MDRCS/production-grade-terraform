# Purpose of a Bastion server is to allow Administrator to Access resources in private Subnets

data "aws_ami" "amazon_linux" {
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-5.10-hvm-2.0.*-x86_64-gp2"]
  }
  owners = ["amazon"]
}

# Defined an IAM Role for Bastion Server
resource "aws_iam_role" "bastion" {
  name               = "${local.prefix}-bastion"
  assume_role_policy = file("./templates/bastion/instance-profile-policy.json")

  tags = merge(
    tomap({ Name = "${local.prefix}-bastion", }),
    local.common_tags
  )

}

# Attach a Policy to our IAM Role
resource "aws_iam_role_policy_attachment" "bastion_attach_policy" {
  role       = aws_iam_role.bastion.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# Attach this instance profile to our IAM Role for Bastion Server
resource "aws_iam_instance_profile" "bastion" {
  name = "${local.prefix}-bastion-instance-profile"
  role = aws_iam_role.bastion.name
}

resource "aws_instance" "bastion" {
  ami                  = data.aws_ami.amazon_linux.id # data reference the component above to get image id
  instance_type        = "t2.micro"
  user_data            = file("./templates/bastion/user-data.sh")
  iam_instance_profile = aws_iam_instance_profile.bastion.name # Link Our instance profile to our Bastion server.
  key_name             = var.bastion_key_name
  subnet_id            = aws_subnet.public_a.id # public subnets : should be accessable from the internet

  vpc_security_group_ids = [
    aws_security_group.bastion.id
  ]

  tags = merge(
    tomap({ Name = "${local.prefix}-bastion", }),
    local.common_tags
  )

}

resource "aws_security_group" "bastion" {
  description = "Control bastion Inbound and Outbound Access"
  name        = "${local.prefix}-bastion"
  vpc_id      = aws_vpc.main.id

  # Inbound Internet Access For SysAdmins thought ssh Connection 
  ingress {
    protocol    = "tcp"
    from_port   = 22 # ssh port 
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"] # Any IP Address
  }

  # Outbound Internet Access for HTTPS Connection
  egress {
    protocol    = "tcp"
    from_port   = 443 # https connection port 
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"] # Any IP Address
  }

  # Outbound Internet Access For HTTP Connection
  egress {
    protocol    = "tcp"
    from_port   = 80 # http connection port 
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"] # Any IP Address
  }

  # Outbound Internet Access to access postgres db instance.
  egress {
    protocol  = "tcp"
    from_port = 5432 # Postgres default port
    to_port   = 5432
    cidr_blocks = [
      aws_subnet.private_a.cidr_block,
      aws_subnet.private_b.cidr_block
    ]
  }

  tags = local.common_tags
}


