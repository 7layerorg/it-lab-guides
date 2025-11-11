# MongoDB Sharded Cluster - Ansible Galaxy Role

## Proper Galaxy Role Structure

This is just a baseline test cluster but fully functional.
Need user setup later and SSL setup also for secured communication if you need this in Prod.

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
