# Documentation

## Description
This project provides scripts to generate fleet tokens for use with TeslaMate, evcc or similar applications. The scripts are designed to be executed in on line on different operating systems, including Windows, Linux, and macOS.

## Usage

### Windows
To execute the script on Windows, use the following command in PowerShell:

```powershell
iex "& { $(iwr -UseBasicParsing https://raw.githubusercontent.com/MyTeslaMate/generate-fleet-tokens/refs/heads/main/tokens.ps1) } test 1234"
```

### Linux
To run the script on Linux, use the following command in your terminal:

```bash
curl -fsSL https://raw.githubusercontent.com/MyTeslaMate/generate-fleet-tokens/refs/heads/main/tokens.sh | bash -s -- test 1234
```


## License
This project is licensed under the MIT License. See the `LICENSE` file for more details.