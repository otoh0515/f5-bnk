#! /bin/bash

## 012-deploy-client-conf.sh
echo "## 012-deploy-client-conf.sh"

ssh client "sudo hostnamectl set-hostname client1"

ssh client "sudo tee /etc/netplan/70-netplan-set.yaml >/dev/null" <<'EOF'
network:
  version: 2
  renderer: networkd

  ethernets:
    ens6:
      dhcp4: false
      dhcp6: false
      accept-ra: false
      addresses:
        - 10.1.30.101/24
      routes:
        - to: 10.1.10.0/24
          via: 10.1.30.5
        - to: 10.2.201.0/24
          via: 10.1.30.5
        - to: 10.2.202.0/24
          via: 10.1.30.5
        - to: 172.16.0.0/12
          via: 10.1.30.5

  vlans:
    ens6.30:
      id: 30
      link: ens6
      dhcp4: false
      dhcp6: false
      accept-ra: false
      addresses:
        - 10.2.30.101/24
      routes:
        - to: 172.16.201.221/32
          via: 10.2.30.5
        - to: 172.16.201.222/32
          via: 10.2.30.5
        - to: 172.16.201.223/32
          via: 10.2.30.5
        - to: 172.16.201.224/32
          via: 10.2.30.5
EOF

# Disable IPv6 using sysctl.d drop-in
ssh client "echo 'net.ipv6.conf.all.disable_ipv6=1' | sudo tee /etc/sysctl.d/99-disable-ipv6.conf >/dev/null"
ssh client "echo 'net.ipv6.conf.default.disable_ipv6=1' | sudo tee -a /etc/sysctl.d/99-disable-ipv6.conf >/dev/null"
ssh client "sudo sysctl --system"

ssh client 'sudo chmod 600 /etc/netplan/70-netplan-set.yaml && sudo netplan apply'

scp ~/udf-cne/bnk-2.2.0-ga/scripts/deploy/client-nginx.conf client:
ssh client "sudo apt-get update"
ssh client "sudo apt-get install nginx -y"
ssh client "sudo rm -f /etc/nginx/sites-enabled/default"
ssh client "sudo mv client-nginx.conf /etc/nginx/sites-enabled/default"
ssh client "sudo systemctl reload nginx"

ssh client "echo '172.16.201.100 red.demo.net red2.demo.net' | sudo tee -a /etc/hosts >> /dev/null"
ssh client "echo '172.16.202.100 blue.demo.net blue2.demo.net' | sudo tee -a /etc/hosts >> /dev/null"
ssh client "echo '172.16.202.101 blue.secure-demo.net red.secure-demo.net' | sudo tee -a /etc/hosts >> /dev/null"

#ssh client "echo 'alias curl=\"curl -Lsk -m 1\"' >> ~/.bash_aliases"

ssh client <<'EOF'
cat <<EOL > ~/.curlrc
# custom CURL options
--location
--silent 
--insecure
--max-time 1
EOL
EOF

ssh client sudo cp /home/ubuntu/.curlrc /root #workaround if user connects as root
