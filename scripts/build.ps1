# Docker Build Script for GitHub MCP and Docker MCP Integration
# This script builds a Docker image from the current Git branch

param(
    [string]$ImageName = "mcp-integration-test",
    [string]$Registry = "",
    [switch]$Push = $false,
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
    Write-Host "🔧 $Message" -ForegroundColor $Color
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

# Main build function
function Build-DockerImage {
    Write-Status "Starting Docker build process..." $Blue
    
    # Check if Docker is running
    try {
        docker version | Out-Null
        Write-Success "Docker is running"
    }
    catch {
        Write-Error "Docker is not running. Please start Docker Desktop."
        exit 1
    }
    
    # Get current Git branch
    try {
        $BranchName = git rev-parse --abbrev-ref HEAD
        Write-Status "Current branch: $BranchName" $Blue
    }
    catch {
        Write-Warning "Could not determine Git branch, using 'main'"
        $BranchName = "main"
    }
    
    # Get Git commit hash
    try {
        $CommitHash = git rev-parse --short HEAD
        Write-Status "Current commit: $CommitHash" $Blue
    }
    catch {
        Write-Warning "Could not determine Git commit hash"
        $CommitHash = "unknown"
    }
    
    # Create timestamp
    $Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    
    # Build image tags
    $BaseTag = if ($Registry) { "$Registry/$ImageName" } else { $ImageName }
    $BranchTag = "$BaseTag`:$BranchName"
    $TimestampTag = "$BaseTag`:$BranchName-$Timestamp"
    $CommitTag = "$BaseTag`:$CommitHash"
    
    Write-Status "Building Docker image..." $Blue
    Write-Status "Tags: $BranchTag, $TimestampTag, $CommitTag" $Blue
    
    # Change to project root directory
    $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $ProjectRoot = Split-Path -Parent $ScriptDir
    Set-Location $ProjectRoot
    
    # Build Docker image
    $BuildArgs = @(
        "build"
        "-f", "docker/Dockerfile"
        "-t", $BranchTag
        "-t", $TimestampTag
        "-t", $CommitTag
        "--build-arg", "BRANCH_NAME=$BranchName"
        "--build-arg", "BUILD_NUMBER=$Timestamp"
        "--build-arg", "COMMIT_HASH=$CommitHash"
    )
    
    if ($Verbose) {
        $BuildArgs += "--progress=plain"
    }
    
    $BuildArgs += "."
    
    try {
        Write-Status "Executing: docker $($BuildArgs -join ' ')" $Blue
        & docker @BuildArgs
        
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Docker image built successfully!"
            Write-Success "Tags created:"
            Write-Host "  • $BranchTag" -ForegroundColor $Green
            Write-Host "  • $TimestampTag" -ForegroundColor $Green
            Write-Host "  • $CommitTag" -ForegroundColor $Green
        }
        else {
            Write-Error "Docker build failed with exit code $LASTEXITCODE"
            exit 1
        }
    }
    catch {
        Write-Error "Docker build failed: $($_.Exception.Message)"
        exit 1
    }
    
    # Verify image
    Write-Status "Verifying built image..." $Blue
    try {
        $ImageInfo = docker inspect $BranchTag | ConvertFrom-Json
        $ImageSize = [math]::Round($ImageInfo[0].Size / 1MB, 2)
        Write-Success "Image verified. Size: $ImageSize MB"
    }
    catch {
        Write-Warning "Could not verify image details"
    }
    
    # Push to registry if requested
    if ($Push -and $Registry) {
        Write-Status "Pushing image to registry..." $Blue
        try {
            docker push $BranchTag
            docker push $TimestampTag
            docker push $CommitTag
            Write-Success "Images pushed to registry successfully!"
        }
        catch {
            Write-Error "Failed to push images to registry: $($_.Exception.Message)"
            exit 1
        }
    }
    elseif ($Push -and -not $Registry) {
        Write-Warning "Push requested but no registry specified"
    }
    
    # Store build information
    $BuildInfo = @{
        timestamp = $Timestamp
        branch = $BranchName
        commit = $CommitHash
        tags = @($BranchTag, $TimestampTag, $CommitTag)
        size_mb = $ImageSize
    }
    
    $BuildInfoJson = $BuildInfo | ConvertTo-Json -Depth 3
    $BuildInfoPath = "build-info.json"
    $BuildInfoJson | Out-File -FilePath $BuildInfoPath -Encoding UTF8
    Write-Success "Build information saved to $BuildInfoPath"
    
    Write-Success "Build process completed successfully!"
    return $BuildInfo
}

# Execute main function
try {
    $BuildResult = Build-DockerImage
    Write-Host "`n🎉 Build Summary:" -ForegroundColor $Green
    Write-Host "   Branch: $($BuildResult.branch)" -ForegroundColor $Blue
    Write-Host "   Commit: $($BuildResult.commit)" -ForegroundColor $Blue
    Write-Host "   Timestamp: $($BuildResult.timestamp)" -ForegroundColor $Blue
    Write-Host "   Size: $($BuildResult.size_mb) MB" -ForegroundColor $Blue
}
catch {
    Write-Error "Build script failed: $($_.Exception.Message)"
    exit 1
}
