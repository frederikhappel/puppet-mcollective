# Class: mcollective::params
#
#   This class provides parameters for all other classes in the mcollective
#   module.  This class should be inherited.
#
# Parameters:
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
class mcollective::params (
  $stomp_server = 'localhost',
  $stomp_port = 6163,
  $stomp_user = 'mcollective',
  $stomp_passwd = 'marionette',
  $mc_security_psk = 'changemeplease',
) {
  $cfgdir = '/etc/mcollective'
  $mc_logfile = '/var/log/mcollective.log'
  $mc_loglevel = 'warn'
  $mc_security_provider = 'psk'

  $mc_libdir = $::operatingsystem ? {
    /(?i-mx:ubuntu|debian)/ => '/usr/share/mcollective/plugins',
    default => '/usr/libexec/mcollective',
  }
}
