<#
.SYNOPSIS
    Teardown Script for CloudMart Microservices Lab
#>

Write-Host "Tearing down microservices-lab Kubernetes resources..." -ForegroundColor Yellow

kubectl delete namespace microservices-lab --timeout=60s

Write-Host "Teardown complete. All pods, services, and volumes cleaned up." -ForegroundColor Green
