# Configuration and Deployment

## Local Development Setup

### Prerequisites

* .NET SDK
* Docker Desktop (configured with Artifactory access)
* Node.js and npm (for frontend apps)
* Git with LFS
* PowerShell (for setup scripts)
* Redis (via Docker)
* SQL Server (via Docker)
* A Chromium-based browser

### Environment Variables

The following environment variables must be configured:

* GitHub Personal Access Token (PAT)
* Jira PAT
* ImperiumRepo - path to the imperium repository (e.g. `C:\source\imperium`)
* ImperiumToolingRepo - path to imperium-tooling repository

### Docker Login

```text
docker login -u [email] artifactory.fmgl.com.au
```

### Initial Setup

1. Set PowerShell execution policy: `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass`
2. Run the initial setup script from imperium-tooling: `.\..initialSetupAndOptionalSeed.ps1`
3. Choose environment when prompted:
    * 1 - Hazelmere
    * 2 - IronBridgeDemo (recommended for seeding)
    * 3 - FlindersDrive
    * 4 - FlyingFish

### Local Service URLs

| Service | URL |
|---------|-----|
| Field UI (asset RD4578) | `http://localhost:3001/` |
| Field UI (asset EX2366) | `http://localhost:3002/` |
| FMS Office (Overwatch) | `http://localhost:3010/` |

### Running Frontend Apps Locally

**Office (Overwatch)**:

1. Ensure the `local-fms-office` container is running
2. Update ImperiumHubUrl port in `Office/Overwatch/Overwatch.Web/ClientApp/public/config.js` to match the `office-signal` Docker container port
3. Run `npm ci` then `npm run start` from the ClientApp directory

**Field (Centurion)**:

1. Ensure the field container is running (e.g. `field-rd4578`)
2. Update ImperiumHubUrl port in `Field/Centurion/Centurion.Web/ClientApp/public/config.js` to match the `field-signal-rd4578` Docker container port
3. Run `npm ci` then `npm run start` from the ClientApp directory

## PlatformConfiguration.json

The root `PlatformConfiguration.json` file defines the service catalogue. Each service entry includes:

* **Port** - the port number the service listens on locally
* **Project path** - relative path to the .csproj file
* **Database** - the SQL Server database name (if applicable)
* **Environment overrides** - per-environment configuration

### Service Port Ranges

Services are assigned ports in functional ranges (examples):

* Mine Model services: 5100-5199
* Asset services: 5300-5599
* Assignment services: 5450-5499, 5660-5699
* Autonomy services: 6100-6899
* Data services: 5670-5699, 5800-5899

## Build and Deploy Pipeline

### GitHub Actions

Workflows are defined in `.github/workflows/` and handle:

* Building and testing on push/PR
* Docker image creation
* Publishing to Artifactory

### Octopus Deploy

Used for release management and deployment to environments. Manages:

* Environment promotion (dev, staging, production)
* Feature flags (e.g. `enable-robot-simulator`, `dev-assets`)
* Configuration injection per environment

### Deployment Targets

* **FMS Core** - Kubernetes clusters
* **FMS Field** - Deployed via Ansible onto assets (VAS - Vehicle Autonomy Stack)
* **FMS Office** - Installed on operator workstations

## Messaging Configuration

### RabbitMQ

Inter-service messaging backbone. Services publish and subscribe to topics for asynchronous communication. Docker configuration is in `Docker/RabbitMq/`.

### DDS (Data Distribution Service)

Used for real-time, low-latency communication with autonomous assets. QoS profiles define reliability and latency constraints. Configuration in `Common/FMG.Autonomy.Dds/`.

### SignalR

Real-time push to frontend applications:

* **Office Signal** - pushes data to Overwatch UI
* **Field Signal** - pushes data to Centurion in-cab UI

## Database Configuration

Services use SQL Server databases. Key aspects:

* Each service owns its database (micro-database pattern)
* Schema management via Entity Framework migrations
* Seeding utilities in `Common/HaulX.Seeding/`
* Database names are defined in PlatformConfiguration.json

## Simulation Environments

### NAsset

Scale testing platform using Akka.NET actors. Components:

* Nasset.Core - shared models
* Nasset.Platform - Akka.NET actor system
* Nasset.FmsServices - FMS integration layer
* Nasset.Web - ASP.NET API with React UI and SignalR

### Robot Simulator

Replicates robot behaviour for development. Enabled via Octopus feature flags in specific environments (dev-nightly, devops).

### WPF Simulator

Desktop application (Asset.Simulator.Wpf) for manually driving simulated manned assets via keyboard input.
