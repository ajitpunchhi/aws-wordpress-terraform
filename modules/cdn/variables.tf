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

