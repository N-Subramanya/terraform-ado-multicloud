#!/usr/bin/env bash
# One-time setup: S3 bucket for Terraform state (versioned, KMS-encrypted, private).
# Locking uses S3 native lock files (use_lockfile = true), so no DynamoDB table is needed.
#   scripts/bootstrap-aws-state.sh <bucket-name> [region]
set -euo pipefail

bucket="${1:?bucket name required}"
region="${2:-us-east-1}"

if [[ "$region" == "us-east-1" ]]; then
  aws s3api create-bucket --bucket "$bucket" --region "$region" > /dev/null
else
  aws s3api create-bucket --bucket "$bucket" --region "$region" \
    --create-bucket-configuration "LocationConstraint=$region" > /dev/null
fi

aws s3api put-bucket-versioning --bucket "$bucket" \
  --versioning-configuration Status=Enabled

aws s3api put-bucket-encryption --bucket "$bucket" \
  --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"aws:kms"},"BucketKeyEnabled":true}]}'

aws s3api put-public-access-block --bucket "$bucket" \
  --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

echo "State bucket ready: s3://$bucket ($region)"
