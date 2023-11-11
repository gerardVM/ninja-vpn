resource "aws_cloudfront_distribution" "distribution" {

    # lifecycle { ignore_changes = [ origin ] }

    origin {
        connection_attempts = 3
        connection_timeout  = 10
        domain_name = "${aws_apigatewayv2_api.api.id}.execute-api.${data.aws_region.current.name}.amazonaws.com"
        origin_id   = "${aws_apigatewayv2_api.api.id}.execute-api.${data.aws_region.current.name}.amazonaws.com"
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

    aliases             = [aws_route53_zone.hosted_zone.name, "*.${aws_route53_zone.hosted_zone.name}"]
    enabled             = true
    is_ipv6_enabled     = true
    default_root_object = "index.html"

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
        target_origin_id = "${aws_apigatewayv2_api.api.id}.execute-api.${data.aws_region.current.name}.amazonaws.com"

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

    viewer_certificate {
        acm_certificate_arn = aws_acm_certificate.cert.arn
        ssl_support_method  = "sni-only"
    }

    # tags = {
    #     Environment = "production"
    # }

    depends_on = [aws_s3_bucket_website_configuration.site]
}
