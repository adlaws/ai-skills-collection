# Core Stacks and Services

FMS Core is the backend engine of Imperium. It is organised into six functional stacks, each containing multiple microservices.

## Asset Stack

Manages assets (trucks, excavators) and their current operational state.

| Service | Description |
|---------|-------------|
| Asset Manager Service | Manages assets, their properties, and configuration for asset types |
| Asset Distributor Service | Distributes asset state changes to subscribing clients |
| Asset Shadow Service | Maintains a real-time shadow copy of each asset's state; provides filtered mine model views |
| Load and Dump Evaluator | Detects when load and dump events have occurred based on telemetry |
| Asset Delay Manager Service | Manages delays and activities applied to assets |
| HEMS Service | Haul truck engine management system integration |
| Asset State Interface | Standardised interface for asset state across the system |

### Key Capabilities

* Hold assets and their current state
* Hold configuration for various asset types
* Allow delays and activities to be set on assets
* Distribute state changes to interested services

## Assignment Stack

Handles the creation, optimisation, and dispatch of assignments (haul missions) to assets.

| Service | Description |
|---------|-------------|
| Optimised Assignment Engine | Computes optimal truck-to-loader assignments based on constraints |
| Assignment Engine Coordinator | Coordinates between assignment engine instances |
| Assignment Engine Hub | Central hub for assignment engine communication |
| Assignment Aggregator | Aggregates assignment data from multiple sources |
| Dispatch Manager | Dispatches assignments to assets and manages assignment lifecycle |
| Material Destination Manager | Manages material routing destinations (dumps, crushers, stockpiles) |
| Travel Time Data Provider | Provides estimated travel times between locations for optimisation |

### Assignment Capabilities

* Create assignments manually (user) or automatically (engine)
* Optimise truck-to-loader pairing for fleet efficiency
* Manage assignment completion for manned and autonomous assets
* Track material destinations and routing

## Autonomy Stack

Controls autonomous vehicle operations and permissions.

| Service | Description |
|---------|-------------|
| Robot Control Service | Manages robot (autonomous vehicle) control commands |
| Robot Script Manager | Stores and manages robot scripts for autonomous operations |
| Asset Permission Service | Centrally manages permissions for autonomous assets |
| Mine Model Control Service | Controls mine model state for autonomy operations |
| Path Permission Service | Manages path-level permissions for autonomous navigation |
| RTK Corrections Service | Provides RTK GPS correction data for centimetre-level positioning |

## Spatial Stack (Mine Model)

Maintains the digital representation of the mine - roads, zones, control points, and routing.

| Service | Description |
|---------|-------------|
| Mine Model Service | Master store of the mine's spatial model (roads, zones, areas) |
| Mine Model Distributor | Distributes mine model updates to subscribing services |
| Mine Model Survey | Manages survey data integration with the mine model |
| Routing Service | Computes routes through the mine road network |
| Spatial Association Service | Associates assets with spatial features (zones, areas, roads) |
| Material Ledger Service | Tracks material quantities at locations across the mine |
| Material Source Service | Manages source locations where material is loaded |
| Area Arrival Manager | Detects when assets arrive at or depart from defined areas |

### Control Points

The spatial stack manages three types of control points:

* **Queue Points** - where trucks wait before entering a load or dump area
* **Load Points** - where trucks are loaded by excavators
* **Dump Points** - where trucks tip their payload

Each control point has state management and watchers that orchestrate vehicle flow.

## Data Stack

Captures business events and mines performance metrics.

| Service | Description |
|---------|-------------|
| Asset State Reporting Service | Reports and persists asset state transitions |
| Cycle Payload Evaluator | Evaluates and records payload data per haul cycle |
| Estimate Time Arrival Service | Estimates arrival times for assets in transit |
| State Time Usage Model Provider | Provides the time usage model configuration for categorising asset time |

## Platform Stack

Cross-cutting infrastructure services.

| Service | Description |
|---------|-------------|
| Identity Service | Authentication and authorisation for FMS users and services |
| Notification Broker Service | Routes notifications to appropriate channels and recipients |

## Support Stack

Operational monitoring and diagnostics.

| Service | Description |
|---------|-------------|
| Sentinel Service | Monitoring, metrics, logging, alerting, and health checks across the FMS |

## Traffic Management

Orchestrates autonomous vehicle movement through mining areas.

### Core Responsibilities

* Autonomous area lifecycle management
* Dynamic lane generation for crusher bays, refuel areas, and custom zones
* Goal point management for autonomous navigation
* Area operations and action generation
* Asset mode management (autonomous/manual transitions)
* Queue management at load, dump, and crusher areas

### Dependencies

* **Hard**: SQL Server, RabbitMQ, Mine Model Service, Dynamic Areas Library, Access Control, HPMG, Assignment Aggregator, Dispatch Manager, Spatial Association, Asset Shadow, Task Manager
* **Soft**: Crusher Control, Snowflake

## FMS Field

Deployed onto each asset in the field.

| Service | Description |
|---------|-------------|
| Field Sync | Synchronises data between VAS (Vehicle Autonomy Stack) and FMS |
| Field Signal | Syncs data to the FMS Field UI (Centurion) via SignalR |
| Field Telemetry | Ingestion and translation of sensor telemetry from the vehicle |

**Centurion** is the in-cab field operator UI built with TypeScript/React.

## FMS Office

Installed on operator workstations in the control room.

| Service | Description |
|---------|-------------|
| Office Sync | Synchronises office state with FMS Core |
| Office Signal | Real-time data push to the office UI via SignalR |

**Overwatch** is the office operator UI - a React application providing fleet-wide visibility and control.
