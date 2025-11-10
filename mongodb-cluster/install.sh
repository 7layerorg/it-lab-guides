#!/bin/bash

#ansible-playbookprep_systems.yml
ansible-playbook site.yml -v
#ansible-playbook init_cluster.yml 
ansible-playbook init_cluster_meta.yml
ansible-playbook init_cluster_data.yml


