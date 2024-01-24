#!/bin/bash

# see https://manual.seafile.com/build_seafile/server/

# nodejs 16
# curl -sL https://deb.nodesource.com/setup_10.x | sudo -E bash -
mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_16.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list
apt update && apt install -y nodejs

apt install -y git tig vim-nox tmux

# helix
sudo snap install helix --classic
sudo snap install bash-language-server --classic

# puppet8
PUPPET_DEB=puppet8-release-focal.deb
wget https://apt.puppetlabs.com/$PUPPET_DEB
sudo dpkg -i --force-all $PUPPET_DEB
rm -rf $PUPPET_DEB
apt update && apt -y install puppet-agent

echo "PATH=\$PATH:/opt/puppetlabs/bin
export LANGUAGE=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export TERM=xterm-256color" >> /root/.bashrc

# rm -rf /etc/puppet/auth.conf
# rm -rf /etc/puppet/hiera.yaml
# rm -rf /etc/puppet/puppet.conf
# apt -y install puppet
# echo 'Defaults        secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin:/opt/puppetlabs/bin:/opt/puppetlabs/puppet/bin"' >/etc/sudoers.d/puppet

# gem install inifile
# puppet module install puppetlabs-mysql
# puppet module install puppet-archive
# puppet module install puppet-nodejs
# puppet module install puppetlabs-apt
# puppet module install puppetlabs-stdlib
# puppet module install puppetlabs-inifile
# puppet module install puppetlabs-vcsrepo
# puppet module install pltraining-dirtree
# puppet module install puppet-alternatives
# puppet module install brainsware-resources_deep_merge

# puppet apply /etc/puppet/code/environments/production/manifests/site.pp --environment=production -vd
