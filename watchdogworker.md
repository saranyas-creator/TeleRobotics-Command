# Watchdog Worker

## Overview

The **Watchdog Worker** is responsible for receiving the health and status information of the robot and its associated subsystems from the Software Services.

The worker inherits from **ZmqWorkerBase** and runs in its own worker thread managed by the **ZmqManager**. It communicates with the Router Service using a **ZeroMQ DEALER** socket. After registering with the Router, it continuously listens for watchdog messages, extracts the subsystem status information, and forwards it to the Qt application.

Unlike the Camera Worker, which receives image frames, the Watchdog Worker only receives watchdog status messages. It does not send operational commands to the robot. Its only transmission is the initial registration request required to establish communication with the Router Service.

The Watchdog Worker is responsible for:

- Registering with the Router Service
- Receiving watchdog messages
- Parsing the received JSON data
- Extracting subsystem status information
- Forwarding subsystem status to the Qt application

---

# Architecture

The Watchdog Worker acts as the communication bridge between the Robot Watchdog Service and the Qt application.

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

The Watchdog Worker communicates only with the Router Service. The Router forwards watchdog messages received from the robot.

---

# 1. Router Registration

Before the Watchdog Worker can receive watchdog messages, it must register itself with the Router Service.

The registration process is performed only once during startup.

Communication flow:

```text
Qt Application
       │
       ▼
Watchdog Worker
       │
       ▼
Create DEALER Socket
       │
       ▼
Connect to Router
       │
       ▼
Send REGISTER
       │
       ▼
Receive REGISTER_ACK
       │
       ▼
Ready to Receive WATCHDOG Messages
```

---

## 1.1 Worker Initialization

The Watchdog Worker is created by the **ZmqManager** during application startup.

```text
Qt Application
       │
       ▼
   ZmqManager
       │
       ▼
Create Watchdog Worker
       │
       ▼
 Worker Thread Starts
```

The constructor initializes the worker.

```cpp
ZMQWatchDogWorker::ZMQWatchDogWorker(QObject *parent)
    : ZmqWorkerBase(parent)
{
}
```

Since the worker inherits from `ZmqWorkerBase`, it automatically receives the common worker lifecycle interface shared by all communication workers.

---

## 1.2 Reading Configuration

The worker first reads the Router endpoint from the application configuration.

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

The endpoint becomes

```text
tcp://127.0.0.1:5555
```

This endpoint is used to connect to the Router Service.

---

## 1.3 Creating the DEALER Socket

The Watchdog Worker creates a ZeroMQ context followed by a DEALER socket.

```cpp
m_context = zmq_ctx_new();

m_socket = zmq_socket(
    m_context,
    ZMQ_DEALER);
```

The DEALER socket is used for communication with the Router Service.

Unlike a SUB socket, the DEALER socket supports bidirectional communication. In the Watchdog Worker, it is used only for:

- Registering with the Router
- Receiving watchdog messages

---

## 1.4 Setting the Worker Identity

Each DEALER socket must have a unique identity so that the Router can identify the connected client.

The Watchdog Worker sets its identity as:

```cpp
const char* identity = "UI_WATCHDOG";

zmq_setsockopt(
    m_socket,
    ZMQ_IDENTITY,
    identity,
    strlen(identity));
```

Identity:

```text
UI_WATCHDOG
```

This identity is used by the Router Service to forward watchdog messages to the correct destination.

---

## 1.5 Connecting to the Router

After creating the socket, the worker establishes a connection with the Router Service.

```cpp
zmq_connect(
    m_socket,
    endpoint.constData());
```

Communication flow:

```text
UI_WATCHDOG
      │
      ▼
 DEALER Socket
      │
      ▼
Router Service
```

At this stage, the communication channel is established, but the worker is not yet registered.

---

## 1.6 Registering with the Router

The worker sends a registration request to the Router.

```json
{
    "id":"REG_UI_WATCHDOG",
    "source":"UI_WATCHDOG",
    "target":"ROUTER",
    "type":"REGISTER",
    "priority":1,
    "payload":
    {
        "role":"UI_WATCHDOG"
    }
}
```

The Router validates the request and responds with:

```json
{
    "type":"REGISTER_ACK"
}
```

Once the acknowledgement is received, the worker is successfully registered and is ready to receive watchdog messages.

