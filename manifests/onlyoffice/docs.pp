# OnlyOffice document server
define sunet::onlyoffice::docs(
  String            $amqp_server      = 'localhost',
  String            $amqp_type        = 'rabbitmq',
  String            $amqp_user        = 'sunet',
  String            $basedir          = "/opt/onlyoffice/docs/${name}",
  String            $contact_mail     = 'noc@sunet.se',
  String            $db_host          = undef,
  String            $db_name          = 'onlyoffice',
  String            $db_type          = 'mariadb',
  String            $db_user          = 'onlyoffice',
  String            $docker_image     = 'onlyoffice/documentserver',
  String            $docker_tag       = 'latest',
  Array[String]     $dns              = [],
  Optional[String]  $external_network = undef,
  String            $hostname         = $::fqdn,
  Enum['yes', 'no'] $letsencrypt      = 'no',
  Integer           $port             = 80,
  String            $redis_host       = undef,
  Integer           $redis_port       = 6379,
  Integer           $tls_port         = 443,
  ) {

  sunet::misc::ufw_allow { 'web_ports':
    from => 'any',
    port => [$port, $tls_port, 8000],
  }
  sunet::system_user {'ds': username => 'ds', group => 'ds' }
  $amqp_secret = safe_hiera('amqp_password',undef)
  $amqp_env = $amqp_secret ? {
    undef   => [],
    default => ["AMQP_TYPE=${amqp_type}","AMQP_URI=amqp://${amqp_user}:${amqp_secret}@${amqp_server}:5672"]
  }

  $db_pwd = safe_hiera('mysql_user_password',undef)

  $db_env = ["DB_HOST=${db_host}","DB_NAME=${db_name}","DB_USER=${db_user}","DB_TYPE=${db_type}"]
  $db_pwd_env = $db_pwd ? {
    undef   => [],
    default => ["DB_PWD=${db_pwd}"]
  }

  $jwt_secret = safe_hiera('document_jwt_key',undef)
  $jwt_env = $jwt_secret ? {
    undef   => [],
    default => ['JWT_ENABLED=true',"JWT_SECRET=${jwt_secret}"]
  }

  $le_env = $letsencrypt ? {
    'no'    => [],
    default => ["LETS_ENCRYPT_DOMAIN=${hostname}","LETS_ENCRYPT_MAIL=${contact_mail}"]
  }

  $redis_secret = safe_hiera('redis_host_password',undef)
  $redis_env = $redis_secret ? {
    undef   => [],
    default => ['REDIS_ENABLED=true',"REDIS_SERVER_HOST=${redis_host}","REDIS_SERVER_PASSWORD=${redis_secret}","REDIS_SERVER_PORT=${redis_port}"]
  }
  $s3_secret = safe_hiera('s3_secret',undef)
  $s3_key = safe_hiera('s3_key',undef)
  $s3_endpoint = safe_hiera('s3_host','s3.sto4.safedc.net')
  $s3_config = base64('encode',"[document-share]\ntype = s3\nprovider = Ceph\naccess_key_id = ${s3_key}\nsecret_access_key = ${s3_secret}\nendpoint = ${s3_endpoint}\nacl = private")

  exec {"${name}_s3plugin_install":
    command => '/usr/bin/docker plugin install sapk/plugin-rclone --grant-all-permissions',
    unless  => '/usr/bin/docker plugin ls | grep sapk/plugin-rclone'
  }

  $ds_environment = flatten([$amqp_env,$db_env,$db_pwd_env,$jwt_env,$le_env,$redis_env])
  exec {"${name}_mkdir_basedir":
    command => "mkdir -p ${basedir}",
    unless  => "/usr/bin/test -d ${basedir}"
  }
  #  -> exec {"${name}_create_key":
  #  command => "/usr/bin/openssl genrsa -out ${basedir}/data/certs/onlyoffice.key 2048",
  #  unless  => "/usr/bin/test -s ${basedir}/data/certs/onlyoffice.key"
  # }
  #  -> exec {"${name}_create_csr":
  #  command => "/usr/bin/openssl req -new -key ${basedir}/data/certs/onlyoffice.key -out ${basedir}/data/certs/onlyoffice.csr -subj '/C=SE/ST=Stockholm/L=Stockholm/O=SUNET/OU=Drive Team/CN=document.drive.sunet.se'",
  #  unless  => "/usr/bin/test -s ${basedir}/data/certs/onlyoffice.csr"
  #}
  #  -> exec {"${name}_create_crt":
  #  command => "/usr/bin/openssl x509 -req -days 3650 -signkey ${basedir}/data/certs/onlyoffice.key -in ${basedir}/data/certs/onlyoffice.csr -out ${basedir}/data/certs/onlyoffice.crt",
  #   unless  => "/usr/bin/test -s ${basedir}/data/certs/onlyoffice.crt"
  # }
  # -> exec {"${name}_create_dhparam":
  #  command => "/usr/bin/openssl dhparam -out ${basedir}/data/certs/dhparam.pem 2048",
  #  unless  => "/usr/bin/test -s ${basedir}/data/certs/dhparam.pem"
  #}
  -> sunet::docker_compose { $name:
    content          => template('sunet/onlyoffice/docker-compose.yml.erb'),
    service_name     => 'onlyoffice',
    compose_dir      => '/opt/',
    compose_filename => 'docker-compose.yml',
    description      => 'OnlyOffice Document Server',
  }
  -> file { "${basedir}/run-document-server.sh":
    ensure  => file,
    mode    => '0755',
    content => template('sunet/onlyoffice/run-document-server.sh.erb'),
  }
  -> file {[$basedir,"${basedir}/logs","${basedir}/data","${basedir}/data/certs",
  "${basedir}/lib"]: ensure => directory }
}
