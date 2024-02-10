#!/bin/bash

exec >>/tmp/config_prometheus.out 2>>/tmp/config_prometheus.err

set -x

function run_playbooks {
    sudo /usr/bin/yum -y install ansible
    mkdir /tmp/ansible
    for f in packages dot_files kubectl docker; do
        /usr/bin/wget -O /tmp/ansible/${f}.yaml $ansible_yaml_dir/${f}.yaml
        sudo ansible-playbook /tmp/ansible/${f}.yaml
    done
}

function docker_non_root {
    sudo groupadd docker
    sudo usermod -aG docker ec2-user
}

function aws_credentials {
    mv /tmp/credentials $base_dir/.aws/
    chmod 400 $base_dir/.aws/credentials
}

function aws_authentication {
    aws ecr get-login-password --region us-west-1 | docker login --username AWS --password-stdin $ecr_server
    aws eks update-kubeconfig --region us-west-1 --name demo
}

function build_container {
    git clone https://github.com/kubesphere/prometheus-example-app.git
    cd $base_dir/prometheus-example-app; docker build -t prometheus-example-app .
}

function push_container_to_ecr {
    docker tag $container_name $ecr_server/$container_name
    docker push $ecr_server/$container_name
}

function deploy_ecr_to_k8s {
    cd $base_dir; git clone https://github.com/scottkaplan/k8s_monitoring.git
    $kubectl apply -f $base_dir/k8s_monitoring/k8s/deployment.yaml
}

function install_prometheus_operator {
    mkdir $base_dir/prometheus-operator
    curl -sL $prometheus_operator_yaml -o $base_dir/prometheus-operator/bundle.yaml
    # prometheus-operator yaml is too big to process on the client
    $kubectl apply --server-side --force-conflicts -f $base_dir/prometheus-operator/bundle.yaml
    $kubectl apply -f $base_dir/k8s_monitoring/k8s/alertmanager.yaml
    $kubectl apply -f $base_dir/k8s_monitoring/k8s/rbac.yaml
    $kubectl apply -f $base_dir/k8s_monitoring/k8s/prometheus.yaml
}

ecr_server=775956577581.dkr.ecr.us-west-1.amazonaws.com
container_name=prometheus-example-app:latest
base_dir=/home/ec2-user
kubectl=/usr/local/bin/kubectl
prometheus_operator_yaml=https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/main/bundle.yaml
ansible_yaml_dir=https://raw.githubusercontent.com/scottkaplan/k8s_monitoring/main/ansible

date
run_playbooks
docker_non_root
aws_credentials
aws_authentication
build_container
push_container_to_ecr
deploy_ecr_to_k8s
install_prometheus_operator
date

exit 0
