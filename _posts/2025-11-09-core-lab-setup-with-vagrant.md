---
title: Core Lab Setup with Vagrant
date: 2025-11-09
---

### Objective
Set up a local virtual environment using **HashiCorp Vagrant** to create test servers for your IT labs.

### Steps
1. Install [Vagrant](https://developer.hashicorp.com/vagrant/downloads) and [VirtualBox](https://www.virtualbox.org/wiki/Downloads)
2. Create a folder:
   ```bash
   mkdir ~/it-lab && cd ~/it-lab

Initialize a VM:

vagrant init ubuntu/focal64
vagrant up

Access it:

vagrant ssh

