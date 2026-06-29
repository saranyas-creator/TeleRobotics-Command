# Telemetry Service

## Overview

The **Telemetry Service** provides the shared memory communication layer between the Qt application and the Teleoperation Software.

Unlike the communication workers, the Telemetry Service does not use ZeroMQ. Instead, it reads robot telemetry directly from a shared memory region that is continuously updated by the Teleoperation Software.

The service is implemented as a singleton, allowing all components of the Qt application to access the latest robot telemetry through a single shared instance.

### Responsibilities

- Attach to the shared memory region.
- Read the latest robot telemetry.
- Validate shared memory data.
- Detect stale telemetry.
- Automatically recover from stale shared memory.
- Provide telemetry snapshots to the Qt application.

---

# Architecture

The Telemetry Service provides read-only access to robot telemetry stored in shared memory.

```text
                Software Services
                        │
                        ▼
              SharedTelemetryWriter
                        │
                        ▼
                 Shared Memory
                        │
                        ▼
                Telemetry Service
                        │
                        ▼
                 Qt Application
```

The Telemetry Service does not communicate with the Robot Software directly. Instead, it reads telemetry from the shared memory region created and maintained by the Teleoperation Software.

---

# 1. Telemetry Snapshot

The Telemetry Service returns robot telemetry using a `TelemetrySnapshot` object.

A snapshot represents a consistent copy of the latest telemetry available in shared memory.

The snapshot contains:

- STL Position
- STL Orientation
- Force Feedback
- Telemetry Age
- Data Validity

```text
TelemetrySnapshot

Position
    X
    Y
    Z

Orientation
    X
    Y
    Z

Force
    X
    Y
    Z

Age

Valid
```

Each call to the Telemetry Service returns a new snapshot representing the latest available telemetry.

---

# 2. Shared Memory Communication

Unlike the communication workers, the Telemetry Service does not communicate through ZeroMQ.

Instead, both the Teleoperation Software and the Qt application access a common shared memory region.

```text
Teleoperation Software
          │
          ▼
 Writes Shared Memory
          │
──────── Shared Memory ────────
          │
          ▼
 Telemetry Service
          │
          ▼
 Qt Application
```

Using shared memory avoids repeated serialization and network communication, enabling efficient access to continuously updated telemetry.

---

## 2.1 Why Shared Memory?

Robot telemetry is updated continuously during teleoperation.

Examples include:

- Force Feedback
- STL Position
- STL Orientation
- Timestamp
- Sequence Number

Since this information changes frequently, using shared memory provides lower latency than repeatedly exchanging messages through a communication socket.

The Teleoperation Software continuously updates the shared memory, while the Telemetry Service reads the latest available telemetry whenever requested.

---

## 2.2 Shared Memory Layout

The shared memory region stores the latest robot telemetry in a fixed data structure.

```text
SharedTelemetry

Sequence Number

Force
    X
    Y
    Z

STL Position
    X
    Y
    Z

STL Orientation
    X
    Y
    Z

Echo Sequence Number

Timestamp
```

The Telemetry Service reads this structure directly from shared memory and converts it into a `TelemetrySnapshot` for use by the Qt application.
