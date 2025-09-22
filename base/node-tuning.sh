#!/bin/bash
set -euo pipefail


echo 8192 > /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages
# echo 32 > /sys/kernel/mm/hugepages/hugepages-1048576kB/nr_hugepages

# network stack
cat << EOF > /etc/sysctl.d/99-hyperliquid.conf
# Core network settings
net.core.rmem_default = 134217728
net.core.wmem_default = 134217728
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.core.netdev_max_backlog = 30000
net.core.netdev_budget = 600

# TCP settings
net.ipv4.tcp_rmem = 4096 87380 134217728
net.ipv4.tcp_wmem = 4096 65536 134217728
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_notsent_lowat = 16384
net.ipv4.tcp_low_latency = 1
net.ipv4.tcp_no_metrics_save = 1
net.ipv4.tcp_moderate_rcvbuf = 1
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_mtu_probing = 1

# Disable IPv6 (Assumed k8s networking is ipv4 configured)
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1

# Connection optimization
net.netfilter.nf_conntrack_max = 524288
net.netfilter.nf_conntrack_tcp_timeout_established = 1800
net.netfilter.nf_conntrack_tcp_timeout_close = 10
net.netfilter.nf_conntrack_tcp_timeout_close_wait = 10
net.netfilter.nf_conntrack_tcp_timeout_fin_wait = 20

#huge-pages
vm.nr_hugepages_2MB = 8192
vm.nr_hugepages_1GB = 32
vm.hugetlb_shm_group = 1000

EOF

sysctl -p /etc/sysctl.d/99-hyperliquid.conf

# CPU affinity for network interrupts
for irq in $(grep eth0 /proc/interrupts | awk '{print $1}' | sed 's/://'); do
    echo 2 > /proc/irq/$irq/smp_affinity
done

# Disable IRQ balancing
systemctl stop irqbalance
systemctl disable irqbalance

echo "Network optimization complete"