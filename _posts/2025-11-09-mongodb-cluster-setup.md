# MongoDB Cluster Ansible Installer - Quick Start

## On Ansible Host (192.168.121.100)

### Step 1: Run the builder (creates everything)
```bash
cd /opt
sudo ./build_mongodb_ansible_installer.sh
```

This creates `/opt/mongodb-cluster/` with:
- Inventory (8 nodes)
- Group variables
- 4 config templates
- 9 numbered playbooks
- README

### Step 2: Run the playbooks in order
```bash
cd /opt/mongodb-cluster

ansible-playbook -i inventory/hosts playbooks/01-install-mongodb.yml
ansible-playbook -i inventory/hosts playbooks/02-create-directories.yml
ansible-playbook -i inventory/hosts playbooks/03-configure-data-nodes.yml
ansible-playbook -i inventory/hosts playbooks/04-configure-config-servers.yml
ansible-playbook -i inventory/hosts playbooks/05-configure-arbiter.yml
ansible-playbook -i inventory/hosts playbooks/06-configure-mongos.yml
ansible-playbook -i inventory/hosts playbooks/07-init-config-replset.yml
ansible-playbook -i inventory/hosts playbooks/08-init-data-replset.yml
ansible-playbook -i inventory/hosts playbooks/09-add-shard.yml
```

### Step 3: Test
```bash
mongosh --host 192.168.121.101 --port 27020
sh.status()
```

Done.

---

**Files:**
- `/opt/build_mongodb_ansible_installer.sh` - ONE builder script
- `/opt/mongodb-cluster/` - Complete ansible installer (created by above)

**What it does:**
- Installs MongoDB 7.0 on 8 nodes
- Creates all directories (`/mnt/data`, `/etc/mongodb-cls`, `/var/log/mongodb`)
- Configures 5 data nodes (rs01)
- Configures 3 config servers (configReplSet)
- Configures 1 arbiter
- Configures 5 mongos routers
- Initializes replica sets
- Adds shard to cluster
