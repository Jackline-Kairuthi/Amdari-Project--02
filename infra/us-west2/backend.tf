terraform {
  backend "s3" {
    bucket = "sentinelpay-tf-state-west2"
    key    = "infra/us-west-2/terraform.tfstate"
    region = "us-west-2"
    dynamodb_table = "sentinelpay-terraform-locks"
    encrypt = true
  }
}



