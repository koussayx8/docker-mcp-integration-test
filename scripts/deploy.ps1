# Docker Deployment Script for GitHub MCP and Docker MCP Integration
# This script deploys and manages Docker containers

param(
    [string]$ImageName = "mcp-integration-test",
    [string]$ContainerName = "mcp-test-container",
    [int]$Port = 8000,
    [switch]$Compose = $false,
    [switch]$Monitor = $false,
    [switch]$Stop = $false,
    [switch]$Verbose = $false
)

# Set error action preference
$ErrorActionPreference = "Stop"

# Colors for output
$Green = "Green"
$Red = "Red"
$Yellow = "Yellow"
$Blue = "Blue"

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

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠️  $Message" -ForegroundColor $Yellow
}

function Test-DockerRunning {
    try {
        docker version | Out-Null
        return $true
    }
    catch {
        return $false
    }
}

function Stop-ExistingContainer {
    param([string]$Name)
    
    try {
        $ExistingContainer = docker ps -a --filter "name=$Name" --format "{{.Names}}"
        if ($ExistingContainer -eq $Name) {
            Write-Status "Stopping existing container: $Name" $Yellow
            docker stop $Name | Out-Null
            docker rm $Name | Out-Null
            Write-Success "Existing container removed"
        }
    }
    catch {
        Write-Warning "Could not check for existing container"
    }
}

function Wait-ForHealthCheck {
    param(
        [string]$ContainerName,
        [int]$TimeoutSeconds = 60
    )
    
    Write-Status "Waiting for container health check..." $Blue
    $StartTime = Get-Date
    
    while ((Get-Date).Subtract($StartTime).TotalSeconds -lt $TimeoutSeconds) {
        try {
            $Health = docker inspect --format='{{.State.Health.Status}}' $ContainerName 2>$null
            
            switch ($Health) {
                "healthy" {
                    Write-Success "Container is healthy!"
                    return $true
                }
                "unhealthy" {
                    Write-Error "Container health check failed"
                    return $false
                }
                "starting" {
                    Write-Status "Container is starting..." $Yellow
                }
                default {
                    Write-Status "Health status: $Health" $Yellow
                }
            }
        }
        catch {
            Write-Status "Waiting for health check to initialize..." $Yellow
        }
        
        Start-Sleep -Seconds 5
    }
    
    Write-Error "Health check timeout after $TimeoutSeconds seconds"
    return $false
}

function Test-ContainerConnectivity {
    param([int]$Port)
    
    Write-Status "Testing container connectivity..." $Blue
    
    # Wait a moment for the container to be ready
    Start-Sleep -Seconds 5
    
    try {
        $Response = Invoke-WebRequest -Uri "http://localhost:$Port/health" -TimeoutSec 10
        if ($Response.StatusCode -eq 200) {
            Write-Success "Container is responding on port $Port"
            $HealthData = $Response.Content | ConvertFrom-Json
            Write-Status "Health status: $($HealthData.status)" $Green
            return $true
        }
    }
    catch {
        Write-Warning "Container connectivity test failed: $($_.Exception.Message)"
        return $false
    }
    
    return $false
}

function Deploy-SingleContainer {
    Write-Status "Deploying single container..." $Blue
    
    # Get current Git branch for tagging
    try {
        $BranchName = git rev-parse --abbrev-ref HEAD
    }
    catch {
        $BranchName = "main"
    }
    
    $ImageTag = "$ImageName`:$BranchName"
    
    # Stop existing container
    Stop-ExistingContainer -Name $ContainerName
    
    # Run new container
    $RunArgs = @(
        "run"
        "-d"
        "--name", $ContainerName
        "-p", "$Port`:8000"
        "-e", "APP_ENV=production"
        "-e", "BRANCH_NAME=$BranchName"
        "--health-cmd", "curl -f http://localhost:8000/health || exit 1"
        "--health-interval", "30s"
        "--health-timeout", "10s"
        "--health-retries", "3"
        "--health-start-period", "40s"
        $ImageTag
    )
    
    Write-Status "Starting container with image: $ImageTag" $Blue
    try {
        $ContainerId = docker @RunArgs
        Write-Success "Container started with ID: $($ContainerId.Substring(0, 12))"
    }
    catch {
        Write-Error "Failed to start container: $($_.Exception.Message)"
        exit 1
    }
    
    # Wait for health check
    if (-not (Wait-ForHealthCheck -ContainerName $ContainerName)) {
        Write-Error "Container failed health check"
        # Show logs for debugging
        Write-Status "Container logs:" $Yellow
        docker logs $ContainerName
        exit 1
    }
    
    # Test connectivity
    if (-not (Test-ContainerConnectivity -Port $Port)) {
        Write-Warning "Container connectivity test failed, but container appears healthy"
    }
    
    Write-Success "Single container deployment completed!"
    Write-Status "Container accessible at: http://localhost:$Port" $Green
}

