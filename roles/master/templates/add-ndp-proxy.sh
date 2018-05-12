#!/bin/bash
echo "1" > '/proc/sys/net/ipv6/conf/{{ipv6_interface}}/proxy_ndp'

for i in `seq 1 100`;
do
  ip neigh add proxy {{ipv6_subnet}}$i dev {{ipv6_interface}}
done

ip addr add {{ipv6ipv6_bridge_address}}/112 dev lxcbr0
