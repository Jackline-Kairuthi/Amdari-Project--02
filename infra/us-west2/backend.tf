terraform {
  backend "s3" {
    bucket         = "sentinelpay-tf-state-west2"
    key            = "us-west2/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "sentinelpay-terraform-locks"
    encrypt        = true
  }
}


