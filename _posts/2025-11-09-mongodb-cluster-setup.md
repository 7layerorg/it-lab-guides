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
ansible-playbook prep_systems.yml # Install NTP, disables SELinux
ansible-playbook site.yml         # Installs, configures, starts everything
ansible-playbook init_cluster.yml # Initializes replica sets + shard

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


And here comes the fun part:

#########################

mongosh --port 27017

rs.status()
{
  set: 'rs01',
  date: ISODate('2025-11-09T19:33:05.101Z'),
  myState: 1,
  term: Long('1'),
  syncSourceHost: '',
  syncSourceId: -1,
  heartbeatIntervalMillis: Long('2000'),
  majorityVoteCount: 4,
  writeMajorityCount: 4,
  votingMembersCount: 6,
  writableVotingMembersCount: 5,
  optimes: {
    lastCommittedOpTime: { ts: Timestamp({ t: 1762716777, i: 2 }), t: Long('1') },
    lastCommittedWallTime: ISODate('2025-11-09T19:32:57.992Z'),
    readConcernMajorityOpTime: { ts: Timestamp({ t: 1762716777, i: 2 }), t: Long('1') },
    appliedOpTime: { ts: Timestamp({ t: 1762716777, i: 2 }), t: Long('1') },
    durableOpTime: { ts: Timestamp({ t: 1762716777, i: 2 }), t: Long('1') },
    lastAppliedWallTime: ISODate('2025-11-09T19:32:57.992Z'),
    lastDurableWallTime: ISODate('2025-11-09T19:32:57.992Z')
  },
  lastStableRecoveryTimestamp: Timestamp({ t: 1762716747, i: 2 }),
  electionCandidateMetrics: {
    lastElectionReason: 'electionTimeout',
    lastElectionDate: ISODate('2025-11-09T19:28:47.953Z'),
    electionTerm: Long('1'),
    lastCommittedOpTimeAtElection: { ts: Timestamp({ t: 1762716516, i: 1 }), t: Long('-1') },
    lastSeenOpTimeAtElection: { ts: Timestamp({ t: 1762716516, i: 1 }), t: Long('-1') },
    numVotesNeeded: 4,
    priorityAtElection: 1,
    electionTimeoutMillis: Long('10000'),
    numCatchUpOps: Long('0'),
    newTermStartDate: ISODate('2025-11-09T19:28:47.973Z'),
    wMajorityWriteAvailabilityDate: ISODate('2025-11-09T19:28:48.482Z')
  },
  members: [
    {
      _id: 0,
      name: '192.168.121.101:27017',
      health: 1,
      state: 1,
      stateStr: 'PRIMARY',
      uptime: 848,
      optime: { ts: Timestamp({ t: 1762716777, i: 2 }), t: Long('1') },
      optimeDate: ISODate('2025-11-09T19:32:57.000Z'),
      lastAppliedWallTime: ISODate('2025-11-09T19:32:57.992Z'),
      lastDurableWallTime: ISODate('2025-11-09T19:32:57.992Z'),
      syncSourceHost: '',
      syncSourceId: -1,
      infoMessage: '',
      electionTime: Timestamp({ t: 1762716527, i: 1 }),
      electionDate: ISODate('2025-11-09T19:28:47.000Z'),
      configVersion: 1,
      configTerm: 1,
      self: true,
      lastHeartbeatMessage: ''
    },
    {
      _id: 1,
      name: '192.168.121.102:27017',
      health: 1,
      state: 2,
      stateStr: 'SECONDARY',
      uptime: 268,
      optime: { ts: Timestamp({ t: 1762716777, i: 2 }), t: Long('1') },
      optimeDurable: { ts: Timestamp({ t: 1762716777, i: 2 }), t: Long('1') },
      optimeDate: ISODate('2025-11-09T19:32:57.000Z'),
      optimeDurableDate: ISODate('2025-11-09T19:32:57.000Z'),
      lastAppliedWallTime: ISODate('2025-11-09T19:32:57.992Z'),
      lastDurableWallTime: ISODate('2025-11-09T19:32:57.992Z'),
      lastHeartbeat: ISODate('2025-11-09T19:33:03.978Z'),
      lastHeartbeatRecv: ISODate('2025-11-09T19:33:04.488Z'),
      pingMs: Long('0'),
      lastHeartbeatMessage: '',
      syncSourceHost: '192.168.121.101:27017',
      syncSourceId: 0,
      infoMessage: '',
      configVersion: 1,
      configTerm: 1
    },
    {
      _id: 2,
      name: '192.168.121.103:27017',
      health: 1,
      state: 2,
      stateStr: 'SECONDARY',
      uptime: 268,
      optime: { ts: Timestamp({ t: 1762716777, i: 2 }), t: Long('1') },
      optimeDurable: { ts: Timestamp({ t: 1762716777, i: 2 }), t: Long('1') },
      optimeDate: ISODate('2025-11-09T19:32:57.000Z'),
      optimeDurableDate: ISODate('2025-11-09T19:32:57.000Z'),
      lastAppliedWallTime: ISODate('2025-11-09T19:32:57.992Z'),
      lastDurableWallTime: ISODate('2025-11-09T19:32:57.992Z'),
      lastHeartbeat: ISODate('2025-11-09T19:33:03.978Z'),
      lastHeartbeatRecv: ISODate('2025-11-09T19:33:04.982Z'),
      pingMs: Long('0'),
      lastHeartbeatMessage: '',
      syncSourceHost: '192.168.121.101:27017',
      syncSourceId: 0,
      infoMessage: '',
      configVersion: 1,
      configTerm: 1
    },
    {
      _id: 3,
      name: '192.168.121.104:27017',
      health: 1,
      state: 2,
      stateStr: 'SECONDARY',
      uptime: 268,
      optime: { ts: Timestamp({ t: 1762716777, i: 2 }), t: Long('1') },
      optimeDurable: { ts: Timestamp({ t: 1762716777, i: 2 }), t: Long('1') },
      optimeDate: ISODate('2025-11-09T19:32:57.000Z'),
      optimeDurableDate: ISODate('2025-11-09T19:32:57.000Z'),
      lastAppliedWallTime: ISODate('2025-11-09T19:32:57.992Z'),
      lastDurableWallTime: ISODate('2025-11-09T19:32:57.992Z'),
      lastHeartbeat: ISODate('2025-11-09T19:33:03.979Z'),
      lastHeartbeatRecv: ISODate('2025-11-09T19:33:04.982Z'),
      pingMs: Long('0'),
      lastHeartbeatMessage: '',
      syncSourceHost: '192.168.121.102:27017',
      syncSourceId: 1,
      infoMessage: '',
      configVersion: 1,
      configTerm: 1
    },
    {
      _id: 4,
      name: '192.168.121.105:27017',
      health: 1,
      state: 2,
      stateStr: 'SECONDARY',
      uptime: 268,
      optime: { ts: Timestamp({ t: 1762716777, i: 2 }), t: Long('1') },
      optimeDurable: { ts: Timestamp({ t: 1762716777, i: 2 }), t: Long('1') },
      optimeDate: ISODate('2025-11-09T19:32:57.000Z'),
      optimeDurableDate: ISODate('2025-11-09T19:32:57.000Z'),
      lastAppliedWallTime: ISODate('2025-11-09T19:32:57.992Z'),
      lastDurableWallTime: ISODate('2025-11-09T19:32:57.992Z'),
      lastHeartbeat: ISODate('2025-11-09T19:33:03.979Z'),
      lastHeartbeatRecv: ISODate('2025-11-09T19:33:04.982Z'),
      pingMs: Long('0'),
      lastHeartbeatMessage: '',
      syncSourceHost: '192.168.121.101:27017',
      syncSourceId: 0,
      infoMessage: '',
      configVersion: 1,
      configTerm: 1
    },
    {
      _id: 5,
      name: '192.168.121.108:27014',
      health: 1,
      state: 7,
      stateStr: 'ARBITER',
      uptime: 268,
      lastHeartbeat: ISODate('2025-11-09T19:33:03.978Z'),
      lastHeartbeatRecv: ISODate('2025-11-09T19:33:03.978Z'),
      pingMs: Long('0'),
      lastHeartbeatMessage: '',
      syncSourceHost: '',
      syncSourceId: -1,
      infoMessage: '',
      configVersion: 1,
      configTerm: 1
    }
  ],
  ok: 1,
  '$clusterTime': {
    clusterTime: Timestamp({ t: 1762716784, i: 1 }),
    signature: {
      hash: Binary.createFromBase64('AAAAAAAAAAAAAAAAAAAAAAAAAAA=', 0),
      keyId: Long('0')
    }
  },
  operationTime: Timestamp({ t: 1762716777, i: 2 })
}

