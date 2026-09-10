CrowdSec Security Testing Environment

❗ WARNING — INTENTIONALLY VULNERABLE SECURITY TESTING ENVIRONMENT

This project is an intentionally vulnerable security testing environment designed to demonstrate and validate CrowdSec detection capabilities against SSH brute-force activity and HTTP/NGINX attacks.

The environment contains intentionally weak credentials and dedicated attacker containers.

DO NOT expose the SSH server, NGINX server, attacker containers, or any of the laboratory networks to the public Internet or an untrusted network.

Run this project only in an isolated and controlled environment.

The credentials included in this project are for testing purposes only and must never be reused on real systems.

Overview

This project provides a Docker-based security testing environment for experimenting with CrowdSec in a controlled and isolated network topology.

The environment contains:

Multiple attacker containers used to generate controlled security-testing traffic.
An SSH server running CrowdSec and monitoring SSH authentication activity.
An NGINX server running CrowdSec and monitoring HTTP access logs.
A router container providing Layer-3 connectivity between the test networks.
Dedicated Docker networks representing separate network segments.

The primary objective is to provide a reproducible environment where users can:

Generate controlled suspicious activity.
Observe application and authentication logs.
Observe CrowdSec parsers processing events.
Observe CrowdSec scenarios detecting suspicious behavior.
Inspect CrowdSec alerts.
Inspect CrowdSec decisions.
Understand how CrowdSec operates inside containerized environments.
Architecture

The environment is divided into three Docker network segments.

                         CrowdSec Security Testing Environment
                         ====================================

                       ATTACKER NETWORK
                         172.16.0.0/24
                              |
                              |
          +-------------------+-------------------+
          |                   |                   |
          |                   |                   |
+---------+---------+ +-------+---------+ +-------+---------+
| attacker-host1a   | | attacker-host1b | | attacker-host2a |
| 172.16.0.101      | | 172.16.0.102    | | 172.16.0.103    |
+-------------------+ +-----------------+ +-----------------+
          |
          |
+---------+-------------------------------------------------+
|                     lab-router                            |
|                                                           |
| 172.16.0.254    192.168.255.254    10.10.10.254          |
+---------+-------------------------------------------------+
          |                    |                    |
          |                    |                    |
          |              ROUTED NETWORK            |
          |              192.168.255.0/24          |
          |                    |                    |
          |                    |                    |
          |             192.168.255.x               |
          |                    |                    |
          +--------------------+--------------------+
                               |
                               |
                       MAIN SERVICE NETWORK
                          10.10.10.0/24
                               |
                +--------------+--------------+
                |                             |
                |                             |
        +-------+--------+             +------+--------+
        |   ssh-server   |             |  nginx-server |
        |  10.10.10.10   |             |  10.10.10.20  |
        |                |             |               |
        | CrowdSec       |             | CrowdSec      |
        | SSH monitoring |             | NGINX monitor |
        +----------------+             +---------------+


Important: The addresses above correspond to the intended topology. If the Compose configuration changes, use docker network inspect to verify the addresses actually assigned to the containers.

Network Topology
Network	Subnet	Purpose
Attacker network	172.16.0.0/24	Attacker containers
Main service network	10.10.10.0/24	SSH and NGINX services
Routed/test network	192.168.255.0/24	Router-to-attacker/test connectivity
Router Addresses

The router provides connectivity between the networks:

Interface / Network	Router Address
Attacker network	172.16.0.254
Routed/test network	192.168.255.254
Main service network	10.10.10.254
Service Addresses
Container	Address	Service
ssh-server	10.10.10.10	SSH + CrowdSec
nginx-server	10.10.10.20	NGINX + CrowdSec
lab-router	10.10.10.254	Router
lab-router	172.16.0.254	Router
lab-router	192.168.255.254	Router
Attacker Addresses

The attacker containers use the 172.16.0.0/24 network.

The current environment contains:

Container	Address
attacker-host1a	172.16.0.101
attacker-host1b	172.16.0.102
attacker-host2a	172.16.0.103
attacker-host2b	172.16.0.104
attacker-host3a	172.16.0.105
attacker-host3b	172.16.0.106

Verify the actual addresses with:

docker network inspect <attacker-network-name>


You can also inspect the container interfaces directly:

docker exec attacker-host1a ip addr


and routes:

docker exec attacker-host1a ip route

Project Structure
docker-environment-to-test-crowdsec/
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
├── .gitignore
├── NETWORK-TOPOLOGY.md
└── README.md

Prerequisites

