FROM alpine:latest

COPY start-tun.sh /
COPY stop-tun.sh /

RUN apk add --no-cache iptables && \
    chmod +x /start-tun.sh /stop-tun.sh

ENV TUN_USER=root \
    TUN_DEVICE=utun0 \
    MTU=9000 \
    ROUTE_TABLE=0x162
    FWMARK=0x162

ENTRYPOINT ["/start-tun.sh"]