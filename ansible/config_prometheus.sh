#!/bin/bash

exec >/tmp/config_prometheus.out 2>/tmp/config_prometheus.err

set -x

sudo /usr/bin/yum -y install ansible
mkdir /tmp/ansible
for f in packages dot_files kubectl docker; do
    /usr/bin/wget -O /tmp/ansible/${f}.yaml https://raw.githubusercontent.com/scottkaplan/k8s_monitoring/main/ansible/${f}.yaml
    sudo ansible-playbook /tmp/ansible/${f}.yaml
done

sudo usermod -aG docker ec2-user
# AWS authentication
aws eks update-kubeconfig --region us-west-1 --name demo
aws ecr get-login-password --region us-west-1 | sudo docker login --username AWS --password-stdin 775956577581.dkr.ecr.us-west-1.amazonaws.com

# Build the container for the service
git clone https://github.com/kubesphere/prometheus-example-app.git
cd /home/ec2-user/prometheus-example-app; sudo docker build -t prometheus-example-app .

# push to ECR
sudo docker tag prometheus-example-app:latest 775956577581.dkr.ecr.us-west-1.amazonaws.com/prometheus-example-app:latest
sudo docker push 775956577581.dkr.ecr.us-west-1.amazonaws.com/prometheus-example-app:latest

# Deploy container from ECR to k8s
cd /home/ec2-user; git clone https://github.com/scottkaplan/k8s_monitoring.git
/usr/local/bin/kubectl apply -f /home/ec2-user/k8s_monitoring/k8s/deployment.yaml

# Install the prometheus operator
mkdir /home/ec2-user/prometheus-operator
curl -sL https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/main/bundle.yaml -o /home/ec2-user/prometheus-operator/bundle.yaml
/usr/local/bin/kubectl apply --server-side --force-conflicts -f /home/ec2-user/prometheus-operator/bundle.yaml
/usr/local/bin/kubectl apply -f /home/ec2-user/k8s_monitoring/k8s/prometheus.yaml
