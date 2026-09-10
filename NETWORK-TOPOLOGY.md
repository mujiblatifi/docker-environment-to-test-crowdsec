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
                              |    10.10.10.254        |
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

The main service network contains the SSH server, NGINX server, and one
interface of the laboratory router.

Services
Container	IP Address	Purpose
lab-router	10.10.10.254	Laboratory router
ssh-server	10.10.10.10	SSH service monitored by CrowdSec
nginx-server	10.10.10.20	NGINX service monitored by CrowdSec

The network is defined in compose.yaml as:

crowdSecNet:
  name: crowdSecNet
  driver: bridge

  ipam:
    config:
      - subnet: 10.10.10.0/24
        gateway: 10.10.10.1

Attacker Network A
attackerNetA
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

Complete Address Table
Container	Hostname	Network	IP Address
lab-router	lab-router	crowdSecNet	10.10.10.254
lab-router	lab-router	attackerNetA	192.168.255.254
lab-router	lab-router	attackerNetB	172.31.0.254
ssh-server	ssh-server	crowdSecNet	10.10.10.10
nginx-server	nginx-server	crowdSecNet	10.10.10.20
attacker-host1a	attacker-host1a	attackerNetA	192.168.255.101
attacker-host2a	attacker-host2a	attackerNetA	192.168.255.102
attacker-host3a	attacker-host3a	attackerNetA	192.168.255.103
attacker-host1b	attacker-host1b	attackerNetB	172.31.0.111
attacker-host2b	attacker-host2b	attackerNetB	172.31.0.112
attacker-host3b	attacker-host3b	attackerNetB	172.31.0.113

Router
The router container is:

Container: lab-router
Hostname:  lab-router

The router has three network interfaces.

```
## Router Interfaces

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

Current Router Routing Table
The current routing table observed inside lab-router is:

default via 192.168.255.1 dev eth0
10.10.10.0/24 dev eth2 proto kernel scope link src 10.10.10.254
172.31.0.0/24 dev eth1 proto kernel scope link src 172.31.0.254
192.168.255.0/24 dev eth0 proto kernel scope link src 192.168.255.254

Verify with:

docker exec lab-router ip route

Current Router Interfaces
The current router interface configuration is:

eth0
    192.168.255.254/24

eth1
    172.31.0.254/24

eth2
    10.10.10.254/24

Verify with:

docker exec lab-router ip addr

SSH Server
The SSH server is:

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

Attacker Hosts
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

Attack Traffic Paths
SSH Attack Path
SSH traffic can originate from either attacker network.

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

The same path applies to:

attacker-host2a
attacker-host3a
attacker-host1b
attacker-host2b
attacker-host3b
```
## NGINX HTTP Attack Path

HTTP traffic follows:

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

For example:

curl http://10.10.10.20/

Network Verification
Docker may recreate containers and interfaces when the environment is rebuilt.

Verify the Docker networks with:

docker network ls

Expected laboratory networks:

crowdSecNet
attackerNetA
attackerNetB

Inspect Network Configuration
Inspect the main network:

docker network inspect crowdSecNet

Inspect attacker Network A:

docker network inspect attackerNetA

Inspect attacker Network B:

docker network inspect attackerNetB

Find Container IP Addresses
Display container names and IP addresses:

docker inspect -f '{{.Name}} {{range .NetworkSettings.Networks}}{{.IPAddress}} {{end}}' \
  $(docker ps -q)

For the router:

docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' lab-router

For the SSH server:

docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' ssh-server

For NGINX:

docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' nginx-server

For attacker-host1a:

docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' attacker-host1a

For attacker-host2a:

docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' attacker-host2a

For attacker-host3a:

docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' attacker-host3a

For `attacker-host1b`:

```bash
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' attacker-host1b

For attacker-host2b:

docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' attacker-host2b

For attacker-host3b:

docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' attacker-host3b

Connectivity Tests
From Network A
Enter:

docker exec -it attacker-host1a bash

Check the interface:

ip addr

Check routes:

ip route

Test the router:

ping -c 3 192.168.255.254

Test NGINX:

ping -c 3 10.10.10.20

Test HTTP:

curl -i http://10.10.10.20/

Test SSH:

nc -vz 10.10.10.10 22

From Network B
Enter:

docker exec -it attacker-host1b bash

Check the interface:

ip addr

Check routes:

ip route

Test the router:

ping -c 3 172.31.0.254

Test NGINX:

ping -c 3 10.10.10.20

Test HTTP:

curl -i http://10.10.10.20/

Test SSH:

nc -vz 10.10.10.10 22

Verify Router Forwarding
Check IPv4 forwarding:

docker exec lab-router \
  cat /proc/sys/net/ipv4/ip_forward

Expected:

1

The router should report:

net.ipv4.ip_forward = 1



## Verify Router Connectivity

Run:

```bash
docker exec lab-router ip addr

