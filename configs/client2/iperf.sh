# Start iperf3 server in the background
# with 1 udp stream, 2Mbit/s
# using ipv4 interfaces
iperf3 -c 44.44.44.2 -t 10000 -i 10 -p 5201 -B 11.11.11.2 -P 128 -b 100000 &
