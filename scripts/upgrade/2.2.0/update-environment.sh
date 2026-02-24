#! /bin/bash

# source ~/udf-cne/bnk-2.2.0-ga/scripts/upgrade/2.2.0/update-environment.sh

# create ~/udf-cne/bnk-2.2.0-ga/ repo
bash ~/udf-cne/bnk-2.2.0-ga/scripts/upgrade/2.1.0/create-repo-2.1.0.sh
bash ~/udf-cne/bnk-2.2.0-ga/scripts/upgrade/2.2.0/create-repo-2.2.0.sh

# create secrets directory in ~/udf-cne/bnk-2.2.0-ga/ and set path to ~/udf-cne/bnk-2.2.0-ga/
bash ~/udf-cne/bnk-2.2.0-ga/scripts/deploy/011-deploy-jumphost-conf.sh
bash
