Network Topology

The CrowdSec Security Testing Environment uses several isolated Docker networks connected through the lab router.

Network Overview
                         CrowdSec Security Testing Environment
                         ====================================

                              Docker Host
                                   |
                                   |
                            Attacker Hosts
                                   |
                                   |
                         192.168.255.0/24
                                   |
                                   |
                         +---------+---------+
                         |       Router      |
                         |   192.168.255.254 |
                         |   10.10.10.254    |
                         |   172.16.0.254    |
                         +----+---------+----+
                              |         |
                10.10.10.0/24|         |172.16.0.0/24
                              |         |
                    +---------+         +---------+
                    |                             |
              +-----+------+               +------+------+
              | SSH Server |               | NGINX Server|
              | 10.10.10.10|              | 10.10.10.20 |
              |            |               |             |
              | CrowdSec   |               | CrowdSec    |
              | SSHD       |               | NGINX       |
              +------------+               +-------------+

Network Segments
Network	Purpose	Router / Gateway
10.10.10.0/24	Main service network	10.10.10.254
172.16.0.0/24	NGINX-side / attacker test network	172.16.0.254
192.168.255.0/24	Attacker / routing network	192.168.255.254

The environment uses isolated Docker networks. The router container provides Layer-3 connectivity between the test networks.

Individual container IP addresses should be verified with Docker because they may change when containers are recreated unless explicitly configured as static addresses in compose.yaml.

Main Service Network
Network: 10.10.10.0/24
Router:  10.10.10.254


The main service network contains the security services monitored by CrowdSec.

Current service addresses:

SSH Server:   10.10.10.10
NGINX Server: 10.10.10.20
Router:       10.10.10.254

SSH Server
Container: ssh-server
IP:        10.10.10.10
Service:   SSH
Port:      22
CrowdSec:  Enabled

NGINX Server
Container: nginx-server
IP:        10.10.10.20
Service:   NGINX
Port:      80
CrowdSec:  Enabled


The NGINX HTTP service is published to the Docker host:

Host:      localhost:8080
Container: nginx-server:80


Test it with:

curl -i http://localhost:8080/

Attacker Network
Network: 192.168.255.0/24
Router:  192.168.255.254


The attacker hosts are connected to the attacker-side network.

The environment currently contains six attacker containers:

attacker-host1a
attacker-host1b
attacker-host2a
attacker-host2b
attacker-host3a
attacker-host3b


Their IP addresses should be discovered dynamically:

docker inspect -f '{{.Name}} {{range .NetworkSettings.Networks}}{{.IPAddress}} {{end}}' \
  attacker-host1a \
  attacker-host1b \
  attacker-host2a \
  attacker-host2b \
  attacker-host3a \
  attacker-host3b


Enter an attacker host with:

docker exec -it attacker-host1a bash


If Bash is not available:

docker exec -it attacker-host1a sh


Check its network configuration:

ip addr


Check its routing table:

ip route

Router

The router container provides connectivity between the isolated networks.

Container:

lab-router


The router participates in the following networks:

10.10.10.0/24
172.16.0.0/24
192.168.255.0/24


The router addresses are:

10.10.10.254
172.16.0.254
192.168.255.254


The router is responsible for forwarding traffic between the test networks.

Inspect the router:

docker exec lab-router ip addr


Display its routes:

docker exec lab-router ip route

Traffic Flow
SSH Brute-Force Test

The SSH security-testing path is:

+-------------------+
| Attacker Host     |
|                   |
| 192.168.255.x     |
+---------+---------+
          |
          | SSH authentication attempts
          |
          v
+-------------------+
|    Lab Router     |
|                   |
| 192.168.255.254   |
| 10.10.10.254      |
+---------+---------+
          |
          | 10.10.10.0/24
          |
          v
+-------------------+
|    SSH Server     |
|                   |
| 10.10.10.10       |
| TCP/22            |
+---------+---------+
          |
          | /var/log/auth.log
          |
          v
+-------------------+
|     CrowdSec      |
|                   |
| SSHD parsers      |
+---------+---------+
          |
          v
+-------------------+
| SSH brute-force   |
| scenarios         |
+---------+---------+
          |
          v
+-------------------+
| CrowdSec Decision |
+-------------------+


The SSH server records authentication events in:

/var/log/auth.log


CrowdSec acquires the log using:

/etc/crowdsec/acquis.d/


The SSH acquisition uses:

filenames:
  - /var/log/auth.log

labels:
  type: syslog

NGINX HTTP Test

The HTTP security-testing path is:

+-------------------+
| Attacker Host     |
|                   |
| 192.168.255.x     |
+---------+---------+
          |
          | HTTP requests
          |
          v
+-------------------+
|    Lab Router     |
+---------+---------+
          |
          | 10.10.10.0/24
          |
          v
+-------------------+
|   NGINX Server    |
|                   |
| 10.10.10.20       |
| TCP/80            |
+---------+---------+
          |
          | /var/log/nginx/access.log
          |
          v
+-------------------+
|     CrowdSec      |
|                   |
| NGINX parsers     |
+---------+---------+
          |
          v
+-------------------+
| HTTP scenarios    |
+---------+---------+
          |
          v
+-------------------+
| CrowdSec Decision |
+-------------------+


The NGINX access log is:

/var/log/nginx/access.log


The CrowdSec acquisition configuration is:

/etc/crowdsec/acquis.d/nginx.yaml


The acquisition configuration is:

filenames:
  - /var/log/nginx/access.log

labels:
  type: nginx

Container Inventory

The environment contains the following primary containers.

