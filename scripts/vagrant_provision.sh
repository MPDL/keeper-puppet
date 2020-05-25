#!/bin/bash

wget https://apt.puppetlabs.com/puppet5-release-bionic.deb
sudo dpkg -i --force-all puppet5-release-bionic.deb
rm -rf puppet5-release-bionic.deb
curl -sL https://deb.nodesource.com/setup_10.x | sudo -E bash -
apt update
apt -y install git tig vim-nox tmux
echo "PATH=\$PATH:/opt/puppetlabs/bin
export LANGUAGE=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export TERM=xterm-256color" >> /root/.bashrc
rm -rf /etc/puppet/auth.conf
rm -rf /etc/puppet/hiera.yaml
rm -rf /etc/puppet/puppet.conf
apt -y install puppet
echo 'Defaults        secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin:/opt/puppetlabs/bin:/opt/puppetlabs/puppet/bin"' >/etc/sudoers.d/puppet

gem install inifile
puppet module install puppetlabs-mysql
puppet module install puppet-archive
puppet module install puppet-nodejs
puppet module install puppetlabs-apt
puppet module install puppetlabs-stdlib
puppet module install puppetlabs-inifile
puppet module install puppetlabs-vcsrepo
puppet module install pltraining-dirtree
puppet module install puppet-alternatives
puppet module install brainsware-resources_deep_merge

puppet apply /etc/puppet/code/environments/production/manifests/site.pp --environment=production -vd
