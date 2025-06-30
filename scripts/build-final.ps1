param(
    [string]$ImageName = "mcp-integration-test",
    [switch]$Verbose = $false
)

Write-Host "Building Docker image..." -ForegroundColor Blue

# Check Docker
try {
    docker version | Out-Null
    Write-Host "Docker is running" -ForegroundColor Green
}
catch {
    Write-Host "Docker is not running" -ForegroundColor Red
    exit 1
}

# Get Git info
try {
    $BranchName = git rev-parse --abbrev-ref HEAD
    Write-Host "Current branch: $BranchName" -ForegroundColor Blue
}
catch {
    $BranchName = "master"
    Write-Host "Using default branch: master" -ForegroundColor Yellow
}

# Build image
$ImageTag = "$ImageName`:$BranchName"
Write-Host "Building image: $ImageTag" -ForegroundColor Blue

try {
    docker build -f docker/Dockerfile -t $ImageTag .
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Build successful!" -ForegroundColor Green
        Write-Host "Image tag: $ImageTag" -ForegroundColor Green
    }
    else {
        Write-Host "Build failed" -ForegroundColor Red
        exit 1
    }
}
catch {
    Write-Host "Build error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "Build completed!" -ForegroundColor Green
