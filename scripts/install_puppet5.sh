#!/bin/bash

# install puppet5 + modules, keeper-puppet
# Ubuntu 20.04.5 LTS

sudo su
apt update
apt install puppet=5.5.10-4ubuntu3 -y
puppet module install puppetlabs-mysql -v 10.4.0
puppet module install puppet-archive -v 6.1.0
puppet module install puppetlabs-apt -v 9.0.0
puppet module install puppetlabs-stdlib -v 6.2.0
puppet module install puppetlabs-inifile -v 4.1.0
puppet module install puppetlabs-vcsrepo -v 5.3.0
puppet module install pltraining-dirtree -v 0.3.0
puppet module install brainsware-resources_deep_merge -v 0.9.1
gem install inifile -v 3.0.0
exit
cd $HOME
git clone https://github.com/MPDL/keeper-puppet.git && cd keeper-puppet
git co keeper_3.1-focal
sudo cp -vr puppet/code/environments /etc/puppet/code



