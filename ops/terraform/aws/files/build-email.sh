#!/bin/bash
subject="VPN Credentials"
docker exec wireguard cat /config/peer1/peer1.conf > /home/ec2-user/wg-client.conf && file_data=$(base64 /home/ec2-user/wg-client.conf)
qrencode -t png -o /home/ec2-user/user-qr.png -r /home/ec2-user/wg-client.conf && image_data=$(base64 /home/ec2-user/user-qr.png)
email=$(cat <<EOF
From: $EMAIL_ADDRESS
To: $EMAIL_ADDRESS
Subject: $subject
MIME-Version: 1.0
Content-Type: multipart/related; boundary=boundary-1

--boundary-1
Content-Type: text/html; charset=utf-8
Content-Transfer-Encoding: 7bit

<!DOCTYPE html>
<html>
<head>
  <title>$subject</title>
</head>
<body>
  <h2>WireGuard VPN</h2>
  <p>Here are your credentials. You can either scan the QR code if you are on your phone or download the attached config file if you are using a desktop machine.</p>
  <img src="cid:user-qr.png" alt="QR code for your VPN" />
</body>
</html>

--boundary-1
Content-Type: image/png
Content-Disposition: inline; filename=user-qr.png
Content-Transfer-Encoding: base64
Content-ID: <user-qr.png>

$image_data

--boundary-1
Content-Type: application/octet-stream
Content-Disposition: attachment; filename=wg-client.conf
Content-Transfer-Encoding: base64
Content-ID: <wg-client.conf>

$file_data

--boundary-1--

EOF
)