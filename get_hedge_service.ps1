# Hedge Scheduler Service Control Script for Windows
# PowerShell version of the Linux bash script

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("start", "stop", "status", "logs", "restart")]
    [string]$Action
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$HedgeScript = Join-Path $ScriptDir "get_hedge_fetcher.py"
$PidFile = Join-Path $ScriptDir "hedge_scheduler.pid"
$LogFile = Join-Path $ScriptDir "hedge_scheduler.log"

function Write-ColorOutput {
    param([string]$Message, [string]$Color = "White")
    Write-Host $Message -ForegroundColor $Color
}

function Test-ProcessRunning {
    param([int]$ProcessId)
    try {
        Get-Process -Id $ProcessId -ErrorAction Stop | Out-Null
        return $true
    }
    catch {
        return $false
    }
}

function Get-PythonExecutable {
    # Try to find Python executable in virtual environment first
    $venvPython = Join-Path $ScriptDir ".venv\Scripts\python.exe"
    if (Test-Path $venvPython) {
        return $venvPython
    }

    # Fallback to system Python
    try {
        $pythonPath = Get-Command python -ErrorAction Stop
        return $pythonPath.Source
    }
    catch {
        try {
            $pythonPath = Get-Command python3 -ErrorAction Stop
            return $pythonPath.Source
        }
        catch {
            Write-ColorOutput "Error: Python executable not found. Please ensure Python is installed." "Red"
            exit 1
        }
    }
}

