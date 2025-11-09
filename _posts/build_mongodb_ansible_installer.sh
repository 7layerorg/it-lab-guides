#!/bin/bash
################################################################################
# MongoDB Sharded Cluster - Complete Ansible Installer Builder
# Run once on: 192.168.121.100 (ansible host)
# Creates: /opt/mongodb-cluster/ with ALL ansible files
################################################################################

set -e

INSTALL_DIR="/opt/mongodb-cluster"

echo "================================================"
echo "MongoDB Cluster - Ansible Installer Builder"
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

echo "[INFO] Creating: $INSTALL_DIR"
mkdir -p $INSTALL_DIR/{playbooks,inventory,group_vars,templates}

################################################################################
# ANSIBLE.CFG
################################################################################
echo "[INFO] Creating ansible.cfg..."
cat > $INSTALL_DIR/ansible.cfg <<'EOF'
[defaults]
inventory = inventory/hosts
host_key_checking = False
interpreter_python = auto_silent

[inventory]
enable_plugins = ini, yaml
EOF

################################################################################
# INVENTORY
################################################################################
echo "[INFO] Creating inventory..."
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

[all:vars]
ansible_user=vagrant
ansible_become=yes
ansible_become_method=sudo
ansible_ssh_private_key_file=~/.ssh/id_ed25519
EOF

################################################################################
# GROUP VARIABLES
################################################################################
echo "[INFO] Creating group_vars..."
cat > $INSTALL_DIR/group_vars/all.yml <<'EOF'
---
mongodb_version: "7.0"
base_data_dir: "/mnt/data"
log_dir: "/var/log/mongodb"
config_dir: "/etc/mongodb-cls"
data_replset: "rs01"
config_replset: "configReplSet"
data_port: 27017
config_port: 27019
arbiter_port: 27014
mongos_port: 27020
config_servers: "configReplSet/192.168.121.106:27019,192.168.121.107:27019,192.168.121.108:27019"
EOF

################################################################################
# TEMPLATES
################################################################################
echo "[INFO] Creating templates..."

# Data node config
cat > $INSTALL_DIR/templates/mongodb_cluster.conf.j2 <<'EOF'
storage:
  dbPath: {{ base_data_dir }}/mongodb
  journal:
    enabled: true
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

# Config server config
cat > $INSTALL_DIR/templates/mongodb_meta.conf.j2 <<'EOF'
storage:
  dbPath: {{ base_data_dir }}/mongodb-config
  journal:
    enabled: true
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

# Arbiter config
cat > $INSTALL_DIR/templates/mongodb_arbiter.conf.j2 <<'EOF'
storage:
  dbPath: {{ base_data_dir }}/mongodb-arbiter
  journal:
    enabled: true
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

# Mongos config
cat > $INSTALL_DIR/templates/mongos.conf.j2 <<'EOF'
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
  configDB: {{ config_servers }}
EOF

################################################################################
# PLAYBOOK 01 - INSTALL MONGODB
################################################################################
echo "[INFO] Creating playbook 01-install-mongodb.yml..."
cat > $INSTALL_DIR/playbooks/01-install-mongodb.yml <<'EOF'
---
- name: Install MongoDB on all nodes
  hosts: data_nodes,config_servers
  become: yes
  tasks:

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
# PLAYBOOK 02 - CREATE DIRECTORIES
################################################################################
echo "[INFO] Creating playbook 02-create-directories.yml..."
cat > $INSTALL_DIR/playbooks/02-create-directories.yml <<'EOF'
---
- name: Create directories on data nodes
  hosts: data_nodes
  become: yes
  tasks:
    - name: Create directories
      file:
        path: "{{ item }}"
        state: directory
        owner: mongod
        group: mongod
        mode: '0755'
      loop:
        - "{{ base_data_dir }}/mongodb"
        - "{{ log_dir }}"
        - "{{ config_dir }}"

- name: Create directories on config servers
  hosts: config_servers
  become: yes
  tasks:
    - name: Create directories
      file:
        path: "{{ item }}"
        state: directory
        owner: mongod
        group: mongod
        mode: '0755'
      loop:
        - "{{ base_data_dir }}/mongodb-config"
        - "{{ log_dir }}"
        - "{{ config_dir }}"

- name: Create directories on arbiter
  hosts: arbiter
  become: yes
  tasks:
    - name: Create directories
      file:
        path: "{{ item }}"
        state: directory
        owner: mongod
        group: mongod
        mode: '0755'
      loop:
        - "{{ base_data_dir }}/mongodb-arbiter"
        - "{{ log_dir }}"
        - "{{ config_dir }}"
