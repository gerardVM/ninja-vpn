# Ninja VPN

Ninja VPN is a really simple volatile VPN server that uses Wireguard in an AWS ec2 instance. You will be able to connect to your own VPN through the common Wireguard client software.

![GitHub last commit](https://img.shields.io/github/last-commit/gerardVM/ninja-vpn)

## Installation

If you are used to Terraform and AWS, you can use the Makefile to build and destroy the VPN server. Edit the `users/<username>.yaml` file with user's desired configuration and run:

```bash
make vpn USER=<username>
```

In case you don't have Terraform installed, you can use Docker to build and destroy the VPN server as follows:

You need:
- An AWS account and user credentials with permissions to create AWS resources.
- Docker installed

Steps:

1. Clone this repo and cd into it.
```bash
docker run -it --rm -v $(pwd):/git alpine/git clone https://github.com/gerardVM/ninja-vpn.git
cd ninja-vpn
```

2. Fill up the `ops/.aws/credentials` file with your AWS credentials and create a Docker container with all necessary tools and permissions:
```bash
docker build -t ninja-vpn-deployer -f Dockerfile.deployer .
```

3. Fill up the `users/<username>.yaml` file with your user's desired configuration. You can decide there if you want to deploy or destroy the VPN server.

4. Build/Destroy the VPN server by using the Docker container
```bash
docker run -it --rm -v $(pwd):/ninja-vpn -w /ninja-vpn ninja-vpn-deployer "make vpn USER=<username>"
```

## Usage

Edit `users/<username>.yaml` file and run following command to deploy/destroy your VPN server:

```bash
make vpn USER=<username>    # Deploy/Destroy user's desired configuration for the VPN server
```

Users can now configure their Wireguard client with the info sent into their email:

- For Android: Scan the QR code with the Wireguard app.
- For Desktop: Import the attached config file into the Wireguard app.

## Countdown feature (optional)

The VPN server will be automatically destroyed after a certain amount of time. You can configure this time in the `users/<username>.yaml` file.

Check [here](https://docs.aws.amazon.com/AmazonCloudWatch/latest/events/ScheduledEvents.html#RateExpressions) for more info about the rate expression syntax.

## Caveats

- Because of the multiuser implementation, some infrastructure like a bucket for resources, a bucket for the backend and a SES service for the sender email need to be set in advance. The configuration that defines those resources can be found in the common.yaml file.

## Next Steps

Sending credentials email just with the first spot instance: Credentials email is being sent after every spot instance interruption. This is not necessary since VPN configuration is passed through the instances of the fleet.

## Contributing

Pull requests are welcome

## License

[MIT](LICENSE.txt)
