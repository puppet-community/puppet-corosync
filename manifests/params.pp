class corosync::params {
  $enable_secauth                      = true
  $authkey_source                      = 'file'
  $authkey                             = '/etc/puppet/ssl/certs/ca.pem'
  $threads                             = $::processorcount
  $port                                = '5405'
  $bind_address                        = $::ipaddress
  $multicast_address                   = 'UNSET'
  $unicast_addresses                   = 'UNSET'
  $force_online                        = false
  $check_standby                       = false
  $log_file                            = false
  $debug                               = false
  $log_stderr                          = true
  $syslog_priority                     = 'info'
  $log_function_name                   = false
  $rrp_mode                            = 'none'
  $ttl                                 = false
  $token                               = 3000
  $token_retransmits_before_lost_const = 10
  $votequorum_expected_votes           = false
  $cluster_name                        = undef
  $join                                = 50
  $consensus                           = false
  $max_messages                        = 17
  $package_corosync                    = true
  $package_pacemaker                   = true
  $version_corosync                    = 'present'
  $version_crmsh                       = 'present'
  $version_pacemaker                   = 'present'
  $version_pcs                         = 'present'
  $restart_corosync_command            = '/usr/sbin/corosync-cfgtool -R'
  $restart_pacemaker_command           = '/usr/bin/systemctl reload pacemaker'

  case $::osfamily {
    'RedHat': {
      $package_crmsh  = false
      $package_pcs    = true
      $set_votequorum = true
      $compatibility  = 'whitetank'
      if versioncmp($::operatingsystemrelease, '7') >= 0 {
        $manage_pacemaker_service = true
        $test_corosync_config = true
        $has_corosync_restart = true
        $has_pacemaker_restart = true
      } else {
        $manage_pacemaker_service = false
        $test_corosync_config = false
        $has_corosync_restart = false
        $has_pacemaker_restart = false
      }
      $package_install_options = undef
    }

    'Debian': {
      $package_crmsh  = true
      $package_pcs    = false
      case $::operatingsystem {
        'Ubuntu': {
          if versioncmp($::operatingsystemrelease, '14.04') >= 0 {
            $compatibility = false
            $set_votequorum = true
            $manage_pacemaker_service = true

            if versioncmp($::operatingsystemrelease, '16.04') >= 0 {
              $test_corosync_config = true
              $has_corosync_restart = true
              $has_pacemaker_restart = true
            } else {

              #FIXME should be moved in another place
              file {'/etc/default/cman':
                ensure  => present,
                content => template('corosync/cman.erb'),
              }

              $test_corosync_config = false
              $has_corosync_restart = false
              $has_pacemaker_restart = false
            }
          } else {
            $compatibility = 'whitetank'
            $set_votequorum = false
            $manage_pacemaker_service = false
            $test_corosync_config = false
            $has_corosync_restart = false
            $has_pacemaker_restart = false
          }
          $package_install_options = undef
        }
        'Debian': {
          if versioncmp($::operatingsystemrelease, '8') >= 0 {
            $set_votequorum = true
            $compatibility = false
            $manage_pacemaker_service = true
            $package_install_options = ['-t', 'jessie-backports']
            $test_corosync_config = true
            $has_corosync_restart = true
            $has_pacemaker_restart = true
          } else {
            $set_votequorum = false
            $compatibility = 'whitetank'
            $manage_pacemaker_service = false
            $package_install_options = undef
            $test_corosync_config = false
            $has_corosync_restart = false
            $has_pacemaker_restart = false
          }
        }
        default : {
          $compatibility = 'whitetank'
          $set_votequorum = false
          $manage_pacemaker_service = false
          $package_install_options = undef
          $test_corosync_config = false
          $has_corosync_restart = false
          $has_pacemaker_restart = false
        }
      }
    }

    default: {
      fail("Unsupported operating system: ${::operatingsystem}")
    }
  }

}
