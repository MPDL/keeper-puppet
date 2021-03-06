#### INSTALLATIOn FOR SINGLE NODE KEEPER
# https://manual.seafile.com/deploy_pro/download_and_setup_seafile_professional_server.html
# https://manual.seafile.com/deploy_pro/deploy_in_a_cluster.html

#class keeper::install (
  #$seafile_root = $keeper::params::seafile_root,
  #$seafile_ver = $keeper::params::seafile_ver,
  #$attr = $keeper::params::attr,
#) inherits keeper::params {
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
  #clean up some stuff from props 
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
      '__SECRET_KEY__'   => "\"${props['global']['__SECRET_KEY__']}\"",
      '__KEEPER_ADMIN_PASSWORD__'   => { 'ensure' => 'absent' },
    },
    })
  $clean_sections = (($clean_settings.delete('repoistories')).delete('package-deps')).delete('release')

  #override $clean_sections with $node_props
  $node_ini = deep_merge($clean_sections, $node_props)  

  #do not install db by default
  #require keeper::db

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


  #### MODULES
  $deb_modules = [
    "lsb-release",
    "build-essential",
    "git-core",
    "openjdk-8-jre",
    "python3",
    "python3-setuptools",
    "python3-pip",
    "poppler-utils",
    "clamav",
    "gettext",
    "memcached",
    "libmemcached-dev",
    "zlib1g-dev",
    "libfreetype6-dev",
    "monitoring-plugins",
    "libffi-dev",
    "libldap2-dev",
    "default-libmysqlclient-dev",
    "libssl1.0-dev",
    "nodejs",
    # dev
    #"phpmyadmin",
    #"php7.2-fpm"
    ]      
  package { $deb_modules:
    ensure => latest,
  }
 
  package { "requirejs":
    ensure   => latest,
    provider => "npm",
    require  => [  Package["nodejs"] ],
  }

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
    "mistune",
    "pytest",
    "elasticsearch",
    ]     
  each($pip_modules) |$m| {
    exec { "pip-${m}":
      command =>   "pip3   install --timeout=3600 ${m}",
      path    => ["/usr/bin", "/usr/local/bin", "/sbin"],
      require => [ Package["python3-pip"], Package["python3-setuptools"] ],
      #unless  => "pip show ${m}",
      logoutput =>  true,
    }
  }

  alternative_entry { '/usr/bin/python3.6':
    ensure  => present,
    altlink => '/usr/bin/python',
    altname => 'python',
    priority => 10,
    require => Package['python3'],
  }

  alternatives { 'python':
    path => '/usr/bin/python3.6',
    require => Package['python3'],
  }

  # remove python2 
  $python2 = [
    "python2",
    "python2-minimal",
  ]
  package { $python2:
    ensure => absent,
    require => Alternatives["python"],
  }


  # Office/PDF Document Preview for BACKGROUND node
  #if $props['global']['__NODE_TYPE__'] in ['SINGLE', 'BACKGROUND'] {
  #  each(["libreoffice", "libreoffice-script-provider-python", ]) |$p| {
  #    package { "${p}":
  #      ensure => "${pkgs[$p]}", 
  #    }
  #  }
  #}

  include apt
  # add nginx apt repo
  apt::source { 'nginx_repo':
    location => "${props['repositories']['__NGINX__']}",
    repos    => 'nginx',
    release  => "${props['repositories']['__OS_RELEASE__']}",
    key      => {
      id     => "${props['repositories']['__NGINX_KEYID__']}",
      source => "${props['repositories']['__NGINX_KEYSERVER__']}"
    },
    include  =>  {
      'src' =>  false,
      'deb' =>  true,
    },
  }
  # nginx
  package { 'nginx':
    ensure  => "${pkgs['nginx']}",
    require => [ Apt::Source['nginx_repo'], Class['apt::update'] ]
  }

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

  # generate keeper ini 
  create_ini_settings($node_ini, $ini_defaults)

  file { "${ini_defaults['path']}":
    *      => $attr,
  }

  $ini_memcached = regsubst("${props['memcached']['__MEMCACHED_KA_UNICAST_PEERS__']}", "\n", "\\n", 'G')

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
	value => "\"${props['global']['__CLUSTER_NODES__']}\"",
  }

  ini_setting {'secret key quotes':
        ensure  => present,
        section => 'global',
        path => "${ini_defaults['path']}",
        setting => '__SECRET_KEY__',
        value => "\"${props['global']['__SECRET_KEY__']}\"",
  }

  ini_setting {'remote log quotes':
        ensure  => present,
        section => 'backup',
        path => "${ini_defaults['path']}",
        setting => '__REMOTE_LOG__',
        value => "\"${props['backup']['__REMOTE_LOG__']}\"",
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



  # should be set for correct work of document preview 
  file { "/run/tmp":
    ensure  => directory,
    mode    => '1777',
  }

  $dirtree = dirtree($::rubysitedir)

  notify { $dirtree: }

  dirtree { 'keeper archive storage':
    ensure  => present,
    path    => "${props['archiving']['__LOCAL_STORAGE__']}",
    parents => true,
  }

  file { "${props['archiving']['__LOCAL_STORAGE__']}":
    ensure => directory,
    mode   => '1777',
  }


  dirtree { 'keeper log directory':
    ensure  => present,
    path    => "${props['logging']['__KEEPER_LOG_DIR__']}",
    parents => true,
  }

  if $props['backend']['__GPFS_DEVICE__'] {
    # This section runs when the GPFS_DEVICE is defined, mainly in QA and PROD
    file { [ "${seafile_root}/ccnet", "${seafile_root}/pids", "${seafile_root}/seahub-data", "${seafile_root}/pro-data", "${seafile_root}/conf" ]:
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
      target => "${seafile_root}/${props['global']['__SEAFILE_SERVER_LATEST_DIR__']}",
      force => true,
      * => $attr,
      require => Archive["$seafile_arch"],
    }
 
    exec { 'setup-seafile-mysql.sh':
      command => "/bin/echo 'skipping setup-seafile-mysql.sh'",
      require => [ File["${seafile_root}/seafile-server-latest"], File["${seafile_root}/ccnet"], File["${seafile_root}/pids"], File["${seafile_root}/seahub-data"], File["${seafile_root}/pro-data"], File["${seafile_root}/conf"], File["${seafile_root}/ccnet/mykey.peer"], File["${seafile_root}/seafile-data"] ],
    }
  }
  else {
    # install seafile for mysql in non-interactive mode
    # see https://manual.seafile.com/deploy/using_mysql.html#setup-in-non-interactive-way
    # NOTE: DBs have been already created in mariadb.pp!!!
    exec { 'setup-seafile-mysql.sh':
      command      => "setup-seafile-mysql.sh auto -n ${props['http']['__SERVER_NAME__']} -i ${props['http']['__NODE_FQDN__']} -d ${seafile_root}/seafile-data -e 1 -o ${db['__DB_HOST__']} -t ${db['__DB_PORT__']} -u ${db['__DB_USER__']} -w ${db['__DB_PASSWORD__']} -c ccnet-db -s seafile-db -b seahub-db",
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
    content  => "{ \"email\": \"${props['global']['__KEEPER_ADMIN_EMAIL__']}\",  \"password\": \"${props['global']['__KEEPER_ADMIN_PASSWORD__']}\" }",
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


  $http_conf = $props['http']['__HTTP_CONF__']
  exec { 'enable_keeper_nginx_conf':
    command => "/bin/bash -c \"nginx_ensite  ${http_conf} \"",
    path    => ["/bin", "/usr/bin", "/usr/local/bin", "/sbin"],
    require => [  Exec['nginx_ensite-install'], Service['nginx'] ],
    creates => "/etc/nginx/sites-enabled/${http_conf}",
    logoutput =>  true,
  }

  file { ['/etc/nginx/sites-enabled', '/etc/nginx/sites-available']: 
    ensure => directory,
    require => [ Package['nginx'] ],
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
  # onlyif not exists
  exec { 'create_keeper_database':
    command  => "/bin/bash -c \"\\$(mysql -s -N --user=${db['__DB_USER__']} --password=${db['__DB_PASSWORD__']} --database=keeper-db < ${seafile_root}/seafile-server-latest/seahub/keeper/keeper-db.sql)\"",
    onlyif  => "/bin/bash -c \"[ -z \\$(mysql -s -N --user=${db['__DB_USER__']} --password=${db['__DB_PASSWORD__']} -e \\\"SELECT schema_name FROM information_schema.schemata WHERE schema_name='keeper-db'\\\") ];\"",
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
    ensure          => running,
    hasrestart      => true,
    enable          => true,
    require => Package['memcached'],
  }

  service { 'nginx':
    ensure          => running,
    hasrestart      => true,
    enable          => true,
    require => [ Package['nginx'], Package['apache2'] ],
  }

  service { 'keeper':
    ensure     => running,
    enable     => true,
    hasrestart => true,
    require    => [ Service['memcached'], Service['nginx'] ], 
  }

  exec { 'restart_nginx':
    command     => '/bin/systemctl restart nginx',
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

class keeper::install::single {
  include keeper::params

  $node_props = {
    #### put here node specific settings 
    'global' => {
      '__NODE_TYPE__'   => 'SINGLE',
    },
    #'http' => {
      #'__NODE_FQDN__'   => '127.0.0.1',
      #'__SERVICE_URL__' => 'http://127.0.0.1',
      #'__SERVER_NAME__' => '127.0.0.1',
      #} 
  }

  $node_defaults = {
    'path'              => "${seafile_root}/keeper-single.ini",
    'key_val_separator' => '=',
  }


  keeper::install { 'single': 
    node_props => $node_props,  
    node_defaults => $node_defaults,
  }

}

class keeper::install::app01 {
  include keeper::params

  $node_props = {}

  $seafile_root = $keeper::params::seafile_root

  $node_defaults = {
    'path'              => "${seafile_root}/keeper-app01-qa.ini",
    'key_val_separator' => '=',
  }


  keeper::install { 'app01': 
    node_props => $node_props,  
    node_defaults => $node_defaults,
  }

}

class keeper::install::app02 {
  include keeper::params

  $seafile_root = $keeper::params::seafile_root

  #$node_props = {'global' => { '__GPFS_FILESET__' => 'keeper-fileset' } }
  $node_props = {}

  $node_defaults = {
    'path'              => "${seafile_root}/keeper-app02-qa.ini",
    'key_val_separator' => '=',
  }


  keeper::install { 'app02': 
    node_props => $node_props,  
    node_defaults => $node_defaults,
  }

}

class keeper::install::app03 {
  include keeper::params

  $seafile_root = $keeper::params::seafile_root

  #$node_props = {'global' => { '__GPFS_FILESET__' => 'keeper-fileset' } }
  $node_props = {}

  $node_defaults = {
    'path'              => "${seafile_root}/keeper-app03-qa.ini",
    'key_val_separator' => '=',
  }


  keeper::install { 'app03': 
    node_props => $node_props,  
    node_defaults => $node_defaults,
  }

}

class keeper::install::app04 {
  include keeper::params

  $seafile_root = $keeper::params::seafile_root

  #$node_props = {'global' => { '__GPFS_FILESET__' => 'keeper-fileset' } }
  $node_props = {}

  $node_defaults = {
    'path'              => "${seafile_root}/keeper-app04-qa.ini",
    'key_val_separator' => '=',
  }

  keeper::install { 'app04':
    node_props => $node_props,
    node_defaults => $node_defaults,
  }

}

class keeper::install::app05 {
  include keeper::params

  $seafile_root = $keeper::params::seafile_root

  #$node_props = {'global' => { '__GPFS_FILESET__' => 'keeper-fileset' } }
  $node_props = {}

  $node_defaults = {
    'path'              => "${seafile_root}/keeper-app05-qa.ini",
    'key_val_separator' => '=',
  }

  keeper::install { 'app05':
    node_props => $node_props,
    node_defaults => $node_defaults,
  }

}
class keeper::install::app06 {
  include keeper::params

  $seafile_root = $keeper::params::seafile_root

  #$node_props = {'global' => { '__GPFS_FILESET__' => 'keeper-fileset' } }
  $node_props = {}

  $node_defaults = {
    'path'              => "${seafile_root}/keeper-app06-qa.ini",
    'key_val_separator' => '=',
  }

  keeper::install { 'app06':
    node_props => $node_props,
    node_defaults => $node_defaults,
  }

}


class keeper::install::back {
  include keeper::params

  $seafile_root = $keeper::params::seafile_root

  $node_props = {
    'global' => { 
      '__NODE_TYPE__' => 'BACKGROUND', 
    },
    'http' => { 
      '__NODE_FQDN__' => '127.0.0.1',
    },
    'office' => { '__IS_OFFICE_CONVERTOR_NODE__' => 'true' },
  }

  $node_defaults = {
    'path'              => "${seafile_root}/keeper-app-bg02-qa.ini",
    'key_val_separator' => '=',
  }


  keeper::install { 'back': 
    node_props => $node_props,  
    node_defaults => $node_defaults,
  }

}



