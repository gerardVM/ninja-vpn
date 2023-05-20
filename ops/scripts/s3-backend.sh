read -p "Do you want to backup your terraform state to S3? [y/N] " yn 
if [ "$yn" = "y" ]; then 
    read -p "Enter your S3 bucket name [ninja-vpn-terraform-state]: " bucket ;
    bucket="${bucket:-ninja-vpn-terraform-state}"; 
    read -p "Enter your S3 bucket key [ninja-vpn.tfstate]: " key; 
    key="${key:-ninja-vpn.tfstate}";
    read -p "Enter your S3 bucket region [us-east-1]: " region; 
    region="${region:-us-east-1}"; 
    echo "terraform {\n backend \"s3\" {\n  bucket = \"$bucket\"\n  key = \"$key\"\n  region = \"$region\"\n }\n}";
fi