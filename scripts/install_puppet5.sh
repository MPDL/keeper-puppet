#!/bin/bash

# install puppet5 + modules, keeper-puppet
# Ubuntu 20.04.5 LTS

MOD_DIR=/etc/puppet/code/environments/production/modules

sudo apt update
sudo apt install puppet=5.5.10-4ubuntu3 -y
sudo puppet module install puppetlabs-mysql -v 10.4.0 -i $MOD_DIR
sudo puppet module install puppetlabs-concat -v 7.3.0 -i $MOD_DIR
sudo puppet module install puppetlabs-translate -v 2.2.0 -i $MOD_DIR
sudo puppet module install puppet-archive -v 6.1.0 -i $MOD_DIR
sudo puppet module install puppetlabs-apt -v 9.0.0 -i $MOD_DIR
sudo puppet module install puppetlabs-stdlib -v 6.6.0 -i $MOD_DIR
sudo puppet module install puppetlabs-inifile -v 4.1.0 -i $MOD_DIR
sudo puppet module install puppetlabs-vcsrepo -v 5.3.0 -i $MOD_DIR
sudo puppet module install pltraining-dirtree -v 0.3.0 -i $MOD_DIR
sudo puppet module install brainsware-resources_deep_merge -v 0.9.1 -i $MOD_DIR
sudo gem install inifile -v 3.0.0

cd $HOME
git clone https://github.com/MPDL/keeper-puppet.git && cd keeper-puppet
git checkout keeper_3.1-focal
sudo cp -vr puppet/code/environments /etc/puppet/code

: <<'END'
pushd /etc/puppet/code/environments/production
sudo mv -v ~/keeper-puppet.ini data/
sudo mv -v ~/seafile-license.txt data/keeper_files/
sudo mv -v ~/mykey.peer data/keeper_files/
sudo mv -v ~/seafile-pro-server_8.0.17_x86-64_Ubuntu.tar.gz modules/keeper/files/
sudo mv -v ~/init.pp modules/keeper/manifests/
popd
END
