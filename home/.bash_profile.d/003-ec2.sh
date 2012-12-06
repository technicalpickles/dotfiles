export EC2_HOME=~/.ec2
export PATH=${PATH}:${EC2_HOME}/bin
export EC2_PRIVATE_KEY=$(ls $EC2_HOME/pk-*.pem 2>/dev/null)
export EC2_CERT=$(ls $EC2_HOME/cert-*.pem 2>/dev/null)
