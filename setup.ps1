# Setup Script for GitHub MCP and Docker MCP Integration Project
# This script initializes the project and verifies all prerequisites

param(
    [switch]$SkipGitInit = $false,
    [switch]$SkipDockerCheck = $false,
    [switch]$InstallDependencies = $false,
    [switch]$CreateGitHubRepo = $false,
    [string]$GitHubRepoName = "mcp-integration-test"
)

# Set error action preference
$ErrorActionPreference = "Stop"

# Colors for output
$Green = "Green"
$Red = "Red"
$Yellow = "Yellow"
$Blue = "Blue"
$Cyan = "Cyan"

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

function Write-Header {
    param([string]$Message)
    Write-Host "`n" -NoNewline
    Write-Host "=" * 60 -ForegroundColor $Blue
    Write-Host $Message -ForegroundColor $Blue
    Write-Host "=" * 60 -ForegroundColor $Blue
}

function Test-Command {
    param([string]$Command)
    try {
        $null = Get-Command $Command -ErrorAction Stop
        return $true
    }
    catch {
        return $false
    }
}

function Test-DockerDesktop {
    try {
        $DockerVersion = docker version --format "{{.Server.Version}}" 2>$null
        if ($DockerVersion) {
            Write-Success "Docker Desktop is running (version: $DockerVersion)"
            return $true
        }
        else {
            Write-Error "Docker Desktop is not running"
            return $false
        }
    }
    catch {
        Write-Error "Docker is not installed or not running"
        return $false
    }
}

function Test-GitConfiguration {
    try {
        $GitUser = git config --global user.name 2>$null
        $GitEmail = git config --global user.email 2>$null
        
        if ($GitUser -and $GitEmail) {
            Write-Success "Git is configured (User: $GitUser, Email: $GitEmail)"
            return $true
        }
        else {
            Write-Warning "Git is not fully configured"
            Write-Status "Please run:" $Yellow
            Write-Status "  git config --global user.name 'Your Name'" $Yellow
            Write-Status "  git config --global user.email 'your.email@example.com'" $Yellow
            return $false
        }
    }
    catch {
        Write-Error "Git is not installed"
        return $false
    }
}

function Test-VSCodeMCPConfiguration {
    $SettingsPath = "$env:APPDATA\Code\User\settings.json"
    
    if (Test-Path $SettingsPath) {
        try {
            $Settings = Get-Content $SettingsPath -Raw | ConvertFrom-Json
            
            $HasGitHubMCP = $Settings.'github.copilot.chat.experimental.mcpServers'.github -ne $null
            $HasDockerMCP = $Settings.'github.copilot.chat.experimental.mcpServers'.docker -ne $null
            
            if ($HasGitHubMCP -and $HasDockerMCP) {
                Write-Success "VS Code MCP servers are configured (GitHub and Docker)"
                return $true
            }
            elseif ($HasGitHubMCP -or $HasDockerMCP) {
                Write-Warning "VS Code MCP servers are partially configured"
                if (-not $HasGitHubMCP) { Write-Status "  Missing: GitHub MCP" $Yellow }
                if (-not $HasDockerMCP) { Write-Status "  Missing: Docker MCP" $Yellow }
                return $false
            }
            else {
                Write-Warning "VS Code MCP servers are not configured"
                return $false
            }
        }
        catch {
            Write-Warning "Could not parse VS Code settings.json"
            return $false
        }
    }
    else {
        Write-Warning "VS Code settings.json not found"
        return $false
    }
}

function Initialize-GitRepository {
    if (Test-Path ".git") {
        Write-Status "Git repository already exists" $Yellow
        return
    }
    
    Write-Status "Initializing Git repository..." $Blue
    
    try {
        git init
        git add .
        git commit -m "Initial commit: GitHub MCP and Docker MCP integration project"
        Write-Success "Git repository initialized"
        
        # Create .gitignore
        $GitIgnoreContent = @"
# Build artifacts
build-info.json
test-report.json
container-metrics-*.json
monitoring-summary-*.json

# Logs
*.log
logs/

# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
env/
venv/
ENV/
env.bak/
venv.bak/

# Docker
.dockerignore

# IDE
.vscode/settings.json
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Temporary files
*.tmp
*.temp
"@
        
        $GitIgnoreContent | Out-File -FilePath ".gitignore" -Encoding UTF8
        git add .gitignore
        git commit -m "Add .gitignore file"
        Write-Success ".gitignore created and committed"
    }
    catch {
        Write-Error "Failed to initialize Git repository: $($_.Exception.Message)"
    }
}

function Install-PythonDependencies {
    Write-Status "Installing Python dependencies..." $Blue
    
    try {
        # Check if Python is available
        $PythonVersion = python --version 2>$null
        if (-not $PythonVersion) {
            Write-Warning "Python is not installed or not in PATH"
            return
        }
        
        Write-Success "Python is available: $PythonVersion"
        
        # Install dependencies for testing
        pip install requests pytest --quiet
        Write-Success "Python test dependencies installed"
    }
    catch {
        Write-Warning "Failed to install Python dependencies: $($_.Exception.Message)"
    }
}

