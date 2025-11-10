#!/bin/bash
################################################################################
# MongoDB Sharded Cluster - PROPER Ansible Galaxy Role Builder
# Run on: 192.168.121.100 (ansible host)
# Creates: /opt/mongodb-cluster/ with proper Galaxy role structure
################################################################################

set -e

INSTALL_DIR="/opt/mongodb-cluster"
ROLE_NAME="mongodb_cluster"

echo "================================================"
echo "MongoDB Cluster - Ansible Galaxy Role Builder"
echo "================================================"
echo ""

if [ "$EUID" -ne 0 ]; then 
   echo "ERROR: Run as root"
   exit 1
fi

if [ -d "$INSTALL_DIR" ]; then
    BACKUP="${INSTALL_DIR}_backup_$(date +%Y%m%d_%H%M%S)"
    echo "[WARN] Backing up to: $BACKUP"
    mv "$INSTALL_DIR" "$BACKUP"
fi

echo "[INFO] Creating Galaxy role structure in: $INSTALL_DIR"

# Create proper Galaxy role structure
mkdir -p $INSTALL_DIR/{roles/$ROLE_NAME/{tasks,vars,templates,defaults,handlers,meta},inventory}

################################################################################
# ANSIBLE.CFG
################################################################################
cat > $INSTALL_DIR/ansible.cfg <<'EOF'
[defaults]
inventory = inventory/hosts
host_key_checking = False
roles_path = roles
interpreter_python = auto_silent

[inventory]
enable_plugins = ini, yaml
EOF

################################################################################
# INVENTORY
################################################################################
cat > $INSTALL_DIR/inventory/hosts <<'EOF'
[data_nodes]
192.168.121.101
192.168.121.102
192.168.121.103
192.168.121.104
192.168.121.105

[config_servers]
192.168.121.106
192.168.121.107
192.168.121.108

[arbiter]
192.168.121.108

[mongos_routers]
192.168.121.101
192.168.121.102
192.168.121.103
192.168.121.104
192.168.121.105

[mongodb_cluster:children]
data_nodes
config_servers
arbiter
mongos_routers

[all:vars]
ansible_user=vagrant
ansible_become=yes
ansible_become_method=sudo
EOF

################################################################################
# ROLE: DEFAULTS
################################################################################
cat > $INSTALL_DIR/roles/$ROLE_NAME/defaults/main.yml <<'EOF'
---
# MongoDB version
mongodb_version: "7.0"

# Directories
base_data_dir: "/mnt/data"
log_dir: "/var/log/mongodb"
config_dir: "/etc/mongodb-cls"

# Replica Sets
data_replset: "rs01"
config_replset: "configReplSet"

# Ports
data_port: 27017
config_port: 27019
arbiter_port: 27014
mongos_port: 27020

# Config servers
config_servers_list:
  - "192.168.121.106:27019"
  - "192.168.121.107:27019"
  - "192.168.121.108:27019"
config_servers_str: "configReplSet/192.168.121.106:27019,192.168.121.107:27019,192.168.121.108:27019"

# Data nodes
data_nodes_list:
  - "192.168.121.101:27017"
  - "192.168.121.102:27017"
  - "192.168.121.103:27017"
  - "192.168.121.104:27017"
  - "192.168.121.105:27017"
EOF

################################################################################
# ROLE: TASKS - MAIN
################################################################################
cat > $INSTALL_DIR/roles/$ROLE_NAME/tasks/main.yml <<'EOF'
---
- name: Include installation tasks
  include_tasks: install.yml
  when: inventory_hostname in groups['data_nodes'] or inventory_hostname in groups['config_servers']

- name: Include data node tasks
  include_tasks: data_node.yml
  when: inventory_hostname in groups['data_nodes']

- name: Include config server tasks
  include_tasks: config_server.yml
  when: inventory_hostname in groups['config_servers']

- name: Include arbiter tasks
  include_tasks: arbiter.yml
  when: inventory_hostname in groups['arbiter']

- name: Include mongos tasks
  include_tasks: mongos.yml
  when: inventory_hostname in groups['mongos_routers']
EOF

################################################################################
# ROLE: TASKS - INSTALL
################################################################################
cat > $INSTALL_DIR/roles/$ROLE_NAME/tasks/install.yml <<'EOF'
---
- name: Add MongoDB repository
  yum_repository:
    name: mongodb-org-7.0
    description: MongoDB Repository
    baseurl: https://repo.mongodb.org/yum/redhat/$releasever/mongodb-org/7.0/x86_64/
    gpgcheck: yes
    enabled: yes
    gpgkey: https://www.mongodb.org/static/pgp/server-7.0.asc

- name: Install MongoDB packages
  yum:
    name:
      - mongodb-org
      - mongodb-org-server
      - mongodb-org-mongos
      - mongodb-org-tools
      - mongodb-mongosh
    state: present

