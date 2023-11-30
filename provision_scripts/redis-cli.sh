#!/bin/bash

sudo yum -y install openssl-devel gcc
wget http://download.redis.io/redis-stable.tar.gz
tar xvzf redis-stable.tar.gz
cd redis-stable
make distclean
make redis-cli BUILD_TLS=yes
sudo install -m 755 src/redis-cli /usr/local/bin/

# src/redis-cli -u rediss://profile-service-rfg:profile-service-pass@clustercfg.terraform-20231130181616361700000003.j38z2q.memorydb.eu-west-2.amazonaws.com:6379/0
