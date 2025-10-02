# Hedge Scheduler Service - Windows Version

This directory contains Windows-compatible versions of the Hedge Scheduler service control script.

## Files

- `get_hedge_service.sh` - Original Linux bash script (Ubuntu)
- `get_hedge_service.ps1` - Windows PowerShell script
- `get_hedge_service.bat` - Windows batch file wrapper for PowerShell script

## Usage

### PowerShell (Recommended)

```powershell
# Start the scheduler
.\get_hedge_service.ps1 -Action start

# Stop the scheduler
.\get_hedge_service.ps1 -Action stop

# Check status
.\get_hedge_service.ps1 -Action status

# View logs
.\get_hedge_service.ps1 -Action logs

# Restart the scheduler
.\get_hedge_service.ps1 -Action restart
```

### Batch File (Alternative)

```cmd
# Start the scheduler
get_hedge_service.bat start

# Stop the scheduler
get_hedge_service.bat stop

# Check status
get_hedge_service.bat status

# View logs
get_hedge_service.bat logs

# Restart the scheduler
get_hedge_service.bat restart
```

## Key Differences from Linux Version

1. **Process Management**: Uses PowerShell jobs instead of background processes
2. **PID Tracking**: Stores job IDs instead of process PIDs
3. **Python Detection**: Automatically finds Python in virtual environment or system-wide
4. **Logging**: Same logging mechanism, but uses PowerShell redirection
5. **Commands**: Uses PowerShell cmdlets instead of Unix commands

## Requirements

- Windows PowerShell 5.1 or higher
- Python 3.8+ (automatically detected)
- Virtual environment in `.venv` folder (optional but recommended)

## Features

- ✅ Automatic Python executable detection
- ✅ Virtual environment support
- ✅ Colored output for better readability
- ✅ Graceful process termination
- ✅ Job status monitoring
- ✅ Log file management
- ✅ Cross-platform compatibility

## Troubleshooting

### Execution Policy Error
If you get execution policy errors, run:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Python Not Found
Ensure Python is installed and accessible. The script checks:
1. `.venv\Scripts\python.exe` (virtual environment)
2. `python` command
3. `python3` command

### Permission Issues
Run PowerShell or Command Prompt as Administrator if you encounter permission errors.

## Migration from Linux

The Windows version maintains the same interface and functionality as the Linux version:

| Linux Command | Windows Equivalent |
|---------------|-------------------|
| `./get_hedge_service.sh start` | `.\get_hedge_service.ps1 -Action start` |
| `./get_hedge_service.sh stop` | `.\get_hedge_service.ps1 -Action stop` |
| `./get_hedge_service.sh status` | `.\get_hedge_service.ps1 -Action status` |

The log files and PID files use the same names and locations for compatibility.