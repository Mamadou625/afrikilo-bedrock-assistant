data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id

  # "us.amazon.nova-2-lite-v1:0" -> "amazon.nova-2-lite-v1:0"
  foundation_model_id = replace(var.model_id, "/^(us|eu|apac|global)\\./", "")

  inference_profile_arn = "arn:aws:bedrock:${var.region}:${local.account_id}:inference-profile/${var.model_id}"
  # A US inference profile routes to several US regions, hence the * region.
  foundation_model_arn = "arn:aws:bedrock:*::foundation-model/${local.foundation_model_id}"
}

# ---------------------------------------------------------------------------
# S3: private bucket holding the FAQ
# ---------------------------------------------------------------------------

resource "aws_s3_bucket" "faq" {
  bucket        = "${var.project_name}-faq-${local.account_id}"
  force_destroy = true # demo project: let terraform destroy remove faq.md too
}

resource "aws_s3_bucket_public_access_block" "faq" {
  bucket                  = aws_s3_bucket.faq.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "faq" {
  bucket = aws_s3_bucket.faq.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_object" "faq" {
  bucket       = aws_s3_bucket.faq.id
  key          = "faq.md"
  source       = "${path.module}/../faq.md"
  etag         = filemd5("${path.module}/../faq.md")
  content_type = "text/markdown; charset=utf-8"
}
