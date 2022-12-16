Put here *.deb, *.tar.gz, and other pkg files

to be accessed from manifests/*.pp with 
```
 source => "puppet:///modules/keeper/<file_name>",
```
or
```
source => "${settings::environmentpath}/${settings::environment}/modules/keeper/files/<file_name>"
```
See https://puppet.com/docs/puppet/5.5/types/file.html#file-attribute-source
