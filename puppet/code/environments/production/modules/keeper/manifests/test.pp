class keeper::test {


  exec { "pip-from-get-pip.py":
  	command => "curl https://bootstrap.pypa.io/get-pip.py > /tmp/get-pip.py && sudo python3 /tmp/get-pip.py && rm /tmp/get-pip.py",
  	path    => ["/usr/bin", "/bin"],
  	#require => [ Package["python3"], Package["python3-setuptools"] ],
  }	
  # $hash1 = {
    # 'sec1' => {
      # 'key1' => 'val1',
      # 'key2' => 'val2',
    # },
    # 'sec2' => {
      # 'key1' => 'val1',
      # 'key2' => 'val2',
    # },
  # }
  # $hash2 = {
    # 'sec1' => {
      # 'key4' => 'val4',
      # 'key5' => 'val5',
      # 'key6' => 'val6',
    # },
    # 'sec2' => {
      # 'key2' => 'hohoho',
      # 'key4' => 'val4',
      # 'key5' => 'val5',
      # 'key6' => 'val6',
    # },
  # }
# 
# 
  # $merged = $hash1.reduce({}) |$memo, $x| {
      # $memo + {$x[0] => $hash2[$x[0]] + $hash1[$x[0]]}
  # }
# 
  # $res = deep_merge($hash1, $hash2)
  # 
  # notice("Hello!!! ${res}")



  # is needed for first seahub start, it will create server admin
  #  see https://github.com/haiwen/seafile-server/blob/master/scripts/check_init_admin.py#L358
  
  # $sections =[
    # 'global',
    # 'system',
    # 'backend',
    # 'db',
    # 'email',
    # 'background',
    # 'office',
    # 'backup',
    # 'bloxberg',
    # 'external_resources',
    # 'archiving',
    # 'doi',
    # 'branding',
    # 'http',
    # 'memcached',
    # 'logging',
    # 'tests'
  # ]
# 
  # $props = $sections.reduce( {} ) |$memo, $sec| {
    # $memo + { $sec => lookup($sec, Hash) }
  # }

  #$defaults = { 
    #'path'              => '/tmp/foo.ini',
    #'key_val_separator' => '=',
  #}

  #$secure_props = deep_merge($props, 
    # { 'db'=> {
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

  
    
  notice("Hello!!! ${settings::environmentpath}/${settings::environment}")

}
