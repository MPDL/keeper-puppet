class keeper::test {


  # is needed for first seahub start, it will create server admin
  #  see https://github.com/haiwen/seafile-server/blob/master/scripts/check_init_admin.py#L358
  
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
    'tests'
  ]

  $props = $sections.reduce( {} ) |$memo, $sec| {
    $memo + { $sec => lookup($sec, Hash) }
  }

  #$defaults = { 
    #'path'              => '/tmp/foo.ini',
    #'key_val_separator' => '=',
  #}

  #$secure_props = deep_merge($props, 
    #{ 'db'=> {
      #'__DB_ROOT_PASSWORD__' => { 'ensure' => 'absent' } 
    #}})
  #$props['global']['__DB_ROOT_PASSWORD__'] = { 'ensure' => 'absent' }


  #create_ini_settings($secure_props , $defaults)
  #file { "/tmp/seafile-license.txt":
    #*      => $attr,
    #source  => "puppet:///keeper_files/seafile-license.txt",
    #source  => "$::environmentpath/$::environment/data/seafile-license.txt",
    #content  => "${props['global']['__SEAFILE_LICENSE__']}",
  #}


    
  #notice("Hello!!! ${settings::environmentpath}/${settings::environment}")

}

