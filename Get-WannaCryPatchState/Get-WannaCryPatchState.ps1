#Version 1.08.00 @KieranWalsh May 2017
# Computer Talk LTD

# Thanks to https://github.com/TLaborde, and https://www.facebook.com/BlackV for notifying me about missing patches.

$OffComputers = @()
$CheckFail = @()
$AlreadyPassed = @()
$Patched = @()
$Unpatched = @()

$date = Get-Date -Format 'yyyy-MM-dd HHmm'

$log = Join-Path -Path ([Environment]::GetFolderPath('MyDocuments')) -ChildPath "WannaCry patch state for $($ENV:USERDOMAIN).log"
$logpatched = Join-Path -Path ([Environment]::GetFolderPath('MyDocuments')) -ChildPath "PatchedSystems.log"

$Patches = @('KB4012212', 'KB4012213', 'KB4012214', 'KB4012215', 'KB4012216', 'KB4012217', 'KB4012598', 'KB4013429', 'KB4015217', 'KB4015438', 'KB4015549', 'KB4015550', 'KB4015551', 'KB4015552', 'KB4015553', 'KB4016635', 'KB4019215', 'KB4019216', 'KB4019264', 'KB4019472')

If(!(Test-Path $logpatched))
{
New-Item $logpatched -type "file"
}

$PatchedComputers = Get-Content $logpatched | Sort-Object

$WindowsComputers = (Get-ADComputer -Filter {
    (OperatingSystem  -Like 'Windows*') -and (OperatingSystem -notlike '*Windows 10*')
}).Name | Sort-Object

"WannaCry patch status $date" | Out-File -FilePath $log

$ADCount = $WindowsComputers.count
$PatchedCount = $PatchedComputers.count
$ComputerCount = $ADCount - $PatchedCount

"Of $ADCount computers $PatchedCount are already patched and will not be checked again"
$loop = 0
foreach($Computer in $WindowsComputers)
{
  If($PatchedComputers -contains $Computer)
  {
    "$Computer has already passed" | Out-File -FilePath $log -Append
	$AlreadyPassed += $Computer
  }
  Else
  {
  $ThisComputerPatches = @()
  $loop ++
  "$loop of $ComputerCount `t$Computer"
  try
  {
    $null = Test-Connection -ComputerName $Computer -Count 1 -ErrorAction Stop
    try
    {
      $Hotfixes = Get-HotFix -ComputerName $Computer -ErrorAction Stop

      $Patches | ForEach-Object -Process {
        if($Hotfixes.HotFixID -contains $_)
        {
          $ThisComputerPatches += $_
        }
      }
    }
    catch
    {
      $CheckFail += $Computer
      "***`t$Computer `tUnable to gather hotfix information" |Out-File -FilePath $log -Append
      continue
    }
    If($ThisComputerPatches)
    {
      "$Computer is patched with $($ThisComputerPatches -join (','))" |Out-File -FilePath $log -Append
      $Computer | Out-File -FilePath $logpatched -Append
      $Patched += $Computer
    }
    Else
    {
      $Unpatched += $Computer
      "*****`t$Computer IS UNPATCHED! *****" |Out-File -FilePath $log -Append
    }
  }
  catch
  {
    $OffComputers += $Computer
    "****`t$Computer `tUnable to connect." |Out-File -FilePath $log -Append
  }
  }
}
' '
"Summary for domain: $ENV:USERDNSDOMAIN"
"Unpatched ($($Unpatched.count)):" |Out-File -FilePath $log -Append
$Unpatched -join (', ')  |Out-File -FilePath $log -Append
'' |Out-File -FilePath $log -Append
"Patched ($($Patched.count)):" |Out-File -FilePath $log -Append
$Patched -join (', ') |Out-File -FilePath $log -Append
'' |Out-File -FilePath $log -Append
"Already Passed ($($AlreadyPassed.count)):" | Out-File -FilePath $log -Append
$AlreadyPassed -join (', ') | Out-File -FilePath $log -Append
'' | Out-File -FilePath $log -Append
"Off/Untested($(($OffComputers + $CheckFail).count)):"|Out-File -FilePath $log -Append
($OffComputers + $CheckFail | Sort-Object)-join (', ')|Out-File -FilePath $log -Append

"Of the $($WindowsComputers.count) windows computers in active directory, $($AlreadyPassed.count) have already passed, $($OffComputers.count) were off, $($CheckFail.count) couldn't be checked, $($Unpatched.count) were unpatched and $($Patched.count) were successfully patched."
'Full details in the log file.'

try
{
  Start-Process -FilePath notepad++ -ArgumentList $log
}
catch
{
  Start-Process -FilePath notepad.exe -ArgumentList $log
}
