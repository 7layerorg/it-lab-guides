---
title: Core Lab Setup with Vagrant
date: 2025-11-09
---

```bash
# Objective #
Set up a local virtual environment using **HashiCorp Vagrant** to create test servers for your IT labs.


# Steps #
1. Install [Vagrant](https://developer.hashicorp.com/vagrant/downloads) and [VirtualBox](https://www.virtualbox.org/wiki/Downloads)
2. Create a folder:
   ```bash
   mkdir ~/it-lab && cd ~/it-lab
3. Create the Vagrant file:


nano Vagrantfile

######

Vagrant.configure("2") do |config|
  config.vm.box = "generic/oracle9"

# Generate SSH key upfront (run once before vagrant up) #
  ssh_pub_key = File.readlines("#{Dir.home}/.ssh/ol9_cluster.pub").first.strip rescue nil
  
# 8 cluster nodes + 1 ansible controller = 9 total #
  NODE_COUNT = 8
  
# Ansible controller node #
  config.vm.define "ol9-ansible" do |node|
    node.vm.hostname = "ol9-ansible"
    node.vm.network "private_network", ip: "192.168.121.100"
    
    node.vm.provider :libvirt do |libvirt|
      libvirt.memory = 2048
      libvirt.cpus = 2
    end
    
    node.vm.provision "shell", inline: <<-SHELL
# Install Ansible #
      dnf install -y ansible-core vim
      
# Copy SSH keys for vagrant user #
      mkdir -p /home/vagrant/.ssh
      cp /media/lazio/vagrant-ol9-cluster /home/vagrant/.ssh/ol9_cluster
      cp /media/lazio/vagrant-ol9-cluster.pub /home/vagrant/.ssh/ol9_cluster.pub
      chmod 600 /home/vagrant/.ssh/ol9_cluster
      chmod 644 /home/vagrant/.ssh/ol9_cluster.pub
      chown -R vagrant:vagrant /home/vagrant/.ssh

# Add all nodes to /etc/hosts
      for j in {1..8}; do
        echo "192.168.121.$((100+j)) ol9-node$j" >> /etc/hosts
      done
      
# Create Ansible inventory
      cat > /home/vagrant/inventory << 'EOF'
[cluster]
ol9-node1 ansible_host=192.168.121.101
ol9-node2 ansible_host=192.168.121.102
ol9-node3 ansible_host=192.168.121.103
ol9-node4 ansible_host=192.168.121.104
ol9-node5 ansible_host=192.168.121.105
ol9-node6 ansible_host=192.168.121.106
ol9-node7 ansible_host=192.168.121.107
ol9-node8 ansible_host=192.168.121.108

[cluster:vars]
ansible_user=vagrant
ansible_ssh_private_key_file=/home/vagrant/.ssh/id_rsa
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
EOF
      chown vagrant:vagrant /home/vagrant/inventory
    SHELL
  end
  
# 8 cluster nodes
  (1..NODE_COUNT).each do |i|
    config.vm.define "ol9-node#{i}" do |node|
      node.vm.hostname = "ol9-node#{i}"
      node.vm.network "private_network", ip: "192.168.121.#{100+i}"
      
      node.vm.provider :libvirt do |libvirt|
        libvirt.memory = 2048
        libvirt.cpus = 2
      end
      
      node.vm.provision "shell", inline: <<-SHELL
# Add ansible controller and all nodes to /etc/hosts
        echo "192.168.121.100 ol9-ansible" >> /etc/hosts
        for j in {1..8}; do
          echo "192.168.121.$((100+j)) ol9-node$j" >> /etc/hosts
        done
        
# Add SSH public key for passwordless access
        if [ -n "#{ssh_pub_key}" ]; then
          mkdir -p /home/vagrant/.ssh
          echo "#{ssh_pub_key}" >> /home/vagrant/.ssh/authorized_keys
          chmod 700 /home/vagrant/.ssh
          chmod 600 /home/vagrant/.ssh/authorized_keys
          chown -R vagrant:vagrant /home/vagrant/.ssh
        fi
      SHELL
    end
  end
end


Initialize a VM:

vagrant init ubuntu/focal64
vagrant up

########

Access it:

vagrant ssh ol9-ansible

Now here in Ansible node create the access for Ansible so it can access all the nodes:

ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""

Test it on the first node:

ssh-copy-id -i ~/.ssh/id_ed25519.pub vagrant@ol9-node1
Type the vagrant password here.

Then test it:
If you can log in to the first node with no password from now on then do the mass key copy to all nodes:

for i in {1..8}; do   ssh-copy-id -i ~/.ssh/id_ed25519.pub vagrant@ol9-node$i; done

Here you need to type the password in each nodes.
Now test them second and the last if those good then all good to go to go to the next level and create the MongoDB cluster.
Exit here and go back to the Ansible node.
