#! /bin/bash

## 011-deploy-jumphost-conf.sh
echo "## 011-deploy-jumphost-conf.sh"


# change from public repo to devrepo
#sed -i "s|repo.f5.com|devrepo.f5.com|g" scripts/deploy/*
#sed -i "s|repo.f5.com|devrepo.f5.com|g" scripts/remove/*

#sed -i "s|cne_pull_64.json|dev_pull_64.json|g" scripts/deploy/*
#sed -i "s|cne_pull_64.json|dev_pull_64.json|g" scripts/remove/*

echo "** installing CNE-tools **"
bash ~/udf-cne/cne-tools/install.sh
# to install cne-tools outside of UDF, use:
# source <(curl -fsSL https://gitlab.com/etlawby/udf-cne/-/raw/main/cne-tools/install.sh) # [--help]

echo "** updating Jumphost DNS records"
echo '172.16.201.100 red.demo.net red2.demo.net' | sudo tee -a /etc/hosts >> /dev/null
echo '172.16.202.100 blue.demo.net blue2.demo.net' | sudo tee -a /etc/hosts >> /dev/null
echo '172.16.202.101 blue.secure-demo.net red.secure-demo.net' | sudo tee -a /etc/hosts >> /dev/null
echo '10.2.30.101 external.demo.net' | sudo tee -a /etc/hosts >> /dev/null
sudo systemctl daemon-reload
sudo systemctl restart dnsmasq

### add additional Jumphost aliases

touch ${HOME}/.bash_aliases
if [ -z "$(cat ${HOME}/.bash_aliases | grep "^source ${HOME}/udf-cne/bnk-2.2.0-ga/scripts/deploy/additional-jumphost-aliases")" ]; then
  echo 'source ${HOME}/udf-cne/bnk-2.2.0-ga/scripts/deploy/additional-jumphost-aliases' >> ${HOME}/.bash_aliases
fi

sudo sed -i "s| f5-spk-cwc.f5-utils||g" /etc/hosts
sudo sed -i "s|^\(.* node1 .*\)[ ]*$|\1 f5-spk-cwc.f5-utils|" /etc/hosts

### Demo-UI is hosted on client; forward Demo-UI traffic to Client.
sudo iptables -t nat -A PREROUTING -d 10.1.1.6 -p tcp --dport 80 -j DNAT --to-destination 10.1.1.4:80
sudo iptables -A FORWARD -p tcp -d 10.1.1.4 --dport 80 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
sudo iptables -A FORWARD -p tcp -s 10.1.1.4 --sport 80 -m state --state ESTABLISHED,RELATED -j ACCEPT
sudo iptables -t nat -A POSTROUTING -p tcp -d 10.1.1.4 --dport 80 -j MASQUERADE

### Configuration is stored in public GitLab repo. Certain secrets (JWT, certs etc.) 
### have been removed and are downloaded from a separate private repo. These are accessed by
### the UDF Jumphost public key. If using these scripts outside of UDF, it will be
### necessary to generate these secrets manually.

### Download Secrets from private repo

rm -rf ${HOME}/udf-cne/bnk-2.2.0-ga/secrets
mkdir -p ${HOME}/udf-cne/bnk-2.2.0-ga/secrets
cd ${HOME}/udf-cne/bnk-2.2.0-ga/secrets

export GIT_SSH_COMMAND="ssh -i ${HOME}/.ssh/id_rsa -o IdentitiesOnly=yes"
git init --initial-branch=main

cat << "EOF" > .git/info/sparse-checkout
secure-demo.crt
secure-demo.key
latest.jwt
f5-far-auth-key.tar
f5-far-auth-key.tar.md5
non-ga-prod-pull-key.json
a.jwt
t.jwt
EOF

if [ -z "$(grep "gitlab.com" ${HOME}/.ssh/known_hosts)" ]; then
  ssh-keyscan gitlab.com >> ${HOME}/.ssh/known_hosts
fi

git remote add origin git@gitlab.com:etlawby/secure-repo.git
git config core.sparseCheckout true
git pull origin main

if [ -d ${HOME}/fake-secrets ]; then
  cp -r ${HOME}/fake-secrets/* .
fi

md5sum -c f5-far-auth-key.tar.md5 
tar -xf f5-far-auth-key.tar 
ln -sf "$(pwd)/cne_pull_64.json" "$(pwd)/../"
ln -sf "$(pwd)/non-ga-prod-pull-key.json" "$(pwd)/../"
ln -sf "$(pwd)/secure-demo.crt" "$(pwd)/../"
ln -sf "$(pwd)/secure-demo.key" "$(pwd)/../"
cd ..

# Create secrets for ga and non-ga (EHF) prod deployments
bash scripts/deploy/create-far-secret-repo.sh secrets/cne_pull_64.json repo.f5.com > far-secret.yaml
bash scripts/deploy/create-far-secret-repo.sh secrets/non-ga-prod-pull-key.json repo.f5.com > far-secret-ehf.yaml

#The following line enables licencing when FLO is deployed
#sed -i "s|<LICENSE-JWT>|$(cat secrets/latest.jwt)|" flo-values.yaml 

# force licencing with reactivate
# flo-values.yaml is stored without JWT in public repo. 
# For manual deployments, it is less error-prone to 
# install the JWT after CWC has deployed. Therefore, 
# the following lines remove the JWT

sed -i '/^[[:space:]]*license:.*$/ { N; /^[[:space:]]*license:.*\n[[:space:]]*jwt:.*$/d; }' flo-values.yaml
sed -i "/jwt:/d" flo-values.yaml
# sed -i "s|jwt:.*$|jwt: $(cat secrets/latest.jwt)|" flo-values.yaml

# temp test
# sed -i "s|jwt: <LICENSE-JWT>|jwt: $(cat secrets/latest.jwt)|" flo-values-test.yaml
# mv flo-values.yaml flo-values-original.yaml
# cp flo-values-test.yaml flo-values.yaml

# install docker to support running BNKboard on Jumphost
sudo apt-get update
sudo apt-get install ca-certificates curl gnupg -y
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin -y

# allow ubuntu user to use docker
sudo usermod -aG docker ubuntu


