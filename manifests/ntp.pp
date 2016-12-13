# Install and configure NTP service
class sunet::ntp(
  $disable_pool_ntp_org = false,
  $add_servers = [],
) {
   package { 'ntp': ensure => 'latest' }
   service { 'ntp':
      name       => 'ntp',
      ensure     => running,
      enable     => true,
      hasrestart => true,
      require => Package['ntp'],
   }

   if $disable_pool_ntp_org {
     # Don't use pool.ntp.org servers, but rather DHCP provided NTP servers
     sunet::snippets::file_line { 'no_pool_ntp_org_servers':
       ensure      => 'comment',
       filename    => '/etc/ntp.conf',
       line        => '^server .*\.pool\.ntp\.org',
       notify      => Service['ntp'],
     }
     sunet::snippets::file_line { 'no_pool_ntp_org_servers2':
       ensure      => 'comment',
       filename    => '/etc/ntp.conf',
       line        => '^pool .*\.pool\.ntp\.org',
       notify      => Service['ntp'],
     }
     sunet::snippets::file_line { 'no_pool_ntp_org_servers3':
       ensure      => 'comment',
       filename    => '/etc/ntp.conf',
       line        => '^pool ntp\.ubuntu\.',
       notify      => Service['ntp'],
     }
   }

   each($add_servers) |$server| {
     sunet::snippets::file_line { "ntp_add_server_${server}":
       filename    => '/etc/ntp.conf',
       line        => "server ${server} iburst",
       notify      => Service['ntp'],
     }
   }
}
