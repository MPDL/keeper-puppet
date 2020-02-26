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
){

  include keeper::params 

  $seafile_root = $keeper::params::seafile_root 
  $seafile_ver = $keeper::params::seafile_ver 
  $attr = $keeper::params::attr 
  $ini_defaults = $keeper::params::defaults
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


  #### MODULES
  # install debian modules
  $deb_modules = [
    "lsb-release",
    "build-essential",
    "git-core",
    #"openjdk-7-jre",
    "openjdk-8-jre",
    "python2.7",
    "poppler-utils",
    #"python-imaging",
    "python-pil",
    "python-mysqldb", 
    "python-memcache",
    "python-ldap",
    "python-urllib3",
    "clamav",
    "gettext",
    "python-dev",
    "memcached",
    "libmemcached-dev",
    "zlib1g-dev",
    "python-netaddr",
    "python-templayer",
    "python-pyrex",
    "python-chardet",
    "python-wstools",
    "libfreetype6-dev",
    "monitoring-plugins",
    # keeper 
    "python-apt",
    "python-debian",
    "python-debianbts",
    "python-defusedxml", 
    "python-soappy",
    "libffi-dev",
    "libssl-dev",
    "libldap2-dev",
    "libmysqlclient-dev",
    ]      
  package { $deb_modules:
    ensure => latest,
  }

  # install easy_install 
  package { "python-setuptools":
    ensure => latest,
  }

  # install pip      
  exec { "python-pip":
    command => "python /usr/lib/python2.7/dist-packages/easy_install.py pip",
    path    => ["/usr/bin", "/usr/local/bin", "/sbin"],
    require => Package["python-setuptools"],
    creates => '/usr/local/bin/pip',
    logoutput =>  true,
  }

  # install seafile pip modules
  $pip_modules = ["boto", "requests", "pylibmc", "django-pylibmc", ]     
  each($pip_modules) |$m| {
    exec { "pip-${m}":
      command => "pip install ${m}",
      path    => ["/usr/bin", "/usr/local/bin", "/sbin"],
      require => Exec["python-pip"],
      unless  => "pip show ${m}",
      logoutput =>  true,
    }
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



  # should be set for correct work of document preview 
  file { "/run/tmp":
    ensure  => directory,
    mode    => '1777',
  }

  file { "${props['archiving']['__LOCAL_STORAGE__']}":
    ensure => 'directory',
    mode   => '1777',
  }

  # install seafile for mysql in non-interactive mode 
  # see https://manual.seafile.com/deploy/using_mysql.html#setup-in-non-interactive-way
  # NOTE: DBs have been already created in mariadb.pp!!!
  exec { 'setup-seafile-mysql.sh':
    command      => "setup-seafile-mysql.sh auto -n ${props['http']['__SERVER_NAME__']} -i ${props['http']['__NODE_FQDN__']} -d ${seafile_root}/seafile-data -e 1 -t ${db['__DB_PORT__']} -u ${db['__DB_USER__']} -w ${db['__DB_PASSWORD__']} -c ccnet-db -s seafile-db -b seahub-db",
    path         => ["${seafile_root}/${seafile_ver}", "/usr/bin", "/usr/local/bin", "/bin"],
    cwd          => "${seafile_root}/${seafile_ver}",
    creates      => "${seafile_root}/seafile-data",
    require => [ Archive["${seafile_arch}"] ],
    logoutput =>  true,
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

  file { "${seafile_root}/seafile-data" :
    ensure  => directory,
    *       => $attr,
    require => Exec['setup-seafile-mysql.sh'] ,
  }

  #### KEEPER

  # checkout from github repo, tagged version  
  vcsrepo { "${seafile_root}/KEEPER":
    ensure   => present,
    provider => git,
    source   => 'https://github.com/MPDL/KEEPER.git',
    revision => "${props['release']['__GIT_REVISION__']}",
  }

  $keeper_ext = "${seafile_root}/KEEPER/seafile_keeper_ext"

  # install keeper pip modules with versions from list
  exec { "keeper-pip-modules":
    command => "pip install -r ${settings::environmentpath}/${settings::environment}/data/keeper_files/pip-reqs.txt",
    path    => ["/bin", "/usr/bin", "/usr/local/bin", "/sbin"],
    require => [ Exec["python-pip"] ],
  }

  $http_conf = $props['http']['__HTTP_CONF__']
  #exec { 'enable_keeper_nginx_conf':
    #command => "/bin/bash -c \"nginx_ensite  ${http_conf} \"",
    #path    => ["/bin", "/usr/bin", "/usr/local/bin", "/sbin"],
    #require => [  Exec['nginx_ensite-install'], Service['nginx'] ],
    #creates => "/etc/nginx/sites-enabled/${http_conf}",
    #logoutput =>  true,
  #}

  file { '/etc/nginx/sites-enabled': 
    ensure => directory,
    require => [ Package['nginx'] ],
  }

  file { "/etc/nginx/sites-enabled/${http_conf}":
    ensure  => link,
    target  => "/etc/nginx/sites-available/${http_conf}",
    require => File['/etc/nginx/sites-enabled'],
  }

  # deploy KEEPER
  file { "${keeper_ext}/build.py":
    mode      => '0755',
  }
  exec { "keeper-deploy-all":
    command   => "./build.py deploy --all -y",
    path      => ["${keeper_ext}", "${seafile_root}/seafile-server-latest/seahub", "/bin", "/usr/bin", "/usr/local/bin", "/sbin", ],
    cwd       => "${keeper_ext}",
    require   => [ Exec["keeper-pip-modules"], Exec['setup-seafile-mysql.sh'], Vcsrepo["${seafile_root}/KEEPER"], Package['nginx'] ],
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

  # create mysql keeper tables
  exec { 'create_keeper_tables':
    command  => "/bin/bash -c \"\\$(mysql -s -N --user=${db['__DB_USER__']} --password=${db['__DB_PASSWORD__']} --database=keeper-db < ${seafile_root}/seafile-server-latest/seahub/keeper/keeper-db.sql)\"",
    path     => ["/usr/bin", "/bin"],
    require => [ Mysql::Db['keeper-db'], Exec['keeper-deploy-all'] ],
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
    require => [ Package['nginx'] ],
  }


  service { 'keeper':
    ensure     => running,
    enable     => true,
    hasrestart => true,
    require    => [ Service['memcached'], Service['nginx'], Service['mysqld'] ], 
  }

  exec { 'restart_nginx':
    command     => '/bin/systemctl restart nginx',
    require     => Service['keeper']
  }

  # remove python3 
  $python3 = [
    "python3",
    "python3-minimal",
    "python3.6",
    "python3.6-minimal",
    "distro-info-data",
    "libpython3-stdlib",
  ]
  package { $python3:
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

  keeper::install { 'single': 
    node_props => $node_props,  
  }

}

class keeper::install::app01 {
  include keeper::params

  $node_props = {}

  keeper::install { 'app01': 
    node_props => $node_props,  
  }

}
class keeper::install::app02 {
  include keeper::params

  #$node_props = {'global' => { '__GPFS_FILESET__' => 'keeper-fileset' } }
  $node_props = {}

  keeper::install { 'app02': 
    node_props => $node_props,  
  }

}
class keeper::install::app03 {
  include keeper::params

  #$node_props = {'global' => { '__GPFS_FILESET__' => 'keeper-fileset' } }
  $node_props = {}

  keeper::install { 'app03': 
    node_props => $node_props,  
  }

}

class keeper::install::back {
  include keeper::params

  $node_props = {
    'global' => { 
      '__NODE_TYPE__' => 'BACKGROUND', 
    },
    'http' => { 
      '__NODE_FQDN__' => '127.0.0.1',
    },
    'office' => { '__IS_OFFICE_CONVERTOR_NODE__' => 'true' },
  }

  keeper::install { 'back': 
    node_props => $node_props,  
  }

}

