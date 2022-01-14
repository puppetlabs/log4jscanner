Facter.add('log4jscanner') do
  confine { ['Linux', 'Darwin', 'windows'].include?(Facter.value(:kernel)) }
  setcode do
    errors = []
    warnings = {}
    last_runtime = ''
    data = {}

    cache_dir = case Facter.value(:kernel)
                when 'Linux', 'Darwin'
                  '/opt/puppetlabs/log4jscanner'
                when 'windows'
                  'C:\ProgramData\PuppetLabs\log4jscanner'
                end

    vulnerable_jars = []
    scan_file = cache_dir + '/vulnerable_jars'
    if File.file?(scan_file)
      last_runtime = File.mtime(scan_file)
      if (Time.now - last_runtime) / (24 * 3600) > 10
        warnings['scan_file_time'] = 'Scan file has not been updated in 10 days'
      end

      vulnerable_jars = File.readlines(scan_file).map { |l| l.strip.encode!('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '') }.reject { |l| l.empty? }
    else
      warnings['scan_file'] = 'Scan file not found, vulnerable jars information invalid'
    end

    error_file = cache_dir + '/scan_errors'
    if File.file?(error_file)
      errors = File.readlines(error_file).map { |l| l.strip.encode!('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '') }.reject { |l| l.empty? }
    end

    data['vulnerable_jars'] = vulnerable_jars
    data['vulnerable_jars_count'] = vulnerable_jars.count
    data['errors'] = errors
    data['last_scan'] = last_runtime
    data
  end
end