exit 

#########################

mongosh --port 27020

#########################

Current Mongosh Log ID:	6910ecb7825e0f38809dc29c
Connecting to:		mongodb://127.0.0.1:27020/?directConnection=true&serverSelectionTimeoutMS=2000&appName=mongosh+2.5.9
Using MongoDB:		7.0.25
Using Mongosh:		2.5.9

For mongosh info see: https://www.mongodb.com/docs/mongodb-shell/

------
   The server generated these startup warnings when booting
   2025-11-09T18:36:08.874+00:00: Access control is not enabled for the database. Read and write access to data and configuration is unrestricted
------

[direct: mongos] test> sh.status()
shardingVersion
{ _id: 1, clusterId: ObjectId('6910df3d6ba3067a72b4a2f1') }
---
shards
[
  {
    _id: 'rs01',
    host: 'rs01/192.168.121.101:27017,192.168.121.102:27017,192.168.121.103:27017,192.168.121.104:27017,192.168.121.105:27017',
    state: 1,
    topologyTime: Timestamp({ t: 1762716544, i: 2 })
  }
]
---
active mongoses
[ { '7.0.25': 5 } ]
---
autosplit
{ 'Currently enabled': 'yes' }
---
balancer
{
  'Currently enabled': 'yes',
  'Failed balancer rounds in last 5 attempts': 0,
  'Currently running': 'no',
  'Migration Results for the last 24 hours': 'No recent migrations'
}
---
shardedDataDistribution
[
  {
    ns: 'config.system.sessions',
    shards: [
      {
        shardName: 'rs01',
        numOrphanedDocs: 0,
        numOwnedDocuments: 17,
        ownedSizeBytes: 1683,
        orphanedSizeBytes: 0
      }
    ]
  }
]
---
databases
[
  {
    database: { _id: 'config', primary: 'config', partitioned: true },
    collections: {
      'config.system.sessions': {
        shardKey: { _id: 1 },
        unique: false,
        balancing: true,
        allowMigrations: true,
        chunkMetadata: [ { shard: 'rs01', nChunks: 1 } ],
        chunks: [
          { min: { _id: MinKey() }, max: { _id: MaxKey() }, 'on shard': 'rs01', 'last modified': Timestamp({ t: 1, i: 0 }) }
        ],
        tags: []
      }
    }
  }
]


#########################

This is the important part:

active mongoses
[ { '7.0.25': 5 } ]

5 Active mongos!

You need to connect always to the mongos, not to the cluster directly, I have seen this issue from several coders they made this mistake as .net for example makes the connections to the active node via checking the arbiter but that is pretty wrong!

Mongos is the router and it makes the routing always to the active primary node and then if the primary fails it marks the wrong node and reroutes the traffic to the new primary and also marks the wrong host as dead and the counter goes down one to four. This cluster is redundant to 2 data nodes and auto heals itself just delete the wrong data and it will pull the data from the current active primary and resyncs.
