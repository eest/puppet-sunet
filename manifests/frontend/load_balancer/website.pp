# New kind of website with one docker-compose setup per website
define sunet::frontend::load_balancer::website(
  Hash $config
) {
  # 'export' config to a file
  file {
    "${confdir}/${name}":
      ensure  => 'directory',
      group   => 'sunetfrontend',
      mode    => '0750',
      ;
    "${confdir}/${name}/config.yml":
      ensure  => 'file',
      group   => 'sunetfrontend',
      mode    => '0640',
      content => inline_template("# File created from Hiera by Puppet\n<%= @config.to_yaml %>\n"),
      ;
  }
}