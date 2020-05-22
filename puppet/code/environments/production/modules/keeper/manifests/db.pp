# puppet module install puppetlabs-apt 

class keeper::db (
  $props = $keeper::params::props,
) inherits keeper::params {

  $db = $props['db']
  $pkgs = $props['package-deps']

  include apt

  # add mariadb apt repo
  apt::source { 'mariadb':
    location => "${props['repositories']['__MARIADB__']}",
    repos    => 'main',
    release  => "${props['repositories']['__OS_RELEASE__']}",
    key      => {
      id     => "${props['repositories']['__MARIADB_KEYID__']}",
      server => "${props['repositories']['__MARIADB_KEYSERVER__']}",
    },
    include  =>  {
      'src' =>  false,
      'deb' =>  true,
    },
  }

  exec { 'apt-update':
    command  => "apt-get update",
    path     => ["/usr/bin", "/bin"],
    require => [ Apt::Source["mariadb"] ],
  }

  package { 'galera-4':
    ensure    => "${pkgs['galera-4']}",
    require   => [Exec["apt-update"]],
  }


  #include '::mysql::server'

  # puppet module install puppetlabs-mysql 
  # mariadb-server
  class { '::mysql::server':
      package_name            => 'mariadb-server',
      package_ensure          => "${pkgs['mariadb-server']}",
      service_name            => 'mysql',
      root_password           => "${db['__DB_ROOT_PASSWORD__']}",
      require                 => [Exec["apt-update"]],
  }

  #Apt::Source['mariadb'] ~>
  #Class['apt::update'] ->
  #Class['::mysql::server']

  # mariadb-client
  class {'::mysql::client':
    package_name => 'mariadb-client',
    package_ensure => "${pkgs['mariadb-client']}",
    require   => [Exec["apt-update"]],
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

  $log_bin = $db['__LOG_BIN__']
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


