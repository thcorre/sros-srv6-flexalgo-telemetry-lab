# Add IPv4
ip address add 172.17.11.2/30 dev eth1
ip route add 172.17.44.0/30 via 172.17.11.1

# Add IPv6
ip -6 address add 2002::172:17:11:2/127 dev eth1
ip -6 route add 2002::172:17:44:0/127 via 2002::172:17:11:1
