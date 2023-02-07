# Main Class for keeper node installation
# To be called from init.pp
define keeper::install (
  Hash $node_props = {},
  Hash $node_defaults = {}
){

  include keeper::params 

  $seafile_root = $keeper::params::seafile_root 
  $seafile_ver = $keeper::params::seafile_ver 
  $attr = $keeper::params::attr 
  if $node_defaults['path'] {
    $ini_defaults = $node_defaults
  }
  else {
    $ini_defaults = $keeper::params::defaults
  }
  $props = $keeper::params::props
  $db = $props['db'] 
  $pkgs = $props['package-deps'] 
  $sys = $props['system']
  
  #clean up some sensitive stuff from default props
  $clean_settings = deep_merge($props, { 
    'db'      => {
      '__DB_ROOT_PASSWORD__' => { 'ensure' => 'absent' } 
    },
    'system'  => {
      '__OS_USER_PASSWORD__' => { 'ensure' => 'absent' }, 
      '__OS_GID__' => { 'ensure' => 'absent' }, 
      '__OS_UID__' => { 'ensure' => 'absent' }, 
    },
    'global'  => {
      '__KEEPER_ADMIN_PASSWORD__'   => { 'ensure' => 'absent' },
    },
    })
  $clean_sections = (($clean_settings.delete('repositories')).delete('package-deps')).delete('release')

  #override $clean_sections with $node_props
  $node_ini = deep_merge($clean_sections, $node_props)  

  # notice("MERGED NODE PROPS: ${node_ini}")
  
  #can be commented if db is already installed
  require keeper::db

  ##### USER / GROUP
  group { "${sys['__OS_GROUP__']}":
    ensure  => present,
    gid  => "${sys['__OS_GID__']}",
  }
  user { "${sys['__OS_USER__']}":
    ensure      => present,
    comment     => 'Seafile User',
    managehome  => true,
    gid         => "${sys['__OS_GID__']}",
    uid         => "${sys['__OS_UID__']}",
    require     => Group["${sys['__OS_GROUP__']}"],
    password    => "${sys['__OS_USER_PASSWORD__']}",
  }


  #### DEB MODULES
  $deb_modules = [
    "lsb-release",
    "build-essential",
    "git-core",
    "openjdk-8-jre",
    "python3",
    "python3-setuptools",
    #"python3-pip",
    "poppler-utils",
    "clamav",
    "gettext",
    "memcached",
    "libmemcached-dev",
    "postfix",
    "zlib1g-dev",
    "libfreetype6-dev",
    "monitoring-plugins",
    "libffi-dev",
    "libldap2-dev",
    "default-libmysqlclient-dev",
    "libmysqlclient-dev"
    #"libssl1.0-dev",
    # dev
    #"phpmyadmin",
    #"php7.2-fpm"
    ]      
  package { $deb_modules:
    ensure => latest,
  }

  exec { "pip-from-get-pip.py":
  	command => "curl https://bootstrap.pypa.io/get-pip.py > /tmp/get-pip.py && sudo python3 /tmp/get-pip.py && rm /tmp/get-pip.py",
  	path    => ["/usr/bin", "/bin"],
  	require => [ Package["python3"], Package["python3-setuptools"] ],
  }

	# PIP MODULES
  $pip_modules = [
    "Pillow", 
    "pylibmc",
    "python3-ldap",
    "captcha", 
    "django-pylibmc", 
    "jinja2", 
    "psd-tools", 
    "django-simple-captcha",
    "configparser",
    "netaddr",
    "paramiko",
    "mysqlclient",
    "sqlalchemy",
    "uwsgi",
    "mistune==0.8.4",
    "pytest",
    "elasticsearch",
    # bloxberg
    "PyPDF2",
    "lds_merkle_proof_2019",
    ]     
  each($pip_modules) |$m| {
    exec { "pip-${m}":
      command =>   "pip3 install --timeout=3600 ${m}",
      path    => ["/usr/bin", "/usr/local/bin", "/sbin"],
      require => [ Package["python3-setuptools"], Exec["pip-from-get-pip.py"] ],
      #unless  => "pip show ${m}",
      logoutput =>  true,
    }
  }
  exec { "upgrade-chardet":
    command =>   "pip3 install --timeout=3600 --upgrade chardet",
    path    => ["/usr/bin", "/usr/local/bin", "/sbin"],
    require => [ Package["python3-setuptools"], Exec["pip-from-get-pip.py"] ],
    #unless  => "pip show ${m}",
    logoutput =>  true,
  }


  # Office/PDF Document Preview for BACKGROUND node
  #if $props['global']['__NODE_TYPE__'] in ['SINGLE', 'BACKGROUND'] {
  #  each(["libreoffice", "libreoffice-script-provider-python", ]) |$p| {
  #    package { "${p}":
  #      ensure => "${pkgs[$p]}", 
  #    }
  #  }
  #}

  # keepalived
  require keeper::keepalived

  # NGINX
  require keeper::nginx

  #file { "/run/php/php7.2-fpm.sock":
  #  ensure  => present,
  #  owner   => "www-data",
  #  group   => "www-data",
  #  require =>  [ Package["php7.2-fpm"], Package["nginx"] ] ,
  #}

  ###### SEAFILE

  # set owner:group to root dir recursively
  file { "$seafile_root" :
    ensure  => directory,
    *       => $attr,
  }

  $seafile_arch = "${seafile_root}/${props['release']['__SEAFILE_SOURCE_TAR__']}"
  # seafile sources
  archive { "$seafile_arch":
    source       => "puppet:///modules/keeper/${props['release']['__SEAFILE_SOURCE_TAR__']}",
    extract      => true,
    extract_path => "${seafile_root}",
    user         => "${sys['__OS_USER__']}",
    group        => "${sys['__OS_GROUP__']}",
    creates      => "${seafile_root}/${seafile_ver}",
    cleanup      => false,
    require       => [ File["$seafile_root"] ],
  }
  
  # seafile latest license
  file { "${seafile_root}/seafile-license.txt":
    *      => $attr,
    source  => "${settings::environmentpath}/${settings::environment}/data/keeper_files/seafile-license.txt",
  }

	# NODE specific INI generation
  # generate keeper ini 
  notice("INI: ${ini_defaults['path']} ")

  create_ini_settings($node_ini, $ini_defaults)

  file { "${ini_defaults['path']}":
    *      => $attr,
  }

  $ini_memcached = regsubst("${node_ini['memcached']['__MEMCACHED_KA_UNICAST_PEERS__']}", "\n", "\\n", 'G')

  ini_setting {'memcached escape newline':
		ensure  => present,
    section => 'memcached',
    path => "${ini_defaults['path']}",
    setting => '__MEMCACHED_KA_UNICAST_PEERS__',
    value => "${ini_memcached}",
  }
  
  ini_setting {'nodes quotes':
  	ensure  => present,
    section => 'global',
    path => "${ini_defaults['path']}",
    setting => '__CLUSTER_NODES__',
		value => "\"${node_ini['global']['__CLUSTER_NODES__']}\"",
  }

  ini_setting {'secret key quotes':
    ensure  => present,
    section => 'global',
    path => "${ini_defaults['path']}",
    setting => '__SECRET_KEY__',
    value => "\"${node_ini['global']['__SECRET_KEY__']}\"",
  }

  # ini_setting {'remote log quotes':
        # ensure  => present,
        # section => 'backup',
        # path => "${ini_defaults['path']}",
        # setting => '__REMOTE_LOG__',
        # value => "\"${props['backup']['__REMOTE_LOG__']}\"",
  # }

  ini_setting { 'subst \x to x for bxb __BLOXBERG_PUBLIC_KEY__':
	  ensure  => present,
	  section => 'bloxberg',
	  path => "${ini_defaults['path']}",
	  setting => '__BLOXBERG_PUBLIC_KEY__',
	  value => regsubst($node_ini['bloxberg']['__BLOXBERG_PUBLIC_KEY__'], '\\\x', 'x'),
  }

#  ini_subsetting {'nodes quotes':
#        ensure  => present,
#        section => 'global',
#        path => "${ini_defaults['path']}",
#        setting => '__CLUSTER_NODES__',
#        subsetting => "${props['http']['__NODE_FQDN__']}",
#        value => '10',
#        quote_char => '"',
#  }


	###
	### KEEPER DIRECTORIES/FILES
	###

  $dirtree = dirtree($::rubysitedir)
	
  # should be set for correct work of document preview 
  file { "/run/tmp":
    ensure  => directory,
    mode    => '1777',
  }

	# ARCHIVING
	dirtree { 'keeper archive storage':
		ensure  => present,
		path    => "${node_ini['archiving']['__LOCAL_STORAGE__']}",
		parents => true,
	}

  #file { "${node_ini['archiving']['__LOCAL_STORAGE__']}":
  #  ensure => directory,
  #  mode   => '1777',
  #}

	# BLOXBERG CERTS
  dirtree { 'bloxberg storage':
    ensure  => present,
    path    => "${node_ini['bloxberg']['__BLOXBERG_CERTS_STORAGE__']}",
    parents => true,
  }

  #file { "${node_ini['bloxberg']['__BLOXBERG_CERTS_STORAGE__']}":
  #  ensure => directory,
  #  mode   => '1777',
  #}

	# LOGS
  dirtree { 'keeper log directory':
    ensure  => present,
    path    => "${node_ini['logging']['__KEEPER_LOG_DIR__']}",
    parents => true,
  }

  
  if ($node_ini['global']['__NODE_TYPE__'] != 'SINGLE') and ($node_ini['backend']['__GPFS_DEVICE__']) {
  	# This section runs for non SINGLE and GPFS_DEVICE is defined
  	# Create dirs/files and do not create db!
    file { [ "${seafile_root}/ccnet", "${seafile_root}/pids", "${seafile_root}/seahub-data", "${seafile_root}/pro-data", "${seafile_root}/conf", "${seafile_root}/logs" ]:
      ensure => directory,
      *      => $attr,
      force => true,
    }

    file { "${seafile_root}/ccnet/mykey.peer":
      *      => $attr,
      source  => "${settings::environmentpath}/${settings::environment}/data/keeper_files/mykey.peer",
      require => [ File["${seafile_root}/ccnet"] ],
    }

    file { "${seafile_root}/seafile-data":
      ensure => link,
      target => "/keeper/seafile-data",
      force => true,
      * => $attr,
    }

    file { "${seafile_root}/seafile-server-latest":
      ensure => link,
      target => "${seafile_root}/${node_ini['global']['__SEAFILE_SERVER_LATEST_DIR__']}",
      force => true,
      * => $attr,
      require => Archive["$seafile_arch"],
    }

 		# skip non interactive setup
    exec { 'setup-seafile-mysql.sh':
      command => "/bin/echo 'skipping setup-seafile-mysql.sh'",
      require => [ File["${seafile_root}/seafile-server-latest"], File["${seafile_root}/ccnet"], File["${seafile_root}/pids"], File["${seafile_root}/seahub-data"], File["${seafile_root}/pro-data"], File["${seafile_root}/conf"], File["${seafile_root}/ccnet/mykey.peer"], File["${seafile_root}/seafile-data"] ],
    }
  }
  elsif ($node_ini['global']['__NODE_TYPE__'] == 'SINGLE') and (!$node_ini['backend']['__GPFS_DEVICE__']) {
  	# ONLY FOR SINGLE NODE WITHOUT GPFS! 
    # see https://manual.seafile.com/deploy/using_mysql.html#setup-in-non-interactive-way
    # NOTE: DBs have been already created in mariadb.pp!!!
    exec { 'setup-seafile-mysql.sh':
      command      => "setup-seafile-mysql.sh auto -n ${node_ini['http']['__SERVER_NAME__']} -i ${node_ini['http']['__NODE_FQDN__']} -d ${seafile_root}/seafile-data -e 1 -o ${db['__DB_HOST__']} -t ${db['__DB_PORT__']} -u ${db['__DB_USER__']} -w ${db['__DB_PASSWORD__']} -c ccnet-db -s seafile-db -b seahub-db",
      path         => ["${seafile_root}/${seafile_ver}", "/usr/bin", "/usr/local/bin", "/bin"],
      cwd          => "${seafile_root}/${seafile_ver}",
      creates      => "${seafile_root}/seafile-data",
      require => [ Archive["${seafile_arch}"] ],
      logoutput =>  true,
    }

    file { "${seafile_root}/seafile-data" :
      ensure  => directory,
      *       => $attr,
      require => Exec['setup-seafile-mysql.sh'],
    }



  }

    # Create server admin after first seahub start
      #  see https://github.com/haiwen/seafile-server/blob/master/scripts/check_init_admin.py#L358
      file { "${seafile_root}/conf/admin.txt":
        content  => "{ \"email\": \"${node_ini['global']['__KEEPER_ADMIN_EMAIL__']}\",  \"password\": \"${node_ini['global']['__KEEPER_ADMIN_PASSWORD__']}\" }",
      }
    
      # clean admin.txt if at least one user already created
      exec { 'clean_admin.txt':
        command  => "rm -f ${seafile_root}/conf/admin.txt",
        onlyif  => "/bin/bash -c \"[[ -n \\$(mysql -s -N --user=${db['__DB_USER__']} --password=${db['__DB_PASSWORD__']} --database=ccnet-db --execute='SELECT * from EmailUser') ]];\"",
        path     => ["/usr/bin", "/bin"],
        require => [ File["${seafile_root}/conf/admin.txt"] ],
      }  
  


  #### KEEPER

  # checkout from github repo, tagged version  
  vcsrepo { "${seafile_root}/KEEPER":
    ensure   => present,
    provider => git,
    source   => 'https://github.com/MPDL/KEEPER.git',
    revision => "${props['release']['__GIT_REVISION__']}",
    *        => $attr,
  }
  
  file { "${seafile_root}/KEEPER" :
    ensure  => directory,
    recurse => true,
    *       => $attr,
    require =>  Vcsrepo["${seafile_root}/KEEPER"],
  }

  $keeper_ext = "${seafile_root}/KEEPER/seafile_keeper_ext"


  $http_conf = $node_ini['http']['__HTTP_CONF__']
  exec { 'enable_keeper_nginx_conf':
    command => "/bin/bash -c \"nginx_ensite  ${http_conf} \"",
    path    => ["/bin", "/usr/bin", "/usr/local/bin", "/sbin"],
    #require => [  Exec['nginx_ensite-install'], Service['nginx'], Class['nginx'] ],
    require => [  Exec['nginx_ensite-install'], Package['nginx'] ],
    creates => "/etc/nginx/sites-enabled/${http_conf}",
    logoutput =>  true,
  }

  file { ['/etc/nginx/sites-enabled', '/etc/nginx/sites-available']:
    ensure => directory,
    require => [ Class['keeper::nginx'] ],
  }

  file { "/etc/nginx/sites-enabled/${http_conf}":
    ensure  => link,
    target  => "/etc/nginx/sites-available/${http_conf}",
    require => File['/etc/nginx/sites-enabled'],
  }

  user { 'nginx':
    groups         => ['www-data', 'nginx'],
    membership     => minimum,
    require        => [ Package['nginx'] ],
  }


  # deploy KEEPER
  file { "${keeper_ext}/build.py":
    mode      => '0755',
  }


 
  exec { "keeper-deploy-all":
    command   => "./build.py deploy --all -y",
    path      => ["${keeper_ext}", "${seafile_root}/seafile-server-latest/seahub", "/bin", "/usr/bin", "/usr/local/bin", "/sbin", ],
    cwd       => "${keeper_ext}",
    # TODO: check pip module dependencies
    require   => [ Exec['setup-seafile-mysql.sh'], Vcsrepo["${seafile_root}/KEEPER"], Package['nginx'] ],
    logoutput =>  true,
  }

  # set correct permissions for seafile and  
  #file { "${seafile_root}-set-permissions":
    #path    => "${seafile_root}",
    #ensure  => present,
    #recurse => true,
    #*       => $attr,
    #require => [ Exec["keeper-deploy-all"] ]
  #}

  # create mysql keeper database and tables
  # onlyif moved to sql: IF NOT EXISTS option for CREATE TABLE|TRIGGER
  exec { 'create_keeper_database':
    command  => "/bin/bash -c \"\\$(mysql -s -N --user=${db['__DB_USER__']} --password=${db['__DB_PASSWORD__']} --database=keeper-db < ${seafile_root}/seafile-server-latest/seahub/keeper/keeper-db.sql)\"",
    #onlyif  => "/bin/bash -c \"[ -z \\$(mysql -s -N --user=${db['__DB_USER__']} --password=${db['__DB_PASSWORD__']} -e \\\"SELECT schema_name FROM information_schema.schemata WHERE schema_name='keeper-db'\\\") ];\"",
    path     => ["/usr/bin", "/bin"],
    require => Exec['keeper-deploy-all'],
  }

  # keeper UTILS
  # nginx_ensite: https://github.com/perusio/nginx_ensite
  vcsrepo { '/opt/nginx_ensite':
    ensure   => present,
    provider => git,
    source   => 'https://github.com/perusio/nginx_ensite.git',
  }
  exec { 'nginx_ensite-install':
    command => 'make install',
    path    => ["/bin", "/usr/bin", "/usr/local/bin", "/sbin"],
    cwd     => "/opt/nginx_ensite",
    require => [ Package['nginx'], Vcsrepo["/opt/nginx_ensite"] ],
    creates => '/usr/local/bin/nginx_ensite',
  }

  # start services
  service { 'memcached':
    #ensure          => running,
    ensure          => stopped,
    hasrestart      => true,
    enable          => true,
    require => Package['memcached'],
  }

  # service { 'nginx':
    # ensure          => running,
    # hasrestart      => true,
    # enable          => true,
    # require => [ Package['nginx'], Package['apache2'] ],
  # }



  # START KEEPER
  service { 'keeper':
    #ensure     => running,
    ensure     => stopped,
    enable     => true,
    hasrestart => true,
    require    => [ Service['memcached'], Class['keeper::nginx'], Exec['create_keeper_database'] ],
  }

	# restart nginx with new updated confs
  exec { 'restart_nginx':
    command     => '/bin/systemctl restart nginx',
    require     => Service['keeper']
  }

  # disable puppet agent
  exec { 'disable_puppet_agent':
    command     => '/usr/bin/puppet agent --disable',
    require     => Service['keeper']
  }


  # remove apache
  $apache2 = [
    "apache2",
    "apache2-bin",
    "apache2-data",
    "libapache2-mod-php7.2",
  ]
  package { $apache2:
    ensure => absent,
  }

}
