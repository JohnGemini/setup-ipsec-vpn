#!/bin/bash
apt-get update
apt-get -y install strongswan xl2tpd
echo -n "Please input the IP of the VPN server: "
read VPN_SERVER_IP
echo -n "Please input the username: "
read VPN_USER
echo -n "Please input the password: "
read VPN_PASSWORD
echo -n "Please input the shared key: "
read VPN_SHARED_KEY
cat >/etc/ipsec.conf <<EOF
# ipsec.conf - strongSwan IPsec configuration file

# basic configuration

config setup
  # strictcrlpolicy=yes
  # uniqueids = no

# Add connections here.

# Sample VPN connections

conn %default
  ikelifetime=60m
  keylife=20m
  rekeymargin=3m
  keyingtries=1
  keyexchange=ikev1
  authby=secret
  ike=aes128-sha1-modp1024,3des-sha1-modp1024!
  esp=aes128-sha1-modp1024,3des-sha1-modp1024!

conn vpn
  keyexchange=ikev1
  left=%defaultroute
  auto=add
  authby=secret
  type=transport
  leftprotoport=17/1701
  rightprotoport=17/1701
  right=$VPN_SERVER_IP
EOF

cat > /etc/ipsec.secrets <<EOF
: PSK "$VPN_SHARED_KEY"
EOF

cat > /etc/xl2tpd/xl2tpd.conf <<EOF
[lac vpn]
lns = $VPN_SERVER_IP
ppp debug = yes
pppoptfile = /etc/ppp/options.l2tpd.client
length bit = yes
EOF

cat > /etc/ppp/options.l2tpd.client <<EOF
ipcp-accept-local
ipcp-accept-remote
refuse-eap
require-chap
noccp
noauth
mtu 1280
mru 1280
noipdefault
defaultroute
usepeerdns
connect-delay 5000
name $VPN_USER
password $VPN_PASSWORD
EOF

chmod 600 /etc/ipsec.secrets
chmod 600 /etc/ppp/options.l2tpd.client
mkdir -p /var/run/xl2tpd
touch /var/run/xl2tpd/l2tp-control