- name: Set SELinux to permissive
  selinux:
    state: permissive
    policy: targeted
  ignore_errors: yes

- name: Open firewall ports
  firewalld:
    port: "{{ item }}"
    permanent: yes
    state: enabled
    immediate: yes
  loop:
    - "{{ data_port }}/tcp"
    - "{{ config_port }}/tcp"
    - "{{ arbiter_port }}/tcp"
    - "{{ mongos_port }}/tcp"
  when: ansible_facts.services['firewalld.service'] is defined
  ignore_errors: yes
EOF

################################################################################
# ROLE: TASKS - DATA NODE
################################################################################
cat > $INSTALL_DIR/roles/$ROLE_NAME/tasks/data_node.yml <<'EOF'
---
- name: Create data directory
  file:
    path: "{{ base_data_dir }}/mongodb"
    state: directory
    owner: mongod
    group: mongod
    mode: '0755'

- name: Create log directory
  file:
    path: "{{ log_dir }}"
    state: directory
    owner: mongod
    group: mongod
    mode: '0755'

- name: Create config directory
  file:
    path: "{{ config_dir }}"
    state: directory
    owner: root
    group: root
    mode: '0755'

- name: Deploy data node config
  template:
    src: mongodb_cluster.conf.j2
    dest: "{{ config_dir }}/mongodb_cluster.conf"
    owner: mongod
    group: mongod
    mode: '0644'
  notify: restart mongodb-cluster

- name: Create systemd service
  template:
    src: mongodb-cluster.service.j2
    dest: /etc/systemd/system/mongodb-cluster.service
    owner: root
    group: root
    mode: '0644'
  notify: restart mongodb-cluster

- name: Enable and start data node service
  systemd:
    name: mongodb-cluster
    enabled: yes
    state: started
    daemon_reload: yes

- name: Wait for data node port
  wait_for:
    port: "{{ data_port }}"
    delay: 5
    timeout: 60
EOF

################################################################################
# ROLE: TASKS - CONFIG SERVER
################################################################################
cat > $INSTALL_DIR/roles/$ROLE_NAME/tasks/config_server.yml <<'EOF'
---
- name: Create config data directory
  file:
    path: "{{ base_data_dir }}/mongodb-config"
    state: directory
    owner: mongod
    group: mongod
    mode: '0755'

- name: Create log directory
  file:
    path: "{{ log_dir }}"
    state: directory
    owner: mongod
    group: mongod
    mode: '0755'

- name: Create config directory
  file:
    path: "{{ config_dir }}"
    state: directory
    owner: root
    group: root
    mode: '0755'

- name: Deploy config server config
  template:
    src: mongodb_meta.conf.j2
    dest: "{{ config_dir }}/mongodb_meta.conf"
    owner: mongod
    group: mongod
    mode: '0644'
  notify: restart mongodb-meta

- name: Create systemd service
  template:
    src: mongodb-meta.service.j2
    dest: /etc/systemd/system/mongodb-meta.service
    owner: root
    group: root
    mode: '0644'
  notify: restart mongodb-meta

- name: Enable and start config server service
  systemd:
    name: mongodb-meta
    enabled: yes
    state: started
    daemon_reload: yes

- name: Wait for config server port
  wait_for:
    port: "{{ config_port }}"
    delay: 5
    timeout: 60
EOF

################################################################################
# ROLE: TASKS - ARBITER
################################################################################
cat > $INSTALL_DIR/roles/$ROLE_NAME/tasks/arbiter.yml <<'EOF'
---
- name: Create arbiter data directory
  file:
    path: "{{ base_data_dir }}/mongodb-arbiter"
    state: directory
    owner: mongod
    group: mongod
    mode: '0755'

- name: Create log directory
  file:
    path: "{{ log_dir }}"
    state: directory
    owner: mongod
    group: mongod
    mode: '0755'

- name: Create config directory
  file:
    path: "{{ config_dir }}"
    state: directory
    owner: root
    group: root
    mode: '0755'

- name: Deploy arbiter config
  template:
    src: mongodb_arbiter.conf.j2
    dest: "{{ config_dir }}/mongodb_arbiter.conf"
    owner: mongod
    group: mongod
    mode: '0644'
  notify: restart mongodb-arbiter

- name: Create systemd service
  template:
    src: mongodb-arbiter.service.j2
    dest: /etc/systemd/system/mongodb-arbiter.service
    owner: root
    group: root
    mode: '0644'
  notify: restart mongodb-arbiter

- name: Enable and start arbiter service
  systemd:
    name: mongodb-arbiter
    enabled: yes
    state: started
    daemon_reload: yes

- name: Wait for arbiter port
  wait_for:
    port: "{{ arbiter_port }}"
    delay: 5
    timeout: 60
EOF

################################################################################
# ROLE: TASKS - MONGOS
################################################################################
cat > $INSTALL_DIR/roles/$ROLE_NAME/tasks/mongos.yml <<'EOF'
---
- name: Create log directory
  file:
    path: "{{ log_dir }}"
    state: directory
    owner: mongod
    group: mongod
    mode: '0755'

- name: Create config directory
  file:
    path: "{{ config_dir }}"
    state: directory
    owner: root
    group: root
    mode: '0755'

- name: Deploy mongos config
  template:
    src: mongos.conf.j2
    dest: "{{ config_dir }}/mongos.conf"
    owner: mongod
    group: mongod
    mode: '0644'
  notify: restart mongos

- name: Create systemd service
  template:
    src: mongos.service.j2
    dest: /etc/systemd/system/mongos.service
    owner: root
    group: root
    mode: '0644'
  notify: restart mongos

- name: Enable and start mongos service
  systemd:
    name: mongos
    enabled: yes
    state: started
    daemon_reload: yes

- name: Wait for mongos port
  wait_for:
    port: "{{ mongos_port }}"
    delay: 5
    timeout: 60
EOF

################################################################################
# ROLE: HANDLERS
################################################################################
cat > $INSTALL_DIR/roles/$ROLE_NAME/handlers/main.yml <<'EOF'
---
- name: restart mongodb-cluster
  systemd:
    name: mongodb-cluster
    state: restarted
    daemon_reload: yes

- name: restart mongodb-meta
  systemd:
    name: mongodb-meta
    state: restarted
    daemon_reload: yes

- name: restart mongodb-arbiter
  systemd:
    name: mongodb-arbiter
    state: restarted
    daemon_reload: yes

- name: restart mongos
  systemd:
    name: mongos
    state: restarted
    daemon_reload: yes
EOF

################################################################################
# ROLE: TEMPLATES
################################################################################
cat > $INSTALL_DIR/roles/$ROLE_NAME/templates/mongodb_cluster.conf.j2 <<'EOF'
storage:
  dbPath: {{ base_data_dir }}/mongodb
  wiredTiger:
    engineConfig:
      cacheSizeGB: 2

systemLog:
  destination: file
  path: {{ log_dir }}/mongodb_cluster.log
  logAppend: true

net:
  port: {{ data_port }}
  bindIp: 0.0.0.0

processManagement:
  fork: true
  pidFilePath: /var/run/mongodb/mongodb_cluster.pid

replication:
  replSetName: {{ data_replset }}

sharding:
  clusterRole: shardsvr
EOF

cat > $INSTALL_DIR/roles/$ROLE_NAME/templates/mongodb_meta.conf.j2 <<'EOF'
storage:
  dbPath: {{ base_data_dir }}/mongodb-config

systemLog:
  destination: file
  path: {{ log_dir }}/mongodb_meta.log
  logAppend: true

net:
  port: {{ config_port }}
  bindIp: 0.0.0.0

processManagement:
  fork: true
  pidFilePath: /var/run/mongodb/mongodb_meta.pid

replication:
  replSetName: {{ config_replset }}

sharding:
  clusterRole: configsvr
EOF

cat > $INSTALL_DIR/roles/$ROLE_NAME/templates/mongodb_arbiter.conf.j2 <<'EOF'
storage:
  dbPath: {{ base_data_dir }}/mongodb-arbiter

systemLog:
  destination: file
  path: {{ log_dir }}/mongodb_arbiter.log
  logAppend: true

net:
  port: {{ arbiter_port }}
  bindIp: 0.0.0.0

processManagement:
  fork: true
  pidFilePath: /var/run/mongodb/mongodb_arbiter.pid

replication:
  replSetName: {{ data_replset }}
EOF

cat > $INSTALL_DIR/roles/$ROLE_NAME/templates/mongos.conf.j2 <<'EOF'
systemLog:
  destination: file
  path: {{ log_dir }}/mongos.log
  logAppend: true

net:
  port: {{ mongos_port }}
  bindIp: 0.0.0.0

processManagement:
  fork: true
  pidFilePath: /var/run/mongodb/mongos.pid

sharding:
  configDB: {{ config_servers_str }}
EOF

cat > $INSTALL_DIR/roles/$ROLE_NAME/templates/mongodb-cluster.service.j2 <<'EOF'
[Unit]
Description=MongoDB Data Node
After=network.target

[Service]
Type=forking
User=mongod
Group=mongod
ExecStart=/usr/bin/mongod --config {{ config_dir }}/mongodb_cluster.conf
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

cat > $INSTALL_DIR/roles/$ROLE_NAME/templates/mongodb-meta.service.j2 <<'EOF'
[Unit]
Description=MongoDB Config Server
After=network.target

[Service]
Type=forking
User=mongod
Group=mongod
ExecStart=/usr/bin/mongod --config {{ config_dir }}/mongodb_meta.conf
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

