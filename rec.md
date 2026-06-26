# Watchdog Worker

## Overview

The **Watchdog Worker** is responsible for receiving the real-time health and operational status of the robot and its associated subsystems.

The worker runs in its own thread and is managed by the **ZmqManager**. It communicates with the Router Service through a **ZeroMQ DEALER** socket. After registering as **UI_WATCHDOG**, it continuously receives watchdog messages, extracts subsystem status information, and forwards the processed data to the Qt application.

Unlike the Command Worker, the Watchdog Worker does not send operational commands to the robot. Its only outgoing communication is the initial registration request with the Router Service. Once registration is complete, the worker only receives watchdog status messages.

### Responsibilities

- Register with the Router Service as **UI_WATCHDOG**
- Receive watchdog status messages
- Parse the received JSON data
- Extract subsystem health information
- Forward subsystem status to the Qt application

---

# Architecture

The following diagram illustrates how the Watchdog Worker is organized within the Qt application.

```text
                Qt Application
                       │
        ┌──────────────┴──────────────┐
        │                             │
        ▼                             ▼
   ZmqManager                  Status Widget
        │                             ▲
        ▼                             │
 Watchdog Worker ─────────────────────┘
```

Component responsibilities:

- **ZmqManager**
  - Creates and manages the Watchdog Worker.
  - Starts and stops the worker thread during the application lifecycle.

- **Watchdog Worker**
  - Handles all watchdog communication.
  - Receives and processes watchdog messages.
  - Emits subsystem status information to the Qt application.

- **Status Widget**
  - Receives subsystem status updates from the Watchdog Worker.
  - Updates the corresponding watchdog indicators displayed in the user interface.

---

# Communication Flow

The Watchdog Worker receives subsystem status information from the Robot Watchdog Service through the Router Service.

```text
Robot Watchdog Service
          │
          ▼
     Router Service
          │
          ▼
UI_WATCHDOG (DEALER)
          │
          ▼
   Watchdog Worker
          │
          ▼
 statusReceived()
          │
          ▼
   Status Widget
```

The communication sequence is as follows:

1. The Robot Watchdog Service periodically generates subsystem health information.
2. The Router Service forwards the watchdog message to the registered **UI_WATCHDOG** client.
3. The Watchdog Worker receives and processes the message.
4. The processed subsystem status is emitted to the Qt application.
5. The Status Widget updates the corresponding watchdog indicators.

The Watchdog Worker acts only as the communication and processing layer. It does not determine how subsystem status is visually represented in the user interface.

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

---

# 2. Receiving Watchdog Messages

After successful registration, the Watchdog Worker continuously listens for watchdog messages forwarded by the Router Service.

Unlike the registration phase, the worker does not send any further messages. Its primary responsibility is to receive, validate, and process watchdog status information.

Communication flow:

```text
Robot Watchdog Service
          │
          ▼
     Router Service
          │
          ▼
   Watchdog Worker
          │
          ▼
 Receive WATCHDOG Message
```

---

## 2.1 Watchdog Message Structure

Each watchdog message consists of two sections:

- **Header**
  - Identifies the message type.
- **Payload**
  - Contains the health status of one or more subsystems.

Example:

```json
{
    "type": "WATCHDOG",
    "payload":
    {
        "robot":"on",
        "joystick":"on",
        "video_stream":"warning",
        "internet":"error"
    }
}
```

The worker validates the message type before processing the payload.

---

## 2.2 Receiving the Message

After registration, the worker enters its receive loop.

```cpp
while (isRunning())
{
    ...
}
```

Inside the loop, the worker waits for incoming messages using the DEALER socket.

```cpp
int n = zmq_recv(
    m_socket,
    buffer,
    sizeof(buffer),
    0);
```

Workflow:

```text
Router Service
       │
       ▼
 DEALER Socket
       │
       ▼
   zmq_recv()
```

Each received message is stored temporarily in a buffer before being parsed.

---

## 2.3 Parsing the JSON Message

The received byte stream is converted into a JSON document.

```cpp
QByteArray data(buffer, n);

QJsonParseError error;

QJsonDocument document =
    QJsonDocument::fromJson(data, &error);
```

If the received data is not valid JSON, the message is ignored.

```cpp
if (error.error != QJsonParseError::NoError)
    continue;
```

This prevents invalid or corrupted messages from being processed.

---

## 2.4 Validating the Message Type

The worker verifies that the received message is a watchdog message.

```cpp
QJsonObject object =
    document.object();

if (object["type"].toString() != "WATCHDOG")
    continue;
```

Only messages with the type:

```text
WATCHDOG
```

are processed.

All other message types are ignored.

---

## 2.5 Extracting the Payload

Once the message has been validated, the worker extracts the payload containing subsystem status information.

```cpp
QJsonObject payload =
    object["payload"].toObject();
```

Example payload:

```json
{
    "robot":"on",
    "joystick":"error",
    "video_stream":"warning",
    "internet":"disconnected"
}
```

Each entry represents the current state of a subsystem.

---

## 2.6 Converting to QVariantMap

The payload is converted into a `QVariantMap`.

```cpp
QVariantMap map;

for (auto it = payload.begin();
     it != payload.end();
     ++it)
{
    map[it.key()] =
        it.value().toVariant();
}
```

Example conversion:

```text
JSON Payload

robot            on
joystick         error
video_stream     warning

        │
        ▼

QVariantMap

robot            → on
joystick         → error
video_stream     → warning
```

The `QVariantMap` provides a convenient format for passing subsystem status information throughout the Qt application.

---

# 3. Subsystem Status Monitoring

The Watchdog Worker does not contain dedicated logic for individual subsystems. Instead, it processes every key-value pair present in the received payload.

This allows new subsystems to be added without modifying the worker implementation.

Typical subsystems include:

- Robot
- Joystick
- Video Stream
- Force Sensor
- Internet
- Camera
- RealSense

Example:

```json
{
    "robot":"on",
    "joystick":"on",
    "force_sensor":"warning",
    "internet":"error"
}
```

Each subsystem is forwarded to the Qt application exactly as received.

---

## 3.1 Supported Status Values

Each subsystem reports its operational state using one of the predefined status values.

The Watchdog Worker forwards these values to the Qt application without modification. The Qt application interprets each status and updates the corresponding watchdog indicator.

| Status | Description | UI Indicator |
|---------|-------------|--------------|
| **on** | Component is operating normally | 🟢 Green |
| **off** | Component is detected but inactive | 🟠 Orange |
| **warning** | Component is operating with a non-critical issue | 🟡 Yellow |
| **error** | Component failure detected | 🔴 Red |
| **disconnected** | Component unavailable or connection lost | ⚫ Gray / Black |
| **initializing** | Component is starting or calibrating | 🔵 Blue |

---

## 3.2 System State Monitoring

In addition to subsystem health, the robot may report its overall operating state.

Typical system states include:

| State | Description |
|--------|-------------|
| **IDLE** | System is powered but idle |
| **READY** | System is ready for operation |
| **EXECUTE** | System is currently executing a task |
| **ERROR** | System fault detected |

The system state is treated like any other payload field and forwarded to the Qt application.
---

# 4. Forwarding Status to the Qt Application

After processing the received watchdog message, the Watchdog Worker forwards the subsystem status to the Qt application.

The parsed subsystem information is emitted through the `statusReceived()` signal.

```cpp
emit statusReceived(map);
```

The emitted `QVariantMap` contains the latest status of all monitored subsystems.

Example:

```text
robot          → on

joystick       → error

video_stream   → warning

internet       → disconnected

force_sensor   → initializing
```

Communication flow:

```text
WATCHDOG JSON
       │
       ▼
 Parse JSON
       │
       ▼
Extract Payload
       │
       ▼
Create QVariantMap
       │
       ▼
emit statusReceived(map)
       │
       ▼
Qt Application
```

The Qt application receives the emitted status information and updates the corresponding watchdog indicators.

Since the Watchdog Worker is responsible only for communication and message processing, it does not perform any user interface updates. This separation keeps the communication layer independent of the presentation layer and allows the UI to determine how subsystem status is visually represented.

---

# 5. Overall Workflow

The complete execution flow of the Watchdog Worker is shown below.

```text
Create Watchdog Worker
        │
        ▼
Read Configuration
        │
        ▼
Create ZeroMQ Context
        │
        ▼
Create DEALER Socket
        │
        ▼
Connect to Router Service
        │
        ▼
Register as UI_WATCHDOG
        │
        ▼
Receive REGISTER_ACK
        │
        ▼
Wait for WATCHDOG Messages
        │
        ▼
Receive JSON Message
        │
        ▼
Validate Message Type
        │
        ▼
Extract Payload
        │
        ▼
Create QVariantMap
        │
        ▼
Emit statusReceived()
        │
        ▼
Qt Application
        │
        ▼
Update Watchdog Indicators
```

---

# Summary

The Watchdog Worker provides the communication interface for receiving subsystem health information from the Robot Software.

Its primary responsibilities include:

- Registering with the Router Service.
- Receiving watchdog JSON messages.
- Validating and parsing the received messages.
- Extracting subsystem status information.
- Converting the payload into a `QVariantMap`.
- Forwarding the parsed status to the Qt application.

The worker is responsible only for communication and message processing. The visualization of subsystem status is handled independently by the Qt user interface.

ker remains focused on message handling, while the Qt application is responsible for presenting the subsystem status to the operator.
