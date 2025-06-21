# Some useful PowerShell scripts

## measure.ps1

This script measures the time and memory usage of a provided command. Command must read from standard input and write to standard output.

### measure usage

```powershell
.\measure.ps1 -f <filePath> -i <inputFile> -o <outputFile>
```

Where:

- `-f <filePath>`: Path to the script or command to be measured.
- `-i <inputFile>`: Input data file for the command.
- `-o <outputFile>`: Output file where the results will be saved.

### measure example

```powershell
.\measure.ps1 -f .\shell_sort.exe -i .\input1.txt -o .\output1.txt
{
    "filePath":  ".\\shell_sort.exe",
    "inputFile":  ".\\input1.txt",
    "outputFile":  ".\\output1.txt",
    "memoryUsed":  "9.266 MB",
    "elapsedTime":  "0.897 seconds"
}
```

### measure TODO

## sandbox.ps1

This script runs a command in a sandboxed environment, limiting its access to the file system and network. Also it limits the command to a specified time and memory usage.

### sandbox usage

```powershell
.\sandbox.ps1 -f <filePath> -i <inputFile> -o <outputFile> [-t <timeLimit>] [-m <memoryLimit>]
```

Where:

- `-f <filePath>`: Path to the script or command to be sandboxed.
- `-i <inputFile>`: Input data file for the command.
- `-o <outputFile>`: Output file where the results will be saved.
- `-t <timeLimit>`: Optional time limit in milliseconds (default is 1000 milliseconds).
- `-m <memoryLimit>`: Optional memory limit in MB (default is 64 MB).

Script will output a JSON object with the following fields:

- `filePath`: Path to the script or command that was executed;
- `inputFile`: Exit code of the command (null if not applicable);
- `outputFile`: Path to the output file;
- `memoryUsage`: Memory usage of the command;
- `elapsedTime`: Time taken to execute the command;
- `exitCode`: Exit code of the command (null if not applicable);
- `status`: Status of the execution. Possible values are:
  - `Success`: The command executed successfully within the limits;
  - `MemoryLimitExceeded`: The command exceeded the memory limit;
  - `TimeLimitExceeded`: The command exceeded the time limit;
  - `ProcessNotStarted`: The command could not be started;
  - `ProcessFailed`: The command failed to execute.

#### sandbox example

```powershell
.\sandbox.ps1 -f .\shell_sort.exe -i .\input1.txt -o .\output1.txt
{
    "filePath":  ".\\shell_sort.exe",
    "inputFile":  ".\\input1.txt",
    "outputFile":  ".\\output1.txt",
    "memoryUsed":  "9.266 MB",
    "elapsedTime":  "0.897 seconds",
    "exitCode":  null,
    "status":  "Success"
}
```

### sandbox TODO

- [ ] Implement limiting file system access.
- [ ] Implement limiting network access.
- [ ] implement start in the sandboxed environment.
