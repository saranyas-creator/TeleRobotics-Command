# Communication Framework

## Overview

The **Communication Framework** provides the communication infrastructure for the Qt application. It acts as the interface between the user interface and the Software Services running in the backend.

The framework is responsible for:

- Sending UI commands to the backend services
- Receiving command responses from the robot
- Receiving camera frames
- Receiving watchdog status updates
- Reading robot telemetry from shared memory

The framework is designed around a modular worker architecture. Each communication task is executed by an independent worker running in its own thread, while a central manager coordinates the lifecycle of all workers.

---

# Architecture

```text
                             Qt Application
                                    │
         ┌──────────────────────────┼──────────────────────────┐
         │                          │                          │
         ▼                          ▼                          ▼
     User Interface            Viewer Module            Status Widgets
         │                          │                          │
         └──────────────────────────┼──────────────────────────┘
                                    │
                                    ▼
                        Communication Framework
                                    │
                 ┌──────────────────┴──────────────────┐
                 │                                     │
                 ▼                                     ▼
            ZmqManager                        TelemetryService
                 │                                     │
                 ▼                                     ▼
            ZmqWorkerBase                     Shared Memory
                 │
     ┌───────────┼───────────────┐
     ▼           ▼               ▼
CommandWorker  CameraWorker  WatchdogWorker
```

The Communication Framework consists of two major components:

- **ZeroMQ Communication**
- **Shared Memory Communication**

ZeroMQ is used for exchanging commands, camera frames, and watchdog messages, while Shared Memory is used to access real-time robot telemetry.

---

# Communication Components

The Communication Framework consists of the following components:

| Component | Responsibility |
|-----------|----------------|
| ZmqManager | Manages the lifecycle of all communication workers |
| ZmqWorkerBase | Provides the common interface for all communication workers |
| CommandWorker | Sends commands and receives command responses |
| CameraWorker | Receives decoded camera frames |
| WatchdogWorker | Receives watchdog status updates |
| TelemetryService | Reads robot telemetry from shared memory |

---

# ZmqWorkerBase

## Overview

`ZmqWorkerBase` is the common base class for all ZeroMQ communication workers.

Every communication worker inherits from this class to provide a consistent interface for lifecycle management, state reporting, error handling, and logging.

```text
QObject
    │
    ▼
ZmqWorkerBase
    │
 ┌──┼──────────────┐
 ▼  ▼              ▼

CommandWorker
CameraWorker
WatchdogWorker
```

### Responsibilities

- Common worker interface
- Worker lifecycle management
- State notifications
- Error notifications
- Logging support

The base class allows all workers to follow the same execution model while implementing their own communication logic.

---

# ZmqManager

## Overview

`ZmqManager` acts as the central coordinator for all communication workers.

Instead of the Qt application managing individual workers directly, it communicates only with the manager. The manager is responsible for creating, registering, starting, stopping, and monitoring all workers.

```text
                 Qt Application
                        │
                        ▼
                  ZmqManager
                        │
        ┌───────────────┼───────────────┐
        ▼               ▼               ▼
 CommandWorker   CameraWorker   WatchdogWorker
```

### Responsibilities

- Create communication workers
- Register workers
- Maintain worker instances
- Start all workers
- Stop all workers
- Forward worker status updates
- Forward worker error notifications

The manager provides a centralized entry point for communication services.

---

# Worker Architecture

Each worker performs one dedicated communication task.

Separating the communication into multiple workers allows different communication channels to operate independently without blocking each other.

```text
               ZmqManager
                    │
     ┌──────────────┼──────────────┐
     ▼              ▼              ▼
CommandWorker  CameraWorker  WatchdogWorker
     │              │              │
 Commands       Video Frames    Watchdog Status
```

Each worker executes independently while sharing a common lifecycle through `ZmqWorkerBase`.

---

# Communication Flow

The Communication Framework exchanges different types of information with the backend services.

```text
                     Qt Application
                            │
                            ▼
                Communication Framework
                            │
      ┌─────────────────────┼─────────────────────┐
      ▼                     ▼                     ▼
CommandWorker        CameraWorker        WatchdogWorker
      │                     │                     │
      ▼                     ▼                     ▼
   ROUTER             Camera Publisher        ROUTER
      ▲                     ▲                     ▲
      │                     │                     │
 Software Services     Software Services    Software Services
```

Each worker communicates only with the backend service responsible for its functionality.

---

# Shared Memory Communication

Robot telemetry is exchanged through shared memory rather than ZeroMQ.

The Teleoperation Service continuously publishes the latest robot telemetry into shared memory, while the Qt application retrieves the data using the `TelemetryService`.

```text
Teleoperation Service
          │
          ▼
 Shared Memory
          │
          ▼
TelemetryService
          │
          ▼
Qt Application
```

The telemetry includes:

- Force Feedback
- STL Position
- STL Orientation
- Sequence Number
- Timestamp

This mechanism enables low-latency telemetry sharing without additional network communication.

---

# Overall Communication Workflow

The following diagram summarizes the complete communication architecture of the Qt application.

```text
                          Qt Application
                                 │
          ┌──────────────────────┼──────────────────────┐
          │                      │                      │
          ▼                      ▼                      ▼
   Communication Framework                    TelemetryService
          │                                         │
          ▼                                         ▼
      ZmqManager                             Shared Memory
          │
          ▼
     ZmqWorkerBase
          │
  ┌───────┼───────────────┐
  ▼       ▼               ▼
Command  Camera       Watchdog
Worker   Worker        Worker
  │         │              │
  ▼         ▼              ▼
Software Services (Router / Camera Publisher)
```

---

# Worker Documentation

Each communication worker is documented separately.

| Document | Description |
|----------|-------------|
| **CommandWorker.md** | Command communication with the Router Service |
| **CameraWorker.md** | Camera frame reception through ZeroMQ PUB-SUB |
| **WatchdogWorker.md** | Watchdog communication with the Router Service |
| **TelemetryService.md** | Shared memory telemetry communication |

These documents describe the implementation details, workflows, and communication protocols of each individual component.
