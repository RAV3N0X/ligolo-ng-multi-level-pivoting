#!/usr/bin/env bash
# Builds the three-segment Ligolo-ng pivoting lab used in the write-up,
# entirely out of Linux network namespaces and veth pairs. Run as root.
#
# Topology:
#   kali   (10.10.14.9/24)              -- Segment A --
#   pivot1 (10.10.14.5/24, 10.10.10.5/24) -- Segment B --
#   app01  (10.10.10.20/24, 172.16.5.20/24)             <- deepest segment, hosts the target service
set -euo pipefail

echo "[*] Cleaning up any previous run..."
for ns in kali pivot1 app01; do ip netns del "$ns" 2>/dev/null || true; done
for l in veth-k-p0 veth-p1-a0 veth-a1-x; do ip link del "$l" 2>/dev/null || true; done

echo "[*] Creating namespaces..."
ip netns add kali
ip netns add pivot1
ip netns add app01
for ns in kali pivot1 app01; do ip netns exec "$ns" ip link set lo up; done

echo "[*] Wiring Segment A: kali <-> pivot1 (10.10.14.0/24)..."
ip link add veth-k-p0 type veth peer name veth-p0-k
ip link set veth-k-p0 netns kali
ip link set veth-p0-k netns pivot1
ip netns exec kali   ip link set veth-k-p0 name eth0
ip netns exec pivot1 ip link set veth-p0-k name eth0
ip netns exec kali   ip addr add 10.10.14.9/24 dev eth0
ip netns exec pivot1 ip addr add 10.10.14.5/24 dev eth0
ip netns exec kali   ip link set eth0 up
ip netns exec pivot1 ip link set eth0 up

echo "[*] Wiring Segment B: pivot1 <-> app01 (10.10.10.0/24)..."
ip link add veth-p1-a0 type veth peer name veth-a0-p1
ip link set veth-p1-a0 netns pivot1
ip link set veth-a0-p1 netns app01
ip netns exec pivot1 ip link set veth-p1-a0 name eth1
ip netns exec app01  ip link set veth-a0-p1 name eth0
ip netns exec pivot1 ip addr add 10.10.10.5/24 dev eth1
ip netns exec app01  ip addr add 10.10.10.20/24 dev eth0
ip netns exec pivot1 ip link set eth1 up
ip netns exec app01  ip link set eth0 up

echo "[*] Wiring Segment C: app01's deepest interface (172.16.5.0/24)..."
ip link add veth-a1-x type veth peer name veth-x-a1
ip link set veth-a1-x netns app01
ip netns exec app01 ip link set veth-a1-x name eth1
ip netns exec app01 ip addr add 172.16.5.20/24 dev eth1
ip netns exec app01 ip link set eth1 up
ip link set veth-x-a1 up

echo "[*] Enabling forwarding and the pivot1 -> app01 deep-segment route..."
ip netns exec pivot1 sysctl -qw net.ipv4.ip_forward=1
ip netns exec app01  sysctl -qw net.ipv4.ip_forward=1
ip netns exec pivot1 ip route add 172.16.5.0/24 via 10.10.10.20

echo "[*] Starting the two internal-only test services..."
mkdir -p /tmp/ligolo-lab/webroot_app01 /tmp/ligolo-lab/webroot_pivot1
echo "internal service on pivot two" > /tmp/ligolo-lab/webroot_app01/index.html
echo "internal service on pivot one" > /tmp/ligolo-lab/webroot_pivot1/index.html
ip netns exec app01  bash -c "cd /tmp/ligolo-lab/webroot_app01  && nohup python3 -m http.server 8080 --bind 172.16.5.20 > /tmp/app01_http.log 2>&1 &"
ip netns exec pivot1 bash -c "cd /tmp/ligolo-lab/webroot_pivot1 && nohup python3 -m http.server 8081 --bind 10.10.10.5  > /tmp/pivot1_http.log 2>&1 &"

echo "[*] Creating the Kali-side tun interface Ligolo-ng will attach to..."
ip netns exec kali ip tuntap add user root mode tun ligolo
ip netns exec kali ip link set ligolo up
ip netns exec kali ip addr add 240.0.0.1/32 dev ligolo

echo "[+] Lab is up. Verify with:"
echo "    ip netns exec kali   ip -br addr"
echo "    ip netns exec pivot1 ip -br addr"
echo "    ip netns exec app01  ip -br addr"
echo
echo "[+] Download the real Ligolo-ng v0.8.3 binaries, then from here:"
echo "    - proxy on kali:    ip netns exec kali   ./proxy -selfcert -laddr 0.0.0.0:11601"
echo "    - agent on pivot1:  ip netns exec pivot1 ./agent -connect 10.10.14.9:11601 -ignore-cert"
echo "    - agent on app01:   ip netns exec app01  ./agent -connect 10.10.10.5:11601 -ignore-cert"
echo "  ...and follow the commands in the write-up from there."
