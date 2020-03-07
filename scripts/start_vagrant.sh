#!/bin/bash
vagrant plugin install vagrant-vbguest
vagrant plugin install vagrant-nfs_guest
vagrant up
# ownership mapping seafile@guest->local user@host (with nfs_guest->bindfs)
#sudo apt install bindfs
#sudo bindfs --map=2101/1000:@2101/@1000 /opt/seafile/KEEPER/seafile_keeper_ext /opt/seafile/KEEPER/seafile_keeper_ext
