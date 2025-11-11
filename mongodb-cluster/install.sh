#!/bin/bash

DATA_NODE_1=$(grep data_node_1 /opt/it-lab-guides/mongodb-cluster/roles/mongodb_cluster/defaults/main.yml | awk '{ print $2 }' | grep -oP '\b(?:\d{1,3}\.){3}\d{1,3}\b')
CONFIG_SERVER_NODE_1=$(grep config_server_node_1 /opt/it-lab-guides/mongodb-cluster/roles/mongodb_cluster/defaults/main.yml | awk '{ print $2 }' | grep -oP '\b(?:\d{1,3}\.){3}\d{1,3}\b')

export DATA_NODE_1
export CONFIG_NODE_1

ansible -m ping $DATA_NODE_1
ansible -m ping $CONFIG_SERVER_NODE_1
ansible -m ping all

#ansible-playbookprep_systems.yml
ansible-playbook site.yml -vv


