# CrowdSec Testing Docker Container Environment

> **WARNING — INTENTIONALLY VULNERABLE SECURITY TESTING ENVIRONMENT**
>
> This project is an intentionally vulnerable educational and research
> environment designed to demonstrate and validate CrowdSec detection
> capabilities against SSH authentication failures and HTTP/NGINX activity.
>
> The environment contains intentionally weak laboratory credentials,
> attacker containers, security-testing tools, and routed Docker networks.
>
> **DO NOT expose the SSH server, NGINX server, attacker containers, or
> laboratory networks to the public Internet or an untrusted network.**
>
> Run this project only in an isolated and controlled environment.
>
> The credentials included in this project are for laboratory use only and
> must never be reused on real systems.

## Overview

This project provides a Docker-based laboratory environment for learning, testing, and researching CrowdSec security detection and response capabilities. The environment provides controlled SSH and HTTP/NGINX traffic, isolated Docker networks, and intentionally vulnerable services to demonstrate how CrowdSec acquires logs, parses events, detects suspicious activity, generates alerts, and creates security decisions.

The environment contains:

- Multiple Kali Linux attacker containers.
- An SSH server running CrowdSec and monitoring SSH authentication activity.
- An NGINX server running CrowdSec and monitoring HTTP access logs.
- A router container providing routed connectivity between laboratory networks.
- Dedicated Docker bridge networks representing separate network segments.
- CrowdSec configurations for log acquisition, parsing, scenarios, alerts,
  metrics, and decisions.

The primary objective is to provide a reproducible environment where students, researchers, and security practitioners can generate controlled test traffic and observe how CrowdSec processes logs, detects activity, and produces alerts and decisions.

This environment is intended for educational and research purposes only.

## Architecture

The laboratory uses three isolated Docker network segments:

                         CrowdSec Security Testing Lab
                         =============================

                 attackerNetA                  attackerNetB
              192.168.255.0/24                 172.31.0.0/24
                       │                              │
                       │                              │
             ┌─────────┴─────────┐          ┌─────────┴─────────┐
             │                   │          │                   │
       attacker-host1a     attacker-host2a  attacker-host1b     attacker-host2b
       192.168.255.101     192.168.255.102  172.31.0.111       172.31.0.112
             │                   │          │                   │
       attacker-host3a             │        attacker-host3b     │
       192.168.255.103             │        172.31.0.113         │
             │                     │              │              │
             └──────────────┬──────┴──────────────┴──────────────┘
                            │
                     ┌──────▼──────┐
                     │  lab-router │
                     │             │
                     │ 192.168.255.254
                     │ 172.31.0.254
                     │ 10.10.10.254
                     └──────┬──────┘
                            │
                     crowdSecNet
                     10.10.10.0/24
                            │
                ┌───────────┴───────────┐
                │                       │
         ┌──────▼──────┐         ┌──────▼──────┐
         │ SSH Server  │         │ NGINX Server│
         │ 10.10.10.10 │         │ 10.10.10.20 │
         │             │         │             │
         │  CrowdSec   │         │  CrowdSec   │
         │    SSHD     │         │    NGINX    │
         └─────────────┘         └─────────────┘

## Network Topology

| Network | Subnet | Router Address | Docker Gateway | Purpose |
|---|---|---|---|---|
| crowdSecNet | 10.10.10.0/24 | 10.10.10.254 | 10.10.10.1 | Main service network |
| attackerNetA | 192.168.255.0/24 | 192.168.255.254 | 192.168.255.1 | Attacker network A |
| attackerNetB | 172.31.0.0/24 | 172.31.0.254 | 172.31.0.1 | Attacker network B |

The Docker bridge gateways and laboratory router addresses are separate.

The laboratory router provides routed connectivity between the three
laboratory networks.

## Static Addresses

### Router

```text
lab-router
    crowdSecNet    10.10.10.254
    attackerNetA   192.168.255.254
    attackerNetB   172.31.0.254
```

### Service Hosts

```text
ssh-server       10.10.10.10
nginx-server     10.10.10.20
```

### Attacker Network A

```text
attacker-host1a  192.168.255.101
attacker-host2a  192.168.255.102
attacker-host3a  192.168.255.103
```

### Attacker Network B

