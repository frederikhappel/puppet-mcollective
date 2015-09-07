# Class: mcollective::client::base
#
#   This class installs the MCollective client component for your nodes.
#
# Parameters:
#
#  [*version*]            - The version of the MCollective package(s) to
#                             be installed.
#  [*config*]             - The content of the MCollective client configuration
#                             file.
#  [*config_file*]        - The full path to the MCollective client
#                             configuration file.
# Actions:
#
# Requires:
#
# Sample Usage:
#
class mcollective::client (
  $stomp_server = $mcollective::params::stomp_server,
  $stomp_port = $mcollective::params::stomp_port,
  $stomp_user = $mcollective::params::stomp_user,
  $stomp_passwd = $mcollective::params::stomp_passwd,
  $mc_security_provider = $mcollective::params::mc_security_provider,
  $mc_security_psk = $mcollective::params::mc_security_psk,
  $ensure = present
) inherits mcollective::params {
  # validate parameters
  validate_string($stomp_server, $stomp_user, $stomp_passwd)
  validate_ip_port($stomp_port)
  validate_re($mc_security_provider, '^[a-zA-Z0-9_]+$')
  validate_re($mc_security_psk, '^[^ \t]+$')
  validate_re($ensure, '^(present|absent)$')

  # define variables
  $cfgfile = "${cfgdir}/client.cfg"

  # package management
  package {
    'mcollective-client':
      ensure => ensure_latest($ensure),
      before => File[$cfgfile] ;
  }

  # configure shorewall if needed
  @shorewall::rule {
    'mcollectiveClient_fw2stompserver' :
      ensure => $ensure,
      action => 'ACCEPT',
      src => 'fw',
      dst => shorewall_zonehost('all', $stomp_server),
      proto => 'tcp',
      dst_port => $stomp_port ;
  }

  file {
    $cfgfile :
      ensure => $ensure,
      content => template('mcollective/client.cfg.erb'),
      mode => '0600',
      owner => 0,
      group => 0,
  }
}
