require 'spec_helper'
describe 'log4jscanner' do
  # I don't think rspec-puppet-facts supports OSX, but the code is here
  # in case that gets added at some point.
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      case os_facts[:kernel]
      when 'Linux'
        let(:fact_upload_cmd) { '/opt/puppetlabs/bin/puppet facts upload' }
        let(:cache_dir) { '/opt/puppetlabs/log4jscanner' }
        let(:scan_script) { 'scan_data_generation.sh' }
        let(:scan_script_mode) { '0700' }
        let(:scan_bin) { 'log4jscanner_nix' }
        let(:checksum) { '1e8d28e53cde54b3b81c66401afd4485adfecdf6cbaf622ff0324fe2b3a1649b' }
        let(:default_script_regex) { %r{CACHEDIR=#{cache_dir}} }
      when 'Darwin'
        let(:fact_upload_cmd) { '/opt/puppetlabs/bin/puppet facts upload --environment production' }
        let(:cache_dir) { '/opt/puppetlabs/log4jscanner' }
        let(:scan_script) { 'scan_data_generation.sh' }
        let(:scan_script_mode) { '0700' }
        let(:scan_bin) { 'log4jscanner_osx' }
        let(:checksum) { 'b81bb538179909213aea0ae414492dd4a5f05e4a243b55894d8507dffcb9d23a' }
        let(:default_script_regex) { %r{CACHEDIR=#{cache_dir}} }
      when 'windows'
        let(:fact_upload_cmd) { '"C:\Program Files\Puppet Labs\Puppet\bin\puppet.bat" facts upload --environment production' }
        let(:cache_dir) { 'C:/ProgramData/PuppetLabs/log4jscanner' }
        let(:scan_script) { 'scan_data_generation.ps1' }
        let(:scan_script_mode) { '0770' }
        let(:scan_bin) { 'log4jscanner.exe' }
        let(:checksum) { 'b360695ad5ea1982966eb827f57cae6d83f2cec54def4e30a72ffb9b91b1b1de' }
        let(:default_script_regex) { %r{\$CacheDir = "#{cache_dir}"} }
      end

      let(:facts) { os_facts }
      let(:environment) { 'production' }
      let(:params) { { 'cron_minute' => 11 } }
      let(:scan_cmd) { "#{cache_dir}/#{scan_script}" }

      context 'with default parameters' do
        it do
          is_expected.to compile.with_all_deps
          is_expected.to contain_file(cache_dir).with_ensure('directory').with_force(true)
          is_expected.to contain_file(scan_bin)
            .with_ensure('file')
            .with_path("#{cache_dir}/#{scan_bin}")
            .with_source("puppet:///modules/log4jscanner/#{scan_bin}")
            .with_mode(scan_script_mode)
            .with_checksum('sha256')
            .with_checksum_value(checksum)
          is_expected.to contain_file(scan_cmd)
            .with_ensure('file')
            .with_mode(scan_script_mode)
            .with_content(default_script_regex)
            .with_require("File[#{scan_bin}]")
            .with_notify('Exec[Log4jscanner generate scan data]')
          is_expected.to contain_exec('Log4jscanner fact upload')
            .with_command(fact_upload_cmd)
            .with_path(['/usr/bin', '/bin', '/sbin', '/usr/local/bin', cache_dir])
            .with_refreshonly(true)
            .with_subscribe(["File[#{scan_cmd}]", "File[#{cache_dir}]"])
          case os_facts[:kernel]
          when 'Linux', 'Darwin'
            is_expected.to contain_exec('Log4jscanner generate scan data')
              .with_command(scan_cmd)
              .with_user('root')
              .with_group('root')
              .with_refreshonly(true)
              .with_require("File[#{scan_cmd}]")
              .with_timeout(0)
            is_expected.to contain_cron('Log4jscanner - Cache scan data')
              .with_ensure('present')
              .with_command(scan_cmd)
              .with_user('root')
              .with_hour('absent')
              .with_minute(11)
              .with_month('absent')
              .with_monthday('absent')
              .with_weekday('absent')
              .with_require("File[#{scan_cmd}]")
          when 'windows'
            is_expected.to contain_exec('Log4jscanner generate scan data')
              .with_path('C:\Windows\System32/WindowsPowerShell/v1.0')
              .with_refreshonly(true)
              .with_command("powershell -executionpolicy remotesigned -file #{scan_cmd}")
              .with_timeout(0)
            is_expected.to contain_scheduled_task('Log4jscanner - Cache scan data')
              .with_ensure('present')
              .with_enabled(true)
              .with_command('C:\Windows\System32/WindowsPowerShell/v1.0/powershell.exe')
              .with_arguments("-NonInteractive -ExecutionPolicy RemoteSigned -File #{scan_cmd}")
              .with_user('SYSTEM')
              .with_trigger(
                {
                  'schedule' => 'daily',
                  'start_time' => '02:11',
                  'every' => 1,
                },
              )
              .with_require("File[#{scan_cmd}]")
          end
        end
      end

      context 'with ensure=absent' do
        it do
          params['ensure'] = 'absent'
          is_expected.to compile.with_all_deps
          is_expected.to contain_file(cache_dir).with_ensure('absent')
          is_expected.to contain_file(scan_bin).with_ensure('absent')
          is_expected.to contain_file(scan_cmd).with_ensure('absent')
          is_expected.not_to contain_exec('Log4jscanner generate scan data')
          is_expected.not_to contain_exec('Log4jscanner fact upload')
          case os_facts[:kernel]
          when 'Linux', 'Darwin'
            is_expected.to contain_cron('Log4jscanner - Cache scan data').with_ensure('absent')
          when 'windows'
            is_expected.to contain_scheduled_task('Log4jscanner - Cache scan data').with_ensure('absent')
          end
        end
      end

      context 'with modified parameters' do
        it do
          params['linux_directories'] = ['/livelong', '/andprosper']
          params['linux_skip'] = ['/peaceand', '/longlife']
          params['scan_data_owner'] = 'picard'
          params['scan_data_group'] = 'starfleet'
          params['cron_user'] = 'riker'
          params['cron_hour'] = 1
          params['cron_month'] = 2
          params['cron_monthday'] = 3
          params['cron_weekday'] = 4
          params['windows_directories'] = ['C:\LiveLong', 'C:\AndProsper']
          params['windows_skip'] = ['C:\PeaceAnd', 'C:\LongLife']
          params['scheduled_task_every'] = 2
          params['osx_directories'] = ['/livelongosx', '/andprosperosx']
          params['osx_skip'] = ['/peaceandosx', '/longlifeosx']

          is_expected.to compile.with_all_deps
          case os_facts[:kernel]
          when 'Linux'
            is_expected.to contain_file(scan_cmd)
              .with_ensure('file')
              .with_content(%r{--skip /peaceand.*--skip /longlife.*/livelong /andprosper}m)
            is_expected.to contain_exec('Log4jscanner generate scan data')
              .with_command(scan_cmd)
              .with_user('picard')
              .with_group('starfleet')
            is_expected.to contain_cron('Log4jscanner - Cache scan data')
              .with_ensure('present')
              .with_command(scan_cmd)
              .with_user('riker')
              .with_hour(1)
              .with_minute(11)
              .with_month(2)
              .with_monthday(3)
              .with_weekday(4)
          when 'Darwin'
            is_expected.to contain_file(scan_cmd)
              .with_ensure('file')
              .with_content(%r{--skip /peaceandosx.*--skip /longlifeosx.*/livelongosx /andprosperosx}m)
            is_expected.to contain_exec('Log4jscanner generate scan data')
              .with_command(scan_cmd)
              .with_user('picard')
              .with_group('starfleet')
            is_expected.to contain_cron('Log4jscanner - Cache scan data')
              .with_ensure('present')
              .with_command(scan_cmd)
              .with_user('riker')
              .with_hour(1)
              .with_minute(11)
              .with_month(2)
              .with_monthday(3)
              .with_weekday(4)
          when 'windows'
            is_expected.to contain_file(scan_cmd)
              .with_ensure('file')
              .with_content(%r{--skip `"C:\\PeaceAnd`".*--skip `"C:\\LongLife`".*`"C:\\LiveLong`".*`"C:\\AndProsper`"}m)
            is_expected.to contain_scheduled_task('Log4jscanner - Cache scan data')
              .with_ensure('present')
              .with_trigger(
                {
                  'schedule'   => 'daily',
                  'start_time' => '02:11',
                  'every'      => 2,
                },
              )
          end
        end
      end
    end
  end
end
