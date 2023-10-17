# bicep-webdb-quickstrater
This repository can be used for quick depoloyment of web-db system using IaaS as web server and PostgreSQL as database. `main.bicep` deploys the components of the architecture bellow.

## Architecture
The overall architecture is like bellow. You can depoloy Azure Bastion as well by setting parameter(`'bastionEnabled'=='Enabled'`).
![](/imgs/webdb-arch.png)

## Deployment
As usually, first create the resource group for this deployment.
```bash
$ az group create --name MyResourceGroup --location japaneast
```
Deploy main.bicep options:

- With parameter file

```
$ az deployment group create --resource-group MyResourceGroup --template-file main.bicep --parameters main.bicepparams
```

- Without parameter file

This option, you have to fill the parameters in the prompt.

```
$ az deployment group create --resource-group MyResourceGroup --template-file main.bicep

vmAdminPassword: xxxx
```

# Lisence
This project is licensed under the MIT License, see the LICENSE.txt file for details.