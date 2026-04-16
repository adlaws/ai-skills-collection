# Quality Attributes and Standards

## Quality Attributes

The following quality attributes guide the architectural design of Imperium:

* **Scalability** - Designed to communicate with a large number of assets (e.g. 400+ on a large site)
* **Portability** - Must run in both OT (Operational Technology) and cloud environments; uses Docker and Kubernetes; avoids cloud-only technologies (e.g. no DynamoDB)
* **Accuracy** - Correct asset state, payload tracking, and spatial positioning
* **Availability** - System must remain operational for continuous mining operations
* **Configurability** - Adaptable to different mine sites and asset configurations
* **Deployability** - Containerised services for repeatable deployment
* **Determinability** - Predictable behaviour for autonomous operations (safety-critical)
* **Efficiency** - Optimised assignment and routing for fleet performance
* **Fault-tolerance** - Graceful degradation under network or service failures
* **Interoperability** - Integration with multiple telemetry sources and vehicle platforms
* **Maintainability** - Clean service boundaries and shared libraries
* **Safety** - Safe autonomous vehicle operations with permission controls

## Logging Standards

Based on Serilog with structured logging.

### Configuration

* Use Serilog with recommended sinks: Console, Debug, File (with Async wrapper)
* Support both JSON-based and code-based configuration
* Use structured log templates with named properties (not positional)

### Log Levels by Environment

| Environment | Default Level |
|-------------|--------------|
| Development | Debug |
| Staging | Information |
| Production | Warning |

### Best Practices

* Use `ILogger<T>` via dependency injection
* Use structured logging with message templates: `Log.Information("Processing order {OrderId}", orderId)`
* Use log scopes for correlation
* For high-throughput paths, use `LoggerMessage.Define` or source generators for zero-allocation logging
* Log at appropriate levels: Trace for diagnostics, Debug for development, Information for business events, Warning for recoverable issues, Error for failures, Critical for system-wide problems

### What to Log

* Service startup and shutdown
* Configuration changes
* Authentication/authorisation events
* Business events (assignments, state changes)
* Errors and exceptions with context
* Performance-relevant metrics

## Tracing Standards

Based on OpenTelemetry with .NET Activity API.

### Terminology

| .NET Term | OpenTelemetry Term | Description |
|-----------|-------------------|-------------|
| Activity | Span | A unit of work within a trace |
| Tag | Attribute | Key-value metadata on a span |
| ActivityEvent | Event | A timestamped annotation |
| ActivitySource | Tracer | Creates new spans |

### Semantic Conventions

Follow OpenTelemetry semantic conventions for consistent naming across services:

* `code.function` - method name
* `code.namespace` - namespace
* `code.filepath` - source file path
* `code.lineno` - line number

### Exception Instrumentation

Record exceptions using semantic convention attributes:

* `exception.type` - exception class name
* `exception.message` - error message
* `exception.stacktrace` - full stack trace

## Coding Standards

### C# / .NET

* Follow Fortescue C# .NET Coding Guidelines
* Enforced by `.editorconfig` file in the repository
* Use consistent formatting via configured auto-formatters

### TypeScript / Frontend

* ESLint and Prettier for code quality and formatting
* React component conventions per team guidelines

## Documentation Standards

* Use MkDocs for documentation site (deployed to `docs.imperium.autonomy.fmgaws.cloud`)
* Documentation source in `docs/` folder
* Follow Robotics Toolkit Documentation System (RTK V0.3.0) standards
* Each service should have an `index.md` documenting: introduction, high-level design, data flow, responsibilities, interfaces (HTTP/gRPC/messaging), orchestration, and dependencies
