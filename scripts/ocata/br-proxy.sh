if_ex=eth0
MAIN_ADDR=192.168.0.100/24

    ovs-vsctl add-br br-proxy
    ovs-vsctl add-port br-proxy eth0
    ip addr del 192.168.0.100/24 dev eth0
    ip addr add 192.168.0.100/24 dev br-proxy
    ip link set br-proxy up promisc on
    ip route add default via 192.168.0.1 dev br-proxy
    ip link add proxy-br-eth1 type veth peer name eth1-br-proxy
    ip link add proxy-br-ex type veth peer name ex-br-proxy
    ovs-vsctl add-br br-eth1
    ovs-vsctl add-br br-ex
    ovs-vsctl add-port br-eth1 eth1-br-proxy
    ovs-vsctl add-port br-ex ex-br-proxy
    ovs-vsctl add-port br-proxy proxy-br-eth1
    ovs-vsctl add-port br-proxy proxy-br-ex
    ip link set eth1-br-proxy up promisc on
    ip link set ex-br-proxy up promisc on
    ip link set proxy-br-eth1 up promisc on
    ip link set proxy-br-ex up promisc on

