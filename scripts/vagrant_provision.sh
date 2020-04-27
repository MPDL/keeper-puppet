#!/bin/bash

wget https://apt.puppetlabs.com/puppet5-release-bionic.deb
dpkg -i --force-all puppet5-release-bionic.deb
rm -rf puppet5-release-bionic.deb
curl -sL https://deb.nodesource.com/setup_10.x | sudo -E bash -
apt update
apt -y install git tig zsh vim-nox neovim tmux
chsh -s $(which zsh)
sh -c "$(wget https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O -)"
sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="agnoster"/g' /root/.zshrc
echo "PATH=\$PATH:/opt/puppetlabs/bin
SEAFILE_DIR=/opt/seafile
hash -d seafile=\$SEAFILE_DIR
hash -d logs=\$SEAFILE_DIR/logs
hash -d latest=\$SEAFILE_DIR/seafile-server-latest
hash -d ext=\$SEAFILE_DIR/KEEPER/seafile_keeper_ext
export LANGUAGE=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export TERM=xterm-256color

### ZPLUG section
source ~/.zplug/init.zsh

# Make sure to use double quotes
zplug 'zsh-users/zsh-syntax-highlighting'
zplug 'zsh-users/zsh-autosuggestions'
zplug 'rupa/z', use:z.sh
zplug 'changyuheng/fz', defer:2

# Supports oh-my-zsh plugins and the like
zplug 'plugins/git',   from:oh-my-zsh
zplug 'plugins/tmux',   from:oh-my-zsh
zplug 'plugins/tmuxinator',   from:oh-my-zsh
zplug 'plugins/systemd',   from:oh-my-zsh

zplug 'zplug/zplug', hook-build:'zplug --self-manage'

# Install packages that have not been installed yet
if ! zplug check --verbose; then
    printf 'Install? [y/N]: '
    if read -q; then
        echo; zplug install
    else
        echo
    fi
fi

zplug load # --verbose 

ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=243'" >> /root/.zshrc
curl -sL --proto-redir -all,https https://raw.githubusercontent.com/zplug/installer/master/installer.zsh | zsh
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf && ~/.fzf/install --all
curl -LO https://github.com/BurntSushi/ripgrep/releases/download/12.0.1/ripgrep_12.0.1_amd64.deb && dpkg -i ripgrep_12.0.1_amd64.deb && rm -f ripgrep_*.deb
curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

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
