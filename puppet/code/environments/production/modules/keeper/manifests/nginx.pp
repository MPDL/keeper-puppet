# see http://nginx.org/en/linux_packages.html#Ubuntu

class keeper::nginx (
  $props = $keeper::params::props,
) inherits keeper::params {


  $nx_release = $props['package-deps']['nginx_release']
  $nx_ver = $props['package-deps']['nginx_ver']

  $deps = [
    "curl",
    "gnupg2",
    "ca-certificates",
    "lsb-release",
    "debian-archive-keyring",
  ]
  package { $deps:
      ensure => latest,
  }
  
  exec { "nx-import-key":
    command   => "curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor | sudo tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null",
    path      => ["/usr/bin"],
    require   => [ Package["curl"], Package["gnupg2"] ],
    logoutput =>  true,
  }

  exec { "nx-add-repo":
    command   => "sh -c \"echo 'deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] http://nginx.org/packages/mainline/ubuntu ${nx_release} nginx'\" | sudo tee /etc/apt/sources.list.d/nginx.list",
    path      => ["/usr/bin", "/bin"],
    require   => [ Exec["nx-import-key"] ],
    logoutput =>  true,
  }

  exec { "nx-pin-ver":
    command   => "sh -c \"echo 'Package: *\\nPin: origin nginx.org\\nPin: release o=nginx\\nPin-Priority: 900\\n'\" | sudo tee /etc/apt/preferences.d/99nginx",
    path      => ["/usr/bin", "/bin"],
    require   => [ Exec["nx-add-repo"] ],
    logoutput =>  true,
  }

  exec { 'nx-apt-update':
    command  => "apt update",
    path     => ["/usr/bin"],
    require => [ Exec["nx-add-repo"], Exec["nx-pin-ver"] ],
  }

  package { "nginx":
    ensure => "${nx_ver}~${nx_release}",
    require => Exec["nx-apt-update"]
  }
  
	# NGINX
  # include apt
  # add nginx apt repo
  # apt::source { 'nginx_repo':
    # location => "${props['repositories']['__NGINX__']}",
    # repos    => 'nginx',
    # release  => "${props['repositories']['__OS_RELEASE__']}",
    # key      => {
      # id     => "${props['repositories']['__NGINX_KEYID__']}",
      # source => "${props['repositories']['__NGINX_KEYSERVER__']}"
    # },
    # include  =>  {
      # 'src' =>  false,
      # 'deb' =>  true,
    # },
  # }
  # nginx
  # package { 'nginx':
    # ensure  => "${pkgs['nginx']}",
    # require => [ Apt::Source['nginx_repo'], Class['apt::update'] ]
  # }

  ######### OR
  # install nginx-mainline stable version
  # class{ 'nginx':
     # manage_repo => false,
     # confd_only => false,
     # package_source => 'nginx-mainline',
     # service_ensure => stopped,
  # }

}
