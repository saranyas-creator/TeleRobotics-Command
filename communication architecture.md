# Communication Framework

## Overview

The Communication Framework provides the communication layer between the Qt application and the Software Services.

It is designed to exchange commands, camera frames, watchdog information, and telemetry without blocking the Qt user interface. To achieve this, communication is separated into independent worker threads, each responsible for a specific communication channel.

All communication workers inherit from a common base class (`ZmqWorkerBase`) and are managed by a centralized manager (`ZmqManager`). This architecture promotes modularity, scalability, and simplifies the addition of new communication channels.

### Responsibilities

- Manage communication between the Qt application and Software Services.
- Execute communication in independent worker threads.
- Keep the Qt user interface responsive.
- Provide a common communication framework for all workers.
- Simplify future expansion of the communication layer.

---

# Architecture

The Communication Framework consists of a centralized manager and multiple communication workers.

```text
                    Qt Application
                           │
                           ▼
                     ZmqManager
                           │
      ┌────────────────────┼────────────────────┐
      ▼                    ▼                    ▼
Command Worker      Camera Worker      Watchdog Worker
      │                    │                    │
      └────────────────────┼────────────────────┘
                           ▼
                     ZmqWorkerBase
```

Each worker is responsible for a specific communication task while sharing a common lifecycle provided by `ZmqWorkerBase`.

---

# Core Components

The Communication Framework is built around two core classes and a set of specialized communication workers.

| Component | Responsibility |
|-----------|----------------|
| **ZmqWorkerBase** | Provides the common interface and lifecycle for all communication workers. |
| **ZmqManager** | Creates, manages, and controls all communication workers. |
| **Command Worker** | Exchanges command messages with the Robot Software. |
| **Camera Worker** | Receives published camera frames and forwards them to the Qt application. |
| **Watchdog Worker** | Receives subsystem status information and forwards it to the Qt application. |

Each worker is implemented independently, allowing communication channels to operate concurrently without affecting one another.

---
# 1. ZmqWorkerBase

## Purpose

`ZmqWorkerBase` is the common base class for all communication workers in the Communication Framework.

Instead of implementing the communication lifecycle independently, every communication worker inherits from `ZmqWorkerBase` and reuses a common interface for initialization, execution, and shutdown.

This provides a consistent communication framework across all workers while allowing each worker to implement its own communication logic.

Current worker implementations include:

- Command Worker
- Camera Worker
- Watchdog Worker

---

## Responsibilities

The base class provides the common functionality required by all communication workers.

Its responsibilities include:

- Defining a common worker interface.
- Managing the worker lifecycle.
- Providing a consistent startup and shutdown mechanism.
- Reporting worker status.
- Providing a common communication interface for all derived workers.

The actual communication logic is implemented by each derived worker.

---

## Worker Lifecycle

Every communication worker follows the same execution lifecycle.

```text
Create Worker
       │
       ▼
Initialize Resources
       │
       ▼
Start Communication
       │
       ▼
Process Messages
       │
       ▼
Stop Communication
       │
       ▼
Release Resources
```

This lifecycle ensures that every worker is initialized, executed, and terminated in a consistent manner.

---

## Common Interface

Each communication worker implements the common interface defined by `ZmqWorkerBase`.

Typical lifecycle functions include:

```cpp
start()

stop()

workerName()
```

These functions allow the `ZmqManager` to manage every worker through a common interface, regardless of its specific communication responsibilities.

---

## Derived Workers

The following workers inherit from `ZmqWorkerBase`.

```text
                 ZmqWorkerBase
                       │
      ┌────────────────┼────────────────┐
      ▼                ▼                ▼

Command Worker   Camera Worker   Watchdog Worker
```

Each derived worker extends the base class by implementing its own communication logic while reusing the common worker lifecycle.

---

## Why Use a Base Class?

Without a common base class, every communication worker would need to independently implement:

- Worker initialization
- Startup procedures
- Shutdown procedures
- Status reporting
- Worker identification

This would lead to duplicated code and inconsistent implementations.

By introducing `ZmqWorkerBase`, all workers share a common structure while remaining independent in their communication logic.

This improves maintainability, code reuse, and consistency across the Communication Framework.

---

## Relationship with ZmqManager

`ZmqWorkerBase` works together with the `ZmqManager`.

```text
                ZmqManager
                     │
        Creates & Controls
                     │
                     ▼
              ZmqWorkerBase
                     │
      ┌──────────────┼──────────────┐
      ▼              ▼              ▼

Command        Camera        Watchdog
 Worker          Worker         Worker
```

The `ZmqManager` is responsible for creating and controlling worker objects, while the workers themselves are responsible for performing communication tasks.

This separation keeps worker management independent from communication logic.
