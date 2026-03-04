################################################################################
# S3 Buckets
################################################################################

# Documents bucket for user uploads
resource "aws_s3_bucket" "documents" {
  bucket = "${local.name_prefix}-documents-${local.account_id}"

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-documents"
  })
}

resource "aws_s3_bucket_versioning" "documents" {
  bucket = aws_s3_bucket.documents.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "documents" {
  bucket = aws_s3_bucket.documents.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "documents" {
  bucket = aws_s3_bucket.documents.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

################################################################################
# Static Assets Bucket (for web if using S3/CloudFront)
################################################################################

resource "aws_s3_bucket" "static" {
  count  = var.enable_cloudfront ? 1 : 0
  bucket = "${local.name_prefix}-static-${local.account_id}"

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-static"
  })
}

resource "aws_s3_bucket_server_side_encryption_configuration" "static" {
  count  = var.enable_cloudfront ? 1 : 0
  bucket = aws_s3_bucket.static[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "static" {
  count  = var.enable_cloudfront ? 1 : 0
  bucket = aws_s3_bucket.static[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

################################################################################
# CloudFront Distribution (optional)
################################################################################

resource "aws_cloudfront_origin_access_control" "static" {
  count                             = var.enable_cloudfront ? 1 : 0
  name                              = "${local.name_prefix}-static-oac"
  description                       = "OAC for ${local.name_prefix} static assets"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "static" {
  count = var.enable_cloudfront ? 1 : 0

  origin {
    domain_name              = aws_s3_bucket.static[0].bucket_regional_domain_name
    origin_id                = "S3-${aws_s3_bucket.static[0].id}"
    origin_access_control_id = aws_cloudfront_origin_access_control.static[0].id
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  comment             = "${local.name_prefix} static assets"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.static[0].id}"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-cloudfront"
  })
}

# S3 bucket policy to allow CloudFront access
resource "aws_s3_bucket_policy" "static" {
  count  = var.enable_cloudfront ? 1 : 0
  bucket = aws_s3_bucket.static[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipal"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.static[0].arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.static[0].arn
          }
        }
      }
    ]
  })
}
