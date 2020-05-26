define keeper::test_ini (
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

  ###### SEAFILE

  # set owner:group to root dir recursively
  file { "$seafile_root" :
    ensure  => directory,
    *       => $attr,
  }

  # generate keeper ini 
  create_ini_settings($node_ini, $ini_defaults)

  file { "${ini_defaults['path']}":
    *      => $attr,
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


}

class keeper::test_ini::single {
  include keeper::params

  $seafile_root = $keeper::params::seafile_root

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
    'path'              => "${seafile_root}/keeper-test_ini-single.ini",
    'key_val_separator' => '=',
  }


  keeper::test_ini { 'single': 
    node_props => $node_props,  
    node_defaults => $node_defaults,
  }

}

class keeper::test_ini::app_node {
  include keeper::params

  $seafile_root = $keeper::params::seafile_root

  $node_props = {'global' => { '__NODE_TYPE__' => 'APP' } }

  $node_defaults = {
    'path'              => "${seafile_root}/keeper-test_ini-app.ini",
    'key_val_separator' => '=',
  }

  keeper::test_ini { 'app_node':
    node_props => $node_props,
    node_defaults => $node_defaults,
  }

}


class keeper::test_ini::back {
  include keeper::params

  $seafile_root = $keeper::params::seafile_root

  $node_props = {
    'global' => { 
      '__NODE_TYPE__' => 'BACKGROUND', 
    },
    'office' => { '__IS_OFFICE_CONVERTOR_NODE__' => 'true' },
  }

  $node_defaults = {
    'path'              => "${seafile_root}/keeper-test_ini-back.ini",
    'key_val_separator' => '=',
  }


  keeper::test_ini { 'back': 
    node_props => $node_props,  
    node_defaults => $node_defaults,
  }

}



