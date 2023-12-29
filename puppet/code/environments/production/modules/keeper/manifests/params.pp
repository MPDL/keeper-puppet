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
    'bloxberg',
    'external_resources',
    'archiving',
    'doi',
    'branding',
    'http',
    'memcached',
    'logging',
    'release',
    'package-deps',
    'repositories'
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
      '__KEEPER_ADMIN_PASSWORD__'   => { 'ensure' => 'absent' },
    },
    'memcached' => {
      '__MEMCACHED_KA_UNICAST_PEERS__' => { 'ensure' => 'absent' },
    },
    })
  $clean_sections = (($clean_settings.delete('repositories')).delete('package-deps')).delete('release')


}
