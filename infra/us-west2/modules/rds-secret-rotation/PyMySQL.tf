# This module creates a Lambda layer for PyMySQL, which can be used in the RDS secret rotation Lambda function.

locals {
  layer_src = "${path.module}/lambda-layer"
}

data "archive_file" "pymysql_layer" {
  type        = "zip"
  source_dir  = local.layer_src
  output_path = "${path.module}/pymysql-layer.zip"
}

resource "aws_lambda_layer_version" "pymysql" {
  layer_name          = "pymysql-layer"
  compatible_runtimes = ["python3.12"]
  filename            = data.archive_file.pymysql_layer.output_path
}
