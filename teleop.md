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
