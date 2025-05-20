variable "name" {
  description = "Name to be used on all resources as identifier"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "domain_name" {
  description = "The domain name for the site"
  type        = string
}

variable "alb_domain_name" {
  description = "The domain name of the ALB"
  type        = string
}

variable "ssl_certificate_arn" {
  description = "The ARN of the SSL certificate"
  type        = string
  default     = ""
}

variable "price_class" {
  description = "The price class for the CloudFront distribution"
  type        = string
  default     = "PriceClass_100" # Only US, Canada, Europe
}

variable "default_ttl" {
  description = "The default TTL for the cache behavior"
  type        = number
  default     = 3600 # 1 hour
}

variable "min_ttl" {
  description = "The minimum TTL for the cache behavior"
  type        = number
  default     = 0
}

variable "max_ttl" {
  description = "The maximum TTL for the cache behavior"
  type        = number
  default     = 86400 # 24 hours
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

locals {
  s3_origin_id  = "${var.name}-${var.environment}-s3-origin"
  alb_origin_id = "${var.name}-${var.environment}-alb-origin"
  use_https     = var.ssl_certificate_arn != ""
}

resource "aws_cloudfront_distribution" "this" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "${var.name}-${var.environment} WordPress distribution"
  default_root_object = "index.php"
  price_class         = var.price_class
  
  aliases = [var.domain_name, "www.${var.domain_name}"]
  
  origin {
    domain_name = var.alb_domain_name
    origin_id   = local.alb_origin_id
    
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = local.use_https ? "https-only" : "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }
  
  # Cache static files
  ordered_cache_behavior {
    path_pattern     = "wp-content/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.alb_origin_id
    
    forwarded_values {
      query_string = false
      headers      = ["Origin"]
      
      cookies {
        forward = "none"
      }
    }
    
    min_ttl                = var.min_ttl
    default_ttl            = var.default_ttl
    max_ttl                = var.max_ttl
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }
  
  # Cache static files
  ordered_cache_behavior {
    path_pattern     = "wp-includes/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.alb_origin_id
    
    forwarded_values {
      query_string = false
      headers      = ["Origin"]
      
      cookies {
        forward = "none"
      }
    }
    
    min_ttl                = var.min_ttl
    default_ttl            = var.default_ttl
    max_ttl                = var.max_ttl
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }
  
  # Default behavior for dynamic content
  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.alb_origin_id
    
    forwarded_values {
      query_string = true
      headers      = ["*"]
      
      cookies {
        forward = "all"
      }
    }
    
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }
  
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  
  viewer_certificate {
    acm_certificate_arn      = var.ssl_certificate_arn
    ssl_support_method       = local.use_https ? "sni-only" : null
    minimum_protocol_version = local.use_https ? "TLSv1.2_2021" : null
    cloudfront_default_certificate = !local.use_https
  }
  
  custom_error_response {
    error_code         = 404
    response_code      = 404
    response_page_path = "/404.php"
  }
  
  custom_error_response {
    error_code         = 403
    response_code      = 403
    response_page_path = "/403.php"
  }
  
  tags = merge(
    {
      "Name" = format("%s-%s-cloudfront", var.name, var.environment)
    },
    var.tags,
  )
}

resource "aws_cloudfront_cache_policy" "wordpress" {
  name        = "${var.name}-${var.environment}-wordpress-cache-policy"
  comment     = "Cache policy for WordPress"
  default_ttl = var.default_ttl
  max_ttl     = var.max_ttl
  min_ttl     = var.min_ttl
  
  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "whitelist"
      cookies {
        items = ["comment_*", "wordpress_*", "wp-settings-*"]
      }
    }
    
    headers_config {
      header_behavior = "whitelist"
      headers {
        items = ["Authorization", "Host", "X-WP-Nonce"]
      }
    }
    
    query_strings_config {
      query_string_behavior = "all"
    }
  }
}

output "domain_name" {
  description = "The domain name of the CloudFront distribution"
  value       = aws_cloudfront_distribution.this.domain_name
}

output "hosted_zone_id" {
  description = "The CloudFront Route 53 zone ID"
  value       = aws_cloudfront_distribution.this.hosted_zone_id
}

output "id" {
  description = "The identifier for the CloudFront distribution"
  value       = aws_cloudfront_distribution.this.id
}

output "arn" {
  description = "The ARN of the CloudFront distribution"
  value       = aws_cloudfront_distribution.this.arn
}