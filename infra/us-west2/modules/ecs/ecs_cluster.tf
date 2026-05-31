resource "aws_ecs_cluster" "this" {
  name = "sentinelpay-cluster"
    tags = {
        Name = "sentinelpay-cluster"
    }   
  
}