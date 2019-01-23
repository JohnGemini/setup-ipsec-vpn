#!/bin/bash
GATEWAY=$(ip route |grep default|grep "via \S*" -o|cut -f2 -d" ")
VPN_SERVER_IP=$(grep lns /etc/xl2tpd/xl2tpd.conf |grep "\S*$" -o)
ACTION=$1
VPN_NET=$2
if [ "$ACTION" == "up" ]; then
  service strongswan restart
  service xl2tpd restart
  ipsec up vpn
  echo "c vpn" > /var/run/xl2tpd/l2tp-control
  ip route add $VPN_SERVER_IP via $GATEWAY
  until ip route|grep ppp0
  do
    sleep 1
  done
  ip route add $VPN_NET dev ppp0
elif [ "$ACTION" == "down" ]; then
  echo "d vpn" > /var/run/xl2tpd/l2tp-control
  ipsec down vpn
fi
