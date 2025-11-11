# MongoDB Sharded Cluster – Ansible Galaxy Role
## Proper Galaxy Role Structure

This repository provides a practical, step-by-step guide for deploying and testing a MongoDB replica set cluster in a lab environment using Ansible. Validated in Oracle Server Linux 9.3, MongoDB 7.0.2.5. Designed for IT professionals and students seeking hands-on experience with MongoDB sharding and replication fundamentals.

##Features:

- Multi-node cluster setup (replica set)
- Vagrant-based or direct deployment; easy VM/lab adaptation
- Reliable, repeatable installation with thoroughly tested Ansible playbooks
- Includes troubleshooting notes for common cluster setup issues
##Requirements: Familiarity with Vagrant (optional), Linux CLI, and fundamental MongoDB concepts.

##Note: This project implements a minimal, operational test cluster for educational and lab purposes. Production deployments require additional setup, including user authentication and SSL for secure communications.

##Directory Structure:

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
