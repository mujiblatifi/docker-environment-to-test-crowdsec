FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Base packages
RUN apt-get update && \
    apt-get install -y \
        openssh-server \
        curl \
        ca-certificates \
        gnupg \
        apt-transport-https \
        sudo \
        iproute2 \
        iputils-ping \
        net-tools \
        procps \
        vim \
        rsyslog \
        gettext-base && \
    rm -rf /var/lib/apt/lists/*

# CrowdSec repository
RUN curl -s https://install.crowdsec.net | sh

# Install CrowdSec files without running the Debian
# package post-installation systemd setup.
RUN apt-get update && \
    apt-get download crowdsec && \
    dpkg-deb -x crowdsec_*.deb /tmp/crowdsec && \
    mkdir -p /etc/crowdsec && \
    cp -a /tmp/crowdsec/etc/crowdsec/. /etc/crowdsec/ && \
    cp /tmp/crowdsec/usr/bin/crowdsec /usr/local/bin/ && \
    cp /tmp/crowdsec/usr/bin/cscli /usr/local/bin/ && \
    rm -rf /tmp/crowdsec crowdsec_*.deb /var/lib/apt/lists/*

# CrowdSec directories
RUN mkdir -p \
    /etc/crowdsec/acquis.d \
    /var/lib/crowdsec/data \
    /run/crowdsec \
    /run/sshd \
    /var/log \
    /var/spool/rsyslog

# IMPORTANT:
# Replace the package-provided CrowdSec configuration
# with our container-specific configuration.
COPY config.yaml /etc/crowdsec/config.yaml

# SSH configuration
COPY sshd_config /etc/ssh/sshd_config

# Entrypoint
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

EXPOSE 22

CMD ["/entrypoint.sh"]
