param([ValidateSet('Kubernetes','Compose')][string]$Mode='Kubernetes',[string]$DbPassword='cloudmart-lab-change-me')
$ErrorActionPreference='Stop'
$projectRoot=Split-Path -Parent $PSScriptRoot
function Run { param([string]$Tool,[Parameter(ValueFromRemainingArguments=$true)][string[]]$Arguments) & $Tool @Arguments; if($LASTEXITCODE -ne 0){throw "$Tool failed with exit code $LASTEXITCODE"} }
Push-Location $projectRoot
try {
  Run docker @('info','--format','{{.ServerVersion}}')
  if($Mode -eq 'Compose') {
    if(-not(Test-Path -LiteralPath '.env')){Set-Content -LiteralPath '.env' -Value "DB_PASSWORD=$DbPassword"}
    Run docker @('compose','up','-d','--build','--wait','--wait-timeout','240')
    $url='http://localhost:5000'
  } else {
    $context=kubectl config current-context
    if($LASTEXITCODE -ne 0){throw 'Select a local Kubernetes context first.'}
    if($context -ne 'docker-desktop' -and $context -ne 'minikube' -and -not $context.StartsWith('kind-')){throw "This lab script supports docker-desktop, minikube or kind contexts. Current: $context"}
    Run kubectl @('cluster-info')
    foreach($service in @('frontend','product-service','order-service')) {
      $short=@{'frontend'='frontend';'product-service'='product';'order-service'='order'}[$service]
      $image="cloudmart-${short}:v1"
      Run docker @('build','-t',$image,"services/$service")
      if($context.StartsWith('kind-')){Run kind @('load','docker-image',$image,'--name',$context.Substring(5))}
      if($context -eq 'minikube'){Run minikube @('image','load',$image)}
    }
    Run kubectl @('apply','-f','k8s/00-namespace.yaml')
    $secret=kubectl create secret generic cloudmart-secret -n microservices-lab "--from-literal=DB_PASSWORD=$DbPassword" --dry-run=client -o yaml
    if($LASTEXITCODE -ne 0){throw 'Secret generation failed'}
    $secret | kubectl apply -f - | Out-Null
    if($LASTEXITCODE -ne 0){throw 'Secret application failed'}
    Run kubectl @('apply','-k','k8s')
    foreach($name in @('product-service','order-service','frontend-service')) {Run kubectl @('rollout','restart',"deployment/$name",'-n','microservices-lab')}
    foreach($name in @('postgres-db','product-service','order-service','frontend-service')) {Run kubectl @('rollout','status',"deployment/$name",'-n','microservices-lab','--timeout=240s')}
    Run kubectl @('get','pods,svc,pvc,hpa','-n','microservices-lab')
    $url='http://localhost:30080'
    if($context -eq 'minikube'){$url=(minikube service frontend-service -n microservices-lab --url | Select-Object -First 1);if($LASTEXITCODE -ne 0){throw 'Minikube service URL failed'}}
    if($context.StartsWith('kind-')) {Write-Host 'In a second terminal: kubectl port-forward -n microservices-lab svc/frontend-service 5000:80';$url='http://localhost:5000'}
  }
  try { $health=Invoke-RestMethod "$url/api/inspector" -TimeoutSec 10; if(@($health.services | Where-Object {$_.status -ne 'healthy'}).Count){throw 'A backend service is not ready'}; Write-Host 'Application health checks passed.' }
  catch { if($Mode -eq 'Kubernetes' -and $context.StartsWith('kind-')){Write-Warning 'Start the port-forward command above, then verify /api/inspector.'}else{throw} }
  Write-Host "Open $url. Read DEMO_GUIDE.md for the college walkthrough."
} finally {Pop-Location}
