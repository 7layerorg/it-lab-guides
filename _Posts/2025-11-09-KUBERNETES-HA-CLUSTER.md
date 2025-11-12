---
title: KUBERNETES-HA-CLUSTER WITH 3-ETCD-NODE & 5 WORKER NODE 
date: 2025-11-09
---

# Objective #
## Set up a MultiMaster HA Kubernetes lab environment using **HashiCorp Vagrant** to create test servers for your IT labs.

##

```bash
apt-get autoremove apt-transport-https ca-certificates curl gnupg lsb-release -y
apt-get install apt-transport-https ca-certificates curl gnupg lsb-release -y
apt-get autoremove docker-ce -y
apt-get autoremove docker.io -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \ $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \ $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list 

sudo apt-get update 
sudo apt-get install docker-ce docker-ce-cli containerd.io

sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg

echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
sudo apt-get autoremove kubelet kubeadm kubectl
sudo apt-get install kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl



export KUBECONFIG=/etc/kubernetes/admin.conf 



kubectl get nodes --show-labels


NETWORKS:
ONLY INSTALL THIS!!!
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml

https://github.com/flannel-io/flannel#deploying-flannel-manually
https://kubernetes.io/docs/concepts/cluster-administration/addons/


SERVICE DEPLOYMENTS:
kubectl create deployment nginx --image=nginx
kubectl describe deployment nginx3

kubectl create service nodeport nginx3 --tcp=80:80







kubectl create clusterrolebinding dashboard-admin-sa --clusterrole=cluster-admin --serviceaccount=default:dashboard-admin-sa





#####
Dashboard:

IMPORTANT: Make sure that you know what you are doing before proceeding. Granting admin privileges to Dashboard's Service Account might be a security risk.

For each of the following snippets for ServiceAccount and ClusterRoleBinding, you should copy them to new manifest files like dashboard-adminuser.yaml and use kubectl apply -f dashboard-adminuser.yaml to create them.

Creating a Service Account
We are creating Service Account with the name admin-user in namespace kubernetes-dashboard first.

apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
Creating a ClusterRoleBinding
In most cases after provisioning the cluster using kops, kubeadm or any other popular tool, the ClusterRole cluster-admin already exists in the cluster. We can use it and create only a ClusterRoleBinding for our ServiceAccount. If it does not exist then you need to create this role first and grant required privileges manually.

apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard

#####


https://github.com/kubernetes/dashboard/blob/master/docs/user/access-control/creating-sample-user.md
https://stackoverflow.com/questions/48744904/how-to-access-kubernetes-dashboard-as-admin-with-userid-passwd-outside-cluster

kubectl describe secret


CERTIFICATE RENEW:

https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/troubleshooting-kubeadm/#kubelet-client-cert
https://platform9.com/kb/kubernetes/node-not-ready-with-error-container-runtime-is-down-pleg-is-not


NEW NODE ADD:

From master node:

kubectl get nodes
kubeadm token create --print-join-command
