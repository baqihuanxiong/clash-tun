#! /bin/sh

set +eu

echo "exit..."
iptables -t mangle -D OUTPUT -j CLASH
iptables -t mangle -D PREROUTING -m set ! --match-set localnetwork dst -j MARK --set-mark $FWMARK
iptables -t mangle -F CLASH
iptables -t mangle -X CLASH

ipset destroy localnetwork

ip route del default dev $TUN_DEVICE table $ROUTE_TABLE
ip rule del fwmark $FWMARK lookup $ROUTE_TABLE
ip tuntap del mode tun $TUN_DEVICE