```text
attacker-host1b  172.31.0.111
attacker-host2b  172.31.0.112
attacker-host3b  172.31.0.113
```
## Project Structure

```text
crowdsec-security-environment/
│
├── attacker/
│   ├── Dockerfile
│   └── entrypoint.sh
│
├── nginx/
│   ├── acquis.d/
│   │   └── nginx.yaml
│   ├── config.yaml
│   ├── Dockerfile
│   ├── entrypoint.sh
│   └── nginx.conf
│
├── router/
│   ├── Dockerfile
│   └── entrypoint.sh
│
├── ssh/
│   ├── config.yaml
│   ├── Dockerfile
│   ├── entrypoint.sh
│   └── sshd_config
│
├── compose.yaml
├── NETWORK-TOPOLOGY.md
├── README.md
└── LICENSE
```

## Prerequisites

Before deploying the environment, install:

- Docker
- Docker Compose v2

Verify Docker:

```bash
docker --version
```

Verify Docker Compose:

```bash
docker compose version
```

The environment is designed to run using Docker containers and does not require CrowdSec to be installed directly on the host.

## Clone the Repository

Clone the repository:

```bash
git clone https://github.com/mujiblatifi/crowdsec-security-environment.git
```

Enter the project directory:

```bash
cd crowdsec-security-environment
```

## Build the Environment

Build all containers without using the build cache:

```bash
docker compose build --no-cache
```

Start the environment:

```bash
docker compose up -d
```

Check the running containers:

```bash
docker compose ps
```

You should see containers similar to:

```text
lab-router
ssh-server
nginx-server
attacker-host1a
attacker-host2a
attacker-host3a
attacker-host1b
attacker-host2b
attacker-host3b
```

## Verify Docker Networks

List Docker networks:

```bash
docker network ls
```

Inspect the main network:

```bash
docker network inspect crowdSecNet
```

Inspect attacker network A:

```bash
docker network inspect attackerNetA
```

Inspect attacker network B:

```bash
docker network inspect attackerNetB
```

The expected subnets are:

```text
crowdSecNet    10.10.10.0/24
attackerNetA   192.168.255.0/24
attackerNetB   172.31.0.0/24
```

The Docker bridge gateways are:

```text
crowdSecNet    10.10.10.1
attackerNetA   192.168.255.1
attackerNetB   172.31.0.1
```

The laboratory router provides the routed connectivity between these
networks.

## Verify the Router

Check router interfaces:

```bash
docker exec lab-router ip addr
```

Check router routes:

```bash
docker exec lab-router ip route
```

The router should have:

```text
192.168.255.254
172.31.0.254
10.10.10.254
```

The expected connected routes are:

```text
10.10.10.0/24
172.31.0.0/24
192.168.255.0/24
```

Verify IPv4 forwarding:

```bash
docker exec lab-router cat /proc/sys/net/ipv4/ip_forward
```

Expected result:

```text
1
```

## Verify Container Addresses

Check all container addresses:

```bash
docker inspect -f '{{.Name}} {{range .NetworkSettings.Networks}}{{.IPAddress}} {{end}}' $(docker ps -q)
```

Check the individual attacker hosts:

```bash
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' attacker-host1a
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' attacker-host2a
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' attacker-host3a

docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' attacker-host1b
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' attacker-host2b
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' attacker-host3b
```

Expected attacker addresses:

```text
attacker-host1a    192.168.255.101
attacker-host2a    192.168.255.102
attacker-host3a    192.168.255.103

attacker-host1b    172.31.0.111
attacker-host2b    172.31.0.112
attacker-host3b    172.31.0.113
```

## Verify the NGINX Server

The NGINX server uses:

```text
Container: nginx-server
IP:        10.10.10.20
Port:      80
Host port: 8080
```

From the Docker host:

```bash
curl -i http://localhost:8080/
```

A successful response should return HTTP 200.

The test page should identify the CrowdSec laboratory NGINX service.

Check the NGINX container:

```bash
docker exec nginx-server ip addr
```

Check its routing table:

```bash
docker exec nginx-server ip route
```

## Verify NGINX Logs

NGINX access logs are located at:

```text
/var/log/nginx/access.log
```

View the log:

