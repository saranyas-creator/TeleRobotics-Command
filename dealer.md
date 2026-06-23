# Router-Dealer Channel

## 1. ROUTER-DEALER Pattern

The Router-Dealer Channel is implemented using the ZeroMQ (ZMQ) ROUTER-DEALER messaging pattern.

The pattern consists of:

* One ROUTER socket
* Multiple DEALER sockets

The ROUTER acts as a central message routing service responsible for receiving, identifying, and forwarding messages between registered dealers.

The DEALER sockets act as communication endpoints that connect to the ROUTER and exchange messages through it.

```text
                    ROUTER
                       │
      ┌────────────────┼────────────────┐
      │                │                │
      ▼                ▼                ▼
   DEALER-1           DEALER-2        DEALER-3
```

All communication between services flows through the ROUTER.
---

## 2. Router Service

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


## 3. Dealer Services

The current implementation contains six DEALER services.

```text
                           ROUTER
                              │
 ┌────────────┬────────────┬────────────┬────────────┬────────────┬────────────┐
 │            │            │            │            │            │
 ▼            ▼            ▼            ▼            ▼            ▼

UI_CMD     ROBOT_CMD    UI_CAMERA   ROBOT_CAMERA  UI_WATCHDOG  ROBOT_WATCHDOG
```

| Dealer         | Description                          |
| -------------- | ------------------------------------ |
| UI_CMD         | UI command communication endpoint    |
| ROBOT_CMD      | Robot command communication endpoint |
| UI_CAMERA      | UI camera signaling endpoint         |
| ROBOT_CAMERA   | Robot camera signaling endpoint      |
| UI_WATCHDOG    | UI health monitoring endpoint        |
| ROBOT_WATCHDOG | Robot health monitoring endpoint     |

Each dealer connects independently to the Router Service.


## 4. Dealer Registration

Before exchanging messages, every dealer must register itself with the Router Service.

Registration allows the Router to associate a Dealer Identity with a Dealer Role.

The same registration process is followed by all six dealers.

### Step 1: Create Dealer Socket

Each service creates a ZeroMQ DEALER socket.

```cpp
m_socket = zmq_socket(m_context, ZMQ_DEALER);
```

### Step 2: Assign Dealer Identity

Each dealer is assigned a unique identity.

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

### Step 4: Send Registration Request

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

### Step 5: Router Registers Dealer

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

### Step 6: Router Sends Registration Acknowledgement

```json
{
    "id": "REG_UI_CMD",
    "type": "REGISTER_ACK",
    "status": "OK"
}
```

### Step 7: Dealer Enters Operational State

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

The same registration lifecycle is followed by all six dealers before any messages are exchanged.

## 5. Message Routing

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

### 5.1 Command Flow

Used for forwarding command messages between the UI and Robot services.

#### UI Command → Robot Command

```text
UI_CMD
   │
   ▼
 ROUTER
   │
   ▼
ROBOT_CMD
```

Used for forwarding command messages from the UI to the Robot.

#### Robot Command → UI Command

```text
ROBOT_CMD
    │
    ▼
 ROUTER
    │
    ▼
 UI_CMD
```

Used for forwarding command acknowledgements, status updates, and robot-generated messages to the UI.

### 5.2 Camera Signaling Flow

Used for exchanging WebRTC signaling messages between the UI and Robot camera services.

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

### 5.3 Watchdog Flow

Used for exchanging watchdog and health-monitoring messages between UI and Robot services.

#### Robot Watchdog → UI Watchdog

```text
ROBOT_WATCHDOG
         │
         ▼
      ROUTER
         │
         ▼
    UI_WATCHDOG
```


## 6. Complete Communication Flow

```text
                           ROUTER
                              │
 ┌────────────┬────────────┬────────────┬────────────┬────────────┬────────────┐
 │            │            │            │            │            │
 ▼            ▼            ▼            ▼            ▼            ▼

UI_CMD     ROBOT_CMD    UI_CAMERA   ROBOT_CAMERA  UI_WATCHDOG  ROBOT_WATCHDOG
```

All command messages, camera signaling messages, watchdog messages, acknowledgements, and responses are routed through the Router Service.

The Router acts as the central communication broker and ensures that messages reach the correct destination dealer without requiring direct connections between services.
