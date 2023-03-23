# puppet module install puppetlabs-apt 

class keeper::db (
  $props = $keeper::params::props,
) inherits keeper::params {

  $db = $props['db']
  $deps = $props['package-deps']

  include apt

  # add 18.04 repos for 20.04
  apt::source { 'bionic-security':
    location => "http://security.ubuntu.com/ubuntu",
    repos => "main",
    release => "bionic-security",
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
    require => [ Apt::Source["mariadb"], Apt::Source["bionic-security"]],
  }


  package { ['libssl1.0-dev', 'libssl1.0.0']:
    # ensure    => "latest",
    require   => [Exec["apt-update"]],
  }
  
  
  
  # include '::mysql::server'

  # puppet module install puppetlabs-mysql 
  # mariadb-server
  class { '::mysql::server':
      package_name            => 'mariadb-server-10.4',
      package_ensure          => "${deps['mariadb_ver']}",
      service_name            => 'mysql',
      root_password           => "${db['__DB_ROOT_PASSWORD__']}",
      #require                 => [Package["mariadb-common"]],
      require                 => [Exec["apt-update"]],
  }

  #Apt::Source['mariadb'] ~>
  #Class['apt::update'] ->
  #Class['::mysql::server']

  # mariadb-client
  class {'::mysql::client':
    package_name => 'mariadb-client-10.4',
    package_ensure => "${deps['mariadb_ver']}",
    #require   => [Exec["apt-update"]],
    require   => [Class['::mysql::server']],
  }

	
  $forced_packages_1 = ['libmariadb3:amd64', 'mysql-common', 'mariadb-common']
  package { $forced_packages_1:
    ensure    => "${deps['mariadb_ver']}",
    require   => [Class['::mysql::server']],
  }

	# strictly install and hold versions to 10.4.17, never versions deadly block galera cluster due to not fixed bug (2022-12-16)!
  $forced_packages_2 = ["mariadb-server-core-10.4", "mariadb-client-core-10.4", "mariadb-client-10.4", "mariadb-client", "mariadb-server-10.4"]
  each($forced_packages_2) |$p| {
    exec { "force-and-hold-10.4.17_${p}":
   		command		=> "apt install ${p}=${deps['mariadb_ver']}; apt-mark hold ${p}",
   		#command		=> "apt install ${p}=${deps[mariadb_ver]} -y && apt-mark hold ${p}",
		path		=> ["/usr/bin"],
   		require		=> [ Package['mariadb-common'] ],
   		logoutput	=>  true,
    }
  }
  
  each($forced_packages_1) |$p| {
    exec { "hold-10.4.17_${p}":
   		command		=> "apt-mark hold ${p}",
		path		=> ["/usr/bin"],
   		require		=> [Exec["force-and-hold-10.4.17_${forced_packages_2[-1]}"]],
   		logoutput	=>  true,
    }
  }

  notice("${deps['galera-4_ver']}")
  exec { 'galera-4':
    ensure    => "apt install galera-4=${deps['galera-4_ver']}; apt-mark hold galera-4",
    path		=> ["/usr/bin"],
    require   => [Exec["apt-update"], Package['mariadb-common']],
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

  $log_bin_dir = $db['__LOG_BIN__']
  # create bin log dir
  exec { "create_${log_bin_dir}":
    command => "mkdir -p ${log_bin_dir} && chown mysql:mysql ${log_bin_dir}",
    path    => ["/bin", "/usr/bin", "/usr/local/bin", "/sbin"],
    creates => "${log_bin_dir}",
    require => [ Class['::mysql::server'] ]
  }

  # restart nginx with new updated confs
  #exec { 'stop_maridb':
  #  command => '/bin/systemctl stop mariadb',
  #  require => [ Class['::mysql::server'] ]
  #}
  # file { "${log_bin_dir}":
  #   owner   => 'mysql',
  #   group   => 'mysql',
  #   require => [ Exec["create_${log_bin_dir}"] ]
  # }

}
