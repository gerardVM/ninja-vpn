resource "aws_cloudfront_distribution" "distribution" {

    # lifecycle { ignore_changes = [ origin ] }

    origin {
        connection_attempts = 3
        connection_timeout  = 10
        domain_name = "${aws_apigatewayv2_api.api.id}.execute-api.${local.api_region}.amazonaws.com"
        origin_id   = "${aws_apigatewayv2_api.api.id}.execute-api.${local.api_region}.amazonaws.com"
        custom_header {
            name  = "x-origin-verify"
            value = module.header_rotation.header_value
        }

        custom_origin_config {
            http_port              = 80
            https_port             = 443
            origin_keepalive_timeout = 5
            origin_protocol_policy = "https-only"
            origin_read_timeout    = 30
            origin_ssl_protocols   = ["TLSv1.2"]
        }
    }
    
    origin {
        connection_attempts = 3
        connection_timeout  = 10
        domain_name = aws_s3_bucket_website_configuration.site.website_endpoint
        origin_id   = aws_s3_bucket_website_configuration.site.website_endpoint

        custom_origin_config {
            http_port              = 80
            https_port             = 443
            origin_keepalive_timeout = 5
            origin_protocol_policy = "http-only"
            origin_read_timeout    = 30
            origin_ssl_protocols   = ["TLSv1.2"]
        }

    }

    # aliases             = [aws_route53_zone.hosted_zone.name]
    enabled             = true
    is_ipv6_enabled     = true
    default_root_object = "index.html"
    # web_acl_id          = aws_wafv2_web_acl.web_acl.id
    web_acl_id          = "arn:aws:wafv2:us-east-1:877759700856:global/webacl/CreatedByCloudFront-07e5fa89-01e9-438c-af4c-98d0a5520d4b/dd217589-1bfc-48d9-80de-b06019efd90a"

    default_cache_behavior {
        allowed_methods  = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
        cached_methods   = ["GET", "HEAD"]
        target_origin_id = aws_s3_bucket_website_configuration.site.website_endpoint

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
    }

    ordered_cache_behavior {
        path_pattern     = "/${aws_apigatewayv2_stage.stage.name}/*"
        allowed_methods  = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
        cached_methods   = ["GET", "HEAD"]
        target_origin_id = "${aws_apigatewayv2_api.api.id}.execute-api.${local.api_region}.amazonaws.com"

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
    }

    restrictions {
        geo_restriction {
            restriction_type = "none"
        }
    }

    # viewer_certificate {
    #     acm_certificate_arn = aws_acm_certificate.cert.arn
    #     ssl_support_method  = "sni-only"
    # }

    viewer_certificate {
        cloudfront_default_certificate = true
    }

    # tags = {
    #     Environment = "production"
    # }

    depends_on = [aws_s3_bucket_website_configuration.site]
}

# resource "aws_wafv2_web_acl" "web_acl" {
#     name        = "web_acl"
#     description = "web_acl"

#     scope = "REGIONAL"

#     default_action {
#         allow {}
#     }

#     visibility_config {
#         cloudwatch_metrics_enabled = true
#         metric_name                = "web_acl"
#         sampled_requests_enabled   = true
#     }

#     rule {
#         name     = "rule"
#         priority = 1

#         action {
#             block {}
#         }

#         statement {
#             not_statement {
#                 statement {
#                     geo_match_statement {
#                         country_codes = ["CN"]
#                     }
#                 }
#             }
#         }

#         visibility_config {
#             cloudwatch_metrics_enabled = true
#             metric_name                = "rule"
#             sampled_requests_enabled   = true
#         }
#     }
# }

output "cloudfront_distribution_domain_name" {
    value = aws_cloudfront_distribution.distribution.domain_name
}