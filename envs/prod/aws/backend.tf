# Remote state in S3 with native S3 locking (use_lockfile: no DynamoDB table needed).
# bucket and region are passed at init time (see scripts/tf.sh).
terraform {
  backend "s3" {
    key          = "prod/aws.tfstate"
    encrypt      = true
    use_lockfile = true
  }
}
