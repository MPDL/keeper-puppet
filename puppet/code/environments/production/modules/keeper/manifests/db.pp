# puppet module install puppetlabs-apt 

define keeper::db (
  Hash $props = {},
  Hash $node_ini = {},
) {

  $db = $props['db']
  $deps = $props['package-deps']

  $ni_db = $node_ini['db']

  notice("NODE_INI from DB: ${node_ini}")

  include apt

  # add 18.04 repos for 20.04
  apt::source { 'focal-security':
    location => "http://security.ubuntu.com/ubuntu",
    repos => "main",
    release => "focal-security",
    include  =>  {
      'src' =>  false,
      'deb' =>  true,
    },
  }
  
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
    command  => "apt update",
    path     => ["/usr/bin", "/bin"],
    require => [ Apt::Source["mariadb"], Apt::Source["focal-security"]],
  }

  package { ['libssl-dev:amd64', 'libssl1.1:amd64', 'libssl1.0.0:amd64']:
    # ensure    => "latest",
    require   => [Exec["apt-update"]],
  }
  
  
  
  # include '::mysql::server'

  # puppet module install puppetlabs-mysql 
  # mariadb-server
  #class { '::mysql::server':
  #    package_name            => 'mariadb-server',
  #    package_ensure          => "${deps['mariadb_ver']}",
  #    service_name            => 'mysql',
  #    root_password           => "${db['__DB_ROOT_PASSWORD__']}",
  #    #require                 => [Package["mariadb-common"]],
  #    require                 => [Exec["apt-update"]],
  #}

  #Apt::Source['mariadb'] ~>
  #Class['apt::update'] ->
  #Class['::mysql::server']

  # mariadb-client
  #class {'::mysql::client':
  #  package_name => 'mariadb-client',
  #  package_ensure => "${deps['mariadb_ver']}",
  #  #require   => [Exec["apt-update"]],
  #  require   => [Class['::mysql::server']],
  #}

	
  $db_pkgs = ['libmariadb3:amd64', 'mysql-common', 'mariadb-common', 'mariadb-client-core', 'mariadb-client', 'mariadb-server-core', 'mariadb-server']
  $db_pkgs_string = join($db_pkgs, "=${deps['mariadb_ver']} ")

  exec { 'install_db_pkgs':
  	# command		=> "apt install $db_pkgs_string=${deps['mariadb_ver']}; apt-mark hold ${p}",
  	command		=> "/usr/bin/apt install -y --allow-downgrades $db_pkgs_string=${deps['mariadb_ver']}",
    # require   => [Class['::mysql::server']],
    require   => Exec['apt-update'],
 		logoutput	=>  true,
  }  
  
  each($db_pkgs) |$p| {
    exec { "hold_${p}":
   		command		=> "/usr/bin/apt-mark hold ${p}",
   		require		=> Exec['install_db_pkgs'],
   		logoutput	=>  true,
    }
  }

  notice("${deps['galera-4_ver']}")
  exec { 'galera-4':
    command    => "/usr/bin/apt install galera-4=${deps['galera-4_ver']}; apt-mark hold galera-4",
    require   => Exec['install_db_pkgs'],
  }

  #Apt::Source['mariadb'] ~>
  #Class['apt::update'] ->
  #Class['::mysql::client']

  service { 'mariadb':
    ensure          => running,
    hasrestart      => true,
    enable          => true,
    require         => Exec['install_db_pkgs'],
  }


  # seafile dbs 
  mysql::db { ['ccnet-db', 'seafile-db', 'seahub-db'] :
    user     => "${ni_db['__DB_USER__']}",
    password => "${ni_db['__DB_PASSWORD__']}",
    host     => 'localhost',
    charset  => 'utf8',
    grant    => ['ALL'],
    require  => Service['mariadb'],
  }

  # keeper db
  mysql::db { 'keeper-db':
    user     => "${ni_db['__DB_USER__']}",
    password => "${ni_db['__DB_PASSWORD__']}",
    host     => 'localhost',
    charset  => 'utf8',
    grant    => ['ALL'],
    require  => Service['mariadb'],
  }

  exec { 'set_log_bin_trust_function_creators':
    command  => "mysql --user=root --password=${db['__DB_ROOT_PASSWORD__']} -e \"SET GLOBAL log_bin_trust_function_creators = 1;\"",
    path     => ["/usr/bin", "/bin"],
    require => Exec['install_db_pkgs'],
  }


  $log_bin_dir = $ni_db['__LOG_BIN__']
  # create bin log dir
  exec { "create_${log_bin_dir}":
    command => "mkdir -p ${log_bin_dir} && chown mysql:mysql ${log_bin_dir}",
    path    => ["/bin", "/usr/bin", "/usr/local/bin", "/sbin"],
    creates => "${log_bin_dir}",
    # require => [ Class['::mysql::server'] ]
    require => [ Exec['install_db_pkgs'] ]
  }


}