```bash
docker exec nginx-server tail -f /var/log/nginx/access.log
```

Generate a test request:

```bash
curl http://localhost:8080/
```

The request should appear in the NGINX access log.


## Verify CrowdSec

CrowdSec runs independently inside the SSH and NGINX containers.

Check the CrowdSec version on the SSH server:

```bash
docker exec ssh-server cscli version
```

Check the CrowdSec version on NGINX:

```bash
docker exec nginx-server cscli version
```

Check CrowdSec machines on the SSH server:

```bash
docker exec ssh-server cscli machines list
```

Check CrowdSec machines on NGINX:

```bash
docker exec nginx-server cscli machines list
```

## Verify CrowdSec Collections

On the SSH server:

```bash
docker exec ssh-server cscli collections list
```

On the NGINX server:

```bash
docker exec nginx-server cscli collections list
```

The exact list of installed collections may change as the CrowdSec Hub
evolves.

Expected HTTP/NGINX-related collections may include:

```text
crowdsecurity/nginx
crowdsecurity/http-cve
crowdsecurity/base-http-scenarios
crowdsecurity/linux
```

The exact collection names and versions should always be verified with:

```bash
cscli collections list
```

## SSH Attack Simulation

The primary demonstration in this environment is an SSH brute-force
simulation.

The attacker containers are intentionally configured to generate controlled
test traffic.

## Enter an Attacker Container

For example:

```bash
docker exec -it attacker-host1a bash
```

Or:

```bash
docker exec -it attacker-host1b bash
```

Check the hostname:

```bash
hostname
```

Check network interfaces:

```bash
ip addr
```

Check routes:

```bash
ip route
```

## Test Connectivity to the SSH Server

The SSH server has the static address:

```text
10.10.10.10
```

From an attacker:

```bash
ping -c 3 10.10.10.10
```

Test TCP port 22:

```bash
nc -vz 10.10.10.10 22
```

## Connect to the SSH Server

The intentionally weak laboratory credentials are:

```text
Username: labuser
Password: labpassword
```

Connect from an attacker:

```bash
ssh labuser@10.10.10.10
```

These credentials are for this laboratory only.

Never reuse them on real systems.

## Generate Failed SSH Authentication Attempts

From an attacker container:

```bash
ssh labuser@10.10.10.10
```

When prompted for the password, enter an intentionally incorrect password.

Repeat the failed authentication attempts in a controlled manner.

Do not run automated password attacks against systems that you do not own
or have explicit authorization to test.

## Monitor SSH Logs

Open another terminal.

Enter the SSH container:

```bash
docker exec -it ssh-server sh
```

Monitor authentication logs:

```bash
tail -f /var/log/auth.log
```

Failed attempts should produce SSH authentication failure events.

The source address should correspond to the attacker container that generated
the traffic.

## Monitor CrowdSec Metrics

Check CrowdSec metrics:

```bash
docker exec ssh-server cscli metrics
```

Check decisions:

```bash
docker exec ssh-server cscli decisions list
```

Check alerts:

```bash
docker exec ssh-server cscli alerts list
```

For detailed JSON output:

```bash
docker exec ssh-server cscli alerts list -o json
```

Depending on the installed CrowdSec scenario and its thresholds, repeated
authentication failures may result in a CrowdSec alert and decision.

The exact behavior can vary with the installed CrowdSec Hub content and
configuration.

## NGINX HTTP Testing

The NGINX server monitors:

```text
/var/log/nginx/access.log
```

The CrowdSec acquisition configuration is located in the repository at:

```text
nginx/acquis.d/nginx.yaml
```

Inside the container it is installed as:

```text
/etc/crowdsec/acquis.d/nginx.yaml
```

The acquisition configuration uses:

```yaml
filenames:
  - /var/log/nginx/access.log

labels:
  type: nginx
```

## Generate HTTP Test Traffic

From an attacker container:

```bash
curl http://10.10.10.20/
```

You can also test the host-published NGINX port from the Docker host:

```bash
curl http://localhost:8080/
```

Monitor NGINX access logs:

```bash
docker exec nginx-server tail -f /var/log/nginx/access.log
```

Generate additional controlled requests as needed for laboratory testing.

Only perform security testing against this environment or systems for which
you have explicit authorization.
## Inspect NGINX CrowdSec Metrics

