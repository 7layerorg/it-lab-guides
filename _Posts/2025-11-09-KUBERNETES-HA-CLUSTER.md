---
title: KUBERNETES-HA-CLUSTER WITH 3-ETCD-NODE & 5 WORKER NODE 
date: 2025-11-09
---

# Objective #
## Set up a MultiMaster HA Kubernetes lab environment using **HashiCorp Vagrant** to create test servers for your IT labs.

```bash
Vagrant.configure("2") do |config|
  config.vm.box = "cloud-image/ubuntu-24.04"

  # --------------------------------------------------
  # 3 Control‑plane nodes (etcd + API server)
  # --------------------------------------------------
  3.times do |i|
    config.vm.define "control#{i+1}" do |node|
      node.vm.hostname = "control#{i+1}"
      node.vm.network "private_network", ip: "192.168.56.#{10 + i}"
      node.vm.provider "virtualbox" do |vb|
        vb.memory = 4096
        vb.cpus   = 2
      end
      node.vm.provision "shell", inline: <<-SHELL
        # Disable swap
        sudo swapoff -a
        sudo sed -i '/ swap / s/^/#/' /etc/fstab
        # Install Docker
        sudo apt-get update
        sudo apt-get install -y docker.io
        sudo systemctl enable docker
        sudo systemctl start docker
        # Install kubeadm, kubelet, kubectl
        sudo apt-get update && sudo apt-get install -y apt-transport-https ca-certificates curl
        curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
        cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
        sudo apt-get update
        sudo apt-get install -y mc
        #sudo apt-mark hold kubelet kubeadm kubectl
        # Ensure kubelet can run
        sudo systemctl enable kubelet
        sudo systemctl start kubelet
      SHELL
    end
  end

  # --------------------------------------------------
  # 5 Worker nodes
  # --------------------------------------------------
  5.times do |i|
    config.vm.define "worker#{i+1}" do |node|
      node.vm.hostname = "worker#{i+1}"
      node.vm.network "private_network", ip: "192.168.56.#{20 + i}"
      node.vm.provider "virtualbox" do |vb|
        vb.memory = 4096
        vb.cpus   = 2
      end
      node.vm.provision "shell", inline: <<-SHELL
        # Disable swap
        sudo swapoff -a
        sudo sed -i '/ swap / s/^/#/' /etc/fstab
        # Install Docker
        sudo apt-get update
        sudo apt-get install -y mc
        #sudo systemctl enable docker
        #sudo systemctl start docker
        # Install kubeadm, kubelet, kubectl
        sudo apt-get update && sudo apt-get install -y apt-transport-https ca-certificates curl
        curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
        cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
        sudo apt-get update
        sudo apt-get install -y mc
        #sudo apt-mark hold kubelet kubeadm kubectl
        # Ensure kubelet can run
        #sudo systemctl enable kubelet
        #sudo systemctl start kubelet
      SHELL
    end
  end

  # --------------------------------------------------
  # Ansible control node
  # --------------------------------------------------
  config.vm.define "ansible" do |node|
    node.vm.hostname = "ansible"
    node.vm.network "private_network", ip: "192.168.56.100"
    node.vm.provider "virtualbox" do |vb|
      vb.memory = 2048
      vb.cpus   = 1
    end
    node.vm.provision "shell", inline: <<-SHELL
      # Basic setup for Ansible
      sudo apt-get update
      sudo apt-get install -y software-properties-common
      sudo apt-add-repository --yes --update ppa:ansible/ansible
      sudo apt-get install -y ansible
      # Optional: create a simple inventory file
      cat <<EOF > /home/vagrant/ansible_inventory
[all]
control1 ansible_host=192.168.56.11
control2 ansible_host=192.168.56.12
control3 ansible_host=192.168.56.13
worker1 ansible_host=192.168.56.21
worker2 ansible_host=192.168.56.22
worker3 ansible_host=192.168.56.23
worker4 ansible_host=192.168.56.24
worker5 ansible_host=192.168.56.25
EOF
    SHELL
  end
end
```

