FROM alpine:3.22

RUN apk add --no-cache \
    bash \
    iproute2 \
    iputils \
    tcpdump \
    traceroute

COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

CMD ["/entrypoint.sh"]
