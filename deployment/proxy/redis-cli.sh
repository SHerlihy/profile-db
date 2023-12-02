#!/bin/bash

cd /home/ec2-user
sudo yum -y install openssl-devel gcc
wget http://download.redis.io/redis-stable.tar.gz
tar xvzf redis-stable.tar.gz
cd redis-stable
make distclean
make redis-cli BUILD_TLS=yes
sudo install -m 755 src/redis-cli /usr/local/bin/

rm -- $0
# cant rm -- $0 as will be running redis
#src/redis-cli -u rediss://$1:$2@$3:6379/0
