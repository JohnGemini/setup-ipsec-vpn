#!/bin/bash
GATEWAY=$(ip route |grep default|grep "via \S*" -o|cut -f2 -d" ")
VPN_SERVER_IP=$(grep lns /etc/xl2tpd/xl2tpd.conf |grep "\S*$" -o)
ACTION=$1
CIDR_CONFIG=$(dirname $0)/cidr.txt
if [ "$ACTION" == "up" ]; then
  if [ ! -f "$CIDR_CONFIG" ]; then
    echo Cannot find cidr.txt
    exit 1
  fi
  service strongswan restart
  service xl2tpd restart
  ipsec up vpn
  echo "c vpn" > /var/run/xl2tpd/l2tp-control
  ip route add $VPN_SERVER_IP via $GATEWAY
  until ip route|grep ppp0
  do
    sleep 1
  done
  for VPN_NET in $(cat $CIDR_CONFIG)
  do
    [[ $VPN_NET =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}(\/([0-9]|[1-2][0-9]|3[0-2]))?$ ]] && ip route add $VPN_NET dev ppp0
  done
elif [ "$ACTION" == "down" ]; then
  echo "d vpn" > /var/run/xl2tpd/l2tp-control
  ipsec down vpn
fi
