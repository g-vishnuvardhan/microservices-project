param([ValidateSet('Kubernetes','Compose')][string]$Mode='Kubernetes',[switch]$DeleteData)
$ErrorActionPreference='Stop'
Push-Location (Split-Path -Parent $PSScriptRoot)
try {
  if($Mode -eq 'Compose') {
    if($DeleteData){docker compose down --volumes}else{docker compose down}
  } else {
    if($DeleteData){kubectl delete namespace microservices-lab --ignore-not-found}
    else {kubectl delete deployment,service,hpa --all -n microservices-lab;Write-Host 'Namespace, Secret and PVC retained. Redeploy with the same DB password.'}
  }
  if($LASTEXITCODE -ne 0){throw 'Cleanup failed'}
} finally {Pop-Location}
