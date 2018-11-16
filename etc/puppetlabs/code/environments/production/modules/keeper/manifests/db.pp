# puppet module install puppetlabs-apt 
include apt
include mysql

class keeper::db (
  $props = $keeper::params::props,
) inherits keeper::params {

  $db = $props['db']
  $pkgs = $props['package-deps']

  package { 'galera-3':
    ensure => "${pkgs['galera-3']}",
  }

  # add mariadb apt repo
  apt::source { 'mariadb':
    location => "${props['apt-locations']['mariadb']}",
    repos    => 'main',
    release  => 'jessie',
    key      => {
      id     => '199369E5404BD5FC7D2FE43BCBCB082A1BB943DB',
      server => 'hkp://keyserver.ubuntu.com:80',
    },
    include  =>  {
      'src' =>  false,
      'deb' =>  true,
    },
  }


  # puppet module install puppetlabs-mysql 
  # mariadb-server
  class { '::mysql::server':
      package_name            => 'mariadb-server',
      package_ensure          => "${pkgs['mariadb-server']}",
      service_name            => 'mysql',
      root_password           => "${db['__DB_ROOT_PASSWORD__']}",
  }

  #Apt::Source['mariadb'] ~>
  #Class['apt::update'] ->
  #Class['::mysql::server']

  # mariadb-client
  class {'::mysql::client':
    package_name => 'mariadb-client',
    package_ensure => "${pkgs['mariadb-client']}",
  }

  #Apt::Source['mariadb'] ~>
  #Class['apt::update'] ->
  #Class['::mysql::client']

  # seafile dbs 
  mysql::db { ['ccnet-db', 'seafile-db', 'seahub-db'] :
    user     => "${db['__DB_USER__']}",
    password => "${db['__DB_PASSWORD__']}",
    host     => 'localhost',
    charset  => 'utf8',
    grant    => ['ALL'],
  }

  # keeper db
  mysql::db { 'keeper-db':
    user     => "${db['__DB_USER__']}",
    password => "${db['__DB_PASSWORD__']}",
    host     => 'localhost',
    charset  => 'utf8',
    grant    => ['ALL'],
  }

  $log_bin = $db['__LOG_BIN_DIR__']
  # create bin log dir
  exec { "create_${log_bin}":
    command => "mkdir -p ${log_bin}",
    path    => ["/bin", "/usr/bin", "/usr/local/bin", "/sbin"],
    creates => "${log_bin}",
    require => [ Class['::mysql::server'] ]
  }

  file { "${log_bin}":
    ensure  => directory,
    owner   => 'mysql',
    group   => 'mysql',
    require => [ Exec["create_${log_bin}"] ]
  }


}


