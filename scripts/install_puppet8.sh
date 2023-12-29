#!/bin/bash

# install puppet8 + modules, keeper-puppet
# Ubuntu 20.04.6 LTS

CONF_DIR=/etc/puppetlabs

# sudo apt update
sudo apt install -y puppet-agent=8.3.1-1focal
sudo puppet module install puppetlabs-mysql -v 14.0.0
sudo puppet module install puppetlabs-concat -v 7.3.0
sudo puppet module install puppetlabs-translate -v 2.2.0
sudo puppet module install puppet-archive -v 6.1.0
sudo puppet module install puppetlabs-apt -v 9.0.2
sudo puppet module install puppetlabs-stdlib -v 6.6.0
sudo puppet module install puppetlabs-inifile -v 6.1.0
sudo puppet module install puppetlabs-vcsrepo -v 5.3.0
sudo puppet module install pltraining-dirtree -v 0.3.0
sudo puppet module install brainsware-resources_deep_merge -v 0.9.1
sudo gem install inifile -v 3.0.0

# cd $HOME
# git clone https://github.com/MPDL/keeper-puppet.git && cd keeper-puppet
# git checkout keeper_5.0-focal
# sudo cp -vr puppet/code/environments /etc/puppet/code

: <<'END'
pushd ${CONF_DIR}/code/environments/production
sudo mv -v ~/keeper-puppet.ini data/
sudo mv -v ~/seafile-license.txt data/keeper_files/
sudo mv -v ~/mykey.peer data/keeper_files/
sudo mv -v ~/seafile-pro-server_9.0.16_x86-64_Ubuntu.tar.gz modules/keeper/files/
sudo mv -v ~/init.pp modules/keeper/manifests/
popd
END
