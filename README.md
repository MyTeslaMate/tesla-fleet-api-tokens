# Tesla Tokens Generator for Tesla Fleet API

## Description
This project offers streamlined scripts to generate access/secret tokens from your own [Tesla Application API](https://developer.tesla.com/docs/fleet-api).

Ideal for generating tokens compatible with TeslaMate, evcc, or similar applications. These scripts are crafted for effortless execution on multiple operating systems, including Windows, Linux, and macOS.

## Prerequisites

Before using the scripts, you need to create an account on [MyTeslaMate](https://app.myteslamate.com/) and go to the [Tesla API section](https://app.myteslamate.com/tesla) to setup your own Tesla API Application.

Attention, the last parameter depends on your user, so it is important to copy the customized installation script from the [Tesla API section](https://app.myteslamate.com/tesla) of your MyTeslaMate account.

## Usage

### Windows
To execute the script on Windows, use the following command in PowerShell:

```powershell
iex "& { $(iwr -UseBasicParsing https://raw.githubusercontent.com/MyTeslaMate/generate-fleet-tokens/refs/heads/main/tokens.ps1) } REPLACE_WITH_YOUR_CUSTOM_DOMAIN"
```

### Linux
To run the script on Linux, use the following command in your terminal:

```bash
curl -fsSL https://raw.githubusercontent.com/MyTeslaMate/generate-fleet-tokens/refs/heads/main/tokens.sh | bash -s -- REPLACE_WITH_YOUR_CUSTOM_DOMAIN
```


## License
This project is licensed under the MIT License. See the [`LICENSE`](LICENCE.md) file for more details.