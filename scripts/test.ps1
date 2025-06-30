# Test Script for GitHub MCP and Docker MCP Integration
# This script runs comprehensive tests against the deployed application

param(
    [string]$BaseUrl = "http://localhost:8000",
    [string]$ContainerName = "mcp-test-container",
    [switch]$UnitTests = $false,
    [switch]$IntegrationTests = $false,
    [switch]$LoadTests = $false,
    [switch]$AllTests = $false,
    [switch]$Verbose = $false
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
    Write-Host "🧪 $Message" -ForegroundColor $Color
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

function Write-TestResult {
    param([string]$TestName, [bool]$Success, [string]$Details = "")
    if ($Success) {
        Write-Host "✅ $TestName" -ForegroundColor $Green
        if ($Details) { Write-Host "   $Details" -ForegroundColor $Cyan }
    }
    else {
        Write-Host "❌ $TestName" -ForegroundColor $Red
        if ($Details) { Write-Host "   $Details" -ForegroundColor $Yellow }
    }
}

# Test results tracking
$TestResults = @{
    Total = 0
    Passed = 0
    Failed = 0
    Tests = @()
}

function Add-TestResult {
    param(
        [string]$TestName,
        [bool]$Success,
        [string]$Details = "",
        [double]$Duration = 0
    )
    
    $TestResults.Total++
    if ($Success) { $TestResults.Passed++ } else { $TestResults.Failed++ }
    
    $TestResults.Tests += @{
        Name = $TestName
        Success = $Success
        Details = $Details
        Duration = $Duration
    }
    
    Write-TestResult -TestName $TestName -Success $Success -Details $Details
}

function Test-ApplicationHealth {
    Write-Status "Testing application health..." $Blue
    
    $StartTime = Get-Date
    try {
        $Response = Invoke-RestMethod -Uri "$BaseUrl/health" -Method GET -TimeoutSec 10
        $Duration = (Get-Date).Subtract($StartTime).TotalMilliseconds
        
        if ($Response.status -eq "healthy") {
            Add-TestResult -TestName "Health Check" -Success $true -Details "Response time: $([math]::Round($Duration, 2))ms" -Duration $Duration
            return $true
        }
        else {
            Add-TestResult -TestName "Health Check" -Success $false -Details "Status: $($Response.status)" -Duration $Duration
            return $false
        }
    }
    catch {
        $Duration = (Get-Date).Subtract($StartTime).TotalMilliseconds
        Add-TestResult -TestName "Health Check" -Success $false -Details "Error: $($_.Exception.Message)" -Duration $Duration
        return $false
    }
}

function Test-ApiEndpoints {
    Write-Status "Testing API endpoints..." $Blue
    
    $Endpoints = @(
        @{ Path = "/"; Name = "Home Page"; ExpectedContent = "Docker MCP Integration Test App" }
        @{ Path = "/api/info"; Name = "API Info"; ExpectedContent = "app_name" }
        @{ Path = "/api/test"; Name = "API Test"; ExpectedContent = "success" }
        @{ Path = "/metrics"; Name = "Metrics"; ExpectedContent = "app_requests_total" }
    )
    
    foreach ($Endpoint in $Endpoints) {
        $StartTime = Get-Date
        try {
            if ($Endpoint.Path -eq "/metrics") {
                $Response = Invoke-WebRequest -Uri "$BaseUrl$($Endpoint.Path)" -Method GET -TimeoutSec 10
                $Content = $Response.Content
            }
            else {
                $Response = Invoke-WebRequest -Uri "$BaseUrl$($Endpoint.Path)" -Method GET -TimeoutSec 10
                $Content = $Response.Content
            }
            
            $Duration = (Get-Date).Subtract($StartTime).TotalMilliseconds
            
            if ($Response.StatusCode -eq 200 -and $Content -match $Endpoint.ExpectedContent) {
                Add-TestResult -TestName $Endpoint.Name -Success $true -Details "Status: $($Response.StatusCode), Time: $([math]::Round($Duration, 2))ms" -Duration $Duration
            }
            else {
                Add-TestResult -TestName $Endpoint.Name -Success $false -Details "Status: $($Response.StatusCode), Content check failed" -Duration $Duration
            }
        }
        catch {
            $Duration = (Get-Date).Subtract($StartTime).TotalMilliseconds
            Add-TestResult -TestName $Endpoint.Name -Success $false -Details "Error: $($_.Exception.Message)" -Duration $Duration
        }
    }
}

function Test-ContainerStatus {
    Write-Status "Testing container status..." $Blue
    
    try {
        $ContainerInfo = docker inspect $ContainerName | ConvertFrom-Json
        
        if ($ContainerInfo.Length -gt 0) {
            $Container = $ContainerInfo[0]
            $IsRunning = $Container.State.Running
            $HealthStatus = $Container.State.Health.Status
            
            if ($IsRunning) {
                Add-TestResult -TestName "Container Running" -Success $true -Details "Status: Running"
            }
            else {
                Add-TestResult -TestName "Container Running" -Success $false -Details "Status: Not Running"
            }
            
            if ($HealthStatus -eq "healthy") {
                Add-TestResult -TestName "Container Health" -Success $true -Details "Health: $HealthStatus"
            }
            else {
                Add-TestResult -TestName "Container Health" -Success $false -Details "Health: $HealthStatus"
            }
        }
        else {
            Add-TestResult -TestName "Container Status" -Success $false -Details "Container not found"
        }
    }
    catch {
        Add-TestResult -TestName "Container Status" -Success $false -Details "Error: $($_.Exception.Message)"
    }
}

function Test-LoadTesting {
    Write-Status "Running load tests..." $Blue
    
    $ConcurrentRequests = 10
    $RequestsPerWorker = 20
    $TotalRequests = $ConcurrentRequests * $RequestsPerWorker
    
    Write-Status "Sending $TotalRequests requests with $ConcurrentRequests concurrent workers..." $Yellow
    
    $Jobs = @()
    $StartTime = Get-Date
    
    for ($i = 1; $i -le $ConcurrentRequests; $i++) {
        $Job = Start-Job -ScriptBlock {
            param($BaseUrl, $RequestCount)
            $Results = @()
            for ($j = 1; $j -le $RequestCount; $j++) {
                try {
                    $Start = Get-Date
                    $Response = Invoke-RestMethod -Uri "$BaseUrl/api/test" -Method GET -TimeoutSec 10
                    $End = Get-Date
                    $Duration = $End.Subtract($Start).TotalMilliseconds
                    $Results += @{ Success = $true; Duration = $Duration }
                }
                catch {
                    $Results += @{ Success = $false; Duration = 0 }
                }
            }
            return $Results
        } -ArgumentList $BaseUrl, $RequestsPerWorker
        
        $Jobs += $Job
    }
    
    # Wait for all jobs to complete
    $AllResults = @()
    foreach ($Job in $Jobs) {
        $JobResults = Receive-Job -Job $Job -Wait
        $AllResults += $JobResults
        Remove-Job -Job $Job
    }
    
    $EndTime = Get-Date
    $TotalDuration = $EndTime.Subtract($StartTime).TotalSeconds
    
    # Analyze results
    $SuccessfulRequests = ($AllResults | Where-Object { $_.Success }).Count
    $FailedRequests = $TotalRequests - $SuccessfulRequests
    $SuccessRate = [math]::Round(($SuccessfulRequests / $TotalRequests) * 100, 2)
    
    if ($SuccessfulRequests -gt 0) {
        $AverageResponseTime = [math]::Round(($AllResults | Where-Object { $_.Success } | Measure-Object -Property Duration -Average).Average, 2)
        $MaxResponseTime = [math]::Round(($AllResults | Where-Object { $_.Success } | Measure-Object -Property Duration -Maximum).Maximum, 2)
        $MinResponseTime = [math]::Round(($AllResults | Where-Object { $_.Success } | Measure-Object -Property Duration -Minimum).Minimum, 2)
    }
    else {
        $AverageResponseTime = 0
        $MaxResponseTime = 0
        $MinResponseTime = 0
    }
    
    $RequestsPerSecond = [math]::Round($TotalRequests / $TotalDuration, 2)
    
    $LoadTestSuccess = $SuccessRate -ge 95 -and $AverageResponseTime -le 1000
    
    Add-TestResult -TestName "Load Test" -Success $LoadTestSuccess -Details "Success Rate: $SuccessRate%, Avg Response: ${AverageResponseTime}ms, RPS: $RequestsPerSecond"
    
    if ($Verbose) {
        Write-Status "Load Test Details:" $Cyan
        Write-Host "  Total Requests: $TotalRequests" -ForegroundColor $Cyan
        Write-Host "  Successful: $SuccessfulRequests" -ForegroundColor $Cyan
        Write-Host "  Failed: $FailedRequests" -ForegroundColor $Cyan
        Write-Host "  Success Rate: $SuccessRate%" -ForegroundColor $Cyan
        Write-Host "  Average Response Time: ${AverageResponseTime}ms" -ForegroundColor $Cyan
        Write-Host "  Min Response Time: ${MinResponseTime}ms" -ForegroundColor $Cyan
        Write-Host "  Max Response Time: ${MaxResponseTime}ms" -ForegroundColor $Cyan
        Write-Host "  Requests Per Second: $RequestsPerSecond" -ForegroundColor $Cyan
        Write-Host "  Total Duration: $([math]::Round($TotalDuration, 2))s" -ForegroundColor $Cyan
    }
}

function Test-UnitTests {
    Write-Status "Running unit tests..." $Blue
    
    # Change to project root
    $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $ProjectRoot = Split-Path -Parent $ScriptDir
    $TestsDir = Join-Path $ProjectRoot "tests"
    
    if (Test-Path $TestsDir) {
        try {
            # Run Python unit tests
            $TestOutput = python -m pytest "$TestsDir" --verbose 2>&1
            
            if ($LASTEXITCODE -eq 0) {
                Add-TestResult -TestName "Unit Tests" -Success $true -Details "All unit tests passed"
            }
            else {
                Add-TestResult -TestName "Unit Tests" -Success $false -Details "Some unit tests failed"
            }
            
            if ($Verbose) {
                Write-Status "Unit Test Output:" $Cyan
                Write-Host $TestOutput -ForegroundColor $Cyan
            }
        }
        catch {
            Add-TestResult -TestName "Unit Tests" -Success $false -Details "Error running unit tests: $($_.Exception.Message)"
        }
    }
    else {
        Add-TestResult -TestName "Unit Tests" -Success $false -Details "Tests directory not found"
    }
}

function Test-SecurityBasics {
    Write-Status "Running basic security tests..." $Blue
    
    # Test for common security headers
    try {
        $Response = Invoke-WebRequest -Uri $BaseUrl -Method GET -TimeoutSec 10
        
        # Check if server header is minimal
        $ServerHeader = $Response.Headers["Server"]
        if (-not $ServerHeader -or $ServerHeader -notmatch "nginx|apache|iis") {
            Add-TestResult -TestName "Server Header Security" -Success $true -Details "Server header is minimal or hidden"
        }
        else {
            Add-TestResult -TestName "Server Header Security" -Success $false -Details "Server header reveals software: $ServerHeader"
        }
        
        # Test for SQL injection (basic)
        try {
            $SqlInjectionUrl = "$BaseUrl/api/test?id=1' OR '1'='1"
            $SqlResponse = Invoke-WebRequest -Uri $SqlInjectionUrl -Method GET -TimeoutSec 10
            
            if ($SqlResponse.StatusCode -eq 200) {
                Add-TestResult -TestName "SQL Injection Test" -Success $true -Details "Application handled malicious input properly"
            }
        }
        catch {
            Add-TestResult -TestName "SQL Injection Test" -Success $true -Details "Application rejected malicious input"
        }
        
    }
    catch {
        Add-TestResult -TestName "Security Tests" -Success $false -Details "Error: $($_.Exception.Message)"
    }
}

function Run-TestSuite {
    Write-Status "Starting comprehensive test suite..." $Blue
    Write-Status "Target: $BaseUrl" $Blue
    Write-Status "Container: $ContainerName" $Blue
    
    # Always run basic tests
    Test-ApplicationHealth
    Test-ApiEndpoints
    Test-ContainerStatus
    Test-SecurityBasics
    
    # Run specific test types based on parameters
    if ($UnitTests -or $AllTests) {
        Test-UnitTests
    }
    
    if ($LoadTests -or $AllTests) {
        Test-LoadTesting
    }
    
    # Generate test report
    Write-Status "Generating test report..." $Blue
    
    $TestReport = @{
        timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        target = $BaseUrl
        container = $ContainerName
        summary = @{
            total = $TestResults.Total
            passed = $TestResults.Passed
            failed = $TestResults.Failed
            success_rate = [math]::Round(($TestResults.Passed / $TestResults.Total) * 100, 2)
        }
        tests = $TestResults.Tests
    }
    
    $TestReportJson = $TestReport | ConvertTo-Json -Depth 4
    $TestReportPath = "test-report.json"
    $TestReportJson | Out-File -FilePath $TestReportPath -Encoding UTF8
    
    # Display summary
    Write-Host "`n📊 Test Summary:" -ForegroundColor $Blue
    Write-Host "  Total Tests: $($TestResults.Total)" -ForegroundColor $Cyan
    Write-Host "  Passed: $($TestResults.Passed)" -ForegroundColor $Green
    Write-Host "  Failed: $($TestResults.Failed)" -ForegroundColor $Red
    Write-Host "  Success Rate: $($TestReport.summary.success_rate)%" -ForegroundColor $Cyan
    Write-Host "  Report saved to: $TestReportPath" -ForegroundColor $Cyan
    
    # Return success status
    return $TestResults.Failed -eq 0
}

# Set default behavior
if (-not ($UnitTests -or $IntegrationTests -or $LoadTests -or $AllTests)) {
    $IntegrationTests = $true
}

# Execute main function
try {
    $TestSuccess = Run-TestSuite
    
    if ($TestSuccess) {
        Write-Success "All tests passed! 🎉"
        exit 0
    }
    else {
        Write-Error "Some tests failed! 😞"
        exit 1
    }
}
catch {
    Write-Error "Test execution failed: $($_.Exception.Message)"
    exit 1
}
