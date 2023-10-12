variable "cloudfront_distribution_arn" {
  description = "The ARN of the CloudFront distribution"
  type        = string
}

variable "cloudfront_distribution_id" {
  description = "The ARN of the CloudFront distribution"
  type        = string
}

variable "cloudfront_origin_id" {
  description = "The ID of the CloudFront origin"
  type        = string
}

variable "cloudfront_authorizer_header_name" {
  description = "The name of the header to use for authorization"
  type        = string
}