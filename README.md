# Ninja VPN

Ninja VPN is a really simple volatile VPN server that uses Wireguard in AWS ec2 instances.

![GitHub last commit](https://img.shields.io/github/last-commit/gerardVM/ninja-vpn)

## Installation

If you are used to Terraform and AWS, you can use the Makefile to build and destroy the VPN server. Remember editing the config.yaml file with your desired configuration.

```bash
make build-vpn
make destroy-vpn
```

In case you don't have Terraform installed, you can use Docker to build and destroy the VPN server as follows:

You need:
- An AWS account and user credentials with permissions to create ec2 instances and security groups
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
docker build -t ninja-vpn-deployer -f ops/docker/Dockerfile.deployer .
```

4. Build the VPN server by using the Docker container
```bash
docker run -it --rm -v $(pwd):/ninja-vpn ninja-vpn-deployer "make build-vpn"
```

5. Once you don't need the VPN anymore, destroy the server by using the Docker container again.
```bash
docker run -it --rm -v $(pwd):/ninja-vpn ninja-vpn-deployer "make destroy-vpn"
```

## Usage

Use commands to manage your VPN server:

```bash
make build-vpn   # Create a new VPN server
make destroy-vpn # Destroy the VPN server
```

Configure your Wireguard client with the provided info:

- For Android: Scan the QR code with the Wireguard app.
- For Desktop: Import the freshly created wireguard.conf file with the Wireguard app.

## Contributing

Pull requests are welcome

## License

[MIT](LICENSE.txt)