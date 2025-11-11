# MongoDB Sharded Cluster – Ansible Galaxy Role
## Proper Galaxy Role Structure

This repository provides a practical, step-by-step guide for deploying and testing a MongoDB replica set cluster in a lab environment with Ansible. 
It has been validated on [test environment details: Oracle Server Linux 9.3, MongoDB 7.0.25.], and is intended for IT professionals, students, and anyone looking to understand the setup and operational basics of MongoDB sharded or replicated clusters.

Supports: Multi-node cluster setup (replica set), Vagrant-based deployments, easy local or VM environment testing.
Requirements: Basic familiarity with Vagrant, Linux command line, and MongoDB concepts.
Cluster validation: All instructions have been fully tested for repeatable and reliable cluster formation; troubleshooting steps are included for common issues.
Purpose: Suitable for training, demonstrations, or lab scenarios—not intended for production use but can be further customized for Prod environment.

This is a fully operational prototype, minimal baseline test cluster to see how it works and how to deploy it via Ansible.
Current deployment has no user setup neither secure communication which needed in Production deployment.
The user and secure based communication will be deployed later on in a sub article.


```
/opt/mongodb-cluster/
├── ansible.cfg
├── inventory/hosts
├── site.yml                  # Main playbook
├── init_cluster.yml          # Initialization playbook
└── roles/
    └── mongodb_cluster/
        ├── defaults/         # Default variables
        ├── tasks/            # Task files
        ├── templates/        # Jinja2 templates
        ├── handlers/         # Service handlers
        └── meta/             # Role metadata
```

## 1. Installation Steps

This single playbook:
- Installs MongoDB on all nodes
- Creates all directories
- Deploys configurations
- Starts all services
- Setups Config server replica set
- Setups Data node replica set with arbiter
- Adds shard to cluster

```bash
./install.sh
```


### 2. Verify
```bash
mongosh --host 192.168.121.108 --port 27014
rs.status()
```

## Cluster Topology

- **Data Nodes (5):** 192.168.121.101-105 (port 27017) - rs01
- **Config Servers (3):** 192.168.121.106-108 (port 27019) - configReplSet
- **Arbiter (1):** 192.168.121.108 (port 27014)
- **Mongos (5):** 192.168.121.101-105 (port 27020)

## Variables

All variables in `roles/mongodb_cluster/defaults/main.yml`

## Services

- mongodb-cluster (data nodes)
- mongodb-meta (config servers)
- mongodb-arbiter
- mongos
