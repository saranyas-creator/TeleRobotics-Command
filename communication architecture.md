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

## Communication Principles

The Communication Framework follows the following design principles:

- **Single Responsibility** – Each worker is responsible for one communication channel.
- **Thread Isolation** – Every worker executes in its own thread.
- **Modular Design** – New communication workers can be added without modifying existing workers.
- **Reusable Framework** – Common functionality is shared through `ZmqWorkerBase`.
- **Centralized Management** – Worker creation and lifecycle management are handled by `ZmqManager`.

These principles provide a scalable and maintainable communication architecture for the Qt application.
