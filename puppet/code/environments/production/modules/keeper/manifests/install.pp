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
  
  $clean_sections = $keeper::params::clean_sections
  ### override $clean_sections with $node_props
  
  notice("NODE PROPS: ${node_props}")
  $node_ini = deep_merge($clean_sections, $node_props)  
  $ni_db = $node_ini['db']

  notice("MERGED NODE PROPS: ${node_ini}")

  
  #can be commented if db is already installed
  keeper::db {'install':
    props => $props,
    node_ini => $node_ini,
  }
  
  
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

  #### TIMEZONE
  exec { 'timezone':
	command => '/usr/bin/timedatectl set-timezone Europe/Berlin'  	
  }

  #### DEB MODULES
  $deb_modules = [
    "lsb-release",
    "build-essential",
    "git-core",
    "openjdk-8-jre",
    "python3",
    "python3-dev",
    "python3-setuptools",
    "python3-ldap",
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

    ]      
  package { $deb_modules:
    ensure => latest,
  }

  exec { "pip-from-get-pip.py":
  	command => "curl https://bootstrap.pypa.io/get-pip.py > /tmp/get-pip.py && sudo python3 /tmp/get-pip.py && rm /tmp/get-pip.py",
  	path    => ["/usr/bin", "/bin"],
  	require => [ Package["python3"], Package["python3-setuptools"] ],
  }

  exec { "upgrade_pyopenssl":
  	command => "pip3 install pyopenssl --upgrade",
    path    => ["/usr/bin", "/usr/local/bin", "/sbin"],
  	require => Exec["pip-from-get-pip.py"],
  }


	# PIP MODULES
  $pip_modules = [

    ### seafile 9.0.x
    "django==3.2.*",
    "future",
    "mysqlclient",
    "pymysql",
    "Pillow",
    "pylibmc",
    "captcha",
    "jinja2",
    "sqlalchemy==1.4.3",
    "psd-tools",
    "django-pylibmc",
    "django-simple-captcha",
    "pycryptodome==3.12.0",
    "cffi==1.14.0",
    "lxml",


    ### seafile 10.0.x
    # "django==3.2.*",
    # "future==0.18.*",
    # "mysqlclient==2.1.*",
    # "pymysql",
    # "pillow==9.3.*",
    # "pylibmc",
    # "captcha==0.4",
    # "markupsafe==2.0.1",
    # "jinja2",
    # "sqlalchemy==1.4.3",
    # "psd-tools",
    # "django-pylibmc",
    # "django_simple_captcha==0.5.*",
    # "djangosaml2==1.5.*",
    # "pysaml2==7.2.*",
    # "pycryptodome==3.16.*",
    # "cffi==1.15.1",
    # "lxml",

    "configparser",
    "netaddr",
    "paramiko",
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
      require => [ Package["python3", "python3-dev", "libmysqlclient-dev"], Exec["pip-from-get-pip.py", "upgrade_pyopenssl"] ],
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

  ###### SEAFILE

  # set owner:group to root dir recursively
  file { "$seafile_root" :
    ensure  => directory,
    *       => $attr,
  }

  # create logs
  file { "${seafile_root}/logs" :
    ensure  => directory,
    *       => $attr,
    require => File[ $seafile_root ],
  }


  $seafile_arch = "${seafile_root}/${props['release']['__SEAFILE_SOURCE_TAR__']}"
  notice($seafile_arch)
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

  inifile::create_ini_settings($node_ini, $ini_defaults)

  file { "${ini_defaults['path']}":
    *      => $attr,
  }

  $escaped_setting = regsubst("${props['memcached']['__MEMCACHED_KA_UNICAST_PEERS__']}", "\n", "\\n", 'G')
  ini_setting {'memcached escape newline':
    * => $ini_defaults,
  	ensure  => present,
    section => 'memcached',
    setting => '__MEMCACHED_KA_UNICAST_PEERS__',
    value => "$escaped_setting",
  }
  
  ini_setting {'nodes quotes':
    * => $ini_defaults,
  	ensure  => present,
    section => 'global',
    setting => '__CLUSTER_NODES__',
  	value => "\"${node_ini['global']['__CLUSTER_NODES__']}\"",
  }

  ini_setting {'secret key quotes':
    * => $ini_defaults,
    ensure  => present,
    section => 'global',
    setting => '__SECRET_KEY__',
    value => "\"${node_ini['global']['__SECRET_KEY__']}\"",
  }


  ini_setting { 'subst \x to x for bxb __BLOXBERG_PUBLIC_KEY__':
    * => $ini_defaults,
	  ensure  => present,
	  section => 'bloxberg',
	  setting => '__BLOXBERG_PUBLIC_KEY__',
	  value => regsubst($node_ini['bloxberg']['__BLOXBERG_PUBLIC_KEY__'], '\\\x', 'x'),
  }


	###
	### KEEPER DIRECTORIES/FILES
	###

  # $dirtree = dirtree($::rubysitedir)
	
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

  # BLOXBERG CERTS
  dirtree { 'bloxberg storage':
    ensure  => present,
    path    => "${node_ini['bloxberg']['__BLOXBERG_CERTS_STORAGE__']}",
    parents => true,
  }

	# LOGS
  dirtree { 'keeper log directory':
    ensure  => present,
    path    => "${node_ini['logging']['__KEEPER_LOG_DIR__']}",
    parents => true,
  }

  file { ["${node_ini['archiving']['__LOCAL_STORAGE__']}", "${node_ini['bloxberg']['__BLOXBERG_CERTS_STORAGE__']}", "${node_ini['logging']['__KEEPER_LOG_DIR__']}"]:
    ensure => directory,
    *      => $attr,
  }

  
  notice("HERE 1 NODE_TYPE -->")
  notice("${node_ini['global']['__NODE_TYPE__']}")
  notice("HERE 2 __GPFS_DEVICE__ -->")
  notice("${node_ini['backend']['__GPFS_DEVICE__']}")
   
  if ($node_ini['global']['__NODE_TYPE__'] != 'SINGLE') and ($node_ini['backend']['__GPFS_DEVICE__']) {
  	# This section runs for non SINGLE and GPFS_DEVICE is defined
  	# Create dirs/files and do not create db!
    file { [ "${seafile_root}/ccnet", "${seafile_root}/pids", "${seafile_root}/pro-data", "${seafile_root}/conf", "${seafile_root}/logs" ]:
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

    file { "${seafile_root}/seahub-data":
      ensure => link,
      target => "/keeper/seahub-data",
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
    
    ## remove seafile-server-latest before setup-seafile-mysql.sh - otherwise it breakes!
    file { "${seafile_root}/seafile-server-latest_removed":
      ensure => absent,
      target => "${seafile_root}/${node_ini['global']['__SEAFILE_SERVER_LATEST_DIR__']}",
      force => true,
      * => $attr,
      require => [  Archive["${seafile_arch}"] ],
    }


    exec { 'setup-seafile-mysql.sh':
      command      => "sudo ./setup-seafile-mysql.sh auto -n ${node_ini['http']['__SERVER_NAME__']} -i ${node_ini['http']['__NODE_FQDN__']} -d ${seafile_root}/seafile-data -e 1 -o ${ni_db['__DB_HOST__']} -t ${ni_db['__DB_PORT__']} -u ${ni_db['__DB_USER__']} -w ${ni_db['__DB_PASSWORD__']} -c ccnet-db -s seafile-db -b seahub-db",
      path         => ["${seafile_root}/${seafile_ver}", "/usr/bin", "/usr/local/bin", "/bin"],
      cwd          => "${seafile_root}/${seafile_ver}",
      creates      => "${seafile_root}/seafile-data",
      require => [  Archive["${seafile_arch}"], File["${seafile_root}/seafile-server-latest_removed"], Keeper::Db['install'] ],
      logoutput =>  true,
    }

    file { ["${seafile_root}/seafile-data", "${seafile_root}/conf"]:
      ensure  => directory,
      *       => $attr,
      recurse => true,
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



  # deploy KEEPER
  file { "${keeper_ext}/build.py":
    mode      => '0755',
  }


  #file {"${seafile_root}/seafile-data":
  #  ensure => directory
  #}
 
  exec { "keeper-deploy-all":
    command   => "./build.py deploy --all -y",
    path      => ["${keeper_ext}", "${seafile_root}/seafile-server-latest/seahub", "/bin", "/usr/bin", "/usr/local/bin", "/sbin", ],
    cwd       => "${keeper_ext}",
    # TODO: check pip module dependencies
    # require   => [ File["${seafile_root}/seafile-data"],  Exec['setup-seafile-mysql.sh'], Vcsrepo["${seafile_root}/KEEPER"], Package['nginx'] ],
    require   => [ File["${seafile_root}/seafile-data"],  Vcsrepo["${seafile_root}/KEEPER"], Package['nginx'] ],
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
    command  => "/bin/bash -c \"\\$(mysql -s -N --user=${ni_db['__DB_USER__']} --password=${ni_db['__DB_PASSWORD__']} --database=keeper-db < ${seafile_root}/seafile-server-latest/seahub/keeper/keeper-db.sql)\"",
    #onlyif  => "/bin/bash -c \"[ -z \\$(mysql -s -N --user=${ni_db['__DB_USER__']} --password=${ni_db['__DB_PASSWORD__']} -e \\\"SELECT schema_name FROM information_schema.schemata WHERE schema_name='keeper-db'\\\") ];\"",
    path     => ["/usr/bin", "/bin"],
    require => Exec['keeper-deploy-all'],
  }

  ### KEEPER UTILS
  
  # nginx_ensite: https://github.com/perusio/nginx_ensite
  vcsrepo { '/opt/nginx_ensite':
    ensure   => present,
    provider => git,
    source   => 'https://github.com/perusio/nginx_ensite.git',
    require => [ Package['nginx']],
  }
  exec { 'nginx_ensite-install':
    command => 'make install',
    path    => ["/bin", "/usr/bin", "/usr/local/bin", "/sbin"],
    cwd     => "/opt/nginx_ensite",
    require => [ Vcsrepo["/opt/nginx_ensite"] ],
    creates => '/usr/local/bin/nginx_ensite',
  }


  $http_conf = $node_ini['http']['__HTTP_CONF__']
  exec { 'enable_keeper_nginx_conf':
    command => "/bin/bash -c \"nginx_ensite ${http_conf}\"",
    path    => ["/bin", "/usr/bin", "/usr/local/bin", "/sbin"],
    require => [  Exec['keeper-deploy-all', 'nginx_ensite-install']],
    creates => "/etc/nginx/sites-enabled/${http_conf}",
    logoutput =>  true,
  }

  file { ['/etc/nginx/sites-enabled', '/etc/nginx/sites-available']:
    ensure => directory,
    require => [ Class['keeper::nginx'], Exec['nginx_ensite-install'] ],
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

  ### START KEEPER
  $reqs = [ Service['memcached'], Class['keeper::nginx'], Exec['create_keeper_database'], ]
  if $props['global']['__NODE_TYPE__'] in ['SINGLE', 'BACKGROUND'] {
    $reqs.push(Class['keeper::elastic'])
  }
  service { 'keeper':
    #ensure     => running,
    ensure     => stopped,
    enable     => true,
    hasrestart => true,
    require    => $reqs,
  }
  


	# restart nginx with new updated confs
  exec { 'restart_nginx':
    command     => '/bin/systemctl restart nginx',
    require     => Service['keeper']
  }

  # disable puppet agent
  exec { 'disable_puppet_agent':
    command     => 'puppet agent --disable',
  	path        => ["/usr/bin", "/bin", "/opt/puppetlabs/bin"],
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
