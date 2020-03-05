#!/bin/bash

wget https://apt.puppetlabs.com/puppet5-release-bionic.deb
sudo dpkg -i --force-all puppet5-release-bionic.deb
rm -rf puppet5-release-bionic.deb
sudo apt update
apt-get -y install git zsh vim-nox 
chsh -s $(which zsh)
sh -c "$(wget https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O -)"
sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="agnoster"/g' /root/.zshrc
echo "PATH=\$PATH:/opt/puppetlabs/bin
SEAFILE_DIR=/opt/seafile
hash -d seafile=\$SEAFILE_DIR
hash -d logs=\$SEAFILE_DIR/logs
hash -d latest=\$SEAFILE_DIR/seafile-server-latest
hash -d ext=\$SEAFILE_DIR/KEEPER/seafile_keeper_ext
export TERM=xterm-256color" >> /root/.zshrc
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf && ~/.fzf/install --all
rm -rf /etc/puppet/auth.conf
rm -rf /etc/puppet/hiera.yaml
rm -rf /etc/puppet/puppet.conf
apt-get -y install puppet
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
puppet module install brainsware-resources_deep_merge

puppet apply /etc/puppet/code/environments/production/manifests/site.pp --environment=production -vd
