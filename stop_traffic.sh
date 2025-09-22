#!/bin/bash

echo "stopping traffic from client-1 to client-2"
docker exec client2 pkill iperf3 > /dev/null 2>&1 &
docker exec client1 pkill iperf3 > /dev/null 2>&1 &
