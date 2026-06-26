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
