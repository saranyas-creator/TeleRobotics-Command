# Router-Dealer Channel

## What is the ROUTER-DEALER Pattern?

The Router-Dealer Channel is implemented using the ZeroMQ (ZMQ) ROUTER-DEALER messaging pattern.

The pattern consists of:

* One ROUTER socket
* Multiple DEALER sockets

The ROUTER acts as a central communication broker responsible for receiving, identifying, and forwarding messages.

The DEALER sockets act as communication endpoints that connect to the ROUTER and exchange messages through it.

```text
                    ROUTER
                       │
      ┌────────────────┼────────────────┐
      │                │                │
      ▼                ▼                ▼
   DEALER           DEALER          DEALER
```

All communication between services flows through the ROUTER.

---

## Router Service

The Communication Layer contains a single ROUTER service.

```text
ROUTER
tcp://*:5555
```

The Router Service is responsible for:

* Accepting dealer connections
* Registering dealers
* Maintaining dealer identities
* Receiving messages
* Forwarding messages to target dealers

The Router Service runs continuously and listens for messages from all registered dealers.

---

## Dealer Services

The current implementation contains six DEALER services.

                    ROUTER
                       │
 ┌─────────┬─────────┬─────────┬─────────┬─────────┬─────────┐
 │         │         │         │         │         │
 ▼         ▼         ▼         ▼         ▼         ▼

UI_CMD  ROBOT_CMD UI_CAMERA ROBOT_CAMERA UI_WATCHDOG ROBOT_WATCHDOG

| Dealer         | Description                          |
| -------------- | ------------------------------------ |
| UI_CMD         | UI command communication endpoint    |
| ROBOT_CMD      | Robot command communication endpoint |
| UI_CAMERA      | UI camera signaling endpoint         |
| ROBOT_CAMERA   | Robot camera signaling endpoint      |
| UI_WATCHDOG    | UI health monitoring endpoint        |
| ROBOT_WATCHDOG | Robot health monitoring endpoint     |

Each dealer connects independently to the Router Service.

---

## Dealer Registration

Before exchanging messages, every dealer must register itself with the Router Service.

Registration allows the Router to associate a Dealer Identity with a Dealer Role.

The same registration process is followed by all six dealers.

---

### Step 1: Create Dealer Socket

Each service creates a ZeroMQ DEALER socket.

**Example**

```cpp
m_socket = zmq_socket(m_context, ZMQ_DEALER);
```

---

### Step 2: Assign Dealer Identity

Each dealer is assigned a unique identity.

**UI_CMD**

```cpp
QByteArray identity = "UI_CMD";

zmq_setsockopt(
    m_socket,
    ZMQ_IDENTITY,
    identity.data(),
    identity.size());
```

Possible identities:

```text
UI_CMD
ROBOT_CMD
UI_CAMERA
ROBOT_CAMERA
UI_WATCHDOG
ROBOT_WATCHDOG
```

---

### Step 3: Connect to Router

The dealer connects to the Router Service.

```cpp
zmq_connect(
    m_socket,
    "tcp://127.0.0.1:5555");
```

Connection flow:

```text
UI_CMD
   │
   ▼
ROUTER
```

The same process is performed by all six dealers.

---

### Step 4: Send Registration Request

After connecting, the dealer sends a REGISTER message.

**Example**

```json
{
    "id": "REG_UI_CMD",
    "type": "REGISTER",
    "source": "UI_CMD",
    "target": "ROUTER",
    "payload":
    {
        "role": "UI_CMD"
    }
}
```

The role changes depending on the dealer.

Examples:

```json
{
    "role": "ROBOT_CMD"
}
```

```json
{
    "role": "UI_CAMERA"
}
```

```json
{
    "role": "ROBOT_CAMERA"
}
```

```json
{
    "role": "UI_WATCHDOG"
}
```

```json
{
    "role": "ROBOT_WATCHDOG"
}
```

---

### Step 5: Router Registers Dealer

When the Router receives a REGISTER message, it stores the dealer identity and role mapping.

**Router Code**

```cpp
identityManager.registerClient(
    clientId,
    role);
```

Registration table:

