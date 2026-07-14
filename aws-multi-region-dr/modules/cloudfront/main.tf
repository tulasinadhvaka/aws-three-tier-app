locals {
  tags           = merge(var.tags, { Module = "cloudfront" })
  primary_origin = "primary-alb"
  dr_origin      = "dr-alb"
}

resource "aws_cloudfront_distribution" "this" {
  enabled = true
  comment = "${var.name_prefix} multi-region failover"

  # Primary origin.
  origin {
    origin_id   = local.primary_origin
    domain_name = var.primary_origin_domain
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  # DR (failover) origin.
  origin {
    origin_id   = local.dr_origin
    domain_name = var.dr_origin_domain
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  # Origin group: CloudFront retries the DR origin when the primary returns
  # these status codes or times out — CDN-layer failover in seconds.
  origin_group {
    origin_id = "failover-group"
    failover_criteria {
      status_codes = [500, 502, 503, 504]
    }
    member {
      origin_id = local.primary_origin
    }
    member {
      origin_id = local.dr_origin
    }
  }

  default_cache_behavior {
    target_origin_id       = "failover-group"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    forwarded_values {
      query_string = true
      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = local.tags
}
