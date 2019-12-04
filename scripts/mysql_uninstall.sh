#!/bin/bash

sudo apt-get -y purge mysql-server mysql-client mysql-common mysql-server-core-5.5 mysql-client-core-5.5
sudo rm -rf /etc/mysql /var/lib/mysql
sudo apt-get -y autoremove
sudo apt-get -y autoclean
