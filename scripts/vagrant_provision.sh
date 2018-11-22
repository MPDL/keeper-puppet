#!/bin/bash
#source /etc/lsb-release
#wget https://apt.puppetlabs.com/puppet-release-jessie.deb
#dpkg -i puppet-release-${DISTRIB_CODENAME}.deb
#dpkg -i puppet-release-jessie.deb
#apt-get update
#apt-get install -y --install-suggests puppet=3.7.2-4+deb8u1
#apt-get -y install git puppet-agent
#echo 'Defaults        secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin:/opt/puppetlabs/bin:/opt/puppetlabs/puppet/bin"' >/etc/sudoers.d/puppet

apt-get remove binutils -y
apt-get install software-properties-common -y
add-apt-repository 'deb http://ftp.debian.org/debian jessie-backports main'
#add-apt-repository 'deb http://ftp.us.debian.org/debian unstable main contrib non-free'
wget https://apt.puppetlabs.com/puppet-release-stretch.deb
dpkg -i puppet-release-stretch.deb
apt-get update
echo "de_DE.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
apt-get -y install git zsh vim-nox 
chsh -s $(which zsh)
sh -c "$(wget https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O -)"
sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="agnoster"/g' /root/.zshrc
echo "PATH=$PATH:/opt/puppetlabs/bin" >> /root/.zshrc
apt-get -y install puppet
apt-get -y install puppet-agent
echo 'Defaults        secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin:/opt/puppetlabs/bin:/opt/puppetlabs/puppet/bin"' >/etc/sudoers.d/puppet

/opt/puppetlabs/puppet/bin/gem install inifile 
/opt/puppetlabs/puppet/bin/puppet module install puppetlabs-mysql
/opt/puppetlabs/puppet/bin/puppet module install puppet-archive
/opt/puppetlabs/puppet/bin/puppet module install puppetlabs-apt
/opt/puppetlabs/puppet/bin/puppet module install puppetlabs-stdlib
/opt/puppetlabs/puppet/bin/puppet module install puppetlabs-inifile
/opt/puppetlabs/puppet/bin/puppet module install puppetlabs-vcsrepo 

/opt/puppetlabs/puppet/bin/puppet apply -vd /etc/puppetlabs/code/environments/production/manifests/site.pp
