class keeper::params {

  $sections =[ 
    'global', 
    'system',
    'backend',  
    'db',
    'email', 
    'background', 
    'office',
    'backup',
    'branding',
    'http',
    'memcached',
    'logging',
    'release',
    'package-deps',
    'apt-locations',
  ]

  $props = $sections.reduce( {} ) |$memo, $sec| {
    $memo + { $sec => lookup($sec, Hash) }
  }

  $seafile_root = $props['global']['__SEAFILE_DIR__'] 
  $seafile_ver = $props['global']['__SEAFILE_SERVER_LATEST_DIR__']

  $defaults = { 
    'path'              => "${seafile_root}/keeper.ini",
    'key_val_separator' => '=',
  }

  $attr = {
    'owner' => "${props['system']['__OS_USER__']}",
    'group' => "${props['system']['__OS_GROUP__']}",
  }


}
