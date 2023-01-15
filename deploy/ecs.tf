resource "aws_ecs_cluster" "main" {
  name = "${local.prefix}-cluster" # One Cluster per env (Staging/QA/Prod)

  tags = local.common_tags
}

# Permissions to start the task
resource "aws_iam_policy" "task_execustion_role_policy" {
  name        = "${local.prefix}-task-exec-role-policy"
  path        = "/"
  description = "Allow ECS to retrieve images from ECR and add logs"
  policy      = file("./templates/ecs/task-exec-role.json")
}

resource "aws_iam_role" "task_execustion_role" {
  name               = "${local.prefix}-task-exec-role"
  assume_role_policy = file("./templates/ecs/assume-role-policy.json")

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "task_execustion_role" {
  role       = aws_iam_role.task_execustion_role.name
  policy_arn = aws_iam_policy.task_execustion_role_policy.arn
}

# Permissions when the task is running 
resource "aws_iam_role" "app_iam_role" {
  name               = "${local.prefix}-api-task"
  assume_role_policy = file("./templates/ecs/assume-role-policy.json")

  tags = local.common_tags
}

resource "aws_cloudwatch_log_group" "ecs_task_logs" {
  name = "${local.prefix}-api"

  tags = local.common_tags
}

data "template_file" "api_container_definitions" {
  template = file("./templates/ecs/container-definitions.json.tpl")

  vars = {
    app_image         = var.ecr_image_api
    proxy_image       = var.ecr_image_proxy
    django_secret_key = var.django_secret_key
    db_host           = aws_db_instance.main.address
    db_name           = aws_db_instance.main.db_name
    db_user           = aws_db_instance.main.username
    db_pass           = aws_db_instance.main.password
    log_group_name    = aws_cloudwatch_log_group.ecs_task_logs.name
    log_group_region  = data.aws_region.current.name
    # this use load balancer dns_name `allowed_hosts            = aws_lb.api.dns_name` # value "*" is temporary before creating our Load balancer
    allowed_hosts            = aws_route53_record.app.fqdn # it use our custom dns 
    s3_storage_bucket_name   = aws_s3_bucket.app_public_files.bucket
    s3_storage_bucket_region = data.aws_region.current.name
  }
}

resource "aws_ecs_task_definition" "api" {
  family                   = "${local.prefix}-api" # just a name
  container_definitions    = data.template_file.api_container_definitions.rendered
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512                                   # api 256 mb \ proxy 256 mb
  execution_role_arn       = aws_iam_role.task_execustion_role.arn # to start a container
  task_role_arn            = aws_iam_role.app_iam_role.arn

  volume {
    name = "static"
  }

  tags = local.common_tags

}

resource "aws_security_group" "ecs_service" {
  description = "Access for the ECS Service."
  name        = "${local.prefix}-ecs-service"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 5432
    to_port   = 5432
    protocol  = "tcp"
    cidr_blocks = [
      aws_subnet.private_a.cidr_block,
      aws_subnet.private_b.cidr_block,
    ]
  }

  ingress {
    from_port = 8000
    to_port   = 8000
    protocol  = "tcp"
    security_groups = [
      aws_security_group.lb.id,
    ]
  }

  tags = local.common_tags

}


resource "aws_ecs_service" "api" {
  name             = "${local.prefix}-api"
  cluster          = aws_ecs_cluster.main.name
  task_definition  = aws_ecs_task_definition.api.family
  desired_count    = 1         # number of tasks (Containers) to run in a service, it depends on your load, 1 is just for testing purposes
  launch_type      = "FARGATE" # Allows us to run tasks without managing the servers (Serverless)
  platform_version = "1.4.0"

  network_configuration {
    subnets = [
      aws_subnet.private_a.id,
      aws_subnet.private_b.id,
    ]
    security_groups = [aws_security_group.ecs_service.id]
    # assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.api.arn # Any time we add new task will automatically be added to our load balancer target group
    container_name   = "proxy"                     # it tells to load balancer to forward to `proxy` container
    container_port   = 8000                        # and use port 8000.
  }

  # it will create https listener before creating ecs services.
  depends_on = [aws_lb_listener.api_https] # create dependancy between resources to ensure that terraform will create resources in the right order.
}

# Import Policy Template for s3 permission of an ECS Task
data "template_file" "ecs_s3_write_policy" {
  template = file("./templates/ecs/s3-write-policy.json.tpl")

  vars = {
    bucket_arn = aws_s3_bucket.app_public_files.arn
  }

}

# Create IAM Policy for ECS Task to Manage S3 bucker
resource "aws_iam_policy" "ecs_s3_access" {
  name        = "${local.prefix}-AppS3AccessPolicy"
  path        = "/"
  description = "Allow access to the django rest api from our s3 bucket."

  policy = data.template_file.ecs_s3_write_policy.rendered

}

# Attach this policy to our ECS IAM Role
resource "aws_iam_role_policy_attachment" "ecs_s3_access" {
  role       = aws_iam_role.app_iam_role.name
  policy_arn = aws_iam_policy.ecs_s3_access.arn
}