Install the following software before deploying the environment:

Docker
Docker Compose v2

Verify Docker:

docker --version


Verify Docker Compose:

docker compose version


The environment is designed to run inside Docker and does not require CrowdSec to be installed directly on the host.

Clone the Repository

Clone the repository:

git clone https://github.com/<YOUR_USERNAME>/docker-environment-to-test-crowdsec.git


Enter the project directory:

cd docker-environment-to-test-crowdsec

Build the Environment

Build all images:

docker compose build


Start the environment:

docker compose up -d


Check the containers:

docker compose ps


You should see the following services:

attacker-host1a
attacker-host1b
attacker-host2a
attacker-host2b
attacker-host3a
attacker-host3b
lab-router
nginx-server
ssh-server

Verify Container Logs

Check the SSH server:

docker logs ssh-server


Check the NGINX server:

docker logs nginx-server


Check the router:

docker logs lab-router


Check an attacker:

docker logs attacker-host1a

Verify the NGINX Server

The NGINX service is published on the Docker host on port 8080.

Run:

curl -i http://localhost:8080/


A successful response should resemble:

HTTP/1.1 200 OK
Server: nginx/1.24.0 (Ubuntu)
Content-Type: text/html


The test page should contain:

<html>
<body>
<h1>CrowdSec Lab NGINX</h1>
<p>NGINX is running.</p>
</body>
</html>


Verify CrowdSec

CrowdSec runs independently inside the ssh-server and nginx-server containers.

Check the CrowdSec version on the SSH server:

docker exec ssh-server cscli version


Check the CrowdSec version on the NGINX server:

docker exec nginx-server cscli version

Verify CrowdSec Machines

On the SSH server:

docker exec ssh-server cscli machines list


On the NGINX server:

docker exec nginx-server cscli machines list


The local CrowdSec machine should be registered with the Local API.

For example:

Name                 IP Address    Status
ssh-server-local     127.0.0.1     ✔️


The exact output may vary depending on the CrowdSec version and initialization state.

Verify CrowdSec Collections

On the SSH server:

docker exec ssh-server cscli collections list


On the NGINX server:

docker exec nginx-server cscli collections list


The SSH server should have the collections required for SSH monitoring.

The NGINX server should have collections such as:

crowdsecurity/nginx
crowdsecurity/http-cve
crowdsecurity/base-http-scenarios
crowdsecurity/linux


The exact collection versions and installed collections may change as the CrowdSec Hub evolves.

SSH Brute-Force Detection Test

The primary demonstration is a controlled SSH brute-force simulation.

The attacker containers are intentionally included to generate test traffic.

1. Enter an Attacker Container

For example:

docker exec -it attacker-host1a bash


If bash is unavailable:

docker exec -it attacker-host1a sh


You should now be inside the attacker container.

Verify its address:

ip addr


Expected address:

172.16.0.101


Verify the routing table:

ip route


The attacker network should have a route toward the main service network through the router.

2. Test Connectivity to the SSH Server

From attacker-host1a:

ping -c 3 10.10.10.10


Test TCP port 22:

nc -vz 10.10.10.10 22


A successful TCP test indicates that the attacker can reach the SSH service.

If ICMP is unavailable or blocked, a failed ping does not necessarily mean that SSH connectivity is unavailable. Use nc or ssh to test TCP connectivity.

3. Connect to the SSH Server

From the attacker container:

ssh labuser@10.10.10.10


The intentionally weak test password is:

labpassword


These credentials exist exclusively for this security testing environment.

They must never be reused on real systems.

4. Generate Failed Authentication Attempts

Exit the successful SSH session if necessary.

Then connect again:

ssh labuser@10.10.10.10


When prompted for the password, enter an incorrect password.

Repeat the failed authentication attempts in a controlled manner.

For example, perform several failed login attempts from:

attacker-host1a


You can repeat the same test from the other attacker containers:

attacker-host1b
attacker-host2a
attacker-host2b
attacker-host3a
attacker-host3b


This allows you to observe traffic from multiple source addresses.

Only perform these tests against this environment or systems for which you have explicit authorization.

Monitor SSH Authentication Logs

Open another terminal on the host.

Follow the SSH authentication log:

docker exec ssh-server tail -f /var/log/auth.log


You should see authentication failures similar to:

Failed password for labuser from 172.16.0.101


The exact log format depends on the SSH and system configuration.

You can also inspect recent events:

docker exec ssh-server tail -n 50 /var/log/auth.log

Verify SSH CrowdSec Acquisition

