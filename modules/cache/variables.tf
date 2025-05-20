variable "name" {
  description = "Name to be used on all resources as identifier"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "subnet_ids" {
  description = "The subnet IDs to deploy the ElastiCache cluster"
  type        = list(string)
}

variable "security_group_id" {
  description = "The security group ID for the ElastiCache cluster"
  type        = string
}

variable "node_type" {
  description = "The compute and memory capacity of the nodes"
  type        = string
  default     = "cache.t3.small"
}

variable "port" {
  description = "The port number on which each of the cache nodes will accept connections"
  type        = number
  default     = 6379
}

variable "num_cache_nodes" {
  description = "The initial number of cache nodes"
  type        = number
  default     = 1
}

variable "engine" {
  description = "The name of the cache engine to be used"
  type        = string
  default     = "redis"
}

variable "engine_version" {
  description = "The version number of the cache engine"
  type        = string
  default     = "6.x"
}

variable "parameter_group_name" {
  description = "The name of the parameter group to associate with this cache cluster"
  type        = string
  default     = null
}

variable "automatic_failover_enabled" {
  description = "Specifies whether a read-only replica will be automatically promoted to read/write primary if the existing primary fails"
  type        = bool
  default     = false
}

variable "maintenance_window" {
  description = "The weekly time range for when maintenance on the cache cluster is performed"
  type        = string
  default     = "sun:05:00-sun:09:00"
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