Communication flow:

```text
UI_WATCHDOG
      │
REGISTER
      ▼
Router Service
      │
REGISTER_ACK
      ▼
UI_WATCHDOG
```

---

## 1.7 Registration Retry Mechanism

The Watchdog Worker continuously retries registration until the Router acknowledges the request.

```text
Send REGISTER
      │
      ▼
REGISTER_ACK ?
   │        │
 Yes       No
  │         │
  ▼         ▼
Continue   Wait 5 Seconds
              │
              ▼
        Retry REGISTER
```

This mechanism ensures that the Watchdog Worker automatically reconnects if the Router Service is not yet available during application startup.

After successful registration, the worker enters the watchdog receive loop and waits for incoming watchdog messages from the Router Service.













































# Watchdog Monitoring

## Overview

The Watchdog system monitors the real-time health of the robot and its associated subsystems.

The robot periodically publishes watchdog status messages through the Router Service. The Qt Watchdog Worker receives these messages, extracts the subsystem status, and updates the watchdog indicators displayed in the user interface.

---

# Communication Flow

```text
Robot Software
      │
      ▼
WATCHDOG Message
      │
      ▼
Router Service
      │
      ▼
Watchdog Worker
      │
      ▼
Qt Status Widget
```

The communication process consists of the following steps:

1. The robot periodically generates watchdog status information.
2. The Router Service forwards the watchdog message.
3. The Watchdog Worker receives and parses the JSON message.
4. The Qt UI updates the corresponding status indicators.

---

# JSON Message Format

Each watchdog message contains the current status of one or more robot subsystems.

## Format

```json
{
    "<subsystem>" : "<state>",
    "<subsystem>" : "<state>"
}
```

## Example

```json
{
    "robot": "ok",
    "video_stream": "warning",
    "realsense": "error",
    "internet": "disconnected",
    "joystick": "initializing"
}
```

---

# Supported Subsystems

The watchdog can monitor any subsystem.

Typical subsystems include:

- Robot
- Video Stream
- Joystick
- Force Sensor
- Camera
- Internet
- RealSense
- System State

Additional subsystems may be added without changing the communication protocol.

---

# Supported Status Values

Each subsystem reports one of the following standardized states.

| State | Description | UI Indicator |
|--------|-------------|--------------|
| **ok** | Operating normally | 🟢 Green |
| **warning** | Operational with a non-critical issue | 🟡 Yellow |
| **error** | Fault detected | 🔴 Red |
| **disconnected** | Device unavailable | ⚫ Black / Gray |
| **initializing** | Device is starting or calibrating | 🔵 Blue |

The Qt application maps each state to the corresponding watchdog indicator colour.

---

# Joystick Status

The joystick is monitored using the same watchdog mechanism.

Typical joystick states are:

| Status | Meaning | UI Indicator |
|---------|---------|--------------|
| **on** | Joystick connected and functioning | 🟢 Green |
| **off** | Joystick detected but inactive | 🟠 Orange |
| **error** | Communication or hardware failure | 🔴 Red |

The Watchdog Worker updates the joystick indicator whenever a new watchdog message is received.

---

# System State

In addition to subsystem status, the robot periodically reports the overall system state.

| State | Description | UI Indicator |
|--------|-------------|--------------|
| **IDLE** | System is powered but idle | ⚪ Gray |
| **READY** | Ready for operation | 🟢 Green |
| **EXECUTE** | Task currently executing | 🟡 Yellow |
| **ERROR** | System fault detected | 🔴 Red |

State values are case-sensitive and must be transmitted in uppercase.

---

# Communication Configuration

The Watchdog channel communicates through the Router Service.

| Parameter | Value |
|----------|-------|
| Host | 127.0.0.1 |
| Port | 5555 |
| Transport | TCP/IP |
| Robot Side | ZeroMQ DEALER |
| Operator Side | ZeroMQ ROUTER |

The Robot Software connects to the Router Service using a DEALER socket.

The Router forwards incoming watchdog messages to the Qt Watchdog Worker.

---

# Overall Workflow

```text
Robot Software
        │
Generate Watchdog Status
        │
        ▼
Router Service
        │
        ▼
Watchdog Worker
        │
Parse JSON
        │
        ▼
Update Status Indicators
        │
        ▼
Qt User Interface
```
