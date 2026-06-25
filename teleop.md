# Channel 3 - Teleoperation

# Overview

The Teleoperation Channel is responsible for real-time communication between the Geomagic Touch device and the robot using **Raw UDP** communication.

To achieve low-latency teleoperation, the channel separates hardware interaction, data transmission, and telemetry reception into independent execution threads. Communication between these threads is performed using shared state objects, while telemetry required by the Qt application is exchanged through a shared memory region.

The Teleoperation Channel consists of:

- Three parallel execution threads
- Two shared state objects for intra-process communication
- One shared memory region for inter-process communication

---



```mermaid
flowchart TB

    %% =========================
    %% External Components
    %% =========================
    J[Geomagic Touch]
    R[Robot]

    %% =========================
    %% Threads
    %% =========================
    H["1. Hardware Loop<br/>(Thread)"]
    TX["2. UDP TX Loop<br/>(Thread)"]
    RX["3. UDP RX Loop<br/>(Thread)"]

    %% =========================
    %% Shared States
    %% =========================
    S1["S1 : ControllerToRobot<br/>Shared State"]
    S2["S2 : RobotToController<br/>Shared State"]

    %% =========================
    %% Shared Memory
    %% =========================
    STW["SharedTelemetryWriter"]
    SHM["Shared Memory<br/>(Inter-Process)"]
    TS["TelemetryService"]
    UI["Qt UI"]

    %% =========================
    %% Hardware Connections
    %% =========================
    J --> H

    %% =========================
    %% Controller Data Flow
    %% =========================
    H -->|Write Controller Data| S1
    S1 -->|Read Controller Data| TX
    TX -->|Raw UDP<br/>ControllerToRobotMsg| R

    %% =========================
    %% Robot Telemetry Flow
    %% =========================
    R -->|Raw UDP<br/>RobotToControllerMsg| RX
    RX -->|Write Telemetry| S2
    S2 -->|Read Force Feedback<br/>STL Position<br/>STL Orientation| H

    %% =========================
    %% Shared Memory Flow
    %% =========================
    RX -->|Publish Telemetry| STW
    STW -->|Write| SHM
    SHM -->|Read| TS
    TS --> UI
```


# Thread Communication

The Teleoperation Channel uses two shared state objects for communication between execution threads and one shared memory region for communication with the Qt application.

---

## S1 - ControllerToRobot Shared State

The **ControllerToRobot Shared State (S1)** enables communication between the **Hardware Loop** and the **UDP TX Loop**.

The Hardware Loop continuously acquires the latest controller state from the Geomagic Touch device and stores it in S1. The UDP TX Loop reads this information from S1 and transmits it to the robot using Raw UDP communication.

### Data Flow

```text
Hardware Loop
      │
Write Controller Data
      ▼
S1 : ControllerToRobot
      ▲
Read Controller Data
      │
UDP TX Loop
```

### Written By

- Hardware Loop

### Read By

- UDP TX Loop

### Stored Data

```text
Sequence Number

Position

Velocity

Angular Velocity

Button States
```

---

## S2 - RobotToController Shared State

The **RobotToController Shared State (S2)** enables communication between the **UDP RX Loop** and the **Hardware Loop**.

The UDP RX Loop continuously receives robot telemetry and stores it in S2. The Hardware Loop reads this information to obtain the latest force feedback and STL pose information.

### Data Flow

```text
Robot
      │
RobotToControllerMsg
      ▼
UDP RX Loop
      │
Write Robot Telemetry
      ▼
S2 : RobotToController
      ▲
Read Force Feedback
Read STL Position
Read STL Orientation
      │
Hardware Loop
```

### Written By

- UDP RX Loop

### Read By

- Hardware Loop

### Stored Data

```text
Force Feedback

STL Position

STL Orientation

Sequence Number
```

---

## Shared Memory

The Qt application executes in a separate process and therefore cannot directly access **S1** or **S2**.