function Show-NextSteps {
    Write-Header "🚀 Setup Complete - Next Steps"
    
    Write-Host "1. Open this project in VS Code:" -ForegroundColor $Cyan
    Write-Host "   code ." -ForegroundColor $Yellow
    
    Write-Host "`n2. Test MCP integration in Copilot Chat:" -ForegroundColor $Cyan
    Write-Host "   Ask: 'Build a Docker image from the current branch'" -ForegroundColor $Yellow
    Write-Host "   Ask: 'Deploy and test the container'" -ForegroundColor $Yellow
    
    Write-Host "`n3. Use VS Code Tasks (Ctrl+Shift+P → 'Tasks: Run Task'):" -ForegroundColor $Cyan
    Write-Host "   • Build Docker Image" -ForegroundColor $Yellow
    Write-Host "   • Deploy Container" -ForegroundColor $Yellow
    Write-Host "   • Run Tests" -ForegroundColor $Yellow
    Write-Host "   • Monitor Container" -ForegroundColor $Yellow
    Write-Host "   • Complete Build-Test-Deploy Pipeline" -ForegroundColor $Yellow
    
    Write-Host "`n4. Manual script execution:" -ForegroundColor $Cyan
    Write-Host "   .\scripts\build.ps1 -Verbose" -ForegroundColor $Yellow
    Write-Host "   .\scripts\deploy.ps1 -Verbose" -ForegroundColor $Yellow
    Write-Host "   .\scripts\test.ps1 -AllTests -Verbose" -ForegroundColor $Yellow
    Write-Host "   .\scripts\monitor.ps1 -ShowLogs -SaveMetrics" -ForegroundColor $Yellow
    
    Write-Host "`n5. Create GitHub repository (if not done already):" -ForegroundColor $Cyan
    Write-Host "   Use Copilot Chat: 'Create a GitHub repository for this project'" -ForegroundColor $Yellow
    Write-Host "   Or manually: gh repo create $GitHubRepoName --public" -ForegroundColor $Yellow
    
    Write-Host "`n6. Access the running application:" -ForegroundColor $Cyan
    Write-Host "   http://localhost:8000 - Main application" -ForegroundColor $Yellow
    Write-Host "   http://localhost:8000/health - Health check" -ForegroundColor $Yellow
    Write-Host "   http://localhost:8000/metrics - Prometheus metrics" -ForegroundColor $Yellow
    
    Write-Host "`n📋 Project Structure:" -ForegroundColor $Blue
    Write-Host "   .github/          - GitHub Actions and Copilot instructions" -ForegroundColor $Cyan
    Write-Host "   .vscode/          - VS Code tasks configuration" -ForegroundColor $Cyan
    Write-Host "   docker/           - Docker configuration files" -ForegroundColor $Cyan
    Write-Host "   src/              - Python application source code" -ForegroundColor $Cyan
    Write-Host "   scripts/          - PowerShell automation scripts" -ForegroundColor $Cyan
    Write-Host "   tests/            - Test suite" -ForegroundColor $Cyan
}

function Main {
    Write-Header "🐳 GitHub MCP & Docker MCP Integration Setup"
    
    Write-Status "Starting project setup..." $Blue
    
    # Prerequisites check
    Write-Status "Checking prerequisites..." $Blue
    
    $PrereqsFailed = 0
    
    if (-not (Test-Command "docker")) {
        Write-Error "Docker is not installed"
        $PrereqsFailed++
    }
    elseif (-not $SkipDockerCheck -and -not (Test-DockerDesktop)) {
        $PrereqsFailed++
    }
    
    if (-not (Test-Command "git")) {
        Write-Error "Git is not installed"
        $PrereqsFailed++
    }
    elseif (-not (Test-GitConfiguration)) {
        $PrereqsFailed++
    }
    
    if (-not (Test-Command "code")) {
        Write-Warning "VS Code CLI is not available (optional)"
    }
    
    # Check VS Code MCP configuration
    if (-not (Test-VSCodeMCPConfiguration)) {
        Write-Warning "VS Code MCP servers may not be properly configured"
        Write-Status "Please ensure GitHub MCP and Docker MCP are configured in VS Code settings" $Yellow
    }
    
    if ($PrereqsFailed -gt 0) {
        Write-Error "Prerequisites check failed. Please install missing requirements."
        exit 1
    }
    
    Write-Success "All prerequisites are available!"
    
    # Git initialization
    if (-not $SkipGitInit) {
        Initialize-GitRepository
    }
    
    # Install dependencies
    if ($InstallDependencies) {
        Install-PythonDependencies
    }
    
    # Create GitHub repository
    if ($CreateGitHubRepo) {
        Write-Status "Creating GitHub repository..." $Blue
        try {
            gh repo create $GitHubRepoName --public --confirm
            git remote add origin "https://github.com/$(gh api user --jq .login)/$GitHubRepoName.git"
            git branch -M main
            git push -u origin main
            Write-Success "GitHub repository created and pushed"
        }
        catch {
            Write-Warning "Failed to create GitHub repository. You can do this manually later."
        }
    }
    
    # Final verification
    Write-Status "Running final verification..." $Blue
    
    $ProjectFiles = @(
        "README.md",
        ".github/copilot-instructions.md",
        ".vscode/tasks.json",
        "docker/Dockerfile",
        "src/app.py",
        "scripts/build.ps1",
        "scripts/deploy.ps1",
        "scripts/test.ps1",
        "scripts/monitor.ps1"
    )
    
    $MissingFiles = 0
    foreach ($File in $ProjectFiles) {
        if (Test-Path $File) {
            Write-Success "$File exists"
        }
        else {
            Write-Error "$File is missing"
            $MissingFiles++
        }
    }
    
    if ($MissingFiles -eq 0) {
        Write-Success "All project files are present!"
        Show-NextSteps
    }
    else {
        Write-Error "$MissingFiles files are missing. Setup may be incomplete."
        exit 1
    }
}

# Execute main function
try {
    Main
}
catch {
    Write-Error "Setup failed: $($_.Exception.Message)"
    exit 1
}
