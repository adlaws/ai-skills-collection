# Codebase Structure

## Repository Layout

The Imperium repository is a monorepo containing all FMS microservices, shared libraries, tooling, and documentation.

```text
imperium/
├── Asset/                    # Asset Stack services
├── AssignmentEngine/         # Assignment Stack services
├── Auth/                     # Identity/authentication services
├── Autonomy/                 # Autonomy Stack services
├── Common/                   # Shared libraries and clients
├── Docker/                   # Docker infrastructure (RabbitMQ etc.)
├── docs/                     # MkDocs documentation site
├── Environments/             # Environment-specific configuration
├── Field/                    # FMS Field services and UI
├── infrastructure/           # Build and deployment infrastructure
├── MineModel/                # Spatial Stack services
├── MinePerformance/          # Data Stack services
├── Notifications/            # Notification services
├── Office/                   # FMS Office services and UI
├── Pacts/                    # Contract testing (Pact)
├── rtk_os/                   # Robotics Toolkit OS
├── scripts/                  # Utility scripts
├── Support/                  # Support Stack (Sentinel)
├── Tools/                    # Developer tooling and local environment
├── TrafficManagement/        # Traffic Management services
├── Imperium.sln              # Main solution file
├── PlatformConfiguration.json # Service ports and configuration
├── mkdocs.yml                # Documentation site configuration
└── Directory.Packages.props  # Central NuGet package management
```

## Solution Files

| Solution | Location | Purpose |
|----------|----------|---------|
| Imperium.sln | Root | Main solution containing all projects |
| AssetStack.sln | Asset/ | Asset Stack services only |
| AllProjects.sln | AssignmentEngine/ | Assignment Engine services |
| IdentityService.sln | Auth/ | Identity and authentication |
| AutonomyStack.sln | Autonomy/ | Autonomy Stack services |
| MineModelStack.sln | MineModel/ | Mine Model/Spatial Stack services |
| AllImperiumProjects.sln | infrastructure/VisualStudioLocalSolution/ | All projects for local IDE development |

## Key Directories by Stack

### Asset Stack (`Asset/`)

* AssetManager/ - Asset management service
* AssetDistributorService/ - Asset state distribution
* AssetShadow/ - Real-time asset state shadow
* LoadAndDumpEvaluator/ - Load/dump event detection
* FMG.Imperium.Asset.AssetDelayManager/ - Delay management
* FMG.Imperium.Asset.Hems/ - Engine management integration
* RobotSimulator/ - Robot simulation
* RtkCorrectionsService/ - RTK GPS corrections

### Assignment Stack (`AssignmentEngine/`)

* AssignmentAggregator/ - Assignment aggregation
* AssignmentEngineCoordinator/ - Engine coordination
* AssignmentEngineHub/ - Central hub
* DispatchManager/ - Assignment dispatch
* MaterialDestinationManager/ - Destination management
* PerpetualAssignmentEngine/ - Optimised assignment engine
* TravelTimeDataProviderService/ - Travel time estimation

### Spatial Stack (`MineModel/`)

* MineModelService/ - Core mine model
* DistributorService/ - Mine model distribution
* RoutingService/ - Route computation
* SpatialAssociationService/ - Spatial association
* MaterialLedgerService/ - Material tracking
* MaterialSourceService/ - Source management
* MineModelControlService/ - Mine model control
* PathPermissionService/ - Path permissions
* AreaArrivalManager/ - Area arrival detection
* Survey/ - Mine model survey

### Data Stack (`MinePerformance/`)

* AssetStateReportingService/ - State reporting
* CyclePayloadEvaluator/ - Payload evaluation
* EstimateTimeArrivalService/ - ETA calculation
* StateTimeUsageModelProvider/ - Time usage model

### Field (`Field/`)

* Centurion/ - In-cab operator UI (React/TypeScript)
* FieldSync/ - VAS data synchronisation
* FieldSignal/ - Real-time UI data via SignalR
* FieldTelemetry/ - Telemetry ingestion
* FieldCommissioning/ - Asset commissioning tools

### Office (`Office/`)

* Overwatch/ - Office operator UI (React/TypeScript)
* OfficeSync/ - Office data synchronisation
* OfficeHub/ - Office SignalR hub

### Common Libraries (`Common/`)

Shared code used across all stacks:

* FMG.Autonomy.Core/ - Core domain types
* FMG.Autonomy.Config/ - Configuration utilities
* FMG.Autonomy.Messaging/ - RabbitMQ messaging abstractions
* FMG.Autonomy.Dds/ - DDS protocol integration
* FMG.Autonomy.Grpc/ - gRPC utilities
* FMG.Autonomy.Logging/ - Serilog logging setup
* FMG.Autonomy.FileStorage/ - File storage abstractions
* FMG.Autonomy.Notifications/ - Notification framework
* FMG.Imperium.ServiceInfrastructure/ - Service hosting and startup
* FMG.Imperium.ServiceInfrastructure.Persistence/ - Database persistence
* FMG.Imperium.Geometry/ - Geometric calculations
* FMG.Imperium.Crypto/ - Cryptographic utilities
* FMG.Imperium.StateManagement/ - State management patterns
* FMG.Imperium.BusinessEvents/ - Business event definitions
* FMG.Imperium.AssetManagement/ - Asset management shared types
* Fortex.Dispatch.* / - Dispatch-related shared libraries
* HaulX.Seeding/ - Database seeding utilities
* Data clients (FMG.Autonomy.Data.Client.*) - Typed HTTP/gRPC clients for each service

## PlatformConfiguration.json

Located at the repository root, this file defines the service catalogue with:

* Port assignments for each service
* Project paths for local development
* Database names
* Environment-specific overrides

Each service entry includes its port number (e.g. mine-model: 5100, asset-manager-service: 5530, routing-service: 5200).
