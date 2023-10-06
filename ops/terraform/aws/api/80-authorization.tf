module "authorization" {
    source = "./modules/authorizer"
}

resource "aws_apigatewayv2_authorizer" "api_authorizer" {
    name             = "api_authorizer"
    api_id           = aws_apigatewayv2_api.api.id
    authorizer_type  = "REQUEST"
    authorizer_uri   = module.authorization.authorizer_uri
    identity_sources = [
        "$request.header.x-origin-verify",
    ]
    authorizer_payload_format_version = "2.0"
}