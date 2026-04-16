# Glossary and Domain Concepts

## Mining Operations Terminology

| Term | Description |
|------|-------------|
| Cycle | The period from when a truck's bed returns to horizontal after tipping material to the point the bed is horizontal after the next tip-off |
| Haul Truck | Off-highway rigid dump truck designed to transport large payloads of material from a loading unit to a dumping destination |
| Excavator / Loader | Machine that loads material into haul trucks at a source location |
| Load Area | Area where trucks are loaded by excavators |
| Dump Area | Area where trucks tip their payload |
| Crusher | Machine that breaks down mined rock; trucks dump into crusher bays |
| Stockpile | A pile of mined material stored temporarily before processing |

## FMS Data Concepts

| Term | OpenTelemetry Name | Description |
|------|-------------------|-------------|
| Delay | delay | Any event preventing a machine from carrying out core functions; timestamped (start/end) and categorised by the Time Usage Model |
| Time Usage Model | timeUsageModel | Model ensuring all time for all assets on a site is uniformly and consistently categorised |
| Time Code | timeCode | Lowest level of business-defined time categorisation; every time code belongs to a time group |
| Time Group | timeGroup | Categorisation of delays: Non-Effective Time, Operating Delay, Operating Standby, External Standby, Unscheduled Maintenance, Scheduled Maintenance |
| State Types | N/A | Categorisation of time managed by the FMS controller |
| Delay Types | delayType | Derivative of State Types with a configurable estimated duration |
| Activity Types | activityType | Derivative of State Types with an associated sequence usable in the FMS Field UI |
| Computed State | N/A | Asset states detected automatically by FMS based on rules and interpretation of base timelines |
| Reported State | N/A | Automated combination of Computed Asset State with Delays and Manual Activities; represents the best approximation of what an asset was doing at any time |

## Payload Concepts

| Term | OpenTelemetry Name | Description |
|------|-------------------|-------------|
| Payload (Cycle) | cyclePayload | Reported payload for the asset's current cycle; always a non-zero value |
| Reported Payload | reportedPayload | FMS best estimation for the payload |
| Sensor Payload | sensorPayload | Calculated payload reading from onboard telemetry capture |
| Specified Payload | N/A | Manually entered corrections of cycle payload using the Cycle Log |

## Spatial Concepts

| Term | Description |
|------|-------------|
| Source Destination | A specific static location within the mine for trucks to be loaded; associated with a specific material grade |
| Dump Destination | A specific static location within the mine for trucks to tip material; associated with material attributes (name, volume, tonnes) |
| Control Point | A managed location (Queue, Load, or Dump point) that orchestrates vehicle flow |
| Queue Point | Location where trucks wait before entering a load or dump area |
| Load Point | Location where trucks are loaded by excavators |
| Dump Point | Location where trucks tip their payload |
| Mine Model | The digital spatial representation of the mine including roads, zones, areas, and routes |
| Route | A computed path through the mine road network between two locations |
| Spatial Association | The linkage between an asset and the spatial features (zones, areas, roads) it is currently within |

## Assignment Concepts

| Term | Description |
|------|-------------|
| Assignment | An instruction for a truck to haul material from a source to a destination |
| Dispatch | The act of sending an assignment to an asset for execution |
| Optimised Assignment | An assignment computed by the assignment engine to maximise fleet efficiency |
| Manual Assignment | An assignment created by an operator overriding the engine |

## Autonomy Concepts

| Term | Description |
|------|-------------|
| VAS | Vehicle Autonomy Stack - the onboard autonomy software running on the asset |
| Robot Script | A predefined sequence of autonomous operations for a vehicle |
| Asset Permission | Authorisation for an autonomous asset to perform specific operations |
| Path Permission | Authorisation for a vehicle to traverse a specific route segment |
| RTK Corrections | Real-Time Kinematic GPS corrections providing centimetre-level positioning accuracy |
| DDS | Data Distribution Service - real-time publish/subscribe protocol used for asset communications |
| Goal Point | A target location for autonomous navigation |

## Telemetry Sources

| Source | Description |
|--------|-------------|
| OCS | Onboard Computing System telemetry |
| Raptorcore | Raptorcore telemetry system |
| Liebherr | Liebherr equipment telemetry (including T264 autonomous trucks) |

## System Components

| Name | Description |
|------|-------------|
| Centurion | The in-cab field operator UI (React/TypeScript) displayed on the asset's screen |
| Overwatch | The office operator UI (React/TypeScript) providing fleet-wide visibility and control |
| Sentinel | Monitoring, metrics, logging, and alerting service for operational support |
| NAsset | Scale testing simulation platform using Akka.NET actors |
| Robot Simulator | Simulates robot (autonomous vehicle) behaviour for development and testing |
| WPF Simulator | Desktop application where users can "drive" simulated manned assets using keyboard |
