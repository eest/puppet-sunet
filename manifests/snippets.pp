define sunet::snippets::ethernet_bonding() {
  # Set up prerequisites for Ethernet LACP bonding of eth0 and eth1,
  # for all physical hosts that are running Ubuntu.
  #
  # Bonding requires setup in /etc/network/interfaces as well.
  #
  if $::is_virtual == 'false' and $::operatingsystem == 'Ubuntu' {
    if $::operatingsystemrelease <= '12.04' {
      package {'ifenslave': ensure => 'present' }
    } else {
      package {'ifenslave-2.6': ensure => 'present' }
    }

    sunet::snippets::file_line { 'load_module_at_boot':
      filename => '/etc/modules',
      line     => 'bonding',
    }
  }
}

define sunet::snippets::encrypted_swap() {

  package { 'ecryptfs-utils':
    ensure => 'installed'
  } ->

  exec {'sunet_ecryptfs_setup_swap':
    command => '/usr/bin/ecryptfs-setup-swap -f',
    onlyif  => 'grep swap /etc/fstab | grep -ve ^# -e cryptswap | grep -q swap',
    path    => ['/usr/local/sbin', '/usr/local/bin', '/usr/sbin', '/usr/bin', '/sbin', '/bin', ],
  }

}

# Add a user to a group
define sunet::snippets::add_user_to_group($username, $group) {
  exec {"add_user_${username}_to_group_${group}_exec":
    command => "adduser --quiet $username $group",
    path    => ['/usr/local/sbin', '/usr/local/bin', '/usr/sbin', '/usr/bin', '/sbin', '/bin', ],
  }
}

# from http://projects.puppetlabs.com/projects/puppet/wiki/Simple_Text_Patterns/5
define sunet::snippets::file_line($filename, $line, $ensure = 'present') {
  case $ensure {
    default : { err ( "unknown ensure value ${ensure}" ) }
    present: {
      exec { "/bin/echo '${line}' >> '${filename}'":
        unless => "/bin/grep -qFx '${line}' '${filename}'"
      }
    }
    absent: {
      exec { "/usr/bin/perl -ni -e 'print unless /^\\Q${line}\\E\$/' '${filename}'":
        onlyif => "/bin/grep -qFx '${line}' '${filename}'"
      }
    }
    uncomment: {
      exec { "/bin/sed -i -e'/${line}/s/^#\\+//' '${filename}'":
        onlyif => "/bin/grep '${line}' '${filename}' | /bin/grep '^#' | /usr/bin/wc -l"
      }
    }
    comment: {
      exec { "/bin/sed -i -e'/${line}/s/^\\(.\\+\\)$/#\\1/' '${filename}'":
        onlyif => "/usr/bin/test `/bin/grep '${line}' '${filename}' | /bin/grep -v '^#' | /usr/bin/wc -l` -ne 0"
      }
    }
  }
}

# Disable IPv6 privacy extensions on servers. Complicates troubleshooting.
define sunet::snippets::disable_ipv6_privacy() {
  augeas { 'server_ipv6_privacy_config':
    context => '/files/etc/sysctl.d/10-ipv6-privacy.conf',
    changes => [
                'set net.ipv6.conf.all.use_tempaddr 0',
                'set net.ipv6.conf.default.use_tempaddr 0',
                ],
    notify => Exec['reload_sysctl_10-ipv6-privacy.conf'],
  }

  exec { 'reload_sysctl_10-ipv6-privacy.conf':
    command     => '/sbin/sysctl -p /etc/sysctl.d/10-ipv6-privacy.conf',
    refreshonly => true,
  }
}

# Set up scriptherder. XXX scriptherder is not *installed* here. Figure out how to.
define sunet::snippets::scriptherder() {
  $scriptherder_dir = '/var/cache/scriptherder'

  file { $scriptherder_dir:
    ensure  => 'directory',
    mode    => '1777',    # like /tmp, so user-cronjobs can also use scriptherder
  }

  # Remove scriptherder data older than 7 days.
  cron { 'scriptherder_cleanup':
    command  => "test -d ${scriptherder_dir} && (find ${scriptherder_dir} -type f -mtime +7 -print0 | xargs -0 rm -f)",
    user     => 'root',
    special  => 'daily',
  }

  # remove old cronjob maintained outside of puppet
  file { '/etc/cron.daily/scriptherder_cleanup':
    ensure   => 'absent',
  }
}

define sunet::snippets::no_icmp_redirects($order=10) {
   $cfg = "/etc/sysctl.d/${order}_${title}.conf";
   file { "${cfg}":
      ensure      => file,
      content     => "net.ipv4.conf.all.accept_redirects = 0\nnet.ipv6.conf.all.accept_redirects = 0\nnet.ipv4.conf.all.send_redirects = 0",
      notify      => Exec["refresh-sysctl-${title}"]
   }
   exec {"refresh-sysctl-${title}":
      command     => "sysctl -p ${cfg}", 
      refreshonly => true
   }
}

define sunet::snippets::secret_file(
  $hiera_key = undef,
  $path      = undef,
  $owner     = root,
  $group     = root,
  $mode      = '0400'
) {
  $data = hiera($hiera_key)
  file { $path:
    owner    => $owner,
    group    => $group,
    mode     => $mode,
    content  => inline_template("<%= @data %>")
  }
}