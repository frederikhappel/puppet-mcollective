# Class: mcollective::server::params
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
class mcollective::server::params (
  $enterprise = false,
) inherits mcollective::params {
  # validate parameters
  validate_bool($enterprise)

  # define variables
  if $enterprise {
    $service_name = 'pe-mcollective'
    $service_start = undef
    $service_stop = undef
  } else {
    $service_name = 'mcollective'
    $service_start = "/sbin/service ${service_name} start"
    $service_stop = "/sbin/service ${service_name} stop"
  }
  $mc_daemonize = '1'
  $package_name = 'mcollective'

  # directories and files
  $plugin_cfgddir = "$cfgdir/plugin.d"
  $plugin_base = "${mc_libdir}/mcollective"
  $plugin_subs = [
    "${plugin_base}/agent",
    "${plugin_base}/application",
    "${plugin_base}/audit",
    "${plugin_base}/connector",
    "${plugin_base}/facts",
    "${plugin_base}/registration",
    "${plugin_base}/security",
    "${plugin_base}/util",
  ]

  $pidfile = '/var/run/mcollectived.pid'
  $rcscript = '/etc/init.d/mcollective'
}
