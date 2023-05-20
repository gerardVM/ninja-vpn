# Ninja VPN

Ninja VPN is a really simple volatile VPN server that uses Wireguard in an AWS ec2 instance. You will be able to connect to your own VPN through the common Wireguard client software.

![GitHub last commit](https://img.shields.io/github/last-commit/gerardVM/ninja-vpn)

## Installation

If you are used to Terraform and AWS, you can use the Makefile to build and destroy the VPN server. Remember editing the config.yaml file with your desired configuration.

```bash
make vpn-deploy # Create and deploy the VPN server
make vpn-destroy # Destroy the VPN server
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

2. Fill up the config.yaml file with your desired configuration and the /ops/.aws/credentials file with your AWS credentials. 

3. Create a Docker container with all necessary tools and permissions.
```bash
docker build -t ninja-vpn-deployer -f Dockerfile.deployer .
```

4. Build the VPN server by using the Docker container
```bash
docker run -it --rm -v $(pwd):/ninja-vpn -w /ninja-vpn ninja-vpn-deployer "make vpn-deploy"
```

5. Once you don't need the VPN anymore, destroy the server by using the Docker container again.
```bash
docker run -it --rm -v $(pwd):/ninja-vpn -w /ninja-vpn ninja-vpn-deployer "make vpn-destroy"
```

## Usage

Use commands to manage your VPN server:

```bash
make vpn-deploy # Create and deploy the VPN server
make vpn-destroy # Destroy the VPN server
```

Configure your Wireguard client with the info sent into your email:

- For Android: Scan the QR code with the Wireguard app.
- For Desktop: Import the attached config file into the Wireguard app.

## Countdown feature (optional)

The VPN server will be automatically destroyed after a certain amount of time. You can configure this time in the config.yaml file.

## Contributing

Pull requests are welcome

## License

[MIT](LICENSE.txt)