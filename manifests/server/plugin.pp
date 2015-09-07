# Define: mcollective::server::plugin
#
#   Manage the files for MCollective plugins.
#
# Parameters:
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
#     mcollective::plugins::plugin { 'package':
#       ensure      => present,
#       type        => 'agent',
#       ddl         => true,
#       application => false,
#     }
#
define mcollective::server::plugin (
  $type,
  $config = undef,
  $ddl = false,
  $application = false,
  $directory = false,
  $source = "puppet:///modules/${caller_module_name}/mcollective",
  $modules = {},
  $ensure = present
) {
  # validate parameters
  validate_re($type, '^(agent|facts|registration|data|util|validator|aggregate)$')
  validate_bool($ddl, $application, $directory)
  validate_hash($modules)
  validate_puppet_source($source)
  if $application and $type != 'agent' {
    fail('Applications only apply to Agent plugins')
  } elsif $ddl and !($type in ['agent', 'data', 'validator', 'aggregate']) {
    fail('DDLs only apply to Agent, Data, Validator or Aggregate plugins')
  } elsif $directory and $type != 'util' {
    fail('Directory mode only apply to Util plugins')
  }
  validate_re($ensure, '^(present|absent)$')

  # define variables
  $name_path = regsubst($name, "^.*#", '')

  # file resource defaults
  File {
    owner => '0',
    group => '0',
    mode  => '0644',
  }

  # manage files
  if $ddl {
    file {
      "${mcollective::server::params::plugin_base}/${type}/${name_path}.ddl" :
        ensure => $ensure,
        source => "${source}/${type}/${name_path}.ddl" ;
    }
  }
  if $directory {
    file {
      "${mcollective::server::params::plugin_base}/${type}/${name_path}" :
        ensure => $ensure ? { present => directory, default => absent },
        recurse => true,
        source => "${source}/${type}/${name_path}" ;
    }
  } else {
    file {
      "${mcollective::server::params::plugin_cfgddir}/${name_path}.cfg":
        ensure => $config ? { undef => absent, default => $ensure },
        content => $config,
        notify => Service[$mcollective::server::params::service_name] ;

      "${mcollective::server::params::plugin_base}/${type}/${name_path}.rb":
        ensure => $ensure,
        source => "${source}/${type}/${name_path}.rb",
        notify => Service[$mcollective::server::params::service_name] ;
    }
  }

  # add application
  if $application {
    file {
    "${mcollective::server::params::plugin_base}/application/${name_path}.rb" :
      ensure => $ensure,
      source => "${source}/application/${name_path}.rb" ;
    }
  }

  # add aggregates, data, validators and utils
  if $type == 'agent' and !empty($modules) {
    if !empty($modules['aggregate']) {
      validate_array($modules['aggregate'])
      $modules_aggregate = array_prefix($modules['aggregate'], "${name}#")
      mcollective::server::plugin { # TODO: replace with loop
        $modules_aggregate :
          ensure => $ensure,
          type => 'aggregate',
          ddl => $ddl,
          source => $source ;
      }
    }
    if !empty($modules['data']) {
      validate_array($modules['data'])
      $modules_data = array_prefix($modules['data'], "${name}#")
      mcollective::server::plugin { # TODO: replace with loop
        $modules_data :
          ensure => $ensure,
          type => 'data',
          ddl => $ddl,
          source => $source ;
      }
    }
    if !empty($modules['validator']) {
      validate_array($modules['validator'])
      $modules_validator = array_prefix($modules['validator'], "${name}#")
      mcollective::server::plugin { # TODO: replace with loop
        $modules_validator :
          ensure => $ensure,
          type => 'validator',
          ddl => $ddl,
          source => $source ;
      }
    }
    if !empty($modules['util']) {
      validate_array($modules['util'])
      $modules_util = array_prefix($modules['util'], "${name}#")
      mcollective::server::plugin { # TODO: replace with loop
        $modules_util :
          ensure => $ensure,
          type => 'util',
          ddl => false,
          source => $source ;
      }
    }
    if !empty($modules['utildir']) {
      validate_array($modules['utildir'])
      $modules_utildir = array_prefix($modules['utildir'], "${name}#")
      mcollective::server::plugin { # TODO: replace with loop
        $modules_utildir :
          ensure => $ensure,
          type => 'util',
          ddl => false,
          directory => true,
          source => $source ;
      }
    }
  }
}
