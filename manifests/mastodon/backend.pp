# mastodon web server
class sunet::mastodon::backend(
  String $db_name                  = 'postgres',
  String $db_user                  = 'postgres',
) {
  # Must set in hiera eyaml
  $db_pass=safe_hiera('db_pass')
  $redis_pass=safe_hiera('redis_pass')


  # Composefile
  sunet::docker_compose { 'mastodon_backend':
    content          => template('sunet/mastodon/backend/docker-compose.yml.erb'),
    service_name     => 'mastodon_backend',
    compose_dir      => '/opt',
    compose_filename => 'docker-compose.yml',
    description      => 'Mastodon backend services',
  }
  file { "/opt/mastodon_backend/redis":
    ensure => directory,
  }

  file { "/opt/mastodon_backend/postgres":
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0751',
  }
  file { '/opt/mastodon_backend/redis/server.conf':
    ensure  => file,
    content => template('sunet/mastodon/backend/redis.conf.erb'),
  }
  sunet::misc::ufw_allow { 'backend_ports':
     from => 'any',
     port => ['5432', '6379']
  }
}
