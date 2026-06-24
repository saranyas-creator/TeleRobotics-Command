## 3.1 Hardware Loop

The Hardware Loop is responsible for direct communication with the Geomagic Touch device.

The loop runs continuously at approximately **1 kHz (1 ms period)** and acts as the interface between the physical joystick hardware and the teleoperation software.

```text
Geomagic Touch
      │
      ▼
 Hardware Loop
      │
      ▼
 Shared State
```

### Responsibilities

The Hardware Loop performs the following operations:

* Joystick connection monitoring
* Joystick initialization
* Hot-unplug detection
* Force feedback handling
* Position acquisition
* Velocity acquisition
* Angular velocity acquisition
* Button state acquisition
* Shared state updates
* Watchdog status reporting

---

### Workflow

```text
Start Loop
    │
    ▼
Send Watchdog
    │
    ▼
Joystick Connected?
    │
 ┌──┴──┐
 │     │
 No    Yes
 │      │
 ▼      ▼
Initialize   Check Alive
               │
               ▼
         Read Force
               │
               ▼
      Read Joystick Data
               │
               ▼
      Update Shared State
               │
               ▼
           Sleep 1 ms
               │
               ▼
          Repeat
```

---

### Watchdog Monitoring

The Hardware Loop periodically sends a watchdog status message to indicate the health of the joystick connection.

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

The watchdog is transmitted approximately once every second.

Purpose:

* Report joystick health status
* Detect hardware failures
* Inform the UI about device availability

---

### Joystick Detection

Before initialization, the loop checks whether the Geomagic Touch device is physically connected.

```cpp
if (!isJoystickPluggedIn())
{
    std::this_thread::sleep_for(
        std::chrono::seconds(1));
    continue;
}
```

The device is detected using its USB identifier.

Purpose:

* Detect joystick availability
* Prevent initialization attempts when the device is disconnected

---

### Joystick Initialization

When a joystick is detected, the service attempts initialization.

```cpp
if (joystick.initialize())
{
    isJoystickConnected = true;
}
```

Purpose:

* Establish communication with the device
* Initialize the joystick SDK
* Prepare the hardware for operation

---

### Hot-Unplug Detection

During operation, the Hardware Loop continuously verifies that the joystick remains available.

```cpp
if (!joystick.isAlive())
{
    joystick.shutdown();
    isJoystickConnected = false;
}
```

Purpose:

* Detect unexpected device disconnection
* Safely shut down hardware communication
* Automatically return to detection mode

---

### Force Feedback Handling

The Hardware Loop retrieves the latest force feedback received from the robot.

```cpp
RobotToControllerMsg latest_force =
    shared_state.getForce();
```

Force components:

```text
Force X
Force Y
Force Z
```

These values are intended to be applied to the Geomagic Touch device to generate haptic feedback.

---

### Joystick Data Acquisition

The Hardware Loop continuously reads the current joystick state.

#### Position

```cpp
auto pos = joystick.getPosition();
```

```text
Position X
Position Y
Position Z
```

#### Velocity

```cpp
auto vel = joystick.getVelocity();
```

```text
Velocity X
Velocity Y
Velocity Z
```

#### Angular Velocity

```cpp
auto ang_vel =
    joystick.getAngularVelocity();
```

```text
Angular Velocity X
Angular Velocity Y
Angular Velocity Z
```

#### Buttons

```cpp
int buttons =
    joystick.getButtons();
```

```text
Button States
```

---

### Controller Message Generation

The acquired joystick information is packed into a ControllerToRobotMsg structure.

```cpp
ControllerToRobotMsg msg{};
```

The message contains:

```text
Sequence Number

Position
Velocity
Angular Velocity

Button States
```

Example:

```text
Sequence Number : 150

Position:
(0.12, 0.25, 0.08)

Velocity:
(0.45, 0.10, 0.00)

Buttons:
1
```

---

### Shared State Update

The generated controller message is written into the shared state.

```cpp
shared_state.setData(msg);
```

Purpose:

* Store the latest joystick state
* Make data available to the UDP Transmit Loop
* Decouple hardware access from network transmission

The Hardware Loop does not transmit UDP packets directly.

---

### Loop Timing

The Hardware Loop operates at approximately 1 kHz.

```cpp
std::this_thread::sleep_for(
    std::chrono::milliseconds(1));
```

This maintains a loop period of roughly 1 ms.

```text
1 ms
  │
  ▼
Read Hardware
  │
  ▼
Update State
  │
  ▼
Repeat
```

---

### Recovery Mechanism

The Hardware Loop includes automatic recovery for hardware failures.

#### Device Not Connected

```text
Joystick Missing
       │
       ▼
Wait 1 Second
       │
       ▼
Retry Detection
```

#### Initialization Failure

```text
Initialization Failed
          │
          ▼
     Wait 1 Second
          │
          ▼
     Retry Initialization
```

#### Hot-Unplug Event

```text
Joystick Running
       │
       ▼
Device Unplugged
       │
       ▼
Shutdown Device
       │
       ▼
Reset Connection State
       │
       ▼
Retry Detection
```

This allows the service to recover automatically without restarting the application.


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


