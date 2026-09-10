FROM kalilinux/kali-rolling

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y \
        bash \
        curl \
        wget \
        iproute2 \
        iputils-ping \
        net-tools \
        dnsutils \
        traceroute \
        nmap \
        netcat-openbsd \
        telnet \
        openssh-client \
        procps \
        vim \
        nano \
        tcpdump \
        jq \
        git \
        python3 \
        python3-pip \
        hydra \
        nikto \
        gobuster \
        sqlmap \
        john \
        metasploit-framework && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

CMD ["/entrypoint.sh"]
