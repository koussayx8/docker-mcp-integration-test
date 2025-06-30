# Final Launch Script for GitHub MCP and Docker MCP Integration
param(
    [switch]$Build = $false,
    [switch]$All = $false,
    [switch]$Help = $false
)

function Show-Help {
    Write-Host "GitHub MCP & Docker MCP Integration - Launch Script" -ForegroundColor Blue
    Write-Host "Usage: .\launch-final.ps1 [OPTIONS]" -ForegroundColor Yellow
    Write-Host "Options:" -ForegroundColor Cyan
    Write-Host "  -Build    Build Docker image only" -ForegroundColor Yellow
    Write-Host "  -All      Build and start container" -ForegroundColor Yellow
    Write-Host "  -Help     Show this help" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Example: .\launch-final.ps1 -All" -ForegroundColor Green
}

function Test-Docker {
    try {
        docker version | Out-Null
        Write-Host "✅ Docker is available" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "❌ Docker is not running. Please start Docker Desktop." -ForegroundColor Red
        return $false
    }
}

function Build-Image {
    Write-Host "`n🔨 Building Docker Image..." -ForegroundColor Blue
    
    try {
        & .\scripts\build-simple.ps1 -Verbose
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Build successful!" -ForegroundColor Green
            return $true
        }
        else {
            Write-Host "❌ Build failed" -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "❌ Build error: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Start-Container {
    Write-Host "`n🚀 Starting Container..." -ForegroundColor Blue
    
    # Stop existing container
    try {
        docker stop mcp-test-container 2>$null
        docker rm mcp-test-container 2>$null
    }
    catch { }
    
    # Start new container
    try {
        $ContainerId = docker run -d --name mcp-test-container -p 8000:8000 mcp-integration-test:master
        Write-Host "✅ Container started: $($ContainerId.Substring(0,12))" -ForegroundColor Green
        
        # Wait and test
        Write-Host "⏳ Waiting for container to be ready..." -ForegroundColor Yellow
        Start-Sleep -Seconds 10
        
        try {
            $Response = Invoke-WebRequest -Uri "http://localhost:8000/health" -TimeoutSec 15
            if ($Response.StatusCode -eq 200) {
                Write-Host "✅ Container is healthy and responding!" -ForegroundColor Green
                Write-Host "🌐 Access your application at: http://localhost:8000" -ForegroundColor Cyan
                return $true
            }
        }
        catch {
            Write-Host "⚠️ Container may still be starting up..." -ForegroundColor Yellow
            Write-Host "🌐 Try accessing: http://localhost:8000" -ForegroundColor Cyan
            return $true
        }
    }
    catch {
        Write-Host "❌ Failed to start container: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Main execution
if ($Help -or (-not ($Build -or $All))) {
    Show-Help
    exit 0
}

if (-not (Test-Docker)) {
    exit 1
}

if ($Build -or $All) {
    if (-not (Build-Image)) {
        exit 1
    }
}

if ($All) {
    if (-not (Start-Container)) {
        exit 1
    }
    
    Write-Host "`n🎉 Complete setup successful!" -ForegroundColor Green
    Write-Host "📋 Next steps:" -ForegroundColor Cyan
    Write-Host "• Open VS Code: code ." -ForegroundColor Yellow
    Write-Host "• Test MCP integration in Copilot Chat" -ForegroundColor Yellow
    Write-Host "• Ask: 'Build a Docker image from the current branch'" -ForegroundColor Yellow
    Write-Host "• Ask: 'Deploy and test the container'" -ForegroundColor Yellow
    Write-Host "• Ask: 'Create a GitHub PR if tests pass'" -ForegroundColor Yellow
    Write-Host "• Visit: http://localhost:8000" -ForegroundColor Yellow
}

Write-Host "`n✨ Done!" -ForegroundColor Green
