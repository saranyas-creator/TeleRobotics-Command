
# Camera Worker

## Overview

The **Camera Worker** is responsible for receiving camera frames published by the **UI_CAMERA** service and delivering them to the Qt application for display.

The worker inherits from **ZmqWorkerBase** and runs in its own worker thread managed by the **ZmqManager**. It communicates with the Software Services using a **ZeroMQ SUB socket**, subscribes to camera topics, receives RGB image frames, converts them into `QImage` objects, and forwards them to the Qt user interface.

The Camera Worker is responsible for:

- Connecting to the camera publisher
- Subscribing to camera topics
- Receiving RGB image frames
- Processing incoming frame data
- Converting raw image data into `QImage`
- Emitting frames to the Qt application

Unlike the Command Worker and Watchdog Worker, the Camera Worker does **not** communicate with the Router Service. Instead, it directly subscribes to the camera publisher created by the Software Services.

---

# Communication Flow

The Camera Worker receives RGB image frames published by the **UI_CAMERA** service and delivers them to the Qt application.

```text
Software Services
        │
        ▼
UI_CAMERA (Publisher)
        │
        ▼
 ZeroMQ PUB Socket
        │
camera.frame.<trackId>
        │
        ▼
Camera Worker (SUB)
        │
        ▼
Frame Processing
        │
        ▼
QImage
        │
        ▼
Qt Camera Widget
```

The communication process consists of two stages.

### Software Services

The UI_CAMERA service publishes decoded RGB image frames through a ZeroMQ PUB socket.

Each published frame is associated with a topic in the following format:

```text
camera.frame.<trackId>
```

Example:

```text
camera.frame.track_01
camera.frame.track_02
camera.frame.track_03
```

### Qt Application

The Camera Worker subscribes to the published camera topics.

Whenever a new frame is published:

- The frame is received by the Camera Worker.
- The topic and payload are extracted.
- The RGB image is converted into a `QImage`.
- The frame is emitted to the Qt application.

---

# Architecture

The Camera Worker is created and managed by the **ZmqManager**.

```text
                 Qt Application
                        │
                        ▼
                  ZmqManager
                        │
                        ▼
                 Camera Worker
                        │
                ZeroMQ SUB Socket
                        │
                        ▼
          camera.frame.<trackId>
                        │
                        ▼
               Frame Processing
                        │
                        ▼
                   QImage Frame
                        │
                        ▼
                Qt Camera Widget
```

The Camera Worker acts as the communication bridge between the Software Services and the Qt application.

---

# 1. Worker Initialization

The Camera Worker is created during application startup by the **ZmqManager**.

```text
Qt Application
       │
       ▼
   ZmqManager
       │
       ▼
Create Camera Worker
       │
       ▼
 Worker Thread Starts
```

The worker constructor initializes the Camera Worker object.

```cpp
ZMQCameraWorker::ZMQCameraWorker(QObject *parent)
    : ZmqWorkerBase(parent)
{
}
```

Since the Camera Worker inherits from `ZmqWorkerBase`, it automatically gains the common worker lifecycle interface shared by all communication workers.

---

# 2. Worker Startup

After the worker thread starts, the `start()` function initializes all communication resources required to receive camera frames.

The startup sequence performs the following operations:

1. Read the communication configuration.
2. Create the ZeroMQ context.
3. Create the SUB socket.
4. Subscribe to the camera topic.
5. Connect to the publisher.
6. Begin listening for incoming frames.

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
Create SUB Socket
      │
      ▼
Subscribe Topic
      │
      ▼
Connect Publisher
      │
      ▼
Wait for Camera Frames
```

---

## 2.1 Reading the Configuration

The Camera Worker first reads the publisher endpoint from the application configuration.

```cpp
const QString host =
    ConfigReader::instance().value(
        "ZMQ",
        "Host",
        "127.0.0.1");

const QString port =
    ConfigReader::instance().value(
        "ZMQ",
        "PubPort",
        "5558");
```

Example configuration:

```text
Host : 127.0.0.1
Port : 5558
```

The endpoint becomes:

```text
tcp://127.0.0.1:5558
```

---

## 2.2 Creating the ZeroMQ Context

Before creating the communication socket, the Camera Worker creates a ZeroMQ context.

```cpp
m_context = zmq_ctx_new();
```

The ZeroMQ context manages all sockets created by this worker and provides the communication environment required for message exchange.

---

## 2.3 Creating the Subscriber Socket

After creating the context, the Camera Worker creates a ZeroMQ SUB socket.

```cpp
m_socket = zmq_socket(
    m_context,
    ZMQ_SUB);
```

The SUB socket is responsible for receiving camera frames published by the Software Services.

Unlike a DEALER socket, the SUB socket does not send registration messages or commands. It only receives messages that match the subscribed topics.

Communication at this stage is shown below.

```text
Software Services
        │
        ▼
UI_CAMERA Publisher
        │
        ▼
 ZeroMQ PUB Socket
        │
        ▼
 ZeroMQ SUB Socket
        │
        ▼
 Camera Worker
```

At this point, the Camera Worker is ready to subscribe to camera topics and receive incoming image frames.
