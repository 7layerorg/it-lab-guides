# Redis Master-Replica Cluster on Kubernetes

## Overview
Deploy a Redis master + 2 replica cluster on Kubernetes using plain manifests 
and MetalLB for external access. No Helm required.

## Prerequisites
- Kubernetes cluster
- MetalLB installed
- local-path storage provisioner

## Files
- `redis-cluster.yaml` — full manifest (namespace, configmaps, statefulsets, services)

## Deploy
```bash
kubectl apply -f redis-cluster.yaml
```

## Verify
```bash
redis-cli -h <EXTERNAL-IP> -p 6379 -a yourpassword INFO replication

In my test case: 
redis-cli -h 10.99.101.204 -p 6379 -a yourpassword info replication
```

Expected output:

```bash
Warning: Using a password with '-a' or '-u' option on the command line interface may not be safe.
# Replication
role:master
connected_slaves:2
slave0:ip=10.244.2.27,port=6379,state=online,offset=1134,lag=1
slave1:ip=10.244.1.33,port=6379,state=online,offset=1134,lag=1
master_failover_state:no-failover
master_replid:0fbc64bda08d6c3be42460e52e36a9c12234eb1b
master_replid2:0000000000000000000000000000000000000000
master_repl_offset:1134
second_repl_offset:-1
repl_backlog_active:1
repl_backlog_size:1048576
repl_backlog_first_byte_offset:1
repl_backlog_histlen:1134
```

## Jenkins result in CI/CD pipeline:

```bash
sent 76 bytes  received 12 bytes  176.00 bytes/sec
total size is 2,927  speedup is 33.26
+ ssh -o StrictHostKeyChecking=no root@192.168.0.165 'kubectl apply -f /tmp/redis-cluster.yaml'
namespace/redis unchanged
secret/redis-secret configured
configmap/redis-master-config unchanged
configmap/redis-replica-config unchanged
statefulset.apps/my-redis-master configured
service/my-redis-master unchanged
statefulset.apps/my-redis-replica configured
service/my-redis-replica unchanged
service/my-redis-master-external unchanged
+ ssh -o StrictHostKeyChecking=no root@192.168.0.165 'kubectl get svc -n redis'
NAME                       TYPE           CLUSTER-IP       EXTERNAL-IP     PORT(S)          AGE
my-redis-master            ClusterIP      10.109.200.89    <none>          6379/TCP         128m
my-redis-master-external   LoadBalancer   10.110.216.118   10.99.101.204   6379:31226/TCP   125m
my-redis-replica           ClusterIP      10.110.227.191   <none>          6379/TCP         128m
+ ssh -o StrictHostKeyChecking=no root@192.168.0.165 'kubectl get pods -n redis'
NAME                 READY   STATUS    RESTARTS   AGE
my-redis-master-0    1/1     Running   0          128m
my-redis-replica-0   1/1     Running   0          128m
my-redis-replica-1   1/1     Running   0          128m
SSH: Connecting from host [jenkins-server]
SSH: Connecting with configuration [Kubernetes] ...
SSH: Disconnecting configuration [Kubernetes] ...
SSH: Transferred 1 file(s)
Finished: SUCCESS
```