EOF

################################################################################
# PLAYBOOK 03 - CONFIGURE DATA NODES
################################################################################
echo "[INFO] Creating playbook 03-configure-data-nodes.yml..."
cat > $INSTALL_DIR/playbooks/03-configure-data-nodes.yml <<'EOF'
---
- name: Configure data nodes
  hosts: data_nodes
  become: yes
  tasks:

    - name: Deploy data node config
      template:
        src: ../templates/mongodb_cluster.conf.j2
        dest: "{{ config_dir }}/mongodb_cluster.conf"
        owner: mongod
        group: mongod
        mode: '0644'

    - name: Create systemd service
      copy:
        dest: /etc/systemd/system/mongodb-cluster.service
        content: |
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

    - name: Start data node
      systemd:
        name: mongodb-cluster
        state: started
        enabled: yes
        daemon_reload: yes

    - name: Wait for port
      wait_for:
        port: "{{ data_port }}"
        delay: 5
EOF

################################################################################
# PLAYBOOK 04 - CONFIGURE CONFIG SERVERS
################################################################################
echo "[INFO] Creating playbook 04-configure-config-servers.yml..."
cat > $INSTALL_DIR/playbooks/04-configure-config-servers.yml <<'EOF'
---
- name: Configure config servers
  hosts: config_servers
  become: yes
  tasks:

    - name: Deploy config server config
      template:
        src: ../templates/mongodb_meta.conf.j2
        dest: "{{ config_dir }}/mongodb_meta.conf"
        owner: mongod
        group: mongod
        mode: '0644'

    - name: Create systemd service
      copy:
        dest: /etc/systemd/system/mongodb-meta.service
        content: |
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

    - name: Start config server
      systemd:
        name: mongodb-meta
        state: started
        enabled: yes
        daemon_reload: yes

    - name: Wait for port
      wait_for:
        port: "{{ config_port }}"
        delay: 5
EOF

################################################################################
# PLAYBOOK 05 - CONFIGURE ARBITER
################################################################################
echo "[INFO] Creating playbook 05-configure-arbiter.yml..."
cat > $INSTALL_DIR/playbooks/05-configure-arbiter.yml <<'EOF'
---
- name: Configure arbiter
  hosts: arbiter
  become: yes
  tasks:

    - name: Deploy arbiter config
      template:
        src: ../templates/mongodb_arbiter.conf.j2
        dest: "{{ config_dir }}/mongodb_arbiter.conf"
        owner: mongod
        group: mongod
        mode: '0644'

    - name: Create systemd service
      copy:
        dest: /etc/systemd/system/mongodb-arbiter.service
        content: |
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

    - name: Start arbiter
      systemd:
        name: mongodb-arbiter
        state: started
        enabled: yes
        daemon_reload: yes

    - name: Wait for port
      wait_for:
        port: "{{ arbiter_port }}"
        delay: 5
EOF

################################################################################
# PLAYBOOK 06 - CONFIGURE MONGOS
################################################################################
echo "[INFO] Creating playbook 06-configure-mongos.yml..."
cat > $INSTALL_DIR/playbooks/06-configure-mongos.yml <<'EOF'
---
- name: Configure mongos routers
  hosts: mongos_routers
  become: yes
  tasks:

    - name: Deploy mongos config
      template:
        src: ../templates/mongos.conf.j2
        dest: "{{ config_dir }}/mongos.conf"
        owner: mongod
        group: mongod
        mode: '0644'

    - name: Create systemd service
      copy:
        dest: /etc/systemd/system/mongos.service
        content: |
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

    - name: Start mongos
      systemd:
        name: mongos
        state: started
        enabled: yes
        daemon_reload: yes

    - name: Wait for port
      wait_for:
        port: "{{ mongos_port }}"
        delay: 5
EOF

################################################################################
# PLAYBOOK 07 - INIT CONFIG REPLICA SET
################################################################################
echo "[INFO] Creating playbook 07-init-config-replset.yml..."
cat > $INSTALL_DIR/playbooks/07-init-config-replset.yml <<'EOF'
---
- name: Initialize config server replica set
  hosts: 192.168.121.106
  become: yes
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
      register: rs_init
      
    - name: Show result
      debug:
        var: rs_init.stdout

    - name: Wait for replica set
      pause:
        seconds: 30
EOF

