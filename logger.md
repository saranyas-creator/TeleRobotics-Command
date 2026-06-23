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

# Log Entry Format

All log entries follow the format:

```text
[Timestamp] [Level] [Thread ID] [Source File:Line Number] Message
```

**Example**

```text
[2026-06-20 16:59:34.551] [info] [1508310] [main.cpp:28]
Communication Service Starting...
```

| Field       | Description                              |
| ----------- | ---------------------------------------- |
| Timestamp   | Date and time when the event occurred    |
| Level       | Logging level (INFO, DEBUG, WARN, ERROR) |
| Thread ID   | Thread that generated the log            |
| Source File | File where the log was generated         |
| Line Number | Source code line number                  |
| Message     | Event description                        |

---

# Logging Levels

## 1. INFO

Used for normal system operations and successful events.

**Example Code**

```cpp
SPDLOG_INFO("Communication Service Starting...");
```

**Example Output**

```text
[2026-06-20 16:59:34.551] [info] [1508310] [main.cpp:28]
Communication Service Starting...
```

---

## 2. DEBUG

Used for detailed runtime information and message flow tracking.

**Example Code**

```cpp
SPDLOG_DEBUG("Forwarding to Robot CMD: ROBOT_CMD");
```

**Example Output**

```text
[2026-06-22 12:08:42.310] [debug] [396870] [router_service.cpp:186]
Forwarding to Robot CMD: ROBOT_CMD
```

---

## 3. WARN

Used for unexpected situations where the system can continue operating.

**Example Code**

```cpp
SPDLOG_WARN("Robot response delayed");
```

**Example Output**

```text
[2026-06-22 12:15:10.421] [warn] [396870] [router_service.cpp:210]
Robot response delayed
```

---

## 4. ERROR

Used when an operation fails or an error condition occurs.

**Example Code**

```cpp
SPDLOG_ERROR("ZMQ Forward Error to UI CMD");
```

**Example Output**

```text
[2026-06-22 12:20:05.112] [error] [396870] [router_service.cpp:220]
ZMQ Forward Error to UI CMD
```

**Example from Current Logs**

```text
[2026-06-20 17:10:50.946] [error] [1558750] [camera_service.cpp:196]
Failed to create pipeline for track 0:
no property "rtcpsync" in element "rtpjitterbuffer"
```
