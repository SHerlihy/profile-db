#!/bin/bash

sudo dpkg --configure -a
find /var/lib/apt/lists -type f  |xargs rm -f >/dev/null \
sudo apt -y update

sudo apt -y install libssl-dev build-essential
wget http://download.redis.io/redis-stable.tar.gz
tar xvzf redis-stable.tar.gz
cd redis-stable
make distclean
make redis-cli BUILD_TLS=yes
sudo install -m 755 src/redis-cli /usr/local/bin/
