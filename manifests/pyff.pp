define sunet::pyff($version = "latest") {
   sunet::docker_run{"pound-${name}":
      image    => "docker.sunet.se/pound",
      imagetag => "latest",
      volumes  => ["/etc/ssl:/etc/ssl"],
      env      => ["BACKEND_PORT=tcp://varnish-${name}.docker:80"],
      ports    => ["443:443"],
      start_on => "docker-varnish-${name}"
   }
   sunet::docker_run {"varnish-${name}":
      image    => 'docker.sunet.se/varnish',
      env      => ["BACKEND_PORT=tcp://pyff-${name}.docker:8080"],
      ports    => ['80:80'],
      start_on => "docker-pyff-${name}"
   }
   sunet::docker_run {"pyff-${name}":
      image     => docker.sunet..se/pyff',
      imagetag => $version,
      volumes   => ['/opt/metadata:/opt/metadata'],
      env       => ['DATADIR=/opt/metadata','LOGLEVEL=INFO']
   }
}