The SSH acquisition configuration is:

/etc/crowdsec/acquis.d/


Inspect it with:

docker exec ssh-server sh -c 'cat /etc/crowdsec/acquis.d/*.yaml'


The acquisition is expected to resemble:

filenames:
  - /var/log/auth.log

labels:
  type: syslog


CrowdSec therefore reads the SSH authentication log as a syslog-formatted source.

Monitor CrowdSec Metrics

While generating failed SSH authentication attempts, run:

docker exec ssh-server cscli metrics


Pay particular attention to:

Acquisition Metrics
Parser Metrics
Scenario Metrics
Local API Metrics

For example, parser metrics may contain entries such as:

crowdsecurity/sshd-logs
crowdsecurity/sshd-success-logs
crowdsecurity/syslog-logs


The metrics help determine whether CrowdSec is successfully reading and processing the log data.

Inspect CrowdSec Alerts

List detected alerts:

docker exec ssh-server cscli alerts list


For detailed JSON output:

docker exec ssh-server cscli alerts list -o json


An alert indicates that CrowdSec detected activity matching a configured scenario.

Inspect CrowdSec Decisions

Check active decisions:

docker exec ssh-server cscli decisions list


If the configured scenario reaches its threshold, CrowdSec may create a decision associated with the attacker's source IP address.

For example, the source could be:

172.16.0.101


The exact result depends on the installed scenario configuration and the activity generated during the test.

Important: An alert and a decision are related but are not identical. An alert represents detected suspicious behavior. A decision represents an action CrowdSec has decided should be applied to an offending source.

Understanding Parser Metrics

CrowdSec parser metrics can initially look confusing.

A simplified example:

| Parser                               | Hits | Parsed | Unparsed |
|--------------------------------------|------|--------|----------|
| child-crowdsecurity/sshd-logs        | 75   | 1      | 74       |
| child-crowdsecurity/sshd-success-logs| 4    | -      | 4        |
| child-crowdsecurity/syslog-logs      | 5    | 5      | -        |
| crowdsecurity/dateparse-enrich       | 1    | 1      | -        |
| crowdsecurity/sshd-logs              | 5    | 1      | 4        |
| crowdsecurity/sshd-success-logs      | 4    | -      | 4        |
| crowdsecurity/syslog-logs            | 5    | 5      | -        |


These counters describe how log lines move through CrowdSec's parser pipeline.

Hits — Number of times the parser received or evaluated an event.
Parsed — Number of events successfully parsed by that parser.
Unparsed — Events that did not match that parser.
Child parsers — Parsers that operate after a parent parser has classified or transformed an event.

A high Unparsed value does not automatically mean CrowdSec is broken.

Different parsers are designed to recognize different log formats or event types. A line that does not belong to one parser may be correctly processed by another parser.

The most important question is whether the expected events eventually reach the appropriate scenario.

For SSH testing, inspect the complete metrics output and look for:

crowdsecurity/sshd-logs


and the SSH brute-force scenarios under:

Scenario Metrics

NGINX Monitoring

The NGINX container is configured to monitor:

/var/log/nginx/access.log


The project acquisition configuration is located at:

nginx/acquis.d/nginx.yaml


Inside the container it is installed as:

/etc/crowdsec/acquis.d/nginx.yaml


The configuration resembles:

filenames:
  - /var/log/nginx/access.log

labels:
  type: nginx


This allows CrowdSec to consume NGINX access logs and process them through the installed NGINX and HTTP parsers and scenarios.

Generate HTTP Test Traffic

From an attacker container:

curl http://10.10.10.20/


The NGINX server should respond with the test page.

You can verify the access log from the Docker host:

docker exec nginx-server tail -f /var/log/nginx/access.log


Generate additional controlled HTTP requests as required for your testing.

Only test this environment or systems for which you have explicit authorization.

Inspect NGINX CrowdSec Metrics

Run:

docker exec nginx-server cscli metrics


Check alerts:

docker exec nginx-server cscli alerts list


Check decisions:

docker exec nginx-server cscli decisions list

CrowdSec Configuration

The main CrowdSec configuration is:

/etc/crowdsec/config.yaml


The local API uses credentials generated at runtime.

The credentials file is:

/etc/crowdsec/local_api_credentials.yaml


Runtime credentials must not be committed to Git.

The project .gitignore should prevent generated secrets and runtime files from being added to the repository.

CrowdSec Acquisition
SSH

SSH authentication logs are acquired from:

/var/log/auth.log


The acquisition configuration is:

filenames:
  - /var/log/auth.log