Run:

```bash
docker exec nginx-server cscli metrics
```

Check alerts:

```bash
docker exec nginx-server cscli alerts list
```

Check decisions:

```bash
docker exec nginx-server cscli decisions list
```

## Test Routing Between Attacker Networks

The router has:

```text
attackerNetA:
    192.168.255.254

attackerNetB:
    172.31.0.254

crowdSecNet:
    10.10.10.254
```

From an attacker on attackerNetA, test the router:

```bash
docker exec attacker-host1a ping -c 3 192.168.255.254
```

From an attacker on attackerNetB:

```bash
docker exec attacker-host1b ping -c 3 172.31.0.254
```

Test the service network from attackerNetA:

```bash
docker exec attacker-host1a ping -c 3 10.10.10.254
```

Test the service network from attackerNetB:

```bash
docker exec attacker-host1b ping -c 3 10.10.10.254
```

Test the SSH server:

```bash
docker exec attacker-host1a ping -c 3 10.10.10.10
```

Test the NGINX server:

```bash
docker exec attacker-host1a ping -c 3 10.10.10.20
```

If ICMP is not permitted by a particular container configuration, use TCP connectivity tests instead.

## Verify Attacker Routes

For an attacker on attackerNetA:

```bash
docker exec attacker-host1a ip route
```

For an attacker on attackerNetB:

```bash
docker exec attacker-host1b ip route
```

The attacker entrypoint configures routes through the appropriate router interface.

For Network A:

```text
192.168.255.254
```

For Network B:

```text
172.31.0.254
```

The expected routes include:

### Network A

```text
10.10.10.0/24 via 192.168.255.254
172.31.0.0/24 via 192.168.255.254
```

### Network B

```text
10.10.10.0/24 via 172.31.0.254
192.168.255.0/24 via 172.31.0.254
```

## CrowdSec Configuration

The primary CrowdSec configuration is:

```text
/etc/crowdsec/config.yaml
```

The local CrowdSec API uses:

```yaml
api:
  client:
    credentials_path: /etc/crowdsec/local_api_credentials.yaml

  server:
    listen_uri: 127.0.0.1:8080
```

The local API credentials are generated during container initialization.

The credentials file is:

```text
/etc/crowdsec/local_api_credentials.yaml
```

Generated credentials must remain runtime-only.

Do not commit CrowdSec credentials, API keys, passwords, or other secrets
to Git.
## CrowdSec Acquisition

### SSH

SSH authentication logs are acquired from:

```text
/var/log/auth.log
```

The acquisition configuration uses:

```yaml
filenames:
  - /var/log/auth.log

labels:
  type: syslog
```

### NGINX

NGINX access logs are acquired from:

```text
/var/log/nginx/access.log
```

The acquisition configuration uses:

```yaml
filenames:
  - /var/log/nginx/access.log

labels:
  type: nginx
```

## Troubleshooting

### Container Keeps Restarting

Check the SSH server:

```bash
docker logs ssh-server --tail 200
```

Check NGINX:

```bash
docker logs nginx-server --tail 200
```

Check the router:

```bash
docker logs lab-router --tail 200
```

Check all services:

```bash
docker compose ps
```

### Validate CrowdSec Configuration

Inside the appropriate container:

```bash
crowdsec -c /etc/crowdsec/config.yaml -t
```

A successful validation should indicate that the configuration is valid.

### Check CrowdSec Processes

On the SSH server:

```bash
docker exec ssh-server pgrep -a crowdsec
```

On NGINX:

```bash
docker exec nginx-server pgrep -a crowdsec
```

### Check the Local API

Inside the SSH container:

```bash
docker exec ssh-server curl -i http://127.0.0.1:8080/health
```

Inside NGINX:

```bash
docker exec nginx-server curl -i http://127.0.0.1:8080/health
```

### Check NGINX Acquisition

List acquisition files:

```bash
docker exec nginx-server ls -la /etc/crowdsec/acquis.d/
```

Display the NGINX acquisition:

```bash
docker exec nginx-server cat /etc/crowdsec/acquis.d/nginx.yaml
```

### Check NGINX Logs

List the log directory:

```bash
docker exec nginx-server ls -lh /var/log/nginx/
```

Monitor the access log:

```bash
docker exec nginx-server tail -f /var/log/nginx/access.log
```

### Check SSH Logs

List SSH authentication logs:

```bash
docker exec ssh-server ls -lh /var/log/auth.log
```

Monitor the authentication log:

```bash
docker exec ssh-server tail -f /var/log/auth.log
```

## Stop the Environment

Stop all containers:

```bash
docker compose down
```

This removes the containers and Compose-managed networks.

## Rebuild the Environment

To rebuild the images without using cached layers:

```bash
docker compose down
docker compose build --no-cache
docker compose up -d
```

## Reset the Environment

To completely recreate the laboratory:

```bash
docker compose down --volumes --remove-orphans
docker compose build --no-cache
docker compose up -d
```

Warning: Removing volumes may delete CrowdSec state, databases,
alerts, decisions, and other runtime information.

This is useful when a clean CrowdSec test environment is required.
## Network Conflicts

Docker may report an error such as:

```text
invalid pool request: Pool overlaps with other one on this address space
```

This means another Docker network is already using an overlapping subnet.

Inspect existing networks:

```bash
docker network ls
```

Inspect their subnets:

```bash
docker network inspect <network-name>
```

The laboratory currently uses:

```text
10.10.10.0/24
192.168.255.0/24
172.31.0.0/24
```

If an old laboratory network exists with a conflicting configuration, remove
it only if it is no longer required:

```bash
docker network rm <network-name>
```

Then recreate the environment:

```bash
docker compose up -d
```

Do not remove Docker networks belonging to other projects unless you
understand their purpose.

## Existing Docker Network Warning

If Compose reports:

```text
a network with name crowdSecNet exists but was not created for project
```

Inspect the network:

```bash
docker network inspect crowdSecNet
```

The Compose configuration explicitly names the network:

```yaml
name: crowdSecNet
```

If the existing network belongs to the current project and has the expected
subnet, it may be possible to reuse it.

If the network is stale or belongs to another environment, stop the relevant
containers and remove the stale network before recreating the lab.

## Verify the Current Router Topology

The router should have three interfaces:

```text
192.168.255.254/24
172.31.0.254/24
10.10.10.254/24
```

Verify with:

```bash
docker exec lab-router ip addr
```

Expected connected routes:

```text
10.10.10.0/24
172.31.0.0/24
192.168.255.0/24
```

Verify with:

```bash
docker exec lab-router ip route
```

The Docker bridge gateways are separate from the router addresses:

```text
Docker gateway:
crowdSecNet    10.10.10.1
attackerNetA   192.168.255.1
attackerNetB   172.31.0.1

Lab router:
crowdSecNet    10.10.10.254
attackerNetA   192.168.255.254
attackerNetB   172.31.0.254
```

The attacker containers use the router addresses for routes between
laboratory networks.

## Security Considerations

This project intentionally contains security weaknesses for educational
and research purposes.

The environment should therefore be treated as untrusted infrastructure.

Do not:

- Expose the SSH service to the public Internet.
- Expose attacker containers to untrusted external networks.
- Reuse the laboratory credentials.
- Use this environment against systems without authorization.
- Commit CrowdSec credentials or secrets to Git.
- Store production credentials in the repository.
- Connect the intentionally vulnerable laboratory networks directly to
  production networks.
- Treat the attacker containers as trusted hosts.

The attacker containers exist specifically to generate controlled test
traffic.
## Responsible Testing

All security-testing activities performed with this project are intended
only for systems that you own or are explicitly authorized to test.

This environment is designed to help students, security researchers,
administrators, and security practitioners understand:

- SSH authentication and brute-force detection.
- HTTP attack detection.
- NGINX log acquisition.
- CrowdSec parsers.
- CrowdSec scenarios.
- CrowdSec alerts.
- CrowdSec decisions.
- Security monitoring.
- Container networking.
- Routed Docker network topologies.

Use the environment responsibly and keep it isolated from production
infrastructure.

## Educational and Research Disclaimer

This project is provided solely for educational and research purposes.

It is an intentionally isolated laboratory environment designed to
demonstrate CrowdSec, Docker networking, logging, monitoring, and security
concepts.

