# Simple Launch Script for GitHub MCP and Docker MCP Integration
param(
    [switch]$Build = $false,
    [switch]$Deploy = $false,
    [switch]$Test = $false,
    [switch]$Monitor = $false,
    [switch]$Stop = $false,
    [switch]$Status = $false,
    [switch]$All = $false,
    [switch]$Help = $false
)

$ErrorActionPreference = "Stop"

function Write-Header($Message) {
    Write-Host "`n$('=' * 60)" -ForegroundColor Blue
    Write-Host $Message -ForegroundColor Blue
    Write-Host "$('=' * 60)" -ForegroundColor Blue
}

function Show-Help {
    Write-Header "GitHub MCP & Docker MCP Integration - Quick Launch"
    Write-Host "Usage: .\launch.ps1 [OPTIONS]" -ForegroundColor Yellow
    Write-Host "Options:" -ForegroundColor Cyan
    Write-Host "  -Build    Build Docker image" -ForegroundColor Yellow
    Write-Host "  -Deploy   Deploy container" -ForegroundColor Yellow
    Write-Host "  -Test     Run tests" -ForegroundColor Yellow
    Write-Host "  -Monitor  Monitor container" -ForegroundColor Yellow
    Write-Host "  -Stop     Stop containers" -ForegroundColor Yellow
    Write-Host "  -Status   Show status" -ForegroundColor Yellow
    Write-Host "  -All      Complete pipeline" -ForegroundColor Yellow
    Write-Host "  -Help     Show help" -ForegroundColor Yellow
}

function Test-Prerequisites {
    try {
        docker version | Out-Null
        Write-Host "✅ Docker is available" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Docker is not running" -ForegroundColor Red
        exit 1
    }
    
    $Scripts = @("build.ps1", "deploy.ps1", "test.ps1", "monitor.ps1")
    foreach ($Script in $Scripts) {
        if (Test-Path "scripts\$Script") {
            Write-Host "✅ $Script exists" -ForegroundColor Green
        }
        else {
            Write-Host "❌ $Script missing" -ForegroundColor Red
            exit 1
        }
    }
}

function Invoke-Build {
    Write-Header "Building Docker Image"
    try {
        & .\scripts\build.ps1 -Verbose
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Build completed successfully!" -ForegroundColor Green
            return $true
        }
        else {
            Write-Host "❌ Build failed" -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "❌ Build execution failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Invoke-Deploy {
    Write-Header "Deploying Container"
    try {
        & .\scripts\deploy.ps1 -Verbose
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Deployment completed successfully!" -ForegroundColor Green
            Start-Sleep -Seconds 5
            try {
                $Response = Invoke-WebRequest -Uri "http://localhost:8000/health" -TimeoutSec 10
                if ($Response.StatusCode -eq 200) {
                    Write-Host "✅ Container is responding!" -ForegroundColor Green
                    Write-Host "🌐 Access at: http://localhost:8000" -ForegroundColor Cyan
                }
            }
            catch {
                Write-Host "⚠️ Container is starting..." -ForegroundColor Yellow
            }
            return $true
        }
        else {
            Write-Host "❌ Deployment failed" -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "❌ Deployment execution failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Invoke-Test {
    Write-Header "Running Tests"
    try {
        & .\scripts\test.ps1 -AllTests -Verbose
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ All tests passed!" -ForegroundColor Green
            return $true
        }
        else {
            Write-Host "❌ Some tests failed" -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "❌ Test execution failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Invoke-Monitor {
    Write-Header "Monitoring Container"
    Write-Host "Press Ctrl+C to stop monitoring" -ForegroundColor Yellow
    try {
        & .\scripts\monitor.ps1 -ShowLogs -SaveMetrics -Detailed
    }
    catch {
        Write-Host "Monitoring stopped" -ForegroundColor Yellow
    }
}

function Invoke-Stop {
    Write-Header "Stopping Containers"
    try {
        & .\scripts\deploy.ps1 -Stop
        Write-Host "✅ Containers stopped" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Failed to stop containers" -ForegroundColor Red
    }
}

function Show-Status {
    Write-Header "Container Status"
    try {
        Write-Host "Docker containers:" -ForegroundColor Blue
        docker ps --filter "name=mcp-test-container"
        
        try {
            $Response = Invoke-WebRequest -Uri "http://localhost:8000/health" -TimeoutSec 5
            if ($Response.StatusCode -eq 200) {
                Write-Host "✅ Application is healthy" -ForegroundColor Green
                Write-Host "🌐 URL: http://localhost:8000" -ForegroundColor Green
            }
        }
        catch {
            Write-Host "⚠️ Application not responding" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "❌ Failed to get status" -ForegroundColor Red
    }
}

function Run-CompletePipeline {
    Write-Header "Complete Build-Deploy-Test Pipeline"
    
    if (-not (Invoke-Build)) {
        Write-Host "❌ Pipeline failed at build stage" -ForegroundColor Red
        return $false
    }
    
    if (-not (Invoke-Deploy)) {
        Write-Host "❌ Pipeline failed at deployment stage" -ForegroundColor Red
        return $false
    }
    
    if (-not (Invoke-Test)) {
        Write-Host "❌ Pipeline failed at testing stage" -ForegroundColor Red
        return $false
    }
    
    Write-Host "✅ Complete pipeline executed successfully!" -ForegroundColor Green
    Write-Host "🌐 Your application is ready at: http://localhost:8000" -ForegroundColor Green
    return $true
}

# Main execution
if ($Help -or (-not ($Build -or $Deploy -or $Test -or $Monitor -or $Stop -or $Status -or $All))) {
    Show-Help
    return
}

Test-Prerequisites

if ($All) {
    Run-CompletePipeline
}
else {
    if ($Stop) { Invoke-Stop }
    if ($Build) { Invoke-Build }
    if ($Deploy) { Invoke-Deploy }
    if ($Test) { Invoke-Test }
    if ($Status) { Show-Status }
    if ($Monitor) { Invoke-Monitor }
}