To enable inter-process communication, the UDP RX Loop publishes the latest robot telemetry into a shared memory region using the **SharedTelemetryWriter**. The Qt application's **TelemetryService** continuously reads this shared memory and provides the telemetry to the user interface.

### Data Flow

```text
UDP RX Loop
      │
      ▼
SharedTelemetryWriter
      │
Write Shared Memory
      ▼
Shared Memory
      ▲
Read Shared Memory
      │
TelemetryService
      │
      ▼
Qt UI
```

### Written By

- SharedTelemetryWriter (invoked by the UDP RX Loop)

### Read By

- TelemetryService

### Published Data

```text
Force Feedback

STL Position

STL Orientation

Sequence Number

Timestamp
```

---

# Thread 1 - Hardware Loop

The **Hardware Loop** is responsible for direct communication with the **Geomagic Touch** device.

It continuously:

- Monitors the joystick connection.
- Applies force feedback received from **S2 (RobotToController Shared State)**.
- Reads the latest controller state from the Geomagic Touch device.
- Generates a **ControllerToRobotMsg**.
- Updates **S1 (ControllerToRobot Shared State)** for the UDP TX Loop.

The Hardware Loop operates at approximately **1 kHz (1 ms period)**.

---

## 1.1 Workflow

```text
Start Loop
      │
      ▼
Send Watchdog
      │
      ▼
Joystick Connected?
      │
 ┌────┴────┐
 │         │
 No       Yes
 │          │
 ▼          ▼
Initialize  Check Alive
               │
               ▼
      Read Force Feedback
          From S2
               │
               ▼
      Read Joystick State
               │
               ▼
Generate ControllerToRobotMsg
               │
               ▼
 Update S1 Shared State
               │
               ▼
        Sleep (1 ms)
               │
               ▼
            Repeat
```

---

## 1.2 Watchdog Monitoring

The Hardware Loop periodically sends a watchdog message indicating the current joystick status.

```json
{
    "type": "WATCHDOG",
    "target": "UI_WATCHDOG",
    "payload":
    {
        "joystick": "on"
    }
}
```

This allows the UI to continuously monitor the operational state of the Geomagic Touch device.

---

## 1.3 Joystick Management

Before normal operation begins, the Hardware Loop verifies that the Geomagic Touch device is connected and initializes the hardware.

### Joystick Detection

```cpp
if (!isJoystickPluggedIn())
{
    std::this_thread::sleep_for(
        std::chrono::seconds(1));
    continue;
}
```

### Joystick Initialization

```cpp
if (joystick.initialize())
{
    isJoystickConnected = true;
}
```

### Hot-Unplug Detection

```cpp
if (!joystick.isAlive())
{
    joystick.shutdown();
    isJoystickConnected = false;
}
```

If the joystick is disconnected during operation, the Hardware Loop automatically returns to the detection stage and retries initialization.

---

## 1.4 Reading Robot Telemetry from S2

The Hardware Loop retrieves the latest telemetry written by the UDP RX Loop into **S2 (RobotToController Shared State)**.

```cpp
RobotToControllerMsg latest_force =
    shared_state.getForce();
```

The retrieved telemetry includes:

```text
Force Feedback

STL Position

STL Orientation
```

The force feedback values are applied to the Geomagic Touch device to generate haptic feedback.

---

## 1.5 Reading Controller State

The Hardware Loop continuously acquires the current controller state.

```cpp
auto pos     = joystick.getPosition();
auto vel     = joystick.getVelocity();
auto ang_vel = joystick.getAngularVelocity();
int buttons  = joystick.getButtons();
```

The acquired controller state consists of:

```text
Position

Velocity

Angular Velocity

Button States
```

---

## 1.6 Generating ControllerToRobot Message

The acquired controller information is packed into a **ControllerToRobotMsg** structure.

```cpp
ControllerToRobotMsg msg{};
```

The generated message contains:

```text
Sequence Number

Position

Velocity

Angular Velocity

Button States
```

---

## 1.7 Updating S1 (ControllerToRobot Shared State)

The generated controller message is written into **S1 (ControllerToRobot Shared State)**.