The project is provided **"AS IS"**, without warranties or guarantees of
any kind, to the maximum extent permitted by applicable law.

The author and contributors are not responsible for damage, data loss,
service disruption, security incidents, unauthorized access, or other
consequences resulting from the use, misuse, modification,
misconfiguration, or deployment of this project.

Users are solely responsible for understanding and safely operating the
environment.

Users must ensure that the laboratory is appropriately isolated and must
not use it against systems or networks without appropriate authorization.

This project may include or install third-party software and packages.
Those components are not owned or relicensed by the author and remain
subject to their respective licenses, terms, and conditions.

By using, copying, modifying, or distributing this project, you acknowledge
that you are responsible for your own use of the project and for complying
with all applicable laws, licenses, terms, rules, and authorization
requirements.

## Third-Party Software and Components

This project uses or may use third-party software, packages, container
images, and other components, including but not limited to:

- Docker
- Docker Compose
- Kali Linux
- Alpine Linux
- NGINX
- CrowdSec
- OpenSSH
- Security and networking utilities distributed through the relevant
  operating-system packages

These components remain subject to their respective licenses, terms,
conditions, and usage requirements.

Nothing in this repository is intended to replace, modify, or supersede
the licenses or terms applicable to third-party software.

Users are responsible for complying with all applicable licenses, terms,
conditions, rules, laws, and authorization requirements relating to
third-party components used by this project.

## Reproducibility

The environment may retrieve packages, CrowdSec Hub content, parsers,
scenarios, and collections during image construction or initialization.

Therefore, the exact behavior of the environment may change over time.

For reproducible experiments, record the versions used.

Docker version:

```bash
docker --version
```

Docker Compose version:

```bash
docker compose version
```

CrowdSec version on the SSH server:

```bash
docker exec ssh-server cscli version
```

CrowdSec version on the NGINX server:

```bash
docker exec nginx-server cscli version
```

Installed collections on the SSH server:

```bash
docker exec ssh-server cscli collections list
```

Installed collections on the NGINX server:

```bash
docker exec nginx-server cscli collections list
```

Laboratory network configuration:

```bash
docker network inspect crowdSecNet
docker network inspect attackerNetA
docker network inspect attackerNetB
```

## AI Assistance

AI-based tools, including GPT, were used as an assistant during the
development and documentation of this project.

AI assistance was used to help with tasks such as drafting, reviewing, explaining, organizing, and improving configuration and documentation.

The project is intended to be reviewed and used as an educational and research laboratory environment.

## License

This project is provided under the license specified in the repository's
`LICENSE` file.

The license applies to the original content of this repository to the extent permitted by applicable law.

Third-party software, packages, container images, tools, and other
components remain subject to their respective licenses and terms.

Users must comply with all applicable licenses, terms, conditions, rules,
laws, regulations, and authorization requirements when using this project
or its third-party components.

## Final Safety Notice

Before starting the laboratory, verify that:

- The environment is isolated.
- The laboratory networks are not connected to production networks.
- The laboratory credentials are not used anywhere else.
- All testing targets are owned by you or covered by explicit authorization.
- The intentionally vulnerable services are not exposed to the public
  Internet.
- Secrets and runtime credentials are not committed to Git.
- The environment is shut down when testing is complete.

The purpose of this project is to provide a controlled environment for
understanding CrowdSec detection, security monitoring, container networking, and authorized security testing.

**Keep the laboratory isolated. Test only systems you are authorized to
test.**

## Laboratory Credentials

The following credentials are intentionally weak and exist solely for laboratory testing:

```text
Username: labuser
Password: labpassword
```

Do not use these credentials on real systems or reuse them anywhere else.

## Scope of the Environment

This project is designed as a self-contained Docker laboratory.

The intended environment consists of:

```text
attackerNetA
192.168.255.0/24

attackerNetB
172.31.0.0/24

crowdSecNet
10.10.10.0/24
```

The laboratory router provides routing between these networks.

The environment is not intended to provide secure production networking, production authentication, production monitoring, or production-grade service deployment.

## End of Document

This laboratory is intended to make CrowdSec behavior and Docker networking easier to understand through controlled experimentation.

Operate it carefully, keep it isolated, and perform security testing only where you have appropriate authorization.
