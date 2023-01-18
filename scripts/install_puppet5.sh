#!/bin/bash

# install puppet5 + modules, keeper-puppet
# Ubuntu 20.04.5 LTS

MOD_DIR=/etc/puppet/code/environments/production/modules

sudo su
apt update
apt install puppet=5.5.10-4ubuntu3 -y
puppet module install puppetlabs-mysql -v 10.4.0 -i $MOD_DIR
puppet module install puppetlabs-concat -v 7.3.0 -i $MOD_DIR
puppet module install puppetlabs-translate -v 2.2.0 -i $MOD_DIR
puppet module install puppet-archive -v 6.1.0 -i $MOD_DIR
puppet module install puppetlabs-apt -v 9.0.0 -i $MOD_DIR
puppet module install puppetlabs-stdlib -v 6.6.0 -i $MOD_DIR
puppet module install puppetlabs-inifile -v 4.1.0 -i $MOD_DIR
puppet module install puppetlabs-vcsrepo -v 5.3.0 -i $MOD_DIR
puppet module install pltraining-dirtree -v 0.3.0 -i $MOD_DIR
puppet module install brainsware-resources_deep_merge -v 0.9.1 -i $MOD_DIR
gem install inifile -v 3.0.0
exit
cd $HOME
git clone https://github.com/MPDL/keeper-puppet.git && cd keeper-puppet
git checkout keeper_3.1-focal
sudo cp -vr puppet/code/environments /etc/puppet/code
