# Simple Setup Script for GitHub MCP and Docker MCP Integration Project
param(
    [switch]$InstallDependencies = $false
)

$ErrorActionPreference = "Stop"

Write-Host "Setting up GitHub MCP and Docker MCP Integration Project..." -ForegroundColor Blue

# Check Docker
try {
    docker version | Out-Null
    Write-Host "✅ Docker is available" -ForegroundColor Green
}
catch {
    Write-Host "❌ Docker is not running. Please start Docker Desktop." -ForegroundColor Red
    exit 1
}

# Check Git
try {
    git --version | Out-Null
    Write-Host "✅ Git is available" -ForegroundColor Green
}
catch {
    Write-Host "❌ Git is not installed" -ForegroundColor Red
    exit 1
}

# Initialize Git if needed
if (-not (Test-Path ".git")) {
    Write-Host "Initializing Git repository..." -ForegroundColor Blue
    git init
    
    # Create .gitignore
    @"
build-info.json
test-report.json
container-metrics-*.json
monitoring-summary-*.json
*.log
logs/
__pycache__/
*.py[cod]
*.tmp
*.temp
"@ | Out-File -FilePath ".gitignore" -Encoding UTF8
    
    git add .
    git commit -m "Initial commit: GitHub MCP and Docker MCP integration project"
    Write-Host "✅ Git repository initialized" -ForegroundColor Green
}

# Install Python dependencies if requested
if ($InstallDependencies) {
    try {
        python --version | Out-Null
        pip install requests pytest --quiet
        Write-Host "✅ Python dependencies installed" -ForegroundColor Green
    }
    catch {
        Write-Host "⚠️ Python not available, skipping dependency installation" -ForegroundColor Yellow
    }
}

Write-Host "`n🚀 Setup Complete!" -ForegroundColor Green
Write-Host "`nNext Steps:" -ForegroundColor Cyan
Write-Host "1. Open in VS Code: code ." -ForegroundColor Yellow
Write-Host "2. Test MCP integration in Copilot Chat" -ForegroundColor Yellow
Write-Host "3. Run: .\launch.ps1 -All" -ForegroundColor Yellow
Write-Host "4. Access app: http://localhost:8000" -ForegroundColor Yellow
