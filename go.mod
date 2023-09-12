module launch_vpn

go 1.21.1

require (
	github.com/aws/aws-lambda-go v1.41.0
	github.com/go-git/go-git/v5 v5.8.1
	github.com/go-yaml/yaml v2.1.0+incompatible
	github.com/hashicorp/go-version v1.6.0
	github.com/hashicorp/hc-install v0.6.0
	github.com/hashicorp/terraform-exec v0.19.0
)

replace github.com/hashicorp/terraform-exec v0.19.0 => github.com/gerardVM/terraform-exec v0.19.1
