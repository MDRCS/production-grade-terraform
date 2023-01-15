resource "aws_db_subnet_group" "main" {
  name = "${local.prefix}-main"
  # database should be accessable to our internal application 
  # we link it to private subnet a/b
  subnet_ids = [
    aws_subnet.private_a.id,
    aws_subnet.private_b.id,
  ]

  tags = merge(
    tomap({ Name = "${local.prefix}-main" }),
    local.common_tags
  )
}

resource "aws_security_group" "rds" {
  # Security groups Allow you to control the inbound/outbound 
  # access allowed to the resource.
  description = "Allow Access to RDS database instance"
  name        = "${local.prefix}-rds-inbound-access"
  vpc_id      = aws_vpc.main.id

  # Ingress Inbound Access
  ingress {
    protocol  = "tcp"
    from_port = 5432 # default port for postgres
    to_port   = 5432

    # internal access Only from bastion server and ECS Service
    security_groups = [
      aws_security_group.bastion.id,
      aws_security_group.ecs_service.id,
    ]
  }

  tags = merge(
    tomap({ Name = "${local.prefix}-main" }),
    local.common_tags
  )
}

resource "aws_db_instance" "main" {
  identifier           = "${local.prefix}-db"
  db_name              = "db_backend"
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "postgres"
  engine_version       = "14.3" # ref : https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_PostgreSQL.html
  instance_class       = "db.t3.micro"
  db_subnet_group_name = aws_db_subnet_group.main.name
  username             = var.db_username
  password             = var.db_password

  # for demo we set it to 0, false, true
  backup_retention_period = 0     #for prod purposes, it's recommanded to set it to 7 to keep a backup of the database for 7 days.
  multi_az                = false # for prod purposes, it's recommanded to create database in multiple zones.
  skip_final_snapshot     = true  # for prod purposes, it's recommanded to set snapshot to false so we keep data even when deleting db instance
  vpc_security_group_ids  = [aws_security_group.rds.id]

  tags = merge(
    tomap({ Name = "${local.prefix}-main" }),
    local.common_tags
  )
}