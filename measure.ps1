# This script measures the time execution and memory usage of a
# program specified by the user.
# Usage: measure.ps1 -f <filePath> -i <inputFile> -o <outputFile>
#   - <filePath> is the path to the executable file
#   - <inputFile> is the path to the input file (input data for the executable)
#   - <outputFile> is the path to the output file (where the results will be written)
# measure result will be written to the console
# output format: | <filePath>| <input> | <output> | <memoryUsage> | <elapsedTime> |

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

#defs
$msDelay = 10 # milliseconds
$memBlock = 1MB
$digitsAfterDecimal = 2
$format = "{0} | {1} | {2} | {3:N$digitsAfterDecimal} MB | {4:N$digitsAfterDecimal} seconds |"

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
$memoryUsage = 0

try {
    while(-not $process.HasExited) {
        Start-Sleep -Milliseconds $msDelay
        try {
            $currentProcess = Get-Process -Id $process.Id -ErrorAction Stop
            $memory = $currentProcess.WorkingSet64 / $memBlock # Convert bytes to MB
            if ($memory -gt $memoryUsage) {
                $memoryUsage = $memory
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
$result = $format -f $filePath, $inputFile, $outputFile, $memoryUsage, $elapsedTime
Write-Host $result
