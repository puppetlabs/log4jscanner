# @param present
#   Whether the scanner should be installed
# @param linux_directories
#   Which directories to scan on Linux nodes
# @param linux_skip
#   Which directories to skip on Linux nodes
# @param scan_data_owner
#   Owner of the generated scan results
# @param scan_data_group
#   Group of the generated scan results
# @param cron_user
# @param cron_hour
# @param cron_month
# @param cron_monthday
# @param cron_weekday
# @param cron_minute
# @param windows_directories
#   Which directories to scan on Windows nodes
# @param windows_skip
#   Which directories to skip on Windows nodes
# @param scheduled_task_every
#   How often the task should run, as a number of days
# @param osx_directories
#   Which directories to scan on OSX nodes
# @param osx_skip
#   Which directories to skip on OSX nodes
class log4jscanner (
  Enum['present', 'absent'] $ensure  = 'present',
  Array[String] $linux_directories   = ['/'],
  Array[String] $linux_skip          = ['/proc', '/sys', '/tmp'],
  String $scan_data_owner            = 'root',
  String $scan_data_group            = 'root',
  String $cron_user                  = 'root',
  $cron_hour                         = absent,
  $cron_month                        = absent,
  $cron_monthday                     = absent,
  $cron_weekday                      = absent,
  $cron_minute                       = fqdn_rand(59),
  Array[String] $windows_directories = ['C:'],
  Array[String] $windows_skip        = ['C:\Windows\Temp'],
  Integer $scheduled_task_every      = 1,
  Array[String] $osx_directories     = ['/'],
  Array[String] $osx_skip            = ['/tmp', '/Users/osx', '/dev', '/private/var/db', '/private/var/folders', '/System/Volumes/Data/private/var/db', '/System/Volumes/Data/private/var/folders'],
) {

  # Run things/set up files, or clean up when ensure=>absent?
  $generate_scan_data_exec = $ensure ? {
    'present' => 'Log4jscanner generate scan data',
    default   => undef,
  }

  $fact_upload_exec = $ensure ? {
    'present' => 'Log4jscanner fact upload',
    default   => undef,
  }

  $ensure_file = $ensure ? {
    'present' => 'file',
    default   => 'absent',
  }

  $ensure_dir = $ensure ? {
    'present' => 'directory',
    default   => 'absent',
  }

  if $facts['env_windows_installdir'] {
    $windows_puppet_install_path = $facts['env_windows_installdir']
  } else {
    $windows_puppet_install_path = "C:\\Program Files\\Puppet Labs\\Puppet"
  }

  case $facts['kernel'] {
    'Linux': {
      $puppet_bin = '/opt/puppetlabs/bin/puppet'
      $fact_upload_params = "facts upload"
      $fact_upload_cmd = "${puppet_bin} ${fact_upload_params}"
      $cache_dir = '/opt/puppetlabs/log4jscanner'
      $scan_script = 'scan_data_generation.sh'
      $scan_script_mode = '0700'
      File {
        owner => $scan_data_owner,
        group => $scan_data_group,
        mode  => '0644',
      }
      $dirs = $linux_directories
      $skip_dirs = $linux_skip
      $scan_bin = 'log4jscanner_nix'
      $checksum = '1e8d28e53cde54b3b81c66401afd4485adfecdf6cbaf622ff0324fe2b3a1649b'
      $scan_cmd = "${cache_dir}/${scan_script}"

      if $generate_scan_data_exec {
        exec { $generate_scan_data_exec:
          command     => $scan_cmd,
          user        => $scan_data_owner,
          group       => $scan_data_group,
          refreshonly => true,
          require     => File[$scan_cmd],
          timeout     => 0,
        }
      }

      cron { 'Log4jscanner - Cache scan data':
        ensure   => $ensure,
        command  => $scan_cmd,
        user     => $cron_user,
        hour     => $cron_hour,
        minute   => $cron_minute,
        month    => $cron_month,
        monthday => $cron_monthday,
        weekday  => $cron_weekday,
        require  => File[$scan_cmd],
      }
    }
    'Darwin': {
      $puppet_bin = '/opt/puppetlabs/bin/puppet'
      $fact_upload_params = "facts upload --environment ${environment}"
      $fact_upload_cmd = "${puppet_bin} ${fact_upload_params}"
      $cache_dir = '/opt/puppetlabs/log4jscanner'
      $scan_script = 'scan_data_generation.sh'
      $scan_script_mode = '0700'
      File {
        owner => $scan_data_owner,
        group => $scan_data_group,
        mode  => '0644',
      }
      $dirs = $osx_directories
      $skip_dirs = $osx_skip
      $scan_bin = 'log4jscanner_osx'
      $checksum = 'b81bb538179909213aea0ae414492dd4a5f05e4a243b55894d8507dffcb9d23a'
      $scan_cmd = "${cache_dir}/${scan_script}"

      if $generate_scan_data_exec {
        exec { $generate_scan_data_exec:
          command     => $scan_cmd,
          user        => $scan_data_owner,
          group       => $scan_data_group,
          refreshonly => true,
          require     => File[$scan_cmd],
          timeout     => 0,
        }
      }

      cron { 'Log4jscanner - Cache scan data':
        ensure   => $ensure,
        command  => $scan_cmd,
        user     => $cron_user,
        hour     => $cron_hour,
        minute   => $cron_minute,
        month    => $cron_month,
        monthday => $cron_monthday,
        weekday  => $cron_weekday,
        require  => File[$scan_cmd],
      }
    }
    'windows': {
      $puppet_bin = "${windows_puppet_install_path}\\bin\\puppet.bat"
      $fact_upload_params = "facts upload --environment ${environment}"
      $fact_upload_cmd = "\"${puppet_bin}\" ${fact_upload_params}"
      $cache_dir = 'C:/ProgramData/PuppetLabs/log4jscanner'
      $scan_script = 'scan_data_generation.ps1'
      $scan_script_mode = '0770'
      $dirs = $windows_directories
      $skip_dirs = $windows_skip
      $scan_bin = 'log4jscanner.exe'
      $checksum = 'b360695ad5ea1982966eb827f57cae6d83f2cec54def4e30a72ffb9b91b1b1de'
      $scan_cmd = "${cache_dir}/${scan_script}"

      if $generate_scan_data_exec {
        exec { $generate_scan_data_exec:
          path        => "${facts['system32']}/WindowsPowerShell/v1.0",
          refreshonly => true,
          command     => "powershell -executionpolicy remotesigned -file ${scan_cmd}",
          timeout     => 0,
        }
      }

      scheduled_task { 'Log4jscanner - Cache scan data':
        ensure    => $ensure,
        enabled   => true,
        command   => "${facts['system32']}/WindowsPowerShell/v1.0/powershell.exe",
        arguments => "-NonInteractive -ExecutionPolicy RemoteSigned -File ${scan_cmd}",
        user      => 'SYSTEM',
        trigger   => {
          schedule   => daily,
          start_time => "02:${cron_minute}",
          every      => $scheduled_task_every,
        },
        require   => File[$scan_cmd],
      }
    }
    default: { fail("Unsupported OS : ${facts['kernel']}") }
  }

  file { $cache_dir:
    ensure => $ensure_dir,
    force  => true,
  }

  file { $scan_bin:
    ensure         => $ensure_file,
    path           => "${cache_dir}/${scan_bin}",
    source         => "puppet:///modules/log4jscanner/${scan_bin}",
    mode           => $scan_script_mode,
    checksum       => 'sha256',
    checksum_value => $checksum,
  }

  $template_data = {
    'directories'        => $dirs,
    'skip'               => $skip_dirs,
    'cache_dir'          => $cache_dir,
    'puppet_bin'         => $puppet_bin,
    'fact_upload_params' => $fact_upload_params,
    'scan_bin'           => $scan_bin,
  }
  file { $scan_cmd:
    ensure  => $ensure_file,
    mode    => $scan_script_mode,
    content => epp("${module_name}/${scan_script}.epp", $template_data),
    require => File[$scan_bin],
    notify  => Exec[$generate_scan_data_exec],
  }

  if $fact_upload_exec {
    exec { $fact_upload_exec:
      command     => $fact_upload_cmd,
      path        => ['/usr/bin', '/bin', '/sbin', '/usr/local/bin', $cache_dir],
      refreshonly => true,
      subscribe   => File[$scan_cmd, $cache_dir],
    }
  }
}
