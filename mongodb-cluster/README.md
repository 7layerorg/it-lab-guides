# MongoDB Sharded Cluster - Ansible Galaxy Role

## Proper Galaxy Role Structure

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

## Installation Steps

### 1. Deploy MongoDB components
```bash
cd /opt/mongodb-cluster
ansible-playbook site.yml
```

This single playbook:
- Installs MongoDB on all nodes
- Creates all directories
- Deploys configurations
- Starts all services

### 2. Initialize cluster
```bash
ansible-playbook init_cluster.yml
```

This initializes:
- Config server replica set
- Data node replica set with arbiter
- Adds shard to cluster

### 3. Verify
```bash
mongosh --host 192.168.121.101 --port 27020
sh.status()
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