```cpp
shared_state.setData(msg);
```

S1 acts as the communication bridge between the Hardware Loop and the UDP TX Loop.

```text
Hardware Loop
      │
Generate ControllerToRobotMsg
      │
      ▼
S1 : ControllerToRobot
      ▲
Read ControllerToRobotMsg
      │
UDP TX Loop
```

The Hardware Loop only updates S1. The UDP TX Loop retrieves the latest controller data from S1 and transmits it to the robot.

---

## 1.8 Recovery Mechanism

The Hardware Loop includes automatic recovery to handle hardware failures.

```text
Joystick Missing
       │
       ▼
Retry Detection
       │
       ▼
Initialize Device
       │
       ▼
Operational
```

If the joystick is disconnected during operation, the Hardware Loop safely shuts down the device, resets the connection state, and automatically retries detection and initialization without requiring the application to be restarted.

## 3.2 UDP TX Loop

The UDP TX Loop is responsible for transmitting controller data from the local teleoperation system to the robot using Raw UDP communication.

The loop runs continuously at approximately **1 kHz (1 ms period)** and sends the latest controller state generated by the Hardware Loop.

```text
Hardware Loop
      │
      ▼
 Shared State
      │
      ▼
 UDP TX Loop
      │
      ▼
   Raw UDP
      │
      ▼
    Robot
```

---

### Responsibilities

The UDP TX Loop performs the following operations:

* Read latest controller data
* Retrieve joystick position
* Retrieve joystick velocity
* Retrieve joystick angular velocity
* Retrieve button states
* Transmit ControllerToRobotMsg
* Maintain continuous robot updates

---

### Workflow

```text
Read Shared State
        │
        ▼
ControllerToRobotMsg
        │
        ▼
Send UDP Packet
        │
        ▼
Robot
        │
        ▼
Sleep 1 ms
        │
        ▼
Repeat
```

---

### Data Source

The UDP TX Loop does not communicate directly with the Geomagic Touch device.

Instead, it reads the latest controller state produced by the Hardware Loop.

```cpp
ControllerToRobotMsg msg =
    shared_state.getData();
```

Flow:

```text
Geomagic Touch
       │
       ▼
 Hardware Loop
       │
       ▼
 Shared State
       │
       ▼
 UDP TX Loop
```

This separation allows hardware access and network communication to operate independently.

---

### ControllerToRobotMsg

The transmitted packet contains the latest controller information.

```text
Sequence Number

Position
Position X
Position Y
Position Z

Velocity
Velocity X
Velocity Y
Velocity Z

Angular Velocity
Angular Velocity X
Angular Velocity Y
Angular Velocity Z

Button States
```

Example:

```text
Sequence Number : 150

Position
X : 0.12
Y : 0.45
Z : -0.03

Velocity
X : 0.50
Y : 0.10
Z : 0.00

Angular Velocity
X : 0.02
Y : 0.01
Z : 0.00

Buttons : 1
```

---

### UDP Transmission

The controller message is transmitted using a UDP socket.

```cpp
sendto(
    udp_socket,
    &msg,
    sizeof(msg),
    0,
    (const struct sockaddr*)&remote_addr,
    sizeof(remote_addr));
```

The destination is configured using:

```text
Remote IP Address
Remote UDP Port
```

Communication flow:

```text
ControllerToRobotMsg
         │
         ▼
     UDP Socket
         │
         ▼
      Network
         │
         ▼
       Robot
```

---

### Loop Timing

The UDP TX Loop operates at approximately 1 kHz.

```cpp
std::this_thread::sleep_for(
    std::chrono::milliseconds(1));
```

Loop timing:

```text
1 ms
 │
 ▼
Read Controller Data
 │
 ▼
Send UDP Packet
 │
 ▼
Repeat
```

This ensures the robot continuously receives updated controller information.

---

### Communication Flow

```text
Geomagic Touch
      │
      ▼
 Hardware Loop
      │
      ▼
 Shared State
      │
      ▼
 UDP TX Loop
      │
      ▼
 ControllerToRobotMsg
      │
      ▼
 Raw UDP
      │
      ▼
 Robot
```

