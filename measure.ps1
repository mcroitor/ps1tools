# This script measures the time execution and memory usage of a
# program specified by the user.
# Usage: measure.ps1 -f <filePath> -i <inputFile> -o <outputFile>
#   - <filePath> is the path to the executable file
#   - <inputFile> is the path to the input file (input data for the executable)
#   - <outputFile> is the path to the output file (where the results will be written)
# measure result will be written to the console
# output format in JSON:
# {
#   "filePath": "<filePath>",
#   "inputFile": "<inputFile>",
#   "outputFile": "<outputFile>",
#   "memoryUsed": <memoryUsed in MB>,
#   "elapsedTime": <elapsedTime in seconds>
# }

param(
    [Parameter(Mandatory=$true)]
    [Alias("f")]
    [string]$filePath,

    [Parameter(Mandatory=$true)]
    [Alias("i")]
    [string]$inputFile,

    [Parameter(Mandatory=$true)]
    [Alias("o")]
    [string]$outputFile
)

function Show-Usage {
    Write-Host "Usage: measure.ps1 -f <filePath> -i <inputFile> -o <outputFile>"
    Write-Host "  -f <filePath>   : Path to the executable file"
    Write-Host "  -i <inputFile>  : Path to the input file (input data for the executable)"
    Write-Host "  -o <outputFile> : Path to the output file (where the results will be written)"
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

if (-not (Test-Path (Split-Path $outputFile -Parent))) {
    Write-Host "Error: Output directory does not exist - $(Split-Path $outputFile -Parent)"
    Show-Usage
    exit 1
}

#defs
$msDelay = 10 # milliseconds for process monitoring timeout
$memBlock = 1MB # Memory block size for measurement in MB
$digitsAfterDecimal = 2
$timeoutSeconds = 300 # Maximum allowed execution time in seconds

# Start measuring memory usage and time
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$process = Start-Process -FilePath $filePath `
    -RedirectStandardInput $inputFile `
    -RedirectStandardOutput $outputFile `
    -NoNewWindow -PassThru

if($null -eq $process) {
    Write-Host "Error: Failed to start process - $filePath"
    exit 1
}

# monitor the process
$memoryUsed = 0

try {
    while(-not $process.HasExited) {
        Start-Sleep -Milliseconds $msDelay
        if ($stopwatch.Elapsed.TotalSeconds -gt $timeoutSeconds) {
            Write-Host "Error: Process timeout exceeded ($timeoutSeconds seconds). Killing process."
            $process.Kill()
            $process.WaitForExit()
            Write-Host "Process killed due to timeout."
            break
        }
        try {
            $currentProcess = Get-Process -Id $process.Id -ErrorAction Stop
            $memory = $currentProcess.WorkingSet64 / $memBlock # Convert bytes to MB
            if ($memory -gt $memoryUsed) {
                $memoryUsed = $memory
            }
        } catch {
            # Process may have exited, ignore error
        }
    }
}
catch {
    Write-Host "Error: An error occurred while monitoring the process."
    exit 1
}
$stopwatch.Stop()

# Output the formatted result
$elapsedTime = $stopwatch.Elapsed.TotalSeconds
$result = @{
    filePath = $filePath
    inputFile = $inputFile
    outputFile = $outputFile
    memoryUsed = [math]::Round($memoryUsed, $digitsAfterDecimal)
    elapsedTime = [math]::Round($elapsedTime, $digitsAfterDecimal)
}

Write-Output ($result | ConvertTo-Json -Depth 3)