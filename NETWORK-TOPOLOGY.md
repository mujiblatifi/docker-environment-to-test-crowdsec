# CrowdSec Testing Docker Container Environment — Network Topology

## Overview

The CrowdSec Security Testing Environment uses three isolated Docker bridge
networks connected through a dedicated laboratory router.

The topology is designed for controlled security testing of:

- CrowdSec SSH authentication detection
- CrowdSec HTTP/NGINX detection
- CrowdSec log acquisition
- CrowdSec parsers
- CrowdSec scenarios
- CrowdSec alerts
- CrowdSec decisions

The primary purpose of this environment is to test and demonstrate
**CrowdSec security detection capabilities** in a controlled Docker laboratory.

Docker networking, logging, monitoring, and routing are supporting components
of the CrowdSec testing environment.

The environment is intentionally isolated and must not be exposed to
untrusted or production networks.

## Network Topology

```text
                         CrowdSec Security Testing Environment
                         =====================================

                                      Docker Host
                                          |
                                          |
                              +-----------+-----------+
                              |                       |
                              |    CrowdSec Lab       |
                              |      Services         |
                              |                       |
                              +-----------+-----------+
                                          |
                                  crowdSecNet
                                  10.10.10.0/24
                                          |
                              +-----------+-----------+
                              |                       |
                              |      lab-router       |
                              |                       |
                              |    10.10.10.254       |
                              |                       |
                              +-----------+-----------+
                                          |
                 +------------------------+------------------------+
                 |                        |                        |
                 |                        |                        |
          attackerNetA              attackerNetB             crowdSecNet
       192.168.255.0/24            172.31.0.0/24            10.10.10.0/24
                 |                        |                        |
        +--------+--------+       +-------+--------+       +------+------+
        |        |        |       |       |        |       |             |
        |        |        |       |       |        |       |             |
      .101     .102     .103    .111    .112     .113    .10           .20
        |        |        |       |       |        |       |             |
        v        v        v       v       v        v       v             v
     host1a   host2a   host3a  host1b  host2b   host3b  SSH Server    NGINX
                                                        CrowdSec      CrowdSec
```


## Docker Networks

| Network | Subnet | Docker Gateway | Router IP |
|---|---|---|---|
| `crowdSecNet` | `10.10.10.0/24` | `10.10.10.1` | `10.10.10.254` |
| `attackerNetA` | `192.168.255.0/24` | `192.168.255.1` | `192.168.255.254` |
| `attackerNetB` | `172.31.0.0/24` | `172.31.0.1` | `172.31.0.254` |

The Docker bridge gateways and laboratory router addresses are separate.

The laboratory router provides routed connectivity between the three
laboratory networks.

## Main Service Network

### crowdSecNet

```text
Network:  crowdSecNet
Subnet:   10.10.10.0/24
Gateway:  10.10.10.1
Router:   10.10.10.254
```
The main service network contains the SSH server, NGINX server, and one
interface of the laboratory router.

### Services
```text
Container	IP Address	Purpose
lab-router	10.10.10.254	Laboratory router
ssh-server	10.10.10.10	SSH service monitored by CrowdSec
nginx-server	10.10.10.20	NGINX service monitored by CrowdSec
```
The network is defined in compose.yaml as:
```text
crowdSecNet:
  name: crowdSecNet
  driver: bridge

  ipam:
    config:
      - subnet: 10.10.10.0/24
        gateway: 10.10.10.1
```

## Attacker Network A
### attackerNetA
```text
Network:  attackerNetA
Subnet:   192.168.255.0/24
Gateway:  192.168.255.1
Router:   192.168.255.254

This network contains the first three attacker hosts.

Attacker Hosts

Container	IP Address
attacker-host1a	192.168.255.101
attacker-host2a	192.168.255.102
attacker-host3a	192.168.255.103

Router Interface
lab-router    192.168.255.254

The network is defined in compose.yaml as:

attackerNetA:
  name: attackerNetA
  driver: bridge

  ipam:
    config:
      - subnet: 192.168.255.0/24
        gateway: 192.168.255.1

```
## Attacker Network B

