<#
.SYNOPSIS
    Teardown Script for Microservices Kubernetes Deployment
#>

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptDir

Write-Host "Tearing down microservices Kubernetes resources..." -ForegroundColor Yellow

kubectl delete -f "$projectRoot\k8s" --ignore-not-found

Write-Host "Teardown complete. All pods, services, and HPAs cleaned up." -ForegroundColor Green
