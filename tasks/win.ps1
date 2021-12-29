[CmdletBinding()]
Param(
  [String]$Directories,
  [String]$Skip = "",
  [Boolean]$Rewrite = $false
)

$ErrorActionPreference = "Stop"

$params = @()

If ($Rewrite) { $params += "-w" }

$skip_dirs = $Skip.split(",")
If (![string]::IsNullOrEmpty($skip_dirs)) {
  $skip_dirs | ForEach-Object {
    $params += "--skip `"$_`""
  }
}

$Directories.split(",") | ForEach-Object { $params += "`"$_`"" }

$installdir = (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))
$cmd = "$installdir\files\log4jscanner.exe"
echo "Command: $cmd $params"
# This is all so we can get the console to show stderr, rather than using &.
# Surely there must be an easier way.
$p = New-object System.Diagnostics.ProcessStartInfo
$p.CreateNoWindow = $true
$p.UseShellExecute = $false
$p.RedirectStandardOutput = $true
$p.RedirectStandardError = $true
$p.FileName = $cmd
$p.Arguments = $params
$process = New-Object System.Diagnostics.Process
$process.StartInfo=$p
[void]$process.Start()
$process.WaitForExit()
$stdout = $process.StandardOutput.ReadToEnd()
$stderr = $process.StandardError.ReadToEnd()
if ($stderr) { 
  Write-Host "Errors during execution:"
  Write-Host $stderr 
}
Write-Host $stdout