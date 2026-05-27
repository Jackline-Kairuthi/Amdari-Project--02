terraform {
 backend "s3" {
   bucket = "sentinelpay-tf-state"
   key = "foo/terraform.tfstate"
   region = "us-west-1"
   dynamodb_table = "sentinelpay-lock-table"
   encrypt = true
 }
}
