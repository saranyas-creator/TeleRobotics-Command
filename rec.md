# Watchdog Worker

## Overview

The **Watchdog Worker** is responsible for receiving real-time health and status information from the Robot Software through the Router Service.

It inherits from **ZmqWorkerBase** and runs in its own worker thread managed by the **ZmqManager**. After registering with the Router Service, the worker continuously listens for watchdog messages, extracts subsystem status information, and forwards it to the Qt application.

Unlike the Command Worker, the Watchdog Worker does not send operational commands to the robot. Its only outgoing communication is the initial registration request with the Router Service. All subsequent communication consists of receiving watchdog status updates.

### Responsibilities

- Register with the Router Service as **UI_WATCHDOG**
- Receive watchdog status messages
- Parse incoming JSON data
- Extract subsystem health information
- Forward status information to the Qt application

---

# Architecture

The Watchdog Worker acts as the communication interface between the Router Service and the Qt user interface.

```text
               Qt Application
                      │
                      ▼
                 ZmqManager
                      │
                      ▼
               Watchdog Worker
                      │
             ZeroMQ DEALER Socket
                      │
                      ▼
                Router Service
                      │
                      ▼
          Robot Watchdog Service
```

The worker receives all watchdog messages through the Router Service and forwards the processed subsystem status to the Qt application.

---

# 1. Worker Initialization

During application startup, the **ZmqManager** creates the Watchdog Worker and starts its worker thread.

The initialization sequence consists of:

1. Reading the communication configuration.
2. Creating the ZeroMQ context.
3. Creating the DEALER socket.
4. Connecting to the Router Service.
5. Registering as **UI_WATCHDOG**.
6. Waiting for watchdog messages.

```text
Create Worker
      │
      ▼
Read Configuration
      │
      ▼
Create ZMQ Context
      │
      ▼
Create DEALER Socket
      │
      ▼
Connect to Router
      │
      ▼
Register as UI_WATCHDOG
      │
      ▼
Receive REGISTER_ACK
      │
      ▼
Wait for WATCHDOG Messages
```

---

## 1.1 Creating the Worker

The Watchdog Worker is created by the **ZmqManager** during application startup.

```cpp
ZMQWatchDogWorker::ZMQWatchDogWorker(QObject *parent)
    : ZmqWorkerBase(parent)
{
}
```

Since the worker inherits from **ZmqWorkerBase**, it automatically gains the common worker lifecycle interface used by all communication workers.

---

## 1.2 Reading the Configuration

The worker reads the Router endpoint from the application configuration.

```cpp
const QString host =
    ConfigReader::instance().value(
        "ZMQ",
        "Host",
        "127.0.0.1");

const QString port =
    ConfigReader::instance().value(
        "ZMQ",
        "WatchDogPort",
        "5555");
```

Example configuration:

```text
Host : 127.0.0.1
Port : 5555
```

The endpoint becomes:

```text
tcp://127.0.0.1:5555
```

This endpoint is used to establish communication with the Router Service.

---

## 1.3 Creating the DEALER Socket

The Watchdog Worker creates a ZeroMQ context followed by a DEALER socket.

```cpp
m_context = zmq_ctx_new();

m_socket = zmq_socket(
    m_context,
    ZMQ_DEALER);
```

The DEALER socket is used to communicate with the Router Service. It allows the worker to register itself during startup and receive watchdog messages forwarded by the Router.

---

## 1.4 Connecting to the Router

After creating the DEALER socket, the worker establishes a connection with the Router Service.

```cpp
zmq_connect(
    m_socket,
    endpoint.constData());
```

Communication flow:

```text
Watchdog Worker
        │
        ▼
ZeroMQ DEALER Socket
        │
        ▼
Router Service
```

At this stage, the communication channel is established, but the worker is not yet registered.

---

## 1.5 Registering as UI_WATCHDOG

Before receiving watchdog messages, the worker must register itself with the Router Service.

The worker sends a registration request using the identity **UI_WATCHDOG**.

```json
{
    "id": "REG_UI_WATCHDOG",
    "source": "UI_WATCHDOG",
    "target": "ROUTER",
    "type": "REGISTER",
    "priority": 1,
    "payload":
    {
        "role": "UI_WATCHDOG"
    }
}
```

The Router validates the registration request and responds with a registration acknowledgement.

```json
{
    "type": "REGISTER_ACK"
}
```

After receiving the acknowledgement, the worker is ready to receive watchdog messages.

---

## 1.6 Registration Retry Mechanism

If the Router Service is unavailable during application startup, the registration request may fail.

To handle this situation, the Watchdog Worker automatically retries registration until a **REGISTER_ACK** is received.

```text
Send REGISTER
      │
      ▼
REGISTER_ACK Received?
      │
 ┌────┴────┐
 │         │
Yes        No
 │          │
 ▼          ▼
Continue   Wait 5 Seconds
              │
              ▼
        Retry Registration
```

This retry mechanism allows the Watchdog Worker to recover automatically if the Router Service starts after the Qt application, eliminating the need to restart the application.
