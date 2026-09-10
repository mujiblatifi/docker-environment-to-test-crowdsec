FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# ============================================================
# BASE PACKAGES
# ============================================================

RUN apt-get update && \
    apt-get install -y \
        nginx \
        curl \
        ca-certificates \
        gnupg \
        apt-transport-https \
        iproute2 \
        iputils-ping \
        net-tools \
        procps \
        vim \
        rsyslog \
        gettext-base && \
    rm -rf /var/lib/apt/lists/*

# ============================================================
# CROWDSEC REPOSITORY
# ============================================================

RUN curl -s https://install.crowdsec.net | sh

# ============================================================
# INSTALL CROWDSEC WITHOUT RUNNING PACKAGE POST-INSTALL
# ============================================================

RUN apt-get update && \
    apt-get download crowdsec && \
    dpkg-deb -x crowdsec_*.deb /tmp/crowdsec && \
    mkdir -p /etc/crowdsec && \
    cp -a /tmp/crowdsec/etc/crowdsec/. /etc/crowdsec/ && \
    cp /tmp/crowdsec/usr/bin/crowdsec /usr/local/bin/ && \
    cp /tmp/crowdsec/usr/bin/cscli /usr/local/bin/ && \
    if [ -d /tmp/crowdsec/usr/lib/crowdsec ]; then \
        mkdir -p /usr/lib/crowdsec && \
        cp -a /tmp/crowdsec/usr/lib/crowdsec/. /usr/lib/crowdsec/; \
    fi && \
    rm -rf /tmp/crowdsec crowdsec_*.deb /var/lib/apt/lists/*

# ============================================================
# CROWDSEC DIRECTORIES
# ============================================================

RUN mkdir -p \
    /etc/crowdsec/acquis.d \
    /var/lib/crowdsec/data \
    /run/crowdsec \
    /var/log/nginx \
    /var/spool/rsyslog

# ============================================================
# NGINX CONFIG
# ============================================================

COPY nginx.conf /etc/nginx/nginx.conf

# ============================================================
# CROWDSEC CONFIG
# ============================================================

COPY config.yaml /etc/crowdsec/config.yaml

# ============================================================
# NGINX ACQUISITION
# ============================================================

COPY acquis.d/nginx.yaml /etc/crowdsec/acquis.d/nginx.yaml

# ============================================================
# ENTRYPOINT
# ============================================================

COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

EXPOSE 80

CMD ["/entrypoint.sh"]
