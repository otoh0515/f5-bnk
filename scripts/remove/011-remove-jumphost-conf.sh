#! /bin/bash

## 011-remove-jumphost-conf.sh
echo "## 011-remove-jumphost-conf.sh"

# rm far-secret.yaml
# rm far-secret-ehf.yaml

### Demo-UI is hosted on client; remove Demo-UI traffic to Client.
sudo iptables -t nat -A PREROUTING -d 10.1.1.6 -p tcp --dport 80 -j DNAT --to-destination 10.1.1.4:80
sudo iptables -A FORWARD -p tcp -d 10.1.1.4 --dport 80 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
sudo iptables -A FORWARD -p tcp -s 10.1.1.4 --sport 80 -m state --state ESTABLISHED,RELATED -j ACCEPT
sudo iptables -t nat -A POSTROUTING -p tcp -d 10.1.1.4 --dport 80 -j MASQUERADE
sudo netfilter-persistent save
sudo systemctl disable netfilter-persistent

# BNKboard requires docker
sudo apt-get remove -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
sudo apt-get purge -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
sudo apt-get autoremove -y
sudo rm -f /etc/apt/sources.list.d/docker.list
sudo rm -f /etc/apt/keyrings/docker.gpg
# sudo rmdir /etc/apt/keyrings 2>/dev/null || true
sudo apt-get update
sudo gpasswd -d ubuntu docker 2>/dev/null || true
# sudo groupdel docker 2>/dev/null || true
sudo rm -rf /var/lib/docker /var/lib/containerd

sed -i '/^source ~\/udf-cne\//d' ~/.bash_aliases
rm ~/.curlrc

echo "** removing CNE-tools **"
bash ~/udf-cne/cne-tools/uninstall.sh