param([string]$BaseUrl='http://localhost:30080',[ValidateRange(1,120)][int]$Seconds=45,[ValidateRange(1,32)][int]$Concurrency=8)
$ErrorActionPreference='Stop'
if($PSVersionTable.PSVersion.Major -lt 7){throw 'Use PowerShell 7 (pwsh) for parallel load requests.'}
$url="$($BaseUrl.TrimEnd('/'))/api/demo/load"
$end=[DateTime]::UtcNow.AddSeconds($Seconds)
1..$Concurrency | ForEach-Object -Parallel {
  $success=0;$failed=0
  while([DateTime]::UtcNow -lt $using:end){try{Invoke-RestMethod -Method Post -Uri $using:url -TimeoutSec 10 | Out-Null;$success++}catch{$failed++}}
  [pscustomobject]@{Worker=$_;Success=$success;Failed=$failed}
} -ThrottleLimit $Concurrency
Write-Host 'Watch kubectl get hpa -n microservices-lab -w. Metrics Server and sustained CPU load are required; scaling is not guaranteed.'
