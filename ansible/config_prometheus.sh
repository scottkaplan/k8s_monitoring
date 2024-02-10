#!/bin/bash

exec >/tmp/config_prometheus.out 2>/tmp/config_prometheus.err

set -x

function run_playbooks {
    sudo /usr/bin/yum -y install ansible
    mkdir /tmp/ansible
    for f in packages dot_files kubectl docker; do
        /usr/bin/wget -O /tmp/ansible/${f}.yaml https://raw.githubusercontent.com/scottkaplan/k8s_monitoring/main/ansible/${f}.yaml
        sudo ansible-playbook /tmp/ansible/${f}.yaml
    done
}

function docker_non_root {
    sudo groupadd docker
    sudo usermod -aG docker ec2-user
}

function aws_credentials {
    mv /tmp/credentials /home/ec2-user/.aws/
    chmod 400 /home/ec2-user/.aws/credentials
}

function aws_authentication {
    aws eks update-kubeconfig --region us-west-1 --name demo
    aws ecr get-login-password --region us-west-1 | docker login --username AWS --password-stdin 775956577581.dkr.ecr.us-west-1.amazonaws.com
}

function build_container {
    git clone https://github.com/kubesphere/prometheus-example-app.git
    cd /home/ec2-user/prometheus-example-app; docker build -t prometheus-example-app .
}

function push_container_to_ecr {
    docker tag prometheus-example-app:latest 775956577581.dkr.ecr.us-west-1.amazonaws.com/prometheus-example-app:latest
    docker push 775956577581.dkr.ecr.us-west-1.amazonaws.com/prometheus-example-app:latest
}

function deploy_ecr_to_k8s {
    cd /home/ec2-user; git clone https://github.com/scottkaplan/k8s_monitoring.git
    /usr/local/bin/kubectl apply -f /home/ec2-user/k8s_monitoring/k8s/deployment.yaml
}

function install_prometheus_operator {
    mkdir /home/ec2-user/prometheus-operator
    curl -sL https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/main/bundle.yaml -o /home/ec2-user/prometheus-operator/bundle.yaml
    /usr/local/bin/kubectl apply --server-side --force-conflicts -f /home/ec2-user/prometheus-operator/bundle.yaml
    /usr/local/bin/kubectl apply -f /home/ec2-user/k8s_monitoring/k8s/prometheus.yaml
}

run_playbooks
docker_non_root
aws_credentials
aws_authentication
build_container
push_container_to_ecr
deploy_ecr_to_k8s
install_prometheus_operator

exit 0