function Deploy-WithCompose {
    Write-Status "Deploying with Docker Compose..." $Blue
    
    # Change to project root
    $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $ProjectRoot = Split-Path -Parent $ScriptDir
    Set-Location $ProjectRoot
    
    # Stop existing services
    try {
        docker-compose -f docker/docker-compose.yml down
        Write-Status "Stopped existing services" $Yellow
    }
    catch {
        Write-Status "No existing services to stop" $Yellow
    }
    
    # Start services
    try {
        docker-compose -f docker/docker-compose.yml up -d
        Write-Success "Services started with Docker Compose"
    }
    catch {
        Write-Error "Failed to start services with Docker Compose: $($_.Exception.Message)"
        exit 1
    }
    
    # Wait for services to be ready
    Start-Sleep -Seconds 10
    
    # Test main application
    if (Test-ContainerConnectivity -Port 8000) {
        Write-Success "Application service is ready"
    }
    
    # Test Nginx proxy
    try {
        $Response = Invoke-WebRequest -Uri "http://localhost:80/health" -TimeoutSec 10
        if ($Response.StatusCode -eq 200) {
            Write-Success "Nginx proxy is working"
        }
    }
    catch {
        Write-Warning "Nginx proxy test failed"
    }
    
    Write-Success "Docker Compose deployment completed!"
    Write-Status "Application accessible at: http://localhost:80" $Green
    Write-Status "Direct access at: http://localhost:8000" $Green
    Write-Status "Prometheus at: http://localhost:9090" $Green
}

function Stop-Deployment {
    Write-Status "Stopping deployment..." $Yellow
    
    if ($Compose) {
        # Stop Docker Compose services
        $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
        $ProjectRoot = Split-Path -Parent $ScriptDir
        Set-Location $ProjectRoot
        
        try {
            docker-compose -f docker/docker-compose.yml down
            Write-Success "Docker Compose services stopped"
        }
        catch {
            Write-Warning "Failed to stop Docker Compose services"
        }
    }
    else {
        # Stop single container
        try {
            docker stop $ContainerName
            docker rm $ContainerName
            Write-Success "Container stopped and removed"
        }
        catch {
            Write-Warning "Failed to stop container"
        }
    }
}

function Show-ContainerStatus {
    Write-Status "Container Status:" $Blue
    docker ps --filter "name=$ContainerName" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    
    if ($Compose) {
        Write-Status "Docker Compose Services:" $Blue
        docker-compose -f docker/docker-compose.yml ps
    }
}

# Main deployment function
function Deploy-Application {
    Write-Status "Starting deployment process..." $Blue
    
    # Check Docker
    if (-not (Test-DockerRunning)) {
        Write-Error "Docker is not running. Please start Docker Desktop."
        exit 1
    }
    
    Write-Success "Docker is running"
    
    # Handle stop request
    if ($Stop) {
        Stop-Deployment
        return
    }
    
    # Deploy based on mode
    if ($Compose) {
        Deploy-WithCompose
    }
    else {
        Deploy-SingleContainer
    }
    
    # Show status
    Show-ContainerStatus
    
    # Monitor if requested
    if ($Monitor) {
        Write-Status "Starting monitoring mode (Ctrl+C to exit)..." $Blue
        try {
            while ($true) {
                Clear-Host
                Write-Status "Container Monitoring - $(Get-Date)" $Blue
                Show-ContainerStatus
                
                # Show recent logs
                Write-Status "Recent Logs:" $Blue
                docker logs --tail 10 $ContainerName
                
                Start-Sleep -Seconds 30
            }
        }
        catch {
            Write-Status "Monitoring stopped" $Yellow
        }
    }
}

# Execute main function
try {
    Deploy-Application
    Write-Success "Deployment process completed!"
}
catch {
    Write-Error "Deployment failed: $($_.Exception.Message)"
    exit 1
}
