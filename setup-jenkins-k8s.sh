#!/bin/bash
# Run this on your EC2 instance: chmod +x setup-jenkins-k8s.sh && ./setup-jenkins-k8s.sh

set -e

echo "=== Installing Jenkins, Docker, kubectl on EC2 ==="

# Update system
sudo yum update -y

# Install Java 17 (required for Jenkins)
sudo yum install -y java-17-amazon-corretto

# Install Docker
sudo yum install -y docker
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ec2-user

# Install Jenkins
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
sudo yum install -y jenkins
sudo systemctl start jenkins
sudo systemctl enable jenkins

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# Install AWS CLI v2 (for ECR/EKS if needed)
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Install Git
sudo yum install -y git

# Wait for Jenkins to start
sleep 30

echo "=== Jenkins Initial Admin Password ==="
sudo cat /var/lib/jenkins/secrets/initialAdminPassword

echo "=== Setup Complete ==="
echo "Access Jenkins at: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8080"
echo "Login with the password above"