labels:
  type: syslog

NGINX

NGINX access logs are acquired from:

/var/log/nginx/access.log


The acquisition configuration is:

filenames:
  - /var/log/nginx/access.log

labels:
  type: nginx

Troubleshooting
Containers Are Not Running

Check the environment:

docker compose ps


Check all container logs:

docker compose logs --tail 200


Check the SSH server:

docker logs ssh-server --tail 200


Check the NGINX server:

docker logs nginx-server --tail 200


Check the router:

docker logs lab-router --tail 200


Check an attacker:

docker logs attacker-host1a --tail 200

SSH Server Is Not Reachable

From an attacker container:

ip addr


Verify that the attacker has a 172.16.0.x address.

Check its routing table:

ip route


Verify the SSH server:

docker exec ssh-server ip addr


The SSH server should have:

10.10.10.10/24


Test TCP connectivity:

nc -vz 10.10.10.10 22


Check the SSH service:

docker exec ssh-server ss -lntp

Check Router Connectivity

Inspect the router interfaces:

docker exec lab-router ip addr


Inspect the router routes:

docker exec lab-router ip route


The router should provide connectivity between:

172.16.0.0/24
10.10.10.0/24
192.168.255.0/24

Check CrowdSec Configuration

Inside the relevant container:

docker exec ssh-server crowdsec -c /etc/crowdsec/config.yaml -t


For NGINX:

docker exec nginx-server crowdsec -c /etc/crowdsec/config.yaml -t


A successful configuration test should indicate that the configuration is valid.

Check CrowdSec Processes

On the SSH server:

docker exec ssh-server pgrep -a crowdsec


On the NGINX server:

docker exec nginx-server pgrep -a crowdsec

Check CrowdSec Acquisition Files

SSH:

docker exec ssh-server ls -la /etc/crowdsec/acquis.d/


Inspect:

docker exec ssh-server sh -c 'cat /etc/crowdsec/acquis.d/*.yaml'


NGINX:

docker exec nginx-server ls -la /etc/crowdsec/acquis.d/


Inspect:

docker exec nginx-server sh -c 'cat /etc/crowdsec/acquis.d/*.yaml'

Check SSH Logs

List the log file:

docker exec ssh-server ls -lh /var/log/auth.log


View recent events:

docker exec ssh-server tail -n 50 /var/log/auth.log


Follow the log:

docker exec ssh-server tail -f /var/log/auth.log

Check NGINX Logs

List NGINX logs:

docker exec nginx-server ls -lh /var/log/nginx/


View recent access events:

docker exec nginx-server tail -n 50 /var/log/nginx/access.log


Follow the access log:

docker exec nginx-server tail -f /var/log/nginx/access.log

CrowdSec Shows No Decisions

A missing decision does not necessarily mean CrowdSec is malfunctioning.

Check the entire processing pipeline:

Verify that the source log contains the expected events.
Verify CrowdSec acquisition metrics.
Verify parser metrics.
Verify scenario metrics.
Check CrowdSec alerts.
Check active decisions.

For SSH:

docker exec ssh-server tail -n 50 /var/log/auth.log

docker exec ssh-server cscli metrics

docker exec ssh-server cscli alerts list

docker exec ssh-server cscli decisions list


The configured scenario must reach its detection threshold before a decision is expected.

Parser Metrics Show Unparsed Events

An Unparsed count is not automatically an error.

CrowdSec uses multiple parsers, and each parser is responsible for recognizing specific event formats.

For example:

crowdsecurity/syslog-logs
crowdsecurity/sshd-logs
crowdsecurity/sshd-success-logs


A line can be unparsed by one parser while still being processed successfully by another parser.

Focus on whether the expected SSH events ultimately reach the relevant SSH scenarios.

Stop the Environment

Stop the running environment:

docker compose down


This stops and removes the containers and the Compose-created networks.

Rebuild the Environment

To rebuild the images:

docker compose down
docker compose build --no-cache
docker compose up -d


Check the resulting environment:

docker compose ps

Reset the Environment

To recreate the environment and remove Compose-managed volumes:

docker compose down --volumes --remove-orphans
docker compose build --no-cache
docker compose up -d


Warning: Removing volumes can delete CrowdSec state, databases, and other runtime information. Use this when you intentionally want a clean environment.

Security Considerations

This project intentionally contains security weaknesses for educational and security-testing purposes.

The environment should therefore be treated as untrusted infrastructure.

Do not:

