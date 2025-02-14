# SUNET Inventory Service
class sunet::invent(
  String  $invent_dir            = '/opt/invent',
  Integer $invent_retention_days = 30,
) {
  $host_os = String($::facts['operatingsystem'], "%d")
  $awk = $host_os ? {
    alpine => 'gawk',
    default => 'awk',
  }
  $script_dir = "${invent_dir}/scripts"

  file { $invent_dir:
    ensure => directory,
  }
  -> file { $script_dir:
    ensure => directory,
  }
  -> file { "${script_dir}/invent.sh":
    content => template('sunet/invent/invent.sh.erb'),
    mode    => '0700',
  }
  -> sunet::scriptherder::cronjob { 'inventory':
    cmd      => "${script_dir}/invent.sh",
    job_name => 'gather_inventory',
    user     => 'root',         
    minute   =>  '*/10',          
  }
}
