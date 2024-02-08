#!/bin/bash

sudo /usr/bin/yum -y install ansible
mkdir /tmp/ansible
for f in packages dot_files kubectl docker; do
    /usr/bin/wget -O /tmp/ansible/${f}.yaml https://raw.githubusercontent.com/scottkaplan/k8s_monitoring/main/ansible/${f}.yaml
    sudo ansible-playbook /tmp/ansible/${f}.yaml
done
