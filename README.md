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

### sandbox TODO

- [ ] Implement limiting file system access.
- [ ] Implement limiting network access.
- [ ] implement start in the sandboxed environment.
