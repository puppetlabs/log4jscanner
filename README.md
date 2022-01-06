# log4jscanner

This module utilizes Google's [log4jscanner](https://github.com/google/log4jscanner) tool to
monitor your infrastructure for vulnerable jar files.

## Description

This module can be used in two ways:
1. Run the log4jscanner::run_scan task on a node. A list of vulernable jars is printed
in the task output.
2. Apply the log4jscanner class to any Linux or Windows nodes with a Puppet Agent.
This will set up a scheduled task to scan for vulnerable jars once per day, and keeps
a custom fact called 'log4jscanner' updated with the results.

## Log4jscanner binaries
The binaries were compiled using Go version 1.17.5 and running `go build` from the 
[google/log4jscanner](https://github.com/google/log4jscanner) repo at SHA
`edf4af1a38a2930c86fdd955da1719e3d649441c`. log4jscanner_nix was compiled on 
Centos 7, log4jscanner.exe on Windows 2019, and log4jscanner_osx on 10.15 (not
yet supported by the rest of the module).

## Setup

### What log4jscanner affects

When the class is applied, the module provides an additional fact (`log4jscanner`). This
also adds a cron job (Linux) or scheduled task (Windows) that defaults to running
once per day.

On Linux systems, files are saved to /opt/puppetlabs/log4jscanner. On Windows, they are
saved to C:\ProgramData\PuppetLabs\log4jscanner.

## Usage

### Manifest
Include the module:
```puppet
include log4jscanner
```

Advanced usage:
```puppet
class { 'log4jscanner':
  linux_directories => ['/opt', '/usr'],
  linux_skip_directories => ['/opt/puppetlabs'],
  cron_hour = 12,
  cron_minute = 30,
  windows_directories => ["C:"],
  windows_skip_directories => ["C:\\Windows\\Temp"],
  scheduled_task_every = 2,
}
```
In this example, all Linux nodes will scan the `/opt` and `/usr` directories, while skipping `/opt/puppetlabs`,
and all Windows nodes will scan `C:` and skip the Windows temp directory. It will scan Linux nodes every day
at 12:30 PM, and Windows nodes every other day.

Note that when using the class with OSX, you'll want to use the `osx_directories` and `osx_skip` parameters,
and you'll likely need to change the `scan_data_group` to `admin` rather than `root`.

### Task
Run a basic scan from the command line:
```bash
puppet task run log4jscanner::run_scan --nodes <nodes> directories=/opt,/var skip=/opt/puppetlabs
```
Note that for OSX, you'll want to run the `log4jscanner::run_scan_osx` task.
## Reference
### Manifest Parameters
- ensure: Set to 'absent' to remove artifacts (cron/scheduled tasks, files) from nodes. (default 'present')
- linux_directories: Array of directories to scan on Linux nodes. (default \['/'\])
- linux_skip: Array of glob patterns to skip scanning on Linux nodes. (default \['/proc','/sys','/tmp'\])
- scan_data_owner: User to own log4jscanner files. (default 'root')
- scan_data_group: Group to own log4jscanner files. (default 'root')
- cron_user: User to run the cron job for scanning. (default 'root')
- cron_hour: Hour for cron job run. (default 'absent')
- cron_month: Month for cron job run. (default 'absent')
- cron_monthday: Day of the month for cron job run. (default 'absent')
- cron_weekday: Day of the week for cron job run. (default 'absent')
- cron_minutes: Minute for cron job run. (default is a random int between 0 and 59)
- windows_directories: Array of directories to scan on Windows nodes. (default \['C:'\])
- windows_skip: Array of glob patterns to skip scanning on Windows nodes. (default \["C:\\Windows\\Temp"\])
- scheduled_task_every: Run the scheduled task every X days. (default 1)
- osx_directories: Array of directories to scan on OSX nodes (default \['/'\])
- osx_skip: Array of glob patterns to skip scanning on OSX nodes (default \['/tmp', '/Users/osx', '/dev', '/private/var/db', '/private/var/folders', '/System/Volumes/Data/private/var/db', '/System/Volumes/Data/private/var/folders'\])

### Task Parameters
- directories: Comma-separated list of directories to search for vulnerable log4j jars
- skip: Comma-separated list of glob patterns to skip when scanning
- rewrite: When true, rewrite vulnerable jars as they are detected. NOT RECOMMENDED.
## Limitations

Tested on a limited number of OS flavors. Please submit fixes if you find bugs!

## Development

Fork, develop, submit pull request.

## Contributors
- [Nick Burgan](mailto:nickb@puppet.com)
- Ben Ford
- Charlie Sharpsteen

Class/fact code heavily cribbed from [os_patching](https://github.com/albatrossflavour/puppet_os_patching) by [Tony Green](mailto:tgreen@albatrossflavour.com)