switch ($Action) {
    "start" {
        if (Test-Path $PidFile) {
            $existingPid = Get-Content $PidFile -ErrorAction SilentlyContinue
            if ($existingPid -and (Test-ProcessRunning -ProcessId $existingPid)) {
                Write-ColorOutput "Hedge Scheduler is already running (PID: $existingPid)" "Green"
                exit 1
            } else {
                Write-ColorOutput "Removing stale PID file" "Yellow"
                Remove-Item $PidFile -ErrorAction SilentlyContinue
            }
        }

        Write-ColorOutput "Starting Hedge Scheduler..." "Green"
        Write-ColorOutput "Working directory: $ScriptDir" "Cyan"
        Write-ColorOutput "Log file: $LogFile" "Cyan"

        $pythonExe = Get-PythonExecutable

        # Start the Python script as a background job
        try {
            $job = Start-Job -ScriptBlock {
                param($pythonExe, $hedgeScript, $logFile)
                # Set UTF-8 encoding to handle Unicode characters properly
                $env:PYTHONIOENCODING = "utf-8"
                & $pythonExe $hedgeScript 15 *>> $logFile
            } -ArgumentList $pythonExe, $HedgeScript, $LogFile

            # Wait a moment for the job to start
            Start-Sleep -Seconds 1

            if ($job.State -eq "Running") {
                $job.Id | Out-File $PidFile
                Write-ColorOutput "Hedge Scheduler started successfully (Job ID: $($job.Id))" "Green"
                Write-ColorOutput "To view logs: Get-Content $LogFile -Tail 20 -Wait" "Cyan"
                Write-ColorOutput "To stop: .\get_hedge_service.ps1 -Action stop" "Cyan"
            } else {
                Write-ColorOutput "Failed to start Hedge Scheduler" "Red"
                exit 1
            }
        }
        catch {
            Write-ColorOutput "Error starting service: $($_.Exception.Message)" "Red"
            exit 1
        }
    }

    "stop" {
        if (-not (Test-Path $PidFile)) {
            Write-ColorOutput "Hedge Scheduler is not running (PID file not found)" "Red"
            exit 1
        }

        $jobId = Get-Content $PidFile -ErrorAction SilentlyContinue
        if ($jobId) {
            try {
                $job = Get-Job -Id $jobId -ErrorAction Stop
                if ($job.State -eq "Running") {
                    Write-ColorOutput "Stopping Hedge Scheduler (Job ID: $jobId)..." "Yellow"

                    # Stop the job
                    Stop-Job -Id $jobId
                    Remove-Job -Id $jobId -Force

                    # Wait for job to stop
                    $timeout = 10
                    $stopped = $false
                    for ($i = 1; $i -le $timeout; $i++) {
                        try {
                            $job = Get-Job -Id $jobId -ErrorAction Stop
                            if ($job.State -ne "Running") {
                                $stopped = $true
                                break
                            }
                        }
                        catch {
                            $stopped = $true
                            break
                        }
                        Start-Sleep -Seconds 1
                    }

                    if (-not $stopped) {
                        Write-ColorOutput "Force stopping..." "Yellow"
                        # Force stop if still running
                        try {
                            Stop-Job -Id $jobId -Force
                            Remove-Job -Id $jobId -Force
                        }
                        catch {
                            Write-ColorOutput "Failed to force stop process" "Red"
                        }
                    }

                    Remove-Item $PidFile -ErrorAction SilentlyContinue
                    Write-ColorOutput "Hedge Scheduler stopped successfully" "Green"
                } else {
                    Write-ColorOutput "Job with ID $jobId is not running" "Red"
                    Remove-Item $PidFile -ErrorAction SilentlyContinue
                }
            }
            catch {
                Write-ColorOutput "Job with ID $jobId not found" "Red"
                Remove-Item $PidFile -ErrorAction SilentlyContinue
            }
        } else {
            Write-ColorOutput "Invalid PID file format" "Red"
            Remove-Item $PidFile -ErrorAction SilentlyContinue
        }
    }

    "status" {
        if (Test-Path $PidFile) {
            $jobId = Get-Content $PidFile -ErrorAction SilentlyContinue
            if ($jobId) {
                try {
                    $job = Get-Job -Id $jobId -ErrorAction Stop
                    if ($job.State -eq "Running") {
                        Write-ColorOutput "Hedge Scheduler is running (Job ID: $jobId)" "Green"
                        Write-ColorOutput "Command: $($job.Command)" "Cyan"
                        $runtime = New-TimeSpan -Start $job.PSBeginTime -End (Get-Date)
                        Write-ColorOutput "Runtime: $($runtime.ToString())" "Cyan"
                    } else {
                        Write-ColorOutput "Hedge Scheduler is not running (PID file exists but job is stopped)" "Red"
                        Remove-Item $PidFile -ErrorAction SilentlyContinue
                    }
                }
                catch {
                    Write-ColorOutput "Hedge Scheduler is not running (job not found)" "Red"
                    Remove-Item $PidFile -ErrorAction SilentlyContinue
                }
            } else {
                Write-ColorOutput "Hedge Scheduler is not running (invalid PID file)" "Red"
                Remove-Item $PidFile -ErrorAction SilentlyContinue
            }
        } else {
            Write-ColorOutput "Hedge Scheduler is not running" "Red"
        }
    }

    "logs" {
        if (Test-Path $LogFile) {
            Write-ColorOutput "Last Hedge Scheduler logs:" "Cyan"
            Write-ColorOutput "================================" "Cyan"
            try {
                Get-Content $LogFile -Tail 20 -ErrorAction Stop
            }
            catch {
                Write-ColorOutput "Error reading log file: $($_.Exception.Message)" "Red"
            }
        } else {
            Write-ColorOutput "Log file not found: $LogFile" "Red"
        }
    }

    "restart" {
        Write-ColorOutput "Restarting Hedge Scheduler..." "Yellow"
        & $MyInvocation.MyCommand.Path -Action stop
        Start-Sleep -Seconds 2
        & $MyInvocation.MyCommand.Path -Action start
    }

    default {
        Write-ColorOutput "Hedge Scheduler Control Script for Windows" "Cyan"
        Write-ColorOutput "==========================================" "Cyan"
        Write-ColorOutput "Usage: .\get_hedge_service.ps1 -Action {start|stop|status|logs|restart}" "White"
        Write-ColorOutput "" "White"
        Write-ColorOutput "Commands:" "White"
        Write-ColorOutput "  start   - Start scheduler (every 15 minutes)" "White"
        Write-ColorOutput "  stop    - Stop scheduler" "White"
        Write-ColorOutput "  status  - Check status" "White"
        Write-ColorOutput "  logs    - Show recent logs" "White"
        Write-ColorOutput "  restart - Restart scheduler" "White"
        Write-ColorOutput "" "White"
        Write-ColorOutput "Working directory: $ScriptDir" "Cyan"
        Write-ColorOutput "Log file: $LogFile" "Cyan"
        exit 1
    }
}