The UDP TX Loop acts as the transmission layer of the Teleoperation Channel, continuously forwarding the latest controller state from the local operator to the remote robot.

## 3.3 UDP RX Loop

The UDP RX Loop is responsible for receiving telemetry data from the robot using Raw UDP communication.

The loop runs continuously and processes data sent by the robot, including force feedback and STL pose information.

```text
Robot
   │
   ▼
 Raw UDP
   │
   ▼
UDP RX Loop
   │
   ▼
Shared State
   │
   ▼
SharedTelemetryWriter
```

---

### Responsibilities

The UDP RX Loop performs the following operations:

* Receive RobotToControllerMsg packets
* Extract force feedback data
* Extract STL position data
* Extract STL orientation data
* Update shared state
* Publish telemetry to shared memory

---

### Workflow

```text
Receive UDP Packet
        │
        ▼
RobotToControllerMsg
        │
        ▼
Update Force Data
        │
        ▼
Publish Telemetry
        │
        ▼
Wait for Next Packet
```

---

### Data Source

The UDP RX Loop continuously listens for incoming UDP packets from the robot.

```cpp
recvfrom(
    udp_socket,
    &rx_msg,
    sizeof(rx_msg),
    0,
    (struct sockaddr*)&sender_addr,
    &sender_len);
```

Communication flow:

```text
Robot
   │
   ▼
Raw UDP
   │
   ▼
UDP RX Loop
```

---

### RobotToControllerMsg

The received packet contains telemetry information generated by the robot.

```text
Force Feedback
Force X
Force Y
Force Z

STL Position
Position X
Position Y
Position Z

STL Orientation
Angle X
Angle Y
Angle Z

Sequence Number
Timestamp
```

---

### Force Feedback Update

After receiving a valid packet, the latest force information is stored in the shared state.

```cpp
shared_state.setForce(rx_msg);
```

Flow:

```text
Robot Force Data
        │
        ▼
 UDP RX Loop
        │
        ▼
 Shared State
```

The Hardware Loop later retrieves this force information and applies it to the Geomagic Touch device.

```text
Robot
   │
   ▼
UDP RX Loop
   │
   ▼
Shared State
   │
   ▼
Hardware Loop
   │
   ▼
Geomagic Touch
```

---

### STL Telemetry

The robot also sends STL pose information.

```text
STL Position
X
Y
Z

STL Orientation
Roll
Pitch
Yaw
```

These values represent the latest robot-side STL position and orientation.

---

### Shared Memory Publishing

After processing the received packet, the telemetry information is written into the shared memory region.

```cpp
telemetry_writer.publish(rx_msg);
```

Published data:

```text
Force X
Force Y
Force Z

STL Position X
STL Position Y
STL Position Z

STL Orientation X
STL Orientation Y
STL Orientation Z

Sequence Number
Timestamp
```

Flow:

```text
Robot
   │
   ▼
UDP RX Loop
   │
   ▼
SharedTelemetryWriter
   │
   ▼
Shared Memory
```

---

### Data Validation

The UDP RX Loop verifies that a complete telemetry packet has been received before processing.

```cpp
if (bytes_received == sizeof(rx_msg))
{
    ...
}
```

Only complete packets are accepted for further processing.

---

### Communication Flow

```text
Robot
   │
   ▼
RobotToControllerMsg
   │
   ▼
UDP RX Loop
   │
   ├──────────────► Shared State
   │                    │
   │                    ▼
   │              Hardware Loop
   │                    │
   │                    ▼
   │              Geomagic Touch
   │
   ▼
SharedTelemetryWriter
   │
   ▼
Shared Memory
   │
   ▼
TelemetryService
   │
   ▼
Qt UI
```

The UDP RX Loop acts as the receiving layer of the Teleoperation Channel, continuously collecting robot telemetry, updating force feedback information, and publishing STL pose data for consumption by both the Hardware Loop and the Qt user interface.


