# Cardano Dev Box 

## Goals
Provision a SSH'able dev box in the cloud that is ready for Cardano development. This is one of the approaches as described in the guide [Lovelace Academy - Getting Started - Running a Full Cardano Node](https://learn.lovelace.academy/getting-started/running-a-full-node/).

## Prerequisites
 - **Azure CLI** [here](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-windows?view=azure-cli-latest#install-or-update)
 - **Terraform** [here](https://www.terraform.io/downloads.html)
 - **Visual Studio Code** [here](https://code.visualstudio.com/download) and the **Remote - SSH** extension 

## Provisioning Azure Infrastructure
Azure CLI and Terraform are cross-platform tools so you can run the same commands across different CPU architectures and OS's.
 - Login with `az login`
 - If required, set your relevant subscription `az account set --subscription ${YOUR_SUBSCRIPTION}` (verify using `az account show`)
 - Create `rg-vars.tfvars` variable assignment file with your variables (see rg-vars.tf for reference). **Example**:
 ```
ssh-allowlist = ["20.86.228.51"] # Your local IP address
location = "northeurope"
resource-prefix = "lla-tn-eun-dev"
storage-prefix = "llatneuncdb"
cdbvm-username = "sa"
cdbvm-size = "Standard_D4as_v4"
cdbvm-nic-accelerated-networking = true
cdbvm-comp-name = "cdb"
# Tags
tag-stage = "testnet"
 ```
 - Run `terraform init`
 - Run `terraform plan -var-file rg-vars.tfvars`
 - If the output looks good, run `terraform apply -var-file rg-vars.tfvars -auto-approve`
 - This will take about 2 minutes to provision the whole infrastructure and spit out the output parameters `sshpvk` and `cdbpip`.
 - Save the SSH private key to a file using `terraform output sshpvk > ssh.pem` for Linux or `terraform output sshpvk | Set-Content ssh.pem` for Windows (powershell required)

## SSH 
Using the SSH key output from Terraform, ensure the relevant security rules are applied with the key prep scripts below.
 
### SSH key prep (Linux)
`chmod 400 ssh.pem`

### SSH key prep (Windows)
```
$path = "ssh.pem"
icacls.exe $path /reset
icacls.exe $path /GRANT:R "$($env:USERNAME):(R)"
icacls.exe $path /inheritance:r
```

### SSH to Provisioned Azure Cloud VMs
`ssh -i ss.pem ss@20.54.24.228` where 20.54.24.228 is the output from `terraform output cdbpip`.

Note: If you are using Windows, ensure you have [OpenSSH](https://www.howtogeek.com/336775/how-to-enable-and-use-windows-10s-built-in-ssh-commands/) 

It is easy using the **Remote - SSH** extension in [Visual Studio Code](https://code.visualstudio.com/download) because it has both an integrated terminal and a full IDE for code manipulation.

### Troubleshooting SSH issues
If you are unable to SSH to the newly created VM please check the SSH NSG (`"${var.resource-prefix}-dev-nsg"`) rule in the Azure Portal and ensure your current IP is included. Don't forget to follow the steps in `SSH key prep` above too.

## Running the full Cardano Node
You can simply run [init.sh](./init.sh) to set the VM up with all the required dependencies and the files required to run a full Cardano node. You can choose to switch between testnet (default) and mainnet networks by commenting/uncommenting the relevant segments. This file can also be used locally in a fresh Linux environment. 
```
git clone https://github.com/LovelaceAcademy/CardanoDevBox.git
cd CardanoDevBox
bash init.sh
```