cat > $INSTALL_DIR/roles/$ROLE_NAME/templates/mongodb-arbiter.service.j2 <<'EOF'
[Unit]
Description=MongoDB Arbiter
After=network.target

[Service]
Type=forking
User=mongod
Group=mongod
ExecStart=/usr/bin/mongod --config {{ config_dir }}/mongodb_arbiter.conf
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

cat > $INSTALL_DIR/roles/$ROLE_NAME/templates/mongos.service.j2 <<'EOF'
[Unit]
Description=Mongos Router
After=network.target

[Service]
Type=forking
User=mongod
Group=mongod
ExecStart=/usr/bin/mongos --config {{ config_dir }}/mongos.conf
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

################################################################################
# ROLE: META
################################################################################
cat > $INSTALL_DIR/roles/$ROLE_NAME/meta/main.yml <<'EOF'
---
galaxy_info:
  author: Lazio
  description: MongoDB Sharded Cluster Installation
  company: NA
  license: MIT
  min_ansible_version: 2.9
  
  platforms:
    - name: EL
      versions:
        - 8
        - 9

dependencies: []
EOF

################################################################################
# MAIN PLAYBOOK
################################################################################
cat > $INSTALL_DIR/site.yml <<'EOF'
---
- name: Deploy MongoDB Sharded Cluster
  hosts: mongodb_cluster
  become: yes
  roles:
    - mongodb_cluster
EOF

################################################################################
# INITIALIZATION PLAYBOOK
################################################################################
cat > $INSTALL_DIR/init_cluster.yml <<'EOF'
---
- name: Initialize config server replica set
  hosts: 192.168.121.106
  become: yes
  vars_files:
    - roles/mongodb_cluster/defaults/main.yml
  tasks:
    - name: Initialize config replica set
      shell: |
        mongosh --port {{ config_port }} --quiet --eval '
        rs.initiate({
          _id: "{{ config_replset }}",
          configsvr: true,
          members: [
            { _id: 0, host: "192.168.121.106:{{ config_port }}" },
            { _id: 1, host: "192.168.121.107:{{ config_port }}" },
            { _id: 2, host: "192.168.121.108:{{ config_port }}" }
          ]
        })
        '
      register: config_rs_init
      
    - name: Show result
      debug:
        var: config_rs_init.stdout

    - name: Wait for replica set
      pause:
        seconds: 30

- name: Initialize data replica set
  hosts: 192.168.121.101
  become: yes
  vars_files:
    - roles/mongodb_cluster/defaults/main.yml
  tasks:
    - name: Initialize data replica set
      shell: |
        mongosh --port {{ data_port }} --quiet --eval '
        rs.initiate({
          _id: "{{ data_replset }}",
          members: [
            { _id: 0, host: "192.168.121.101:{{ data_port }}" },
            { _id: 1, host: "192.168.121.102:{{ data_port }}" },
            { _id: 2, host: "192.168.121.103:{{ data_port }}" },
            { _id: 3, host: "192.168.121.104:{{ data_port }}" },
            { _id: 4, host: "192.168.121.105:{{ data_port }}" },
            { _id: 5, host: "192.168.121.108:{{ arbiter_port }}", arbiterOnly: true }
          ]
        })
        '
      register: data_rs_init
      
    - name: Show result
      debug:
        var: data_rs_init.stdout

    - name: Wait for replica set
      pause:
        seconds: 30

    - name: Add shard to cluster
      shell: |
        mongosh --port {{ mongos_port }} --quiet --eval '
        sh.addShard("{{ data_replset }}/192.168.121.101:{{ data_port }},192.168.121.102:{{ data_port }},192.168.121.103:{{ data_port }},192.168.121.104:{{ data_port }},192.168.121.105:{{ data_port }}")
        '
      register: shard_add
      
    - name: Show shard add result
      debug:
        var: shard_add.stdout

    - name: Check cluster status
      shell: |
        mongosh --port {{ mongos_port }} --quiet --eval 'sh.status()'
      register: cluster_status
      
    - name: Show cluster status
      debug:
        var: cluster_status.stdout
EOF

################################################################################
# README
################################################################################
cat > $INSTALL_DIR/README.md <<'EOF'
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
EOF

echo ""
echo "================================================"
echo "COMPLETE!"
echo "================================================"
echo ""
echo "Created proper Ansible Galaxy role in: $INSTALL_DIR"
echo ""
echo "Structure:"
tree -L 3 $INSTALL_DIR 2>/dev/null || find $INSTALL_DIR -type d | head -20
echo ""
echo "Next steps:"
echo "  cd $INSTALL_DIR"
echo "  ansible-playbook site.yml         # Deploy everything"
echo "  ansible-playbook init_cluster.yml # Initialize cluster"
echo ""