Container	Role	Network
lab-router	Network router	All lab networks
ssh-server	SSH + CrowdSec	10.10.10.0/24
nginx-server	NGINX + CrowdSec	10.10.10.0/24
attacker-host1a	Attack/test host	Attacker network
attacker-host1b	Attack/test host	Attacker network
attacker-host2a	Attack/test host	Attacker network
attacker-host2b	Attack/test host	Attacker network
attacker-host3a	Attack/test host	Attacker network
attacker-host3b	Attack/test host	Attacker network
Verify the Actual Topology

Docker may assign different container IP addresses after containers are removed and recreated.

Always verify the current addresses rather than assuming an address.

List running containers:

docker ps


List Docker networks:

docker network ls


Show the Compose configuration:

docker compose config


Inspect a Docker network:

docker network inspect <network-name>


Display all container IP addresses:

docker inspect -f '{{.Name}} {{range .NetworkSettings.Networks}}{{.IPAddress}} {{end}}' \
  $(docker ps -q)

Verify Individual Containers
SSH Server
docker inspect -f \
'{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' \
ssh-server


Or:

docker exec ssh-server ip addr


Display routes:

docker exec ssh-server ip route

NGINX Server
docker inspect -f \
'{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' \
nginx-server


Or:

docker exec nginx-server ip addr


Display routes:

docker exec nginx-server ip route

Lab Router
docker inspect -f \
'{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' \
lab-router


Or:

docker exec lab-router ip addr


Display routes:

docker exec lab-router ip route

Verify Attacker Hosts

For attacker-host1a:

docker inspect -f \
'{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' \
attacker-host1a


For attacker-host1b:

docker inspect -f \
'{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' \
attacker-host1b


For attacker-host2a:

docker inspect -f \
'{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' \
attacker-host2a


For attacker-host2b:

docker inspect -f \
'{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' \
attacker-host2b


For attacker-host3a:

docker inspect -f \
'{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' \
attacker-host3a


For attacker-host3b:

docker inspect -f \
'{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' \
attacker-host3b

Connectivity Testing
From an Attacker Host

Enter an attacker:

docker exec -it attacker-host1a bash


Check the local address:

ip addr


Check the routing table:

ip route


Test the SSH server:

ping -c 3 10.10.10.10


Test SSH:

nc -vz 10.10.10.10 22


Test NGINX:

curl -i http://10.10.10.20/


If ICMP is disabled or filtered, a failed ping does not necessarily mean that TCP connectivity is unavailable. Use nc or curl to test the actual service.

Host-Port Access

The Docker host exposes the NGINX HTTP service on port 8080:

Docker Host
    |
    | TCP/8080
    v
nginx-server
    |
    | TCP/80
    v
NGINX


Test from the Docker host:

curl -i http://localhost:8080/


The SSH service is published on port 2222:

Docker Host
    |
    | TCP/2222
    v
ssh-server
    |
    | TCP/22
    v
SSHD


Test from the Docker host:

ssh -p 2222 labuser@localhost


The published host ports are intended for local testing. Do not expose them to untrusted networks.

CrowdSec Monitoring Flow
SSH
SSH authentication
        |
        v
/var/log/auth.log
        |
        v
CrowdSec acquisition
        |
        v
syslog parser
        |
        v
SSHD scenarios
        |
        v
Alert
        |
        v
Decision


Useful commands:

docker exec ssh-server cscli metrics

docker exec ssh-server cscli alerts list

docker exec ssh-server cscli decisions list

NGINX
HTTP request
        |
        v
NGINX
        |
        v
/var/log/nginx/access.log
        |
        v
CrowdSec acquisition
        |
        v
NGINX parser
        |
        v
HTTP scenarios
        |
        v
Alert
        |
        v
Decision


Useful commands:

docker exec nginx-server cscli metrics

docker exec nginx-server cscli alerts list

docker exec nginx-server cscli decisions list

Important: Container IPs vs. Network Addresses

The following values represent network ranges:

10.10.10.0/24
172.16.0.0/24
192.168.255.0/24


They are not individual container addresses.

The following are individual addresses:

10.10.10.10       SSH server
10.10.10.20       NGINX server
10.10.10.254      Router


The attacker host addresses should be discovered using Docker unless they are explicitly assigned static addresses in compose.yaml.

Do not assume that a container will retain the same dynamically assigned IP after:

docker compose down


followed by:

docker compose up -d


For this reason, use Docker service/container names where Docker DNS is available, and use docker inspect to determine IP addresses when testing routed connectivity.

Recommended Verification Sequence

After starting the environment:

docker compose up -d


Check the containers:

docker compose ps


Check the networks:

docker network ls


Check the router:

docker exec lab-router ip addr


Check the router routes:

docker exec lab-router ip route


Check the SSH server:

docker exec ssh-server ip addr


Check the NGINX server:

docker exec nginx-server ip addr


Check an attacker:

docker exec attacker-host1a ip addr


Check attacker routes:

docker exec attacker-host1a ip route


Test NGINX:

curl -i http://localhost:8080/


Test SSH from the host:

ssh -p 2222 labuser@localhost


Test SSH from an attacker:

docker exec -it attacker-host1a bash


Then:

nc -vz 10.10.10.10 22

Security Boundary

This topology is intentionally designed for security testing.

The attacker hosts are part of the controlled environment and are intended to generate test traffic toward the services being monitored by CrowdSec.

The environment should remain isolated from:

Production networks
Production servers
Corporate networks
Untrusted users
Public Internet-facing interfaces

Do not connect the lab router to a production network.

Do not reuse the test credentials outside this environment.

Do not use the attacker hosts to test systems for which you do not have explicit authorization.

The purpose of the topology is to provide a reproducible and isolated environment for learning how network traffic becomes logs, how CrowdSec parses those logs, and how detection scenarios produce alerts and decisions.