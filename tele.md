# Communication Framework

## 1. Overview

The **Communication Framework** provides the communication layer between the Qt application and the Software Services. It enables the application to exchange commands, camera frames, watchdog status, and robot telemetry while maintaining a responsive user interface.

The framework follows a modular architecture in which each communication channel is implemented by an independent worker running in its own thread. These workers are centrally managed by the **ZmqManager** and share a common communication interface through **ZmqWorkerBase**.

Communication within the framework is divided into two categories:

- **ZeroMQ Communication** – Used for commands, camera frames, and watchdog messages.
- **Shared Memory Communication** – Used for real-time robot telemetry.

This separation allows each communication mechanism to be optimized for its specific purpose.

---

# 2. Architecture

The Communication Framework consists of two independent communication layers.

```text
                    Qt Application
                           │
                           ▼
               Communication Framework
          ┌────────────────┴────────────────┐
          ▼                                 ▼
     ZeroMQ Layer                  Shared Memory Layer
          │                                 │
          ▼                                 ▼
     ZmqManager                    TelemetryService
          │                                 │
          ▼                                 ▼
    ZmqWorkerBase                  Shared Memory
          │
 ┌────────┼──────────────┐
 ▼        ▼              ▼

Command  Camera     Watchdog
Worker   Worker      Worker
```

The **ZeroMQ Layer** manages communication with the Software Services, while the **Shared Memory Layer** provides low-latency access to robot telemetry.

---

# 3. Communication Components

The framework consists of the following components.

| Component | Responsibility |
|-----------|----------------|
| **ZmqManager** | Creates, manages, starts, and stops all communication workers. |
| **ZmqWorkerBase** | Provides the common communication interface shared by all communication workers. |
| **CommandWorker** | Exchanges command messages with the Robot Software. |
| **CameraWorker** | Receives published RGB image frames. |
| **WatchdogWorker** | Receives subsystem health and status updates. |
| **TelemetryService** | Reads robot telemetry from shared memory. |

Each component performs a dedicated responsibility, allowing the communication channels to operate independently.

---

# 4. ZmqWorkerBase

## 4.1 Overview

`ZmqWorkerBase` is the common base class for all ZeroMQ communication workers.

Rather than implementing communication independently, every communication worker inherits from `ZmqWorkerBase`, providing a common interface and a consistent communication lifecycle.

Current workers derived from `ZmqWorkerBase` include:

- CommandWorker
- CameraWorker
- WatchdogWorker

```text
                 QObject
                    │
                    ▼
             ZmqWorkerBase
                    │
      ┌─────────────┼─────────────┐
      ▼             ▼             ▼

CommandWorker  CameraWorker  WatchdogWorker
```

---

## 4.2 Responsibilities

The base class provides common functionality shared by all communication workers.

Responsibilities include:

- Common worker interface
- Worker lifecycle management
- State notifications
- Error notifications
- Logging support

Each derived worker implements its own communication logic while reusing the common functionality provided by the base class.

---

# 5. ZmqManager

## 5.1 Overview

`ZmqManager` is the central manager of the Communication Framework.

It is responsible for creating, managing, starting, and stopping all communication workers used by the Qt application.

Instead of every worker being managed independently, the `ZmqManager` provides a single point for controlling the communication framework.

```text
                  ZmqManager
                       │
      ┌────────────────┼────────────────┐
      ▼                ▼                ▼

Command Worker   Camera Worker   Watchdog Worker
```

---

## 5.2 Responsibilities

The `ZmqManager` is responsible for:

- Creating communication workers
- Creating worker threads
- Assigning workers to threads
- Starting communication workers
- Stopping communication workers
- Managing the worker lifecycle

The manager coordinates the execution of communication workers but does not process communication data itself.

---

# 6. Communication Flow

The Communication Framework exchanges different types of information with the Software Services through dedicated communication channels.

```text
                 Qt Application
                        │
        ┌───────────────┼───────────────┐
        ▼               ▼               ▼

Command Worker  Camera Worker  Watchdog Worker
        │               │               │
        ▼               ▼               ▼

Router      Camera Publisher      Router
        │               │               │
        ▼               ▼               ▼

Software Services
```

Each communication channel operates independently.

- **Command Worker** exchanges commands and responses through the Router Service.
- **Camera Worker** subscribes to RGB image frames published by the Camera Publisher.
- **Watchdog Worker** receives subsystem health information through the Router Service.
- **TelemetryService** independently retrieves robot telemetry through shared memory.

---

# 7. Thread Architecture

Each communication worker executes in its own thread.

```text
                 Qt Main Thread
                        │
                        ▼
                   ZmqManager
      ┌─────────────────┼─────────────────┐
      ▼                 ▼                 ▼

Command Thread   Camera Thread   Watchdog Thread
      │                 │                 │
      ▼                 ▼                 ▼

Command Worker Camera Worker Watchdog Worker
```

Running communication in dedicated worker threads prevents network operations from blocking the Qt event loop.

This architecture provides:

- Responsive user interface
- Independent communication channels
- Concurrent communication
- Improved scalability
- Simplified maintenance

---

# 8. Shared Memory Communication

Unlike the communication workers, robot telemetry is not exchanged through ZeroMQ.

The **TelemetryService** reads telemetry directly from shared memory published by the Software Services.

```text
Software Services
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

The shared telemetry includes:

- Force Feedback
- STL Position
- STL Orientation
- Sequence Number
- Timestamp

Using shared memory enables low-latency access to continuously updated robot telemetry without introducing additional network communication.

---

# 9. Related Documentation

The implementation details of each communication component are documented separately.

| Document | Description |
|----------|-------------|
| **CommandWorker.md** | Bidirectional command communication with the Robot Software |
| **CameraWorker.md** | Camera frame subscription and processing |
| **WatchdogWorker.md** | Robot subsystem health monitoring |
| **TelemetryService.md** | Shared memory telemetry communication |

---

# 10. Summary

The Communication Framework provides a modular and scalable communication infrastructure for the Qt application.

The framework combines a centralized communication manager (**ZmqManager**), a common worker interface (**ZmqWorkerBase**), and specialized communication workers to exchange commands, camera frames, and watchdog information with the Software Services. Real-time robot telemetry is accessed independently through the **TelemetryService** using shared memory.

By separating communication into dedicated worker threads and independent communication channels, the framework maintains a responsive user interface while providing reliable, maintainable, and extensible communication between the Qt application and the Software Services.
