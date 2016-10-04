#!/usr/bin/env bash

set -eux

# Sample custom configuration script - add your own commands here
# to add some additional commands for your environment
#
# For example:
# yum install -y curl wget git tmux firefox xvfb
DBHOST=localhost
DBNAME=devdb
DBUSER=devdbuser
DBPASSWD=devdbpwd

echo -e "\n--- Installing dkms and build tools for current kernel ---\n"
apt-get install -y dkms build-essential linux-headers-generic linux-headers-$(uname -r)  >> /var/log/vm_build.log 2>&1

echo -e "\n--- Updating packages list ---\n"
apt-get -qq update

echo -e "\n--- Install base packages ---\n"
apt-get -y install vim curl build-essential python-software-properties git software-properties-common >> /var/log/vm_build.log 2>&1

# MySQL setup for development purposes ONLY
echo -e "\n--- Install MySQL specific packages and settings ---\n"
debconf-set-selections <<< "mysql-server mysql-server/root_password password $DBPASSWD"
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $DBPASSWD"
apt-get -y install mysql-server >> /var/log/vm_build.log 2>&1

echo -e "\n--- Setting up our MySQL user and db ---\n"
mysql -uroot -p$DBPASSWD -e "CREATE DATABASE $DBNAME" >> /var/log/vm_build.log 2>&1
mysql -uroot -p$DBPASSWD -e "grant all privileges on $DBNAME.* to '$DBUSER'@'%' identified by '$DBPASSWD'" > /var/log/vm_build.log 2>&1

echo -e "\n--- Installing aerospike ---\n"
cd /tmp
curl -L http://www.aerospike.com/download/server/3.9.1.1/artifact/ubuntu16| tar xvz
cd /tmp/aerospike-server-community-3.9.1.1-ubuntu16.04
./asinstall >> /var/log/vm_build.log 2>&1

echo -e "\n--- Installing Oracle Java8 ---\n"
add-apt-repository -y ppa:webupd8team/java
apt-get -qq update
debconf-set-selections <<< "oracle-java8-installer shared/accepted-oracle-license-v1-1 select true"
apt-get -y install oracle-java8-installer oracle-java8-unlimited-jce-policy oracle-java8-set-default >> /var/log/vm_build.log 2>&1
echo -e "\n--- Starting mysql and aerospike ---\n"
systemctl enable mysql
systemctl start mysql
systemctl enable aerospike
systemctl start aerospike