Expected relevant interfaces:

eth0 -> 192.168.255.254/24
eth1 -> 172.31.0.254/24
eth2 -> 10.10.10.254/24

Run:

docker exec lab-router ip route

Expected directly connected networks:

10.10.10.0/24
172.31.0.0/24
192.168.255.0/24

Docker Compose Network Configuration
The authoritative network configuration is maintained in:

compose.yaml

The relevant network definitions are:

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

Important Addressing Notes
The following values are part of the current laboratory topology:

crowdSecNet
10.10.10.0/24

attackerNetA
192.168.255.0/24

attackerNetB
172.31.0.0/24

The previous 172.16.0.0/24 network is no longer used by this environment.

Do not use:

172.16.0.0/24
172.16.0.254
172.16.0.111
172.16.0.112
172.16.0.113

The Network B addresses are now:

172.31.0.254
172.31.0.111
172.31.0.112
172.31.0.113

Network Naming
The current Docker network names are:

crowdSecNet
attackerNetA
attackerNetB

The spelling is important.

Do not use the old misspelled names:

attakerNetA
attakerNetB

All current Compose configuration and documentation should use:

attackerNetA
attackerNetB

## Recreating the Networks

If Docker reports a network overlap or stale network configuration, stop the
Compose environment:

```bash
docker compose down

Inspect the existing networks:

docker network ls

If an old laboratory network is no longer needed, remove it explicitly:

docker network rm <network-name>

Then recreate the environment:

docker compose up -d

Before removing a network, verify that it is not being used by another
Docker project.

Verify the Complete Topology
Run:

docker compose ps

Then:

docker network inspect crowdSecNet

docker network inspect attackerNetA

docker network inspect attackerNetB

Finally:

docker exec lab-router ip addr

and:

docker exec lab-router ip route

The resulting configuration should correspond to:

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

Security Warning
This topology is intentionally designed for security testing.

The attacker containers are capable of generating network traffic and
security-testing activity.

Keep the entire environment isolated.

Do not expose the following to the public Internet:

ssh-server
nginx-server

attacker-host1a
attacker-host2a
attacker-host3a

attacker-host1b
attacker-host2b
attacker-host3b

lab-router

Do not connect the laboratory networks directly to production infrastructure.

Only perform security testing against systems and networks that you own or
have explicit authorization to test.
```
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

Servers
ssh-server
    10.10.10.10
    SSH: 22

nginx-server
    10.10.10.20
    HTTP: 80

Attackers
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

Router
lab-router

    192.168.255.254
    172.31.0.254
    10.10.10.254

CrowdSec Testing Flow
The network topology supports controlled CrowdSec testing through the
following paths:

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

For SSH testing:

Attacker
    |
    v
SSH Server
    |
    v
/var/log/auth.log
    |
    v
CrowdSec

For HTTP/NGINX testing:

Attacker
    |
    v
NGINX Server
    |
    v
/var/log/nginx/access.log
    |
    v
CrowdSec

The network topology exists to provide controlled and repeatable traffic
sources for these CrowdSec detection tests.

## Security and Responsible Use

This project is an intentionally vulnerable security testing environment.

It is provided for:

- Educational purposes
- Security research
- Defensive-security testing
- Authorized security testing
- CrowdSec detection testing

The environment may contain intentionally weak credentials, vulnerableconfigurations, security-testing tools, and attacker containers.

You are responsible for ensuring that all testing is performed against systems and networks for which you have explicit authorization.

Do not use this environment to attack, scan, probe, disrupt, or gain
unauthorized access to third-party systems or networks.

Do not expose the laboratory networks or attacker containers to the public Internet.

Do not reuse laboratory credentials on real systems.

Do not place production credentials, secrets, tokens, private keys or other sensitive information in this project.

## Isolation Requirements

The laboratory should remain isolated from:

- Production networks
- Corporate networks
- Untrusted networks
- Public Internet
- Systems that are not authorized testing targets

The attacker containers should be treated as untrusted laboratory hosts.

The router should only provide connectivity between the intended laboratory
network segments.

## CrowdSec Testing Scope

The primary security purpose of this topology is to provide controlled
traffic sources and target services for testing CrowdSec.

The environment is intended to demonstrate:

- SSH authentication failure detection
- SSH brute-force detection
- HTTP request detection
- NGINX log acquisition
- CrowdSec parsing
- CrowdSec scenarios
- CrowdSec alerts
- CrowdSec decisions
- CrowdSec monitoring and validation

Docker networking and routing are supporting infrastructure for these tests.
```
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