Expose the SSH service to the public Internet.
Expose the NGINX service unnecessarily.
Expose attacker containers to external networks.
Reuse the test credentials.
Use the environment against systems without authorization.
Commit CrowdSec credentials or secrets to Git.
Store production credentials in the repository.
Connect the laboratory networks directly to production networks.
Use the intentionally weak credentials outside this environment.

The attacker containers exist specifically to generate controlled test traffic.

Responsible Testing

All security simulations provided by this project are intended only for:

Systems you own.
Systems you are explicitly authorized to test.
This isolated security testing environment.

Do not use the attacker containers to target third-party systems or Internet services.

The purpose of the environment is to help users understand security monitoring and detection concepts without exposing real infrastructure.

What This Environment Demonstrates

This environment can be used to study:

Docker network segmentation.
Routing between isolated Docker networks.
SSH authentication monitoring.
SSH brute-force detection.
NGINX access-log monitoring.
HTTP security monitoring.
CrowdSec acquisitions.
CrowdSec parsers.
CrowdSec scenarios.
CrowdSec alerts.
CrowdSec decisions.
CrowdSec Local API.
Security monitoring in containerized environments.
Reproducibility

The environment retrieves CrowdSec Hub content during initialization.

Because CrowdSec Hub content can change over time, the exact installed scenarios, parsers, collections, and versions may change.

For reproducible experiments, record the Docker versions:

docker --version

docker compose version


Record the CrowdSec version on the SSH server:

docker exec ssh-server cscli version


Record the CrowdSec version on the NGINX server:

docker exec nginx-server cscli version


Record installed collections:

docker exec ssh-server cscli collections list

docker exec nginx-server cscli collections list


Record parser information:

docker exec ssh-server cscli parsers list

docker exec nginx-server cscli parsers list

Network Verification

To inspect Docker networks:

docker network ls


Inspect a specific network:

docker network inspect <network-name>


Inspect the running containers:

docker compose ps


Inspect the address of a specific container:

docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' ssh-server


For the NGINX server:

docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' nginx-server


For an attacker:

docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' attacker-host1a

Example Testing Workflow

A typical SSH CrowdSec test can be performed in this order.

Terminal 1 — Start the Environment
docker compose up -d

Terminal 2 — Monitor SSH Logs
docker exec ssh-server tail -f /var/log/auth.log

Terminal 3 — Monitor CrowdSec
docker exec ssh-server cscli metrics

Terminal 4 — Enter the Attacker
docker exec -it attacker-host1a bash


Then:

ssh labuser@10.10.10.10


Use an incorrect password repeatedly to generate failed authentication events.

After the test, inspect:

docker exec ssh-server cscli alerts list


and:

docker exec ssh-server cscli decisions list

Expected SSH Detection Flow

The intended processing flow is:

Attacker Container
       |
       | SSH authentication attempts
       v
ssh-server :22
       |
       | /var/log/auth.log
       v
CrowdSec Acquisition
       |
       v
Syslog Parser
       |
       v
SSHD Parser
       |
       v
SSH Brute-Force Scenario
       |
       v
CrowdSec Alert
       |
       v
CrowdSec Decision


This flow is the primary purpose of the SSH portion of the environment.

Expected NGINX Monitoring Flow

The intended NGINX flow is:

Attacker Container
       |
       | HTTP requests
       v
nginx-server :80
       |
       | /var/log/nginx/access.log
       v
CrowdSec Acquisition
       |
       v
NGINX Parser
       |
       v
HTTP Scenarios
       |
       v
CrowdSec Alert
       |
       v
CrowdSec Decision


The exact scenario triggered depends on the HTTP activity and the CrowdSec Hub configuration installed in the environment.

Contributing

Contributions are welcome.

When submitting changes:

Keep the environment isolated and safe by default.
Do not commit credentials or secrets.
Document changes to the network topology.
Document new services or containers.
Test changes with Docker Compose before submitting a pull request.
Document relevant CrowdSec configuration changes.
Avoid introducing unnecessary external network exposure.
Keep intentionally vulnerable components clearly documented.
License

Add the license appropriate for your project here.

For example, this project may use the MIT License if that is appropriate for your intended distribution.

Disclaimer

This project is provided for educational, security-testing, and research purposes.

It is intentionally designed to contain vulnerable components and weak credentials.

The authors and contributors are not responsible for damage, disruption, unauthorized access, data loss, or other consequences resulting from misuse of this environment.

Always obtain appropriate authorization before performing security testing.

Keep the environment isolated. Test responsibly. Never reuse the laboratory credentials.