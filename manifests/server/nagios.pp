class mcollective::server::nagios (
  $stomp_host,
  $stomp_port,
  $ensure = present
) {
  # validate parameters
  validate_string($stomp_host)
  validate_integer($stomp_port)
  validate_re($ensure, '^(present|absent)$')

  # configure nagios monitored service
  @nagios::nrpe::check {
    'check_mcollective_process' :
      ensure => $ensure,
      source => 'check_procs',
      commands => {
        check_mcollective_process => '-a /usr/sbin/mcollectived -c 1:1',
      },
      manage_script => false ;

    'check_mcollective_connect' :
      ensure => $ensure,
      source => 'check_tcp',
      commands => {
        check_mcollective_stomp => "-H ${stomp_host} -p ${stomp_port}",
      },
      manage_script => false ;
  }
  @activecheck::service::nrpe {
    'mcollective_process' :
      ensure => $ensure,
      check_interval_in_seconds => 60,
      check_command => 'check_mcollective_process' ;

    'mcollective_stomp' :
      service_description => "mcollective_stomp tcp://${stomp_host}:${stomp_port}",
      check_command => 'check_mcollective_stomp',
      dependent_service_description => 'mcollective_process' ;
  }
}
