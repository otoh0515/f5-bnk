#! /bin/bash

## 012-remove-client-conf.sh
echo "## 012-remove-client-conf.sh"

ssh client "sudo rm -f /etc/nginx/sites-enabled/default"
ssh client "sudo apt-get remove nginx -y"
ssh client "sudo apt-get autoremove -y"

ssh client "sudo sed -i '/^172.16.201.100 /d' /etc/hosts" 
ssh client "sudo sed -i '/^172.16.202.100 /d' /etc/hosts"

ssh client "rm ~/.curlrc"
ssh client "sudo rm /root/.curlrc"

ssh client "sudo ip link set ens6.30 down"
ssh client "sudo ip addr delete 10.2.30.101/24 dev ens6.30"
ssh client "sudo ip link delete link ens6 name ens6.30 type vlan id 30"
ssh client "sudo ip route delete 172.16.0.0/12 via 10.1.30.5"
ssh client "sudo ip route delete 10.2.201.0/24 via 10.1.30.5"
ssh client "sudo ip route delete 10.2.202.0/24 via 10.1.30.5"
ssh client "sudo ip route delete 10.1.10.0/24 via 10.1.30.5"
ssh client "sudo ip link set ens6 down"
ssh client "sudo ip addr delete 10.1.30.101/24 dev ens6"
ssh client "sudo hostnamectl set-hostname ubuntu"
