# Class: mcollective::server
class mcollective::server (
  $stomp_server = $mcollective::params::stomp_server,
  $stomp_port = $mcollective::params::stomp_port,
  $stomp_user = $mcollective::params::stomp_user,
  $stomp_passwd = $mcollective::params::stomp_passwd,
  $mc_security_provider = $mcollective::params::mc_security_provider,
  $mc_security_psk = $mcollective::params::mc_security_psk,
  $fact_source = 'yaml',
  $yaml_facter_source = '/etc/mcollective/facts.yaml',
  $runstyle = 'daemon',
  $ensure = present
) inherits mcollective::server::params {
  # validate parameters
  validate_string($stomp_server, $stomp_user, $stomp_passwd)
  validate_ip_port($stomp_port)
  validate_re($mc_security_provider, '^[a-zA-Z0-9_]+$')
  validate_re($mc_security_psk, '^[^ \t]+$')
  validate_absolute_path($yaml_facter_source)
  validate_re($fact_source, '^(facter|yaml)$')
  validate_re($runstyle, '^(service|daemon|monit|off)$')
  validate_re($ensure, '^(present|absent)$')

  # define variables
  $cfgfile = "${cfgdir}/server.cfg"

  # package management
  # TODO: yum repo ['puppet', 'puppet-dependencies']
  package {
    [$package_name, 'rubygem-stomp'] :
      ensure => ensure_latest($ensure), # repo puppet, puppet-dependencies
      require => Package['java'] ;
  }

  # include classes
  class {
    'mcollective::server::nagios' :
      ensure => $ensure,
      stomp_host => $stomp_server,
      stomp_port => $stomp_port ;

    'mcollective::server::plugins' :
      ensure => $ensure ;
  }

  # configure shorewall if needed
  @shorewall::rule {
    'mcollectiveServer_fw2stompserver' :
      ensure => $ensure,
      action => 'ACCEPT',
      src => 'fw',
      dst => shorewall_zonehost('all', $stomp_server),
      proto => 'tcp',
      dst_port => $stomp_port ;
  }

  case $ensure {
    present : {
      # file resource defaults
      File {
        owner => '0',
        group => '0',
        mode => '0644',
        require => Package[$package_name],
      }

      # $plugin_base and $plugin_subs are meant to be arrays.
      file {
        [$plugin_cfgddir, $plugin_base, $plugin_subs] :
          ensure => directory ;

        $cfgfile :
          content => template('mcollective/server.cfg.erb'),
          mode => '0640',
          owner => 0,
          group => 0 ;

        $rcscript :
          source => 'puppet:///modules/mcollective/mcollectived.sh',
          mode => '0755' ;
      }

      # determine start type
      case $runstyle {
        /(service|daemon|monit)/ : {
          # run as system service
          service {
            $service_name :
              ensure => $runstyle ? { 'monit' => undef, default => running },
              enable => true,
              hasstatus => true,
              start => $service_start,
              stop => $service_stop,
              require => File[$rcscript],
              subscribe => [
                Package[$package_name],
                File[$cfgfile],
              ] ;
          }

          # supervise with monit?
          monit::check::process {
            $service_name :
              ensure => $runstyle ? { 'monit' => present, default => absent },
              manageinitd => false,
              pidfile => $pidfile,
              start_program => "/sbin/service ${service_name} start",
              start_timeout_in_seconds => 30,
              stop_program => "/sbin/service ${service_name} stop",
              stop_timeout_in_seconds => 10,
              conditions => [
                'if uptime > 24 hours then restart',
              ],
              require => Service[$service_name] ;
          }
        }

        /off/ : { # disable service
          service {
            $service_name :
              enable => false,
              hasrestart => true,
              hasstatus => true,
              start => $service_start,
              stop => $service_stop,
              require => [
                Package[$package_name],
                File[$cfgfile, $rcscript],
              ] ;
          }
        }
      }
    }

    absent : {
      # stop service
      service {
        $service_name :
          ensure => absent,
          enable => false,
          hasrestart => true,
          hasstatus => true,
          start => $service_start,
          stop => $service_stop,
          before => [
            Package[$package_name],
            File[$cfgfile, $rcscript],
          ] ;
      }

      # remove leftovers
      file {
        [$cfgdir, $rcscript] :
          ensure => absent,
          recurse => true,
          force => true,
          require => Package[$package_name] ;
      }
    }
  }

  # nightly restart between 1:00 and 2:00 UTC
  cron {
    'mcollectiveRestart' :
      ensure => $runstyle ? { /(service|daemon)/ => $ensure, default => absent },
      command => "/sbin/service ${service_name} restart >/dev/null 2>&1",
      user => 'root',
      minute => $::cronminute ? { undef => 11, default => $::cronminute },
      hour => 1 ;
  }
}
