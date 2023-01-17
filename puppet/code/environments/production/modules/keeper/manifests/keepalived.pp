# install keepalived

class keeper::keepalived (
  $props = $keeper::params::props,
) inherits keeper::params {


  $ka_ver = $props['package-deps']['keepalived_ver']

  package { "keepalived":
      ensure => "$ka_ver",
  }

  group { "keepalived_script":
    ensure => present,
    require => Package["keepalived"],
  }

  exec { "ka-keepalived_script-user":
    command   => "useradd -r -s /sbin/nologin -g keepalived_script -M keepalived_script",
    onlyif => "/bin/bash -c \"[[ ! \\$(/usr/bin/id -u keepalived_script) ]]\"",
    path      => ["/usr/sbin"],
    require   => [ Group["keepalived_script"] ],
    logoutput =>  true,
  }

  file { "/var/run/keepalived.state":
    ensure => present,
    owner => "keepalived_script",
    group => "keepalived_script",
    require => [ Group["keepalived_script"], Exec["ka-keepalived_script-user"] ],
  }

}
