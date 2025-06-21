# This script sandboxes an app by the time execution and memory usage.
# Usage: sandbox.ps1 -f <filePath> -i <inputFile> -o <outputFile> [-m <memoryLimit>] [-t <timeLimit>]
#   - <filePath> is the path to the executable file
#   - <inputFile> is the path to the input file (input data for the executable)
#   - <outputFile> is the path to the output file (where the results will be written)
#   - <memoryLimit> is the maximum memory usage in MB (optional), default is 64MB
#   - <timeLimit> is the maximum execution time in milliseconds (optional), default is 1000 millisecond
# Result of execution will be written to the console in the JSON format:
#
# {
#   "filePath": "<filePath>",
#   "inputFile": "<inputFile>",
#   "outputFile": "<outputFile>",
#   "memoryUsage": <memoryUsage in MB>,
#   "elapsedTime": <elapsedTime in seconds>,
#   "status": "<status of execution>"
# }
# Possible status values:
#   - "Success" if the process completed within the limits
#   - "MemoryLimitExceeded" if the process exceeded the memory limit
#   - "TimeLimitExceeded" if the process exceeded the time limit
#   - "ProcessNotStarted" if the process could not be started
#   - "ProcessFailed" if the process failed to execute
param(
    [Parameter(Mandatory=$true)]
    [Alias("f")]
    [string]$filePath,

    [Parameter(Mandatory=$true)]
    [Alias("i")]
    [string]$inputFile,

    [Parameter(Mandatory=$true)]
    [Alias("o")]
    [string]$outputFile,

    [Parameter(Mandatory=$false)]
    [Alias("m", "memoryLimit")]
    [int]$memoryLimitMB = 64,

    [Parameter(Mandatory=$false)]
    [Alias("t", "timeLimit")]
    [int]$timeLimitMS = 1000
)

# usage function
function Show-Usage {
    Write-Host "Usage: sandbox.ps1 -f <filePath> -i <inputFile> -o <outputFile> [-m <memoryLimit>] [-t <timeLimit>]"
    Write-Host "  -f, --filePath     Path to the executable file"
    Write-Host "  -i, --inputFile    Path to the input file"
    Write-Host "  -o, --outputFile   Path to the output file"
    Write-Host "  -m, --memoryLimit  Maximum memory usage in MB (default: 64MB)"
    Write-Host "  -t, --timeLimit    Maximum execution time in milliseconds (default: 1000ms)"
}

# Validate parameters
if (-not (Test-Path $filePath)) {
    Write-Host "Error: File not found - $filePath"
    Show-Usage
    exit 1
}

if (-not (Test-Path $inputFile)) {
    Write-Host "Error: Input file not found - $inputFile"
    Show-Usage
    exit 1
}

#defs
$msDelay = 10 # milliseconds
$memBlock = 1MB
$digitsAfterDecimal = 3

$status = "Success"
$usedMemory = 0
$elapsedTime = 0

# Start measuring memory usage and time
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

$process = Start-Process -FilePath $filePath `
    -RedirectStandardInput $inputFile `
    -RedirectStandardOutput $outputFile `
    -ErrorAction Stop `
    -NoNewWindow -PassThru `
    -PriorityClass "BelowNormal"

if($null -eq $process) {
    $result = @{
        filePath = $filePath
        inputFile = $inputFile
        outputFile = $outputFile
        memoryUsage = 0
        elapsedTime = 0
        status = "ProcessNotStarted"
    }
    Write-Output ($result | ConvertTo-Json)
    exit 1
}

# monitor the process
try {
    while(-not $process.HasExited) {
        Start-Sleep -Milliseconds $msDelay
        try {
            $currentProcess = Get-Process -Id $process.Id -ErrorAction Stop
            $memory = $currentProcess.WorkingSet64 / $memBlock
            if ($memory -gt $usedMemory) {
                $usedMemory = $memory
            }
        } catch {
            break # Process exited, break the loop
        }

        if ($usedMemory -gt $memoryLimitMB) {
            $status = "MemoryLimitExceeded"
            $process.Kill()
            break
        }
        if ($stopwatch.Elapsed.TotalMilliseconds -ge $timeLimitMS) {
            $status = "TimeLimitExceeded"
            $process.Kill()
            break
        }
    }
} catch {
    Write-Host "Error: Failed to monitor process - $_"
    exit 1
}

$stopwatch.Stop()
$elapsedTime = $stopwatch.Elapsed.TotalSeconds

# Optionally add exit code
$exitCode = $null
try { $exitCode = $process.ExitCode } catch {}

$result = @{
    filePath = $filePath
    inputFile = $inputFile
    outputFile = $outputFile
    memoryUsage = [math]::Round($usedMemory, $digitsAfterDecimal).ToString() + " MB"
    elapsedTime = [math]::Round($elapsedTime, $digitsAfterDecimal).ToString() + " seconds"
    status = $status
    exitCode = $exitCode
}

Write-Output ($result | ConvertTo-Json -Depth 3)