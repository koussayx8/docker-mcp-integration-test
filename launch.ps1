# Quick Launch Script for GitHub MCP and Docker MCP Integration
# This script provides a simple way to get the project running quickly

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

# Set error action preference
$ErrorActionPreference = "Stop"

# Colors for output
$Green = "Green"
$Red = "Red"
$Yellow = "Yellow"
$Blue = "Blue"
$Cyan = "Cyan"
$Magenta = "Magenta"

function Write-Status {
    param([string]$Message, [string]$Color = "White")
    Write-Host "🚀 $Message" -ForegroundColor $Color
}

function Write-Success {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor $Green
}

function Write-Error {
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor $Red
}

function Write-Header {
    param([string]$Message)
    Write-Host "`n" -NoNewline
    Write-Host "=" * 60 -ForegroundColor $Blue
    Write-Host $Message -ForegroundColor $Blue
    Write-Host "=" * 60 -ForegroundColor $Blue
}

function Show-Help {
    Write-Header "🐳 GitHub MCP & Docker MCP Integration - Quick Launch"
    
    Write-Host "`nUsage:" -ForegroundColor $Cyan
    Write-Host "  .\launch.ps1 [OPTIONS]" -ForegroundColor $Yellow
    
    Write-Host "`nOptions:" -ForegroundColor $Cyan
    Write-Host "  -Build        Build Docker image from current branch" -ForegroundColor $Yellow
    Write-Host "  -Deploy       Deploy container and run health checks" -ForegroundColor $Yellow
    Write-Host "  -Test         Run comprehensive test suite" -ForegroundColor $Yellow
    Write-Host "  -Monitor      Start container monitoring (Ctrl+C to stop)" -ForegroundColor $Yellow
    Write-Host "  -Stop         Stop and cleanup containers" -ForegroundColor $Yellow
    Write-Host "  -Status       Show current container status" -ForegroundColor $Yellow
    Write-Host "  -All          Run complete build-deploy-test pipeline" -ForegroundColor $Yellow
    Write-Host "  -Help         Show this help message" -ForegroundColor $Yellow
    
    Write-Host "`nExamples:" -ForegroundColor $Cyan
    Write-Host "  .\launch.ps1 -All          # Complete pipeline" -ForegroundColor $Yellow
    Write-Host "  .\launch.ps1 -Build        # Just build image" -ForegroundColor $Yellow
    Write-Host "  .\launch.ps1 -Deploy       # Deploy after building" -ForegroundColor $Yellow
    Write-Host "  .\launch.ps1 -Test         # Run tests on deployed container" -ForegroundColor $Yellow
    Write-Host "  .\launch.ps1 -Monitor      # Monitor running container" -ForegroundColor $Yellow
    Write-Host "  .\launch.ps1 -Status       # Check container status" -ForegroundColor $Yellow
    Write-Host "  .\launch.ps1 -Stop         # Stop and cleanup" -ForegroundColor $Yellow
    
    Write-Host "`nQuick Start:" -ForegroundColor $Cyan
    Write-Host "1. First time setup:" -ForegroundColor $Yellow
    Write-Host "   .\setup.ps1" -ForegroundColor $Magenta
    Write-Host "2. Complete pipeline:" -ForegroundColor $Yellow
    Write-Host "   .\launch.ps1 -All" -ForegroundColor $Magenta
    Write-Host "3. Monitor the application:" -ForegroundColor $Yellow
    Write-Host "   .\launch.ps1 -Monitor" -ForegroundColor $Magenta
    
    Write-Host "`nMCP Integration:" -ForegroundColor $Cyan
    Write-Host "• Use Copilot Chat: 'Build a Docker image from the current branch'" -ForegroundColor $Yellow
    Write-Host "• Use Copilot Chat: 'Deploy and test the container'" -ForegroundColor $Yellow
    Write-Host "• Use Copilot Chat: 'Create a GitHub PR if tests pass'" -ForegroundColor $Yellow
    Write-Host "• Use Copilot Chat: 'Monitor container performance'" -ForegroundColor $Yellow
    
    Write-Host "`nAccess Points:" -ForegroundColor $Cyan
    Write-Host "• Application: http://localhost:8000" -ForegroundColor $Yellow
    Write-Host "• Health Check: http://localhost:8000/health" -ForegroundColor $Yellow
    Write-Host "• Metrics: http://localhost:8000/metrics" -ForegroundColor $Yellow
    Write-Host "• API Test: http://localhost:8000/api/test" -ForegroundColor $Yellow
}

function Test-Prerequisites {
    $Issues = @()
    
    # Check Docker
    try {
        docker version | Out-Null
        Write-Success "Docker is available"
    }
    catch {
        $Issues += "Docker is not running or not installed"
    }
    
    # Check if scripts exist
    $RequiredScripts = @("build.ps1", "deploy.ps1", "test.ps1", "monitor.ps1")
    foreach ($Script in $RequiredScripts) {
        $ScriptPath = "scripts\$Script"
        if (Test-Path $ScriptPath) {
            Write-Success "$Script exists"
        }
        else {
            $Issues += "$Script is missing from scripts directory"
        }
    }
    
    if ($Issues.Count -gt 0) {
        Write-Error "Prerequisites check failed:"
        foreach ($Issue in $Issues) {
            Write-Host "  • $Issue" -ForegroundColor $Red
        }
        Write-Host "`nPlease run setup first: .\setup.ps1" -ForegroundColor $Yellow
        exit 1
    }
}

function Invoke-Build {
    Write-Header "🔨 Building Docker Image"
    Write-Status "Executing build script..." $Blue
    
    try {
        & .\scripts\build.ps1 -Verbose
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Build completed successfully!"
            return $true
        }
        else {
            Write-Error "Build failed with exit code $LASTEXITCODE"
            return $false
        }
    }
    catch {
        Write-Error "Build execution failed: $($_.Exception.Message)"
        return $false
    }
}

function Invoke-Deploy {
    Write-Header "🚀 Deploying Container"
    Write-Status "Executing deployment script..." $Blue
    
    try {
        & .\scripts\deploy.ps1 -Verbose
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Deployment completed successfully!"
            
            # Wait a moment for the container to be fully ready
            Write-Status "Waiting for container to be ready..." $Blue
            Start-Sleep -Seconds 10
            
            # Quick connectivity test
            try {
                $Response = Invoke-WebRequest -Uri "http://localhost:8000/health" -TimeoutSec 10
                if ($Response.StatusCode -eq 200) {
                    Write-Success "Container is responding! ✨"
                    Write-Status "Access your application at: http://localhost:8000" $Green
                }
            }
            catch {
                Write-Status "Container is starting, may take a moment to respond" $Yellow
            }
            
            return $true
        }
        else {
            Write-Error "Deployment failed with exit code $LASTEXITCODE"
            return $false
        }
    }
    catch {
        Write-Error "Deployment execution failed: $($_.Exception.Message)"
        return $false
    }
}

function Invoke-Test {
    Write-Header "🧪 Running Tests"
    Write-Status "Executing test script..." $Blue
    
    try {
        & .\scripts\test.ps1 -AllTests -Verbose
        if ($LASTEXITCODE -eq 0) {
            Write-Success "All tests passed! 🎉"
            return $true
        }
        else {
            Write-Error "Some tests failed"
            return $false
        }
    }
    catch {
        Write-Error "Test execution failed: $($_.Exception.Message)"
        return $false
    }
}

function Invoke-Monitor {
    Write-Header "📊 Monitoring Container"
    Write-Status "Starting container monitoring..." $Blue
    Write-Status "Press Ctrl+C to stop monitoring" $Yellow
    
    try {
        & .\scripts\monitor.ps1 -ShowLogs -SaveMetrics -Detailed
    }
    catch {
        Write-Status "Monitoring stopped" $Yellow
    }
}

function Invoke-Stop {
    Write-Header "🛑 Stopping Containers"
    Write-Status "Stopping and cleaning up containers..." $Blue
    
    try {
        & .\scripts\deploy.ps1 -Stop
        Write-Success "Containers stopped and cleaned up"
    }
    catch {
        Write-Error "Failed to stop containers: $($_.Exception.Message)"
    }
}

function Show-Status {
    Write-Header "📋 Container Status"
    
    try {
        Write-Status "Docker containers:" $Blue
        docker ps --filter "name=mcp-test-container" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}\t{{.Image}}"
        
        Write-Status "`nDocker images:" $Blue
        docker images --filter "reference=mcp-integration-test*" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedSince}}"
        
        # Test connectivity if container is running
        try {
            $Response = Invoke-WebRequest -Uri "http://localhost:8000/health" -TimeoutSec 5
            if ($Response.StatusCode -eq 200) {
                $HealthData = $Response.Content | ConvertFrom-Json
                Write-Status "`nApplication Health:" $Blue
                Write-Host "  Status: $($HealthData.status)" -ForegroundColor $Green
                Write-Host "  Uptime: $([math]::Round($HealthData.uptime, 2)) seconds" -ForegroundColor $Green
                Write-Host "  URL: http://localhost:8000" -ForegroundColor $Green
            }
        }
        catch {
            Write-Status "`nApplication: Not responding or not running" $Yellow
        }
    }
    catch {
        Write-Error "Failed to get status: $($_.Exception.Message)"
    }
}

function Run-CompletePipeline {
    Write-Header "🔄 Complete Build-Deploy-Test Pipeline"
    
    # Build
    if (-not (Invoke-Build)) {
        Write-Error "Pipeline failed at build stage"
        return $false
    }
    
    # Deploy
    if (-not (Invoke-Deploy)) {
        Write-Error "Pipeline failed at deployment stage"
        return $false
    }
    
    # Test
    if (-not (Invoke-Test)) {
        Write-Error "Pipeline failed at testing stage"
        return $false
    }
    
    Write-Success "Complete pipeline executed successfully! 🎉"
    Write-Status "Your application is ready at: http://localhost:8000" $Green
    
    Write-Host "`nNext steps:" -ForegroundColor $Cyan
    Write-Host "• Monitor: .\launch.ps1 -Monitor" -ForegroundColor $Yellow
    Write-Host "• Create GitHub PR via Copilot Chat" -ForegroundColor $Yellow
    Write-Host "• Access application: http://localhost:8000" -ForegroundColor $Yellow
    
    return $true
}

# Main execution logic
function Main {
    # Show help if requested or no parameters
    if ($Help -or (-not ($Build -or $Deploy -or $Test -or $Monitor -or $Stop -or $Status -or $All))) {
        Show-Help
        return
    }
    
    # Check prerequisites
    Test-Prerequisites
    
    # Execute based on parameters
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
}

# Execute main function
try {
    Main
}
catch {
    Write-Error "Launch script failed: $($_.Exception.Message)"
    exit 1
}
