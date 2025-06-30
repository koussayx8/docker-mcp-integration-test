# Monitoring Script for GitHub MCP and Docker MCP Integration
# This script monitors container performance and generates reports

param(
    [string]$ContainerName = "mcp-test-container",
    [int]$IntervalSeconds = 30,
    [int]$DurationMinutes = 0,  # 0 = run indefinitely
    [switch]$SaveMetrics = $false,
    [switch]$ShowLogs = $false,
    [switch]$Detailed = $false
)

# Set error action preference
$ErrorActionPreference = "Continue"

# Colors for output
$Green = "Green"
$Red = "Red"
$Yellow = "Yellow"
$Blue = "Blue"
$Cyan = "Cyan"
$Magenta = "Magenta"

function Write-Status {
    param([string]$Message, [string]$Color = "White")
    Write-Host "📊 $Message" -ForegroundColor $Color
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

# Metrics storage
$MetricsHistory = @()

function Get-ContainerStats {
    param([string]$ContainerName)
    
    try {
        # Get container stats
        $StatsJson = docker stats $ContainerName --no-stream --format "json" 2>$null
        if (-not $StatsJson) {
            return $null
        }
        
        $Stats = $StatsJson | ConvertFrom-Json
        
        # Get additional container info
        $InspectJson = docker inspect $ContainerName 2>$null
        if ($InspectJson) {
            $Inspect = $InspectJson | ConvertFrom-Json
            $Container = $Inspect[0]
        }
        else {
            $Container = $null
        }
        
        # Parse CPU percentage (remove % sign)
        $CpuPercent = [double]($Stats.CPUPerc -replace '%', '')
        
        # Parse memory usage
        $MemoryParts = $Stats.MemUsage -split ' / '
        $MemoryUsed = $MemoryParts[0]
        $MemoryLimit = $MemoryParts[1]
        
        # Convert memory to MB
        function Convert-MemoryToMB {
            param([string]$MemoryString)
            
            if ($MemoryString -match '(\d+\.?\d*)\s*(\w+)') {
                $Value = [double]$Matches[1]
                $Unit = $Matches[2].ToUpper()
                
                switch ($Unit) {
                    'B' { return $Value / 1MB }
                    'KB' { return $Value / 1KB }
                    'KIB' { return $Value * 1024 / 1MB }
                    'MB' { return $Value }
                    'MIB' { return $Value * 1024 * 1024 / 1MB }
                    'GB' { return $Value * 1024 }
                    'GIB' { return $Value * 1024 * 1024 * 1024 / 1MB }
                    default { return $Value }
                }
            }
            return 0
        }
        
        $MemoryUsedMB = Convert-MemoryToMB -MemoryString $MemoryUsed
        $MemoryLimitMB = Convert-MemoryToMB -MemoryString $MemoryLimit
        $MemoryPercent = if ($MemoryLimitMB -gt 0) { [math]::Round(($MemoryUsedMB / $MemoryLimitMB) * 100, 2) } else { 0 }
        
        # Parse network I/O
        $NetworkParts = $Stats.NetIO -split ' / '
        $NetworkIn = $NetworkParts[0]
        $NetworkOut = $NetworkParts[1]
        
        # Parse block I/O
        $BlockParts = $Stats.BlockIO -split ' / '
        $BlockRead = $BlockParts[0]
        $BlockWrite = $BlockParts[1]
        
        return @{
            Timestamp = Get-Date
            ContainerName = $Stats.Name
            ContainerID = $Stats.Container.Substring(0, 12)
            CPU_Percent = $CpuPercent
            Memory_Used_MB = [math]::Round($MemoryUsedMB, 2)
            Memory_Limit_MB = [math]::Round($MemoryLimitMB, 2)
            Memory_Percent = $MemoryPercent
            Network_In = $NetworkIn
            Network_Out = $NetworkOut
            Block_Read = $BlockRead
            Block_Write = $BlockWrite
            PIDs = $Stats.PIDs
            Status = if ($Container) { $Container.State.Status } else { "unknown" }
            Health = if ($Container -and $Container.State.Health) { $Container.State.Health.Status } else { "none" }
            Uptime = if ($Container) { 
                $StartTime = [datetime]$Container.State.StartedAt
                (Get-Date).Subtract($StartTime).ToString("hh\:mm\:ss")
            } else { "unknown" }
        }
    }
    catch {
        Write-Warning "Failed to get container stats: $($_.Exception.Message)"
        return $null
    }
}

function Get-ApplicationMetrics {
    param([string]$BaseUrl = "http://localhost:8000")
    
    try {
        # Get application health
        $HealthResponse = Invoke-RestMethod -Uri "$BaseUrl/health" -Method GET -TimeoutSec 5
        
        # Get application metrics (Prometheus format)
        $MetricsResponse = Invoke-WebRequest -Uri "$BaseUrl/metrics" -Method GET -TimeoutSec 5
        
        # Parse some basic metrics from Prometheus format
        $RequestsTotal = 0
        if ($MetricsResponse.Content -match 'app_requests_total\{[^}]*\}\s+(\d+)') {
            $RequestsTotal = [int]$Matches[1]
        }
        
        return @{
            Health_Status = $HealthResponse.status
            Health_Uptime = $HealthResponse.uptime
            Requests_Total = $RequestsTotal
            Last_Check = Get-Date
        }
    }
    catch {
        Write-Warning "Failed to get application metrics: $($_.Exception.Message)"
        return @{
            Health_Status = "unavailable"
            Health_Uptime = 0
            Requests_Total = 0
            Last_Check = Get-Date
        }
    }
}

function Display-ContainerMetrics {
    param($Stats, $AppMetrics)
    
    if (-not $Stats) {
        Write-Error "Container not found or not running"
        return
    }
    
    # Clear screen for real-time display
    Clear-Host
    
    Write-Host "🐳 Docker Container Monitoring - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor $Blue
    Write-Host "=" * 80 -ForegroundColor $Blue
    
    # Container basic info
    Write-Host "`n📋 Container Information:" -ForegroundColor $Cyan
    Write-Host "  Name: $($Stats.ContainerName)" -ForegroundColor $Green
    Write-Host "  ID: $($Stats.ContainerID)" -ForegroundColor $Green
    Write-Host "  Status: $($Stats.Status)" -ForegroundColor $(if ($Stats.Status -eq "running") { $Green } else { $Red })
    Write-Host "  Health: $($Stats.Health)" -ForegroundColor $(if ($Stats.Health -eq "healthy") { $Green } elseif ($Stats.Health -eq "unhealthy") { $Red } else { $Yellow })
    Write-Host "  Uptime: $($Stats.Uptime)" -ForegroundColor $Green
    
    # Resource usage
    Write-Host "`n💻 Resource Usage:" -ForegroundColor $Cyan
    Write-Host "  CPU: $($Stats.CPU_Percent)%" -ForegroundColor $(if ($Stats.CPU_Percent -gt 80) { $Red } elseif ($Stats.CPU_Percent -gt 50) { $Yellow } else { $Green })
    Write-Host "  Memory: $($Stats.Memory_Used_MB) MB / $($Stats.Memory_Limit_MB) MB ($($Stats.Memory_Percent)%)" -ForegroundColor $(if ($Stats.Memory_Percent -gt 80) { $Red } elseif ($Stats.Memory_Percent -gt 50) { $Yellow } else { $Green })
    Write-Host "  PIDs: $($Stats.PIDs)" -ForegroundColor $Green
    
    # Network I/O
    Write-Host "`n🌐 Network I/O:" -ForegroundColor $Cyan
    Write-Host "  Input: $($Stats.Network_In)" -ForegroundColor $Green
    Write-Host "  Output: $($Stats.Network_Out)" -ForegroundColor $Green
    
    # Block I/O
    Write-Host "`n💾 Block I/O:" -ForegroundColor $Cyan
    Write-Host "  Read: $($Stats.Block_Read)" -ForegroundColor $Green
    Write-Host "  Write: $($Stats.Block_Write)" -ForegroundColor $Green
    
    # Application metrics
    if ($AppMetrics) {
        Write-Host "`n🚀 Application Metrics:" -ForegroundColor $Cyan
        Write-Host "  Health: $($AppMetrics.Health_Status)" -ForegroundColor $(if ($AppMetrics.Health_Status -eq "healthy") { $Green } else { $Red })
        Write-Host "  App Uptime: $([math]::Round($AppMetrics.Health_Uptime, 2))s" -ForegroundColor $Green
        Write-Host "  Total Requests: $($AppMetrics.Requests_Total)" -ForegroundColor $Green
    }
    
    # Performance indicators
    Write-Host "`n📈 Performance Indicators:" -ForegroundColor $Cyan
    $PerfStatus = "Good"
    $PerfColor = $Green
    
    if ($Stats.CPU_Percent -gt 80 -or $Stats.Memory_Percent -gt 80) {
        $PerfStatus = "High Usage"
        $PerfColor = $Red
    }
    elseif ($Stats.CPU_Percent -gt 50 -or $Stats.Memory_Percent -gt 50) {
        $PerfStatus = "Moderate Usage"
        $PerfColor = $Yellow
    }
    
    Write-Host "  Overall Status: $PerfStatus" -ForegroundColor $PerfColor
    
    # Show recent logs if requested
    if ($ShowLogs) {
        Write-Host "`n📝 Recent Logs (last 10 lines):" -ForegroundColor $Cyan
        try {
            $Logs = docker logs --tail 10 $ContainerName 2>&1
            if ($Logs) {
                $Logs | ForEach-Object {
                    Write-Host "  $_" -ForegroundColor $Yellow
                }
            }
        }
        catch {
            Write-Host "  Unable to fetch logs" -ForegroundColor $Red
        }
    }
    
    Write-Host "`n" -NoNewline
    Write-Host "Press Ctrl+C to stop monitoring..." -ForegroundColor $Magenta
}

function Save-MetricsToFile {
    param($Stats, $AppMetrics)
    
    if (-not $Stats) { return }
    
    $MetricEntry = @{
        Container = $Stats
        Application = $AppMetrics
    }
    
    $Script:MetricsHistory += $MetricEntry
    
    # Save to JSON file every 10 entries
    if ($MetricsHistory.Count % 10 -eq 0) {
        $MetricsFile = "container-metrics-$(Get-Date -Format 'yyyyMMdd').json"
        $MetricsHistory | ConvertTo-Json -Depth 4 | Out-File -FilePath $MetricsFile -Encoding UTF8
        Write-Status "Metrics saved to $MetricsFile" $Blue
    }
}

function Start-Monitoring {
    Write-Status "Starting container monitoring..." $Blue
    Write-Status "Container: $ContainerName" $Blue
    Write-Status "Interval: $IntervalSeconds seconds" $Blue
    if ($DurationMinutes -gt 0) {
        Write-Status "Duration: $DurationMinutes minutes" $Blue
    }
    else {
        Write-Status "Duration: Indefinite (Ctrl+C to stop)" $Blue
    }
    
    $StartTime = Get-Date
    $EndTime = if ($DurationMinutes -gt 0) { $StartTime.AddMinutes($DurationMinutes) } else { $null }
    
    try {
        while ($true) {
            # Check if we should stop based on duration
            if ($EndTime -and (Get-Date) -gt $EndTime) {
                Write-Success "Monitoring completed after $DurationMinutes minutes"
                break
            }
            
            # Get metrics
            $ContainerStats = Get-ContainerStats -ContainerName $ContainerName
            $AppMetrics = Get-ApplicationMetrics
            
            # Display metrics
            Display-ContainerMetrics -Stats $ContainerStats -AppMetrics $AppMetrics
            
            # Save metrics if requested
            if ($SaveMetrics) {
                Save-MetricsToFile -Stats $ContainerStats -AppMetrics $AppMetrics
            }
            
            # Wait for next interval
            Start-Sleep -Seconds $IntervalSeconds
        }
    }
    catch [System.Management.Automation.PipelineStoppedException] {
        Write-Host "`n" -NoNewline
        Write-Status "Monitoring stopped by user" $Yellow
    }
    catch {
        Write-Error "Monitoring error: $($_.Exception.Message)"
    }
    finally {
        # Final metrics save
        if ($SaveMetrics -and $MetricsHistory.Count -gt 0) {
            $FinalMetricsFile = "container-metrics-final-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
            $MetricsHistory | ConvertTo-Json -Depth 4 | Out-File -FilePath $FinalMetricsFile -Encoding UTF8
            Write-Success "Final metrics saved to $FinalMetricsFile"
            
            # Generate summary report
            $Summary = @{
                monitoring_session = @{
                    start_time = $StartTime.ToString("yyyy-MM-dd HH:mm:ss")
                    end_time = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
                    duration_minutes = [math]::Round((Get-Date).Subtract($StartTime).TotalMinutes, 2)
                    samples_collected = $MetricsHistory.Count
                }
                performance_summary = @{
                    avg_cpu_percent = [math]::Round(($MetricsHistory.Container.CPU_Percent | Measure-Object -Average).Average, 2)
                    max_cpu_percent = ($MetricsHistory.Container.CPU_Percent | Measure-Object -Maximum).Maximum
                    avg_memory_percent = [math]::Round(($MetricsHistory.Container.Memory_Percent | Measure-Object -Average).Average, 2)
                    max_memory_percent = ($MetricsHistory.Container.Memory_Percent | Measure-Object -Maximum).Maximum
                }
            }
            
            $SummaryFile = "monitoring-summary-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
            $Summary | ConvertTo-Json -Depth 3 | Out-File -FilePath $SummaryFile -Encoding UTF8
            Write-Success "Monitoring summary saved to $SummaryFile"
        }
    }
}

# Main execution
try {
    Start-Monitoring
}
catch {
    Write-Error "Monitoring failed: $($_.Exception.Message)"
    exit 1
}
