class sunet::fticks($ensure=present,$url=undef,$args='',$pipe='/dev/fticks') {
   ensure_resource(service,'rsyslog',{ensure=>running})
   $_ensure_file = $ensure ? {
       'present'   => 'file',
       'absent'    => 'absent'
   }
   $_ensure_service = $ensure ? {
       'present'   => 'running',
       'absent'    => 'absent'
   }
   sunet::remote_file{'/usr/sbin/fticks':
       mode            => '0755',
       ensure          => $_ensure_file,
       remote_location => 'https://raw.githubusercontent.com/SUNET/flog/master/scripts/fticks.py'
   }
   file {'/etc/systemd/system/fticks.service':
       ensure          => $_ensure_file,
       content         => template('sunet/fticks/fticks.service.erb')
   }
   file {'/etc/rsyslog.d/70-sunet-fticks-pipe.conf':
       ensure          => $_ensure_file,
       content         => inline_template(":rawmsg,contains,"F-TICKS" |$pipe")
       notify          => Service['rsyslog']
   }
   service {'fticks':
      ensure           => $_ensure_service
   }
}
