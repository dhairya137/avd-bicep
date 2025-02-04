# Azure Virtual Desktop Infrastructure with Bicep

This project implements a complete Azure Virtual Desktop (AVD) infrastructure using Bicep templates. It includes secure password management through Azure Key Vault and automated role assignments for users.

## Architecture Overview

The solution deploys the following components:

1. **Resource Group** (resourceGroup.bicep)
   - Central resource group for all AVD components
   - Location: Central India
   - Contains all related resources

2. **Host Pool** (hostPool.bicep)
   - Type: Pooled
   - Load Balancer: Depth First
   - Max Session Limit: 5
   - RDP Properties: Configured for optimal user experience
   - Validation Environment enabled

3. **Application Group** (applicationGroup.bicep)
   - Type: Desktop
   - Linked to Host Pool
   - Manages application access

4. **Workspace** (workspace.bicep)
   - User-friendly interface for AVD
   - Connected to Application Group
   - Public network access enabled

5. **Virtual Network** (virtualNetwork.bicep)
   - Address Space: 10.0.0.0/16
   - Two subnets:
     - subnet1: 10.0.0.0/24
     - subnet2: 10.0.1.0/24

6. **Virtual Machine** (virtualMachine.bicep)
   - Windows 11 AVD-optimized image
   - Size: Standard_B1ms
   - AAD Join enabled
   - Network interface with public IP
   - Connected to subnet1
   - Extensions:
     - AVD Agent
     - AAD Login for Windows

7. **Key Vault** (keyVault.bicep)
   - Secure storage for VM admin password
   - Enabled for deployment and disk encryption
   - Access policies for authorized users

8. **Role Assignments**
   - Integrated in virtualMachine.bicep
   - Two key roles assigned to users:
     - Virtual Machine User Login
     - Desktop Virtualization User

## Security Features

1. **Secure Password Management**
   - Admin passwords stored in Azure Key Vault
   - No passwords in code or parameter files
   - Easy password rotation without code changes
   - Controlled access through Key Vault policies

2. **Role-Based Access Control (RBAC)**
   - Automated role assignments
   - Principle of least privilege
   - User access managed through Azure AD

## Deployment Process

1. **Prerequisites**
   ```bash
   # Get your Azure AD Object ID
   az ad signed-in-user show --query id --output tsv
   ```

2. **Parameter Configuration**
   - Update main.bicepparams.json with:
     - Your Azure AD Object ID for Key Vault access
     - User Principal IDs for role assignments
     - Other environment-specific parameters

3. **Initial Deployment**
   ```bash
   az deployment sub create \
     --location centralindia \
     --template-file main.bicep \
     --parameters @main.bicepparams.json
   ```

4. **Set VM Password**
   ```bash
   az keyvault secret set \
     --vault-name kv-rg-avd \
     --name vmAdminPassword \
     --value "YourSecurePassword123!"
   ```

## User Access Management

1. **Getting User Principal IDs**
   ```bash
   az ad user show --id user@domain.com --query id --output tsv
   ```

2. **Adding Users**
   - Add user principal IDs to the userPrincipalIds array in main.bicepparams.json
   - Users automatically get required roles:
     - Virtual Machine User Login
     - Desktop Virtualization User

## File Structure

```
.
├── main.bicep                 # Main deployment template
├── main.bicepparams.json      # Parameter values
├── Modules/
│   ├── applicationGroup.bicep  # Application group configuration
│   ├── hostPool.bicep         # Host pool configuration
│   ├── keyVault.bicep         # Key Vault for secure passwords
│   ├── resourceGroup.bicep     # Resource group creation
│   ├── virtualMachine.bicep    # VM with role assignments
│   ├── virtualNetwork.bicep    # Network configuration
│   └── workspace.bicep         # Workspace configuration
└── overview.md                # This documentation file
```

## Best Practices Implemented

1. **Modularity**
   - Separate Bicep modules for each component
   - Easy to maintain and update
   - Reusable components

2. **Security**
   - Secure password management
   - RBAC implementation
   - AAD integration

3. **Networking**
   - Structured network design
   - Subnet segregation
   - Public/Private access control

4. **Scalability**
   - Parameterized configurations
   - Easy to add more users
   - Flexible resource sizing

## Maintenance and Updates

1. **Password Rotation**
   - Update password in Key Vault
   - No deployment changes needed
   - Immediate effect on new deployments

2. **Adding Users**
   - Get user's Principal ID
   - Add to userPrincipalIds in parameters
   - Redeploy to apply roles

3. **Scaling**
   - Adjust VM size in parameters
   - Modify session host count
   - Update network ranges as needed

## Quick Start

For a quick deployment with default values:

1. Clone this repository
2. Get your Azure AD Object ID:
   ```bash
   az ad signed-in-user show --query id --output tsv
   ```
3. Update main.bicepparams.json with your Object ID
4. Deploy:
   ```bash
   az deployment sub create \
     --location centralindia \
     --template-file main.bicep \
     --parameters @main.bicepparams.json
   ```
5. Set VM password in Key Vault
6. Access AVD through Microsoft Windows Desktop client