### attackerNetB

```text
Network:  attackerNetB
Subnet:   172.31.0.0/24
Gateway:  172.31.0.1
Router:   172.31.0.254

This network contains the second group of attacker hosts.

Attacker Hosts
Container	IP Address
attacker-host1b	172.31.0.111
attacker-host2b	172.31.0.112
attacker-host3b	172.31.0.113

Router Interface
lab-router    172.31.0.254

The network is defined in compose.yaml as:

attackerNetB:
  name: attackerNetB
  driver: bridge

  ipam:
    config:
      - subnet: 172.31.0.0/24
        gateway: 172.31.0.1
```
## Complete Address Table
| Container | Hostname | Network | IP Address |
|---|---|---|---|
| `lab-router` | `lab-router` | `crowdSecNet` | `10.10.10.254` |
| `lab-router` | `lab-router` | `attackerNetA` | `192.168.255.254` |
| `lab-router` | `lab-router` | `attackerNetB` | `172.31.0.254` |
| `ssh-server` | `ssh-server` | `crowdSecNet` | `10.10.10.10` |
| `nginx-server` | `nginx-server` | `crowdSecNet` | `10.10.10.20` |
| `attacker-host1a` | `attacker-host1a` | `attackerNetA` | `192.168.255.101` |
| `attacker-host2a` | `attacker-host2a` | `attackerNetA` | `192.168.255.102` |
| `attacker-host3a` | `attacker-host3a` | `attackerNetA` | `192.168.255.103` |
| `attacker-host1b` | `attacker-host1b` | `attackerNetB` | `172.31.0.111` |
| `attacker-host2b` | `attacker-host2b` | `attackerNetB` | `172.31.0.112` |
| `attacker-host3b` | `attacker-host3b` | `attackerNetB` | `172.31.0.113` |


## Router
The router container is:

Container: lab-router
Hostname:  lab-router

The router has three network interfaces.

### Router Interfaces

```text
crowdSecNet:
    10.10.10.254/24

attackerNetA:
    192.168.255.254/24

attackerNetB:
    172.31.0.254/24

The router connects:

10.10.10.0/24
192.168.255.0/24
172.31.0.0/24

IPv4 forwarding is enabled inside the router.

The Compose configuration uses:

sysctls:
  net.ipv4.ip_forward: "1"
  net.ipv4.conf.all.rp_filter: "0"
  net.ipv4.conf.default.rp_filter: "0"
```
### Current Router Routing Table
The current routing table observed inside lab-router is:
```text
default via 192.168.255.1 dev eth0
10.10.10.0/24 dev eth2 proto kernel scope link src 10.10.10.254
172.31.0.0/24 dev eth1 proto kernel scope link src 172.31.0.254
192.168.255.0/24 dev eth0 proto kernel scope link src 192.168.255.254
```
Verify with:
```text
docker exec lab-router ip route
```
#### Current Router Interfaces
The current router interface configuration is:
```text
eth0
    192.168.255.254/24

eth1
    172.31.0.254/24

eth2
    10.10.10.254/24
```
Verify with:
```text
docker exec lab-router ip addr
```

## SSH Server
The SSH server is:
```text
Container: ssh-server
Hostname:  ssh-server
Network:   crowdSecNet
IP:        10.10.10.10
SSH Port:  22

The Docker host publishes the SSH service on:

localhost:2222

From the Docker host:

ssh -p 2222 labuser@127.0.0.1

From an attacker container:

ssh labuser@10.10.10.10

The SSH server writes authentication events to:

/var/log/auth.log

CrowdSec monitors this log.
```
## NGINX Server

The NGINX server is:

```text
Container: nginx-server
Hostname:  nginx-server
Network:   crowdSecNet
IP:        10.10.10.20
HTTP Port: 80

The Docker host publishes HTTP port 8080:

localhost:8080

From the Docker host:

curl -i http://127.0.0.1:8080/

From an attacker container:

curl -i http://10.10.10.20/

NGINX writes access events to:

/var/log/nginx/access.log

CrowdSec monitors this log.
```

## Attacker Hosts
The environment contains six Kali-based attacker containers.

They are divided into two attacker networks.

Attacker Network A
attacker-host1a
192.168.255.101

attacker-host2a
192.168.255.102

attacker-host3a
192.168.255.103

Attacker Network B
attacker-host1b
172.31.0.111

attacker-host2b
172.31.0.112

attacker-host3b
172.31.0.113

Each attacker uses the common attacker image built from:

./attacker

Enter an attacker container with:

docker exec -it attacker-host1a bash

or:

docker exec -it attacker-host1b bash

## Attack Traffic Paths

The laboratory router provides controlled routed connectivity between the
attacker networks and the services on `crowdSecNet`.

Traffic generated by the attacker containers reaches the target services
through `lab-router`. The target services then generate log events that are
processed by CrowdSec.

### SSH Attack Path

SSH traffic can originate from either attacker network.

#### Network A

```text
attacker-host1a
192.168.255.101
        |
        v
192.168.255.254
lab-router
        |
        v
10.10.10.10
ssh-server
        |
        v
/var/log/auth.log
        |
        v
CrowdSec
        |
        v
SSH parser
        |
        v
SSH brute-force scenario
        |
        v
CrowdSec alert / decision
```

The same path applies to:

- `attacker-host2a` — `192.168.255.102`
- `attacker-host3a` — `192.168.255.103`

#### Network B

```text
attacker-host1b
172.31.0.111
        |
        v
172.31.0.254
lab-router
        |
        v
10.10.10.10
ssh-server
        |
        v
/var/log/auth.log
        |
        v
CrowdSec
        |
        v
SSH parser
        |
        v
SSH brute-force scenario
        |
        v
CrowdSec alert / decision
```

The same path applies to:

- `attacker-host2b` — `172.31.0.112`
- `attacker-host3b` — `172.31.0.113`

### NGINX HTTP Attack Path

HTTP traffic follows the same general routing model.

```text
Attacker
    |
    v
Lab Router
    |
    v
10.10.10.20
nginx-server
    |
    v
/var/log/nginx/access.log
    |
    v
CrowdSec
    |
    v
NGINX / HTTP parsers
    |
    v
HTTP security scenarios
    |
    v
CrowdSec alert / decision
```

For example:

```bash
curl http://10.10.10.20/
```

## Network Verification

Docker may recreate containers and network interfaces when the environment
is rebuilt.

### Verify Docker Networks

List the Docker networks:

```bash
docker network ls
```

Expected laboratory networks:

```text
crowdSecNet
attackerNetA
attackerNetB
```

### Inspect Network Configuration

Inspect the main service network:

```bash
docker network inspect crowdSecNet
```

Inspect attacker Network A:

```bash
docker network inspect attackerNetA
```

Inspect attacker Network B:

```bash
docker network inspect attackerNetB
```

### Find Container IP Addresses

Display container names and IP addresses:

```bash
docker inspect -f '{{.Name}} {{range .NetworkSettings.Networks}}{{.IPAddress}} {{end}}' \
  $(docker ps -q)
```

For the router:

```bash
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' lab-router
```

For the SSH server:

```bash
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' ssh-server
```

For NGINX:

```bash
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' nginx-server
```

For `attacker-host1a`:

```bash
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' attacker-host1a
```

For `attacker-host2a`:

```bash
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' attacker-host2a
```

For `attacker-host3a`:

```bash
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' attacker-host3a
```

For `attacker-host1b`:

```bash
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' attacker-host1b
```

For `attacker-host2b`:

```bash
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' attacker-host2b
```

For `attacker-host3b`:

```bash
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' attacker-host3b
```

## Connectivity Tests

### From Network A

Enter `attacker-host1a`:

```bash
docker exec -it attacker-host1a bash
```

Check the interface configuration:

```bash
ip addr
```

Check the routing table:

```bash
ip route
```

Test connectivity to the Network A router interface:

```bash
ping -c 3 192.168.255.254
```

Test connectivity to NGINX:

```bash
ping -c 3 10.10.10.20
```

Test HTTP connectivity:

```bash
curl -i http://10.10.10.20/
```

Test SSH connectivity:

```bash
nc -vz 10.10.10.10 22
```

### From Network B

Enter `attacker-host1b`:

```bash
docker exec -it attacker-host1b bash
```

Check the interface configuration:

```bash
ip addr
```

Check the routing table:

```bash
ip route
```

Test connectivity to the Network B router interface:

```bash
ping -c 3 172.31.0.254
```

Test connectivity to NGINX:

```bash
ping -c 3 10.10.10.20
```

Test HTTP connectivity:

```bash
curl -i http://10.10.10.20/
```

Test SSH connectivity:

```bash
nc -vz 10.10.10.10 22
```

## Verify Router Forwarding

Check IPv4 forwarding:

```bash
docker exec lab-router \
  cat /proc/sys/net/ipv4/ip_forward
```

Expected output:

```text
1
```

This confirms that IPv4 forwarding is enabled inside `lab-router`.

## Verify Router Connectivity

Display the router interfaces:

```bash
docker exec lab-router ip addr
```

Expected relevant interfaces:

```text
eth0 -> 192.168.255.254/24
eth1 -> 172.31.0.254/24
eth2 -> 10.10.10.254/24
```

Display the router routing table:

```bash
docker exec lab-router ip route
```

Expected directly connected networks:

```text
10.10.10.0/24
172.31.0.0/24
192.168.255.0/24
```

## Docker Compose Network Configuration

The authoritative network configuration is maintained in:

`compose.yaml`

The relevant network definitions are:

```yaml
networks:

  crowdSecNet:
    name: crowdSecNet
    driver: bridge

    ipam:
      config:
        - subnet: 10.10.10.0/24
          gateway: 10.10.10.1

  attackerNetA:
    name: attackerNetA
    driver: bridge

    ipam:
      config:
        - subnet: 192.168.255.0/24
          gateway: 192.168.255.1

  attackerNetB:
    name: attackerNetB
    driver: bridge

    ipam:
      config:
        - subnet: 172.31.0.0/24
          gateway: 172.31.0.1
```

## Important Addressing Notes

The following values are part of the current laboratory topology.

### Main Service Network

```text
crowdSecNet
10.10.10.0/24
```

### Attacker Network A

```text
attackerNetA
192.168.255.0/24
```

### Attacker Network B

```text
attackerNetB
172.31.0.0/24
```

The previous `172.16.0.0/24` network is no longer used by this environment.

Do not use the old Network B addresses:

```text
172.16.0.0/24
172.16.0.254
172.16.0.111
172.16.0.112
172.16.0.113
```

The current Network B addresses are:

```text
172.31.0.254
172.31.0.111
172.31.0.112
172.31.0.113
```

## Network Naming

The current Docker network names are:

```text
crowdSecNet
attackerNetA
attackerNetB
```

The spelling is important.

Do not use the old misspelled names:

```text
attakerNetA
attakerNetB
```

All current Compose configuration and documentation should use:

```text
attackerNetA
attackerNetB
```

## Recreating the Networks

If Docker reports a network overlap or stale network configuration, stop the
Compose environment:

```bash
docker compose down
```

Inspect the existing networks:

```bash
docker network ls
```

If an old laboratory network is no longer needed, remove it explicitly:

```bash
docker network rm <network-name>
```

Before removing a network, verify that it is not being used by another
Docker project.

Then recreate the environment:

```bash
docker compose up -d
```

## Verify the Complete Topology

Check the Compose services:

```bash
docker compose ps
```

Inspect the main service network:

```bash
docker network inspect crowdSecNet
```

Inspect attacker Network A:

```bash
docker network inspect attackerNetA
```

Inspect attacker Network B:

```bash
docker network inspect attackerNetB
```

Display the router interfaces:

```bash
docker exec lab-router ip addr
```

Display the router routing table:

```bash
docker exec lab-router ip route
```

The resulting configuration should correspond to:

```text
                         +----------------------+
                         |      lab-router      |
                         +----------------------+
                            /        |        \
                           /         |         \
                          /          |          \
                         /           |           \
                        v            v            v

             attackerNetA      crowdSecNet      attackerNetB
            192.168.255.0/24   10.10.10.0/24    172.31.0.0/24

                 |                  |                  |
                 |                  |                  |
        +--------+--------+    +----+----+    +-------+-------+
        |        |        |    |         |    |       |       |
        v        v        v    v         v    v       v       v

      .101     .102     .103  .10       .20  .111   .112    .113

      host1a   host2a   host3a SSH     NGINX host1b host2b host3b
```

## Security Warning

This topology is intentionally designed for security testing.

The attacker containers are capable of generating network traffic and
security-testing activity.

Keep the entire environment isolated.

Do not expose the following services or containers to the public Internet:

```text
ssh-server
nginx-server

attacker-host1a
attacker-host2a
attacker-host3a

attacker-host1b
attacker-host2b
attacker-host3b

lab-router
```

Do not connect the laboratory networks directly to production
infrastructure.

Only perform security testing against systems and networks that you own or
have explicit authorization to test.

## Topology Summary

### Networks

```text
crowdSecNet
    10.10.10.0/24
    gateway: 10.10.10.1
    router:  10.10.10.254

attackerNetA
    192.168.255.0/24
    gateway: 192.168.255.1
    router:  192.168.255.254

attackerNetB
    172.31.0.0/24
    gateway: 172.31.0.1
    router:  172.31.0.254
```

### Servers

```text
ssh-server
    10.10.10.10
    SSH: 22

nginx-server
    10.10.10.20
    HTTP: 80
```

### Attackers

```text
attacker-host1a
    192.168.255.101

attacker-host2a
    192.168.255.102

attacker-host3a
    192.168.255.103

attacker-host1b
    172.31.0.111

attacker-host2b
    172.31.0.112

attacker-host3b
    172.31.0.113
```

### Router

```text
lab-router
    192.168.255.254
    172.31.0.254
    10.10.10.254
```

## CrowdSec Testing Flow

The network topology supports controlled CrowdSec testing through the
following paths:

```text
Attacker
    |
    v
Laboratory Router
    |
    v
Target Service
    |
    v
Service Log
    |
    v
CrowdSec Acquisition
    |
    v
CrowdSec Parser
    |
    v
CrowdSec Scenario
    |
    v
CrowdSec Alert
    |
    v
CrowdSec Decision
```

### SSH Testing

```text
Attacker
    |
    v
Laboratory Router
    |
    v
SSH Server
    |
    v
/var/log/auth.log
    |
    v
CrowdSec Acquisition
    |
    v
SSH Parser
    |
    v
SSH Brute-Force Scenario
    |
    v
CrowdSec Alert / Decision
```

The SSH attack path can originate from any of the six attacker containers:

```text
attacker-host1a
    192.168.255.101

attacker-host2a
    192.168.255.102

attacker-host3a
    192.168.255.103

attacker-host1b
    172.31.0.111

attacker-host2b
    172.31.0.112

attacker-host3b
    172.31.0.113
```

### HTTP / NGINX Testing

HTTP traffic follows:

```text
Attacker
    |
    v
Laboratory Router
    |
    v
10.10.10.20
nginx-server
    |
    v
/var/log/nginx/access.log
    |
    v
CrowdSec Acquisition
    |
    v
NGINX / HTTP Parser
    |
    v
HTTP Security Scenario
    |
    v
CrowdSec Alert / Decision
```

For example:

```bash
curl http://10.10.10.20/
```

## Network Verification

Docker may recreate containers and interfaces when the environment is
rebuilt.

### Verify Docker Networks

```bash
docker network ls
```

Expected laboratory networks:

```text
crowdSecNet
attackerNetA
attackerNetB
```

### Inspect Network Configuration

Inspect the main network:

```bash
docker network inspect crowdSecNet
```

Inspect attacker Network A:

```bash
docker network inspect attackerNetA
```

Inspect attacker Network B:

```bash
docker network inspect attackerNetB
```

### Find Container IP Addresses

Display container names and IP addresses:

```bash
docker inspect -f '{{.Name}} {{range .NetworkSettings.Networks}}{{.IPAddress}} {{end}}' \
  $(docker ps -q)
```

For the router:

```bash
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' lab-router
```

For the SSH server:

```bash
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' ssh-server
```

For NGINX:

```bash
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' nginx-server
```

For attacker-host1a:

```bash
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' attacker-host1a
```

For attacker-host2a:

```bash
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' attacker-host2a
```

For attacker-host3a:

```bash
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' attacker-host3a
```

For attacker-host1b:

```bash
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' attacker-host1b
```

For attacker-host2b:

```bash
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' attacker-host2b
```

For attacker-host3b:

```bash
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' attacker-host3b
```

## Connectivity Tests

### From Network A

Enter the attacker container:

```bash
docker exec -it attacker-host1a bash
```

Check the interface:

```bash
ip addr
```

Check routes:

```bash
ip route
```

Test the router:

```bash
ping -c 3 192.168.255.254
```

Test NGINX:

```bash
ping -c 3 10.10.10.20
```

Test HTTP:

```bash
curl -i http://10.10.10.20/
```

Test SSH:

```bash
nc -vz 10.10.10.10 22
```

### From Network B

Enter the attacker container:

```bash
docker exec -it attacker-host1b bash
```

Check the interface:

```bash
ip addr
```

Check routes:

```bash
ip route
```

Test the router:

```bash
ping -c 3 172.31.0.254
```

Test NGINX:

```bash
ping -c 3 10.10.10.20
```

Test HTTP:

```bash
curl -i http://10.10.10.20/
```

Test SSH:

```bash
nc -vz 10.10.10.10 22
```

## Verify Router Forwarding

Check IPv4 forwarding:

```bash
docker exec lab-router \
  cat /proc/sys/net/ipv4/ip_forward
```

Expected:

```text
1
```

The router should report:

```text
net.ipv4.ip_forward = 1
```

## Verify Router Connectivity

Run:

```bash
docker exec lab-router ip addr
```

Expected relevant interfaces:

```text
eth0 -> 192.168.255.254/24
eth1 -> 172.31.0.254/24
eth2 -> 10.10.10.254/24
```

Run:

```bash
docker exec lab-router ip route
```

Expected directly connected networks:

```text
10.10.10.0/24
172.31.0.0/24
192.168.255.0/24
```

## Docker Compose Network Configuration

The authoritative network configuration is maintained in:

```text
compose.yaml
```

The relevant network definitions are:

```yaml
networks:

  crowdSecNet:
    name: crowdSecNet
    driver: bridge

    ipam:
      config:
        - subnet: 10.10.10.0/24
          gateway: 10.10.10.1

  attackerNetA:
    name: attackerNetA
    driver: bridge

    ipam:
      config:
        - subnet: 192.168.255.0/24
          gateway: 192.168.255.1

  attackerNetB:
    name: attackerNetB
    driver: bridge

    ipam:
      config:
        - subnet: 172.31.0.0/24
          gateway: 172.31.0.1
```

## Important Addressing Notes

The following values are part of the current laboratory topology:

```text
crowdSecNet
    10.10.10.0/24

attackerNetA
    192.168.255.0/24

attackerNetB
    172.31.0.0/24
```

The previous `172.16.0.0/24` network is no longer used by this environment.

Do not use:

```text
172.16.0.0/24
172.16.0.254
172.16.0.111
172.16.0.112
172.16.0.113
```

The Network B addresses are now:

```text
172.31.0.254
172.31.0.111
172.31.0.112
172.31.0.113
```

## Network Naming

The current Docker network names are:

```text
crowdSecNet
attackerNetA
attackerNetB
```

The spelling is important.

Do not use the old misspelled names:

```text
attakerNetA
attakerNetB
```

All current Compose configuration and documentation should use:

```text
attackerNetA
attackerNetB
```

## Recreating the Networks

If Docker reports a network overlap or stale network configuration, stop the
Compose environment:

```bash
docker compose down
```

Inspect the existing networks:

```bash
docker network ls
```

If an old laboratory network is no longer needed, remove it explicitly:

```bash
docker network rm <network-name>
```

Then recreate the environment:

```bash
docker compose up -d
```

Before removing a network, verify that it is not being used by another
Docker project.

## Verify the Complete Topology

Run:

```bash
docker compose ps
```

Then:

```bash
docker network inspect crowdSecNet
```

```bash
docker network inspect attackerNetA
```

```bash
docker network inspect attackerNetB
```

Finally:

```bash
docker exec lab-router ip addr
```

and:

```bash
docker exec lab-router ip route
```

The resulting configuration should correspond to:

```text
                         +----------------------+
                         |      lab-router      |
                         +----------------------+
                            /        |        \
                           /         |         \
                          /          |          \
                         /           |           \
                        v            v            v

             attackerNetA      crowdSecNet      attackerNetB
            192.168.255.0/24   10.10.10.0/24    172.31.0.0/24

                 |                  |                  |
                 |                  |                  |
        +--------+--------+    +----+----+    +-------+-------+
        |        |        |    |         |    |       |       |
        v        v        v    v         v    v       v       v

      .101     .102     .103  .10       .20  .111   .112    .113

      host1a   host2a   host3a SSH     NGINX host1b host2b host3b
```

## Security Warning

This topology is intentionally designed for security testing.

The attacker containers are capable of generating network traffic and
security-testing activity.

Keep the entire environment isolated.

Do not expose the following to the public Internet:

```text
ssh-server
nginx-server

attacker-host1a
attacker-host2a
attacker-host3a

attacker-host1b
attacker-host2b
attacker-host3b

lab-router
```

Do not connect the laboratory networks directly to production infrastructure.

Only perform security testing against systems and networks that you own or
have explicit authorization to test.

## Disclaimer

This project is provided "as is", without warranties or guarantees of any kind.

The authors and contributors are not responsible for unauthorized use, damage, disruption, data loss, security incidents, or other consequences resulting from the use or misuse of this project.

By using this project, you agree to use it only in environments where you have appropriate authorization.

## License

Unless a separate license file states otherwise, this project is intended to be distributed under the license specified in the repository's `LICENSE` file.

Third-party software, packages, container images, tools, and other
components remain subject to their respective licenses and terms.

Users must comply with all applicable licenses, terms, conditions, rules, laws, regulations, and authorization requirements when using this project or its third-party components.

## Final Topology Reference

The authoritative current topology is:

```text
crowdSecNet
    10.10.10.0/24
    gateway 10.10.10.1

attackerNetA
    192.168.255.0/24
    gateway 192.168.255.1

attackerNetB
    172.31.0.0/24
    gateway 172.31.0.1


lab-router
    10.10.10.254
    192.168.255.254
    172.31.0.254

ssh-server
    10.10.10.10

nginx-server
    10.10.10.20

attacker-host1a
    192.168.255.101

attacker-host2a
    192.168.255.102

attacker-host3a
    192.168.255.103

attacker-host1b
    172.31.0.111

attacker-host2b
    172.31.0.112

attacker-host3b
    172.31.0.113
```
### Authoritative Configuration
The Docker Compose configuration is the authoritative source for the
actual network configuration:
```text
compose.yaml
```
This document should be kept synchronized with compose.yaml.
If the Docker configuration changes, update this topology document
accordingly.

## Final Safety Notice
Before starting the laboratory, verify that:

The environment is isolated.
The laboratory networks are not connected to production networks.
Laboratory credentials are not used anywhere else.
All testing targets are owned by you or covered by explicit authorization.
The intentionally vulnerable services are not exposed to the public
Internet.
Secrets and runtime credentials are not committed to Git.
The environment is shut down when testing is complete.
The purpose of this topology is to provide controlled network connectivity
for CrowdSec security detection testing.

Keep the laboratory isolated.
