class mcollective::server::plugins (
  $ensure = present
) {
  # validate parameters
  validate_re($ensure, '^(present|absent)$')

  # define plugins
  Mcollective::Server::Plugin {
    ensure => $ensure,
  }
  mcollective::server::plugin {
    'registration' :
      type => 'agent',
      ddl => false,
      application => false ;

    'facter_facts' :
      type => 'facts' ;

    'yaml_facts' :
      type => 'facts' ;

    'service' :
      type => 'agent',
      ddl => true,
      application => false ;

    'package' :
      type => 'agent',
      ddl => true,
      application => false,
      modules => {
        utildir => ['package']
      } ;

    'meta' :
      type => 'registration',
      ddl => false,
      application => false ;

    'filemgr' :
      type => 'agent',
      ddl => true,
      application => true ;

    'process' :
      type => 'agent',
      ddl => true,
      application => false ;
  }

  # realize all defined mcollective plugins
  Mcollective::Server::Plugin <||>
}
