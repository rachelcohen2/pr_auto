resource "aws_ecs_task_definition" "sf_Jenkins_service" {
  family = "service"
  container_definitions = jsonencode([
    {
        name      = "JenkinsContainer"
        image = "629343647160.dkr.ecr.eu-west-2.amazonaws.com/some/thing:latest"
        execution_role_arn = "arn:aws:iam::629343647160:role/ecsTaskExecutionRole"
        memory = 3072
        cpu = 256
        essential = true
        portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
        }
      ]
    }
    ])
    # volume {
    #   name = "vol"
    # }
  
}



# resource "aws_iam_role_policy_attachment" "ecs_agent" {
#   role       = "aws_iam_role.ecs_agent.name"
#   policy_arn = "arn:aws:iam::629343647160:role/ecsInstanceRole"
# }
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
    # resources = [ "arn:aws:iam::629343647160:role/ecsInstanceRole" ]
  }
}

resource "aws_iam_role" "role" {
  name               = "test_role"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  permissions_boundary = "arn:aws:iam::629343647160:policy/PCSKPermissionsBoundary"
}

resource "aws_iam_instance_profile" "ecs_agent_jk" {
  name = "ecs-agent"
  role = "ecsInstanceRole"
}

resource "aws_ecs_cluster" "ecs_jk_cluster" {
  name = "Jenkins-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_launch_configuration" "asg_conf" {
  name          = "ecs_instance_jenkins"
  iam_instance_profile = aws_iam_instance_profile.ecs_agent_jk.name
  image_id      = var.ami
  instance_type = "m5.xlarge"
  associate_public_ip_address = true
  security_groups = [var.sg]
  user_data = <<EOF
#!/bin/bash
sudo su
echo ECS_CLUSTER=${aws_ecs_cluster.ecs_jk_cluster.name} >> /etc/ecs/ecs.config
EOF
  # vpc_classic_link_id = var.vpc
}

resource "aws_autoscaling_group" "failure_analysis_ecs_asg" {
    name                      = "asg_jenkins"
    vpc_zone_identifier       = [var.subnet-zone]
    launch_configuration      = aws_launch_configuration.asg_conf.name

    desired_capacity          = 1
    min_size                  = 0
    max_size                  = 1
    health_check_grace_period = 300
    health_check_type         = "EC2"

}