################################################################################
# PLAYBOOK 08 - INIT DATA REPLICA SET
################################################################################
echo "[INFO] Creating playbook 08-init-data-replset.yml..."
cat > $INSTALL_DIR/playbooks/08-init-data-replset.yml <<'EOF'
---
- name: Initialize data replica set
  hosts: 192.168.121.101
  become: yes
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
      register: rs_init
      
    - name: Show result
      debug:
        var: rs_init.stdout

    - name: Wait for replica set
      pause:
        seconds: 30
EOF

################################################################################
# PLAYBOOK 09 - ADD SHARD
################################################################################
echo "[INFO] Creating playbook 09-add-shard.yml..."
cat > $INSTALL_DIR/playbooks/09-add-shard.yml <<'EOF'
---
- name: Add shard to cluster
  hosts: 192.168.121.101
  become: yes
  tasks:

    - name: Add shard
      shell: |
        mongosh --port {{ mongos_port }} --quiet --eval '
        sh.addShard("{{ data_replset }}/192.168.121.101:{{ data_port }},192.168.121.102:{{ data_port }},192.168.121.103:{{ data_port }},192.168.121.104:{{ data_port }},192.168.121.105:{{ data_port }}")
        '
      register: shard_add
      
    - name: Show result
      debug:
        var: shard_add.stdout

    - name: Check shard status
      shell: |
        mongosh --port {{ mongos_port }} --quiet --eval 'sh.status()'
      register: shard_status
      
    - name: Show shard status
      debug:
        var: shard_status.stdout
EOF

################################################################################
# README
################################################################################
echo "[INFO] Creating README..."
cat > $INSTALL_DIR/README.md <<'EOF'
# MongoDB Sharded Cluster - Ansible Installer

## Cluster Topology

**Data Nodes (5):** 192.168.121.101-105 (port 27017) - Replica Set: rs01
**Config Servers (3):** 192.168.121.106-108 (port 27019) - Replica Set: configReplSet
**Arbiter (1):** 192.168.121.108 (port 27014) - Part of rs01
**Mongos Routers (5):** 192.168.121.101-105 (port 27020)

## Installation Order

```bash
cd /opt/mongodb-cluster

# 1. Install MongoDB on all nodes
ansible-playbook -i inventory/hosts playbooks/01-install-mongodb.yml

# 2. Create directories on all nodes
ansible-playbook -i inventory/hosts playbooks/02-create-directories.yml

# 3. Configure data nodes (5 servers)
ansible-playbook -i inventory/hosts playbooks/03-configure-data-nodes.yml

# 4. Configure config servers (3 servers)
ansible-playbook -i inventory/hosts playbooks/04-configure-config-servers.yml

# 5. Configure arbiter (1 server)
ansible-playbook -i inventory/hosts playbooks/05-configure-arbiter.yml

# 6. Configure mongos routers (5 servers)
ansible-playbook -i inventory/hosts playbooks/06-configure-mongos.yml

# 7. Initialize config server replica set
ansible-playbook -i inventory/hosts playbooks/07-init-config-replset.yml

# 8. Initialize data replica set
ansible-playbook -i inventory/hosts playbooks/08-init-data-replset.yml

# 9. Add shard to cluster
ansible-playbook -i inventory/hosts playbooks/09-add-shard.yml
```

## Verify Cluster

Connect to any mongos:
```bash
mongosh --host 192.168.121.101 --port 27020
```

Check status:
```javascript
sh.status()
```

## Files Structure

```
/opt/mongodb-cluster/
├── inventory/hosts           # All 8 nodes
├── group_vars/all.yml        # Variables
├── templates/                # Config templates
│   ├── mongodb_cluster.conf.j2
│   ├── mongodb_meta.conf.j2
│   ├── mongodb_arbiter.conf.j2
│   └── mongos.conf.j2
└── playbooks/                # 9 playbooks (numbered)
```

## Config Locations on Nodes

- Data nodes: `/etc/mongodb-cls/mongodb_cluster.conf`
- Config servers: `/etc/mongodb-cls/mongodb_meta.conf`
- Arbiter: `/etc/mongodb-cls/mongodb_arbiter.conf`
- Mongos: `/etc/mongodb-cls/mongos.conf`
- Data directory: `/mnt/data/`
- Logs: `/var/log/mongodb/`
EOF




################################################################################
# FINISH
################################################################################
echo ""
echo "================================================"
echo "COMPLETE!"
echo "================================================"
echo ""
echo "Created in: $INSTALL_DIR"
echo ""
echo "Structure:"
ls -lh $INSTALL_DIR/
echo ""
echo "Next: cd $INSTALL_DIR && cat README.md"
echo ""