```text
UI_CMD           → Identity A
ROBOT_CMD        → Identity B
UI_CAMERA        → Identity C
ROBOT_CAMERA     → Identity D
UI_WATCHDOG      → Identity E
ROBOT_WATCHDOG   → Identity F
```

This table is maintained by the Router and is later used for message forwarding.

---

### Step 6: Router Sends Registration Acknowledgement

After successful registration, the Router sends a REGISTER_ACK message.

**Example**

```json
{
    "id": "REG_UI_CMD",
    "type": "REGISTER_ACK",
    "status": "OK"
}
```

---

### Step 7: Dealer Enters Operational State

After receiving REGISTER_ACK, the dealer is considered registered and ready for communication.

```text
Create Dealer
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
Ready for Communication
```

The same registration lifecycle is followed by:

```text
UI_CMD
ROBOT_CMD
UI_CAMERA
ROBOT_CAMERA
UI_WATCHDOG
ROBOT_WATCHDOG
```

before any commands, camera signaling messages, or watchdog messages can be exchanged.

## Message Routing

Once a dealer successfully registers and receives a `REGISTER_ACK`, it can begin exchanging messages through the Router Service.

The Router continuously listens for incoming messages from all registered dealers and forwards them to the appropriate destination based on the `target` field.

```text
Receive Message
       │
       ▼
 Parse JSON
       │
       ▼
 Determine Target
       │
       ▼
 Forward Message
```

---

### UI Command Flow

Used for forwarding commands from the UI to the Robot.

```text
UI_CMD
   │
   ▼
 ROUTER
   │
   ▼
ROBOT_CMD
```

**Example Message**

```json
{
    "id": "cmd_001",
    "type": "COMMAND",
    "source": "UI_CMD",
    "target": "ROBOT_CMD",
    "payload":
    {
        "action": "start_scan"
    }
}
```

**Router Logic**

```cpp
else if (target == "ROBOT_CMD")
{
    forwardToRobotCMD(router, data);
}
```

---

### Robot Response Flow

Used for forwarding responses from the Robot back to the UI.

```text
ROBOT_CMD
    │
    ▼
 ROUTER
    │
    ▼
 UI_CMD
```

**Example Message**

```json
{
    "id": "cmd_001",
    "type": "COMMAND_ACK",
    "source": "ROBOT_CMD",
    "target": "UI_CMD"
}
```

**Router Logic**

```cpp
else if (target == "UI_CMD")
{
    forwardToUICMD(router, data);
}
```

---

### Camera Signaling Flow

Used for WebRTC signaling messages exchanged between the UI and Robot camera services.

#### UI Camera → Robot Camera

```text
UI_CAMERA
     │
     ▼
  ROUTER
     │
     ▼
ROBOT_CAMERA
```

#### Robot Camera → UI Camera

```text
ROBOT_CAMERA
      │
      ▼
   ROUTER
      │
      ▼
  UI_CAMERA
```

**Router Logic**

```cpp
else if (target == "ROBOT_CAMERA")
{
    forwardToRobotCamera(router, data);
}

else if (target == "UI_CAMERA")
{
    forwardToUICamera(router, data);
}
```

---

### Watchdog Flow

Used for monitoring communication health and service availability.

```text
UI_WATCHDOG
      │
      ▼
   ROUTER
      │
      ▼
ROBOT_WATCHDOG
```

The Router receives watchdog messages and forwards them to the Watchdog Handler for processing.

**Router Logic**

```cpp
if (type == "WATCHDOG" &&
    target == "UI_WATCHDOG")
{
    watchdogHandler.handle(
        data,
        router,
        identityManager);
}
```

---

### Complete Communication Flow

```text
                    ROUTER
                       │
 ┌─────────────┬───────┼─────────────┐
 │             │       │             │
 ▼             ▼       ▼             ▼

UI_CMD      UI_CAMERA  UI_WATCHDOG

ROBOT_CMD   ROBOT_CAMERA ROBOT_WATCHDOG
```

All command messages, camera signaling messages, watchdog messages, acknowledgements, and responses are routed through the Router Service.

The Router acts as the central communication broker and ensures that messages reach the correct destination dealer without requiring direct connections between services.

