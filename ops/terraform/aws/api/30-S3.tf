resource "aws_s3_bucket" "bucket" {
    bucket = local.config.bucket_name
}

resource "aws_s3_bucket" "site" {
    bucket = "vpnn-site"
}

data "template_file" "index_html" {
    template = file(local.index_path)
    vars = {
        api_gateway_url = "${aws_apigatewayv2_api.api.api_endpoint}/${aws_apigatewayv2_stage.stage.name}${element(split(" ", aws_apigatewayv2_route.lambda.route_key),1)}"
    }
}

resource "aws_s3_object" "index" {
    bucket       = aws_s3_bucket.site.id
    key          = "index.html"
    content      = data.template_file.index_html.rendered
    content_type = "text/html"
}

resource "aws_s3_bucket_policy" "allow_site_access" {
    bucket = aws_s3_bucket.site.id
    policy = jsonencode({
        Statement = [
            {
                Sid       = "PublicReadGetObject"
                Action    = "s3:GetObject"
                Effect    = "Allow"
                Principal = "*"
                Resource  = "arn:aws:s3:::vpnn-site/*"
            },
        ]
        Version   = "2012-10-17"
    })
}

resource "aws_s3_bucket_website_configuration" "site" {
    bucket = aws_s3_bucket.site.id
    index_document {
        suffix = "index.html"
    }
}