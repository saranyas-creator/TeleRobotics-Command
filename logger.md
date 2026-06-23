# Logging Framework (spdlog)

## What is spdlog?

spdlog is a high-performance C++ logging library used to record application events during runtime.

The TeleRobotics software uses spdlog as the central logging framework to capture system events, communication status, warnings, errors, and debugging information.

All logs are written to:

* Console output (for real-time monitoring)
* Rotating log files (for debugging and troubleshooting)

Using a centralized logging framework ensures consistent log formatting and simplifies issue diagnosis during development and deployment.

---

## Why do we use spdlog?

The TeleRobotics system contains multiple software services running simultaneously, including:

* Communication Service
* Router Service
* Camera Service
* Teleoperation Service
* Shared Memory Service

When an issue occurs, logs help developers understand:

* What happened
* When it happened
* Which service generated the event
* Whether the operation succeeded or failed

spdlog automatically adds:

* Timestamp
* Log level
* Thread ID
* Source file name
* Source line number

to every log entry.

---

## Logging Levels

The project primarily uses four logging levels.

### INFO

Used to record normal system operations and successful events.

Example:

```cpp
SPDLOG_INFO("Communication Service Starting...");
```

Log Output:

```text
[2026-06-20 16:59:34.551] [info] [1508310] [main.cpp:28]
Communication Service Starting...
```

Use INFO when:

* Service starts successfully
* Service stops successfully
* Device registration succeeds
* Communication channels are established

---

### DEBUG

Used for detailed runtime information helpful during development and troubleshooting.

Example:

```cpp
SPDLOG_DEBUG("Forwarding to Robot CMD: ROBOT_CMD");
```

Log Output:

```text
[2026-06-22 12:08:42.310] [debug] [396870]
[router_service.cpp:186]
Forwarding to Robot CMD: ROBOT_CMD
```

Use DEBUG when:

* Tracking message routing
* Monitoring internal state changes
* Verifying communication flow
* Debugging application behavior

---

### WARN

Used when an unexpected situation occurs but the application can continue operating.

Example:

```cpp
SPDLOG_WARN("Robot response delayed");
```

Possible Output:

```text
[2026-06-22 12:15:10.421] [warn]
[router_service.cpp:210]
Robot response delayed
```

Use WARN when:

* Latency becomes unusually high
* Connection quality degrades
* Retry mechanisms are activated
* Non-critical issues occur

---

### ERROR

Used when an operation fails and developer attention is required.

Example:

```cpp
SPDLOG_ERROR(
    "Failed to create pipeline for track {}",
    trackId
);
```

Log Output:

```text
[2026-06-20 17:10:50.946] [error]
[camera_service.cpp:196]
Failed to create pipeline for track 0
```

Use ERROR when:

* Camera initialization fails
* Communication fails
* File operations fail
* Resource creation fails

---

## Log Entry Format

Each log entry follows the format:

```text
[Timestamp] [Level] [Thread ID] [Source File:Line Number] Message
```

Example:

```text
[2026-06-20 16:59:34.551] [info] [1508310]
[main.cpp:28]
Communication Service Starting...
```

Meaning:

* Timestamp → When the event occurred
* Level → Severity of the event
* Thread ID → Thread that generated the log
* Source File → File generating the log
* Line Number → Exact code location
* Message → Description of the event

```
```
