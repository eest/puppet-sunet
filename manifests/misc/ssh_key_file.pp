define sunet::misc::ssh_key_file(
  String $public,
  String $private,
  String $user = 'root',
  Enum ['present', 'absent'] $ensure = 'present',
) {
  file {
    $name:
      owner   => $user,
      mode    => '0400',
      content => $private,
      ;
    "${name}.pub":
      owner   => $user,
      mode    => '0400',
      content => $public,
      ;
  }
}
