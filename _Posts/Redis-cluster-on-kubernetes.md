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
```

Expected output:

