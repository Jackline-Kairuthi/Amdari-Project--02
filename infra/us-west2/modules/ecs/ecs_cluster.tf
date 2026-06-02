resource "aws_ecs_cluster" "this" {
  name = "sentinelpay-cluster"
  setting {
  name  = "containerInsights"
  value = "enabled"
}

    tags = {
        Name = "sentinelpay-cluster"
    }   
  
}