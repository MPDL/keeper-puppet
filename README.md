# keeper-puppet
Puppet installation scripts for KEEPER infrastructure

### Manual installation
* put/defeine files:
```
~/keeper-puppet.ini
~/seafile-license.txt
~/mykey.peer
~/seafile-pro-server_10.0.11_x86-64_Ubuntu.tar.gz
~/init.pp
 ```
* run
  ./scripts/install_puppet8.sh
  cd /etc/puppetlabs/code/environments/production
  ```
* update `init.pp` for specific node
* run 
  ```
  cd /etc/puppetlabs/code/environments/production
  sudo -E RUBYOPT='-W0' puppet apply --hiera_config=hiera.yaml --modulepath=modules manifests/site.pp --environment=production -vd
  ```

### Installation with Vagrant
sudo apt-get install virtualbox
sudo apt-get install vagrant
./scripts/start_vagrant.sh
```
