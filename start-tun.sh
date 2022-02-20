#! /bin/sh

trap "sigterm_handler" TERM

sigterm_handler() {
    /stop-tun.sh
    exit 143;
}

config_tun() {
    ip tuntap add user $TUN_USER mode tun $TUN_DEVICE
    ip link set $TUN_DEVICE up
    ip route replace default dev $TUN_DEVICE table $ROUTE_TABLE
    ifconfig $TUN_DEVICE mtu $MTU
}

/stop-tun.sh >> /dev/null 2>&1

set -eu

config_tun
ip rule add fwmark $FWMARK lookup $ROUTE_TABLE

ipset create localnetwork hash:net
ipset add localnetwork 127.0.0.0/8
ipset add localnetwork 10.0.0.0/8
ipset add localnetwork 169.254.0.0/16
ipset add localnetwork 192.168.0.0/16
ipset add localnetwork 224.0.0.0/4
ipset add localnetwork 240.0.0.0/4
ipset add localnetwork 172.16.0.0/12

iptables -t mangle -N CLASH
iptables -t mangle -F CLASH
iptables -t mangle -A CLASH -p tcp --dport 53 -j MARK --set-mark $FWMARK
iptables -t mangle -A CLASH -p udp --dport 53 -j MARK --set-mark $FWMARK
iptables -t mangle -A CLASH -m addrtype --dst-type BROADCAST -j RETURN
iptables -t mangle -A CLASH -m set --match-set localnetwork dst -j RETURN
iptables -t mangle -A CLASH -d 198.18.0.0/16 -j MARK --set-mark $FWMARK
iptables -t mangle -A CLASH -j MARK --set-mark $FWMARK

iptables -t mangle -I OUTPUT -j CLASH
iptables -t mangle -I PREROUTING -m set ! --match-set localnetwork dst -j MARK --set-mark $FWMARK

echo "done"

set +eu

while true
do
    if ! ip route show table $ROUTE_TABLE | grep $TUN_DEVICE >> /dev/null
    then
        config_tun
    fi
    sleep 4s
done