# Ninja VPN

Ninja VPN is a really simple volatile VPN server that uses Wireguard in an AWS ec2 instance. You will be able to connect to your own VPN through the common Wireguard client software.

![GitHub last commit](https://img.shields.io/github/last-commit/gerardVM/ninja-vpn)

## The fancy expected result

You just need to run something in the lines of this:

```bash
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "action": "deploy",
    "email": "your_email@example.com",
    "timezone": "Europe/Madrid",
    "countdown": "50 minutes",
    "region": "eu-west-1"
  }' <your-api-gateway-endpoint>
```

And you will receive an email in few minutes with the VPN configuration and a QR code to scan with your Wireguard app.

## How to use this repository

### Deploy the API

```bash
make tf-deploy TF_TARGET=api
```

### Deploy the VPN manually
  
```bash
make tf-deploy TF_TARGET=vpn
```

## Contributing

Pull requests are welcome

## License

[MIT](LICENSE.txt)
