# keeper-puppet
Puppet installation scripts for KEEPER infrastructure

### Manual installation
KEEPER cluster node installation on the bare installed Ubuntu 20.04.5 LTS:
* run
  ```
  ./scripts/install_puppet5.sh
  cd /etc/puppet/code/environments/production
  ```
* put 
	* `keeper-puppet.ini` into `data/`
	* `mykey.peer` and `seafile-license.txt` into `data/keeper_files/`
	* `seafile-pro-server_8.0.17_x86-64_Ubuntu.tar.gz` into `modules/keeper/files/`
	* `init.pp` into `modules/keeper/manifests/`
* update `init.pp` for specific node
* run 
  ```
  sudo RUBYOPT='-W0' puppet apply --hiera_config=hiera.yaml --modulepath=modules manifests/site.pp --environment=production -vd
  ```

### Installation with Vagrant
Install git-lfs: https://github.com/git-lfs/git-lfs/wiki/Installation before cloning.

```
mkdir puppet/etc/puppetlabs/code/environments/production/data
```
Put in <code>puppet/etc/puppetlabs/code/environments/production/data</code> directory common <code>keeper.ini</code> and <code>keeper_files</code> directory. Setup <code>keeper.ini</code> if needed.
```
sudo apt-get install virtualbox
sudo apt-get install vagrant
./scripts/start_vagrant.sh
```
