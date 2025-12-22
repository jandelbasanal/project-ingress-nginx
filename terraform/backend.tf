# Terraform backend configuration (example)
# IMPORTANT: configure these values before running in CI. Create the S3 bucket and DynamoDB table first.
# Replace the placeholders with your values or configure a remote backend in your environment.

terraform {
  backend "s3" {
    bucket         = "<YOUR_TFSTATE_S3_BUCKET>"    # e.g. my-terraform-state-bucket
    key            = "project-ingress-nginx/terraform.tfstate"
    region         = "ap-northeast-1"
    dynamodb_table = "<YOUR_DYNAMODB_LOCK_TABLE>" # e.g. tfstate-locks
    encrypt        = true
  }
}
