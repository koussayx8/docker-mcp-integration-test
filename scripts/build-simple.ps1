# Simple Docker Build Script
param(
    [string]$ImageName = "mcp-integration-test",
    [switch]$Verbose = $false
)

$ErrorActionPreference = "Stop"

Write-Host "Building Docker image..." -ForegroundColor Blue

# Check Docker
try {
    docker version | Out-Null
    Write-Host "✅ Docker is running" -ForegroundColor Green
}
catch {
    Write-Host "❌ Docker is not running" -ForegroundColor Red
    exit 1
}

# Get Git info
try {
    $BranchName = git rev-parse --abbrev-ref HEAD
    Write-Host "📋 Current branch: $BranchName" -ForegroundColor Blue
}
catch {
    $BranchName = "main"
    Write-Host "⚠️ Could not get Git branch, using 'main'" -ForegroundColor Yellow
}

try {
    $CommitHash = git rev-parse --short HEAD
    Write-Host "📋 Current commit: $CommitHash" -ForegroundColor Blue
}
catch {
    $CommitHash = "unknown"
}

# Build tags
$Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$BranchTag = "$ImageName`:$BranchName"
$TimestampTag = "$ImageName`:$BranchName-$Timestamp"

Write-Host "🔨 Building image with tags: $BranchTag, $TimestampTag" -ForegroundColor Blue

# Build command
$BuildArgs = @(
    "build"
    "-f", "docker/Dockerfile"
    "-t", $BranchTag
    "-t", $TimestampTag
    "--build-arg", "BRANCH_NAME=$BranchName"
    "--build-arg", "BUILD_NUMBER=$Timestamp"
    "--build-arg", "COMMIT_HASH=$CommitHash"
    "."
)

if ($Verbose) {
    Write-Host "Executing: docker $($BuildArgs -join ' ')" -ForegroundColor Cyan
}

try {
    & docker @BuildArgs
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Docker image built successfully!" -ForegroundColor Green
        Write-Host "📦 Tags created:" -ForegroundColor Green
        Write-Host "  • $BranchTag" -ForegroundColor Green
        Write-Host "  • $TimestampTag" -ForegroundColor Green
        
        # Save build info
        $BuildInfo = @{
            timestamp = $Timestamp
            branch = $BranchName
            commit = $CommitHash
            tags = @($BranchTag, $TimestampTag)
        }
        
        $BuildInfo | ConvertTo-Json | Out-File -FilePath "build-info.json" -Encoding UTF8
        Write-Host "💾 Build info saved to build-info.json" -ForegroundColor Green
    }
    else {
        Write-Host "❌ Docker build failed" -ForegroundColor Red
        exit 1
    }
}
catch {
    Write-Host "❌ Docker build failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "🎉 Build completed successfully!" -ForegroundColor Green
