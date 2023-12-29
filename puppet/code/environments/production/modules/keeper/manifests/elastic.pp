# see 

class keeper::elastic (
#  $props = $keeper::params::props,
) inherits keeper::params {

 
  exec { "docker-import-key":
    command   => "install -m 0755 -d /etc/apt/keyrings && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg && chmod a+r /etc/apt/keyrings/docker.gpg",
    path      => ["/usr/bin"],
    logoutput =>  true,
  }

  exec { "docker-add-repo":
    command   => "sh -c \"echo 'deb [arch=\$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \$(. /etc/os-release && echo \"\$VERSION_CODENAME\") stable'\" | tee /etc/apt/sources.list.d/docker.list > /dev/null && apt update",
    path      => ["/usr/bin", "/bin"],
    require   => [ Exec["docker-import-key"] ],
    logoutput =>  true,
  }

  $docker_pkgs = ['docker-ce', 'docker-ce-cli', 'containerd.io', 'docker-buildx-plugin', 'docker-compose-plugin']
  package { $docker_pkgs:
    ensure => latest,
    require => [ Exec["docker-add-repo"] ],
  }
  
  exec { "pull-elastic-docker":
    command   => "docker pull elasticsearch:7.16.2",
    path      => ["/usr/bin", "/bin"],
    require   => Package[$docker_pkgs],
    logoutput =>  true,
  }


}
