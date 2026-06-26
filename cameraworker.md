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
---

# 3. Connecting to the Publisher

After creating the SUB socket, the Camera Worker connects to the camera publisher exposed by the Software Services.

```cpp
if (zmq_connect(m_socket, endpoint.constData()) != 0)
{
    emitError("Camera worker zmq_connect failed");
    stop();
    return;
}
```

The connection endpoint is configured as:

```text
tcp://<Host>:<PubPort>
```

For example,

```text
tcp://127.0.0.1:5558
```

Communication flow:

```text
Software Services
        │
        ▼
UI_CAMERA Publisher
        │
tcp://127.0.0.1:5558
        │
        ▼
Camera Worker
```

Once the connection is established, the Camera Worker is ready to subscribe to camera topics.

---

# 4. Topic Subscription

The Camera Worker subscribes to the base camera topic.

```cpp
zmq_setsockopt(
    m_socket,
    ZMQ_SUBSCRIBE,
    kTopicBase,
    strlen(kTopicBase));
```

The subscribed topic is

```text
camera.frame.
```

Each published frame contains a topic in the following format.

```text
camera.frame.<trackId>
```

Example:

```text
camera.frame.track_01

camera.frame.track_02

camera.frame.track_03
```

By subscribing to the base topic `camera.frame.`, the Camera Worker automatically receives frames from all active camera tracks without subscribing to each track individually.

---

# 5. Preparing for Frame Reception

After connecting and subscribing, the Camera Worker prepares to receive incoming frames asynchronously.

The worker configures a receive timeout for the SUB socket.

```cpp
int timeout = kRecvTimeoutMs;

zmq_setsockopt(
    m_socket,
    ZMQ_RCVTIMEO,
    &timeout,
    sizeof(timeout));
```

The worker is then marked as running.

```cpp
setRunning(true);
```

Next, the ZeroMQ socket file descriptor is obtained.

```cpp
int fd;

size_t fd_len = sizeof(fd);

zmq_getsockopt(
    m_socket,
    ZMQ_FD,
    &fd,
    &fd_len);
```

This file descriptor is used to monitor incoming data without blocking the Qt event loop.

---

# 6. Asynchronous Frame Reception

The Camera Worker creates a `QSocketNotifier` to monitor the ZeroMQ socket.

```cpp
m_notifier =
    new QSocketNotifier(
        fd,
        QSocketNotifier::Read,
        this);

connect(
    m_notifier,
    &QSocketNotifier::activated,
    this,
    &ZMQCameraWorker::handleReadyRead);
```

The notifier continuously watches the socket.

Whenever a new frame arrives, Qt automatically invokes the `handleReadyRead()` function.

Communication flow:

```text
ZeroMQ Publisher
        │
        ▼
 ZeroMQ SUB Socket
        │
        ▼
 QSocketNotifier
        │
        ▼
handleReadyRead()
```

Using `QSocketNotifier` allows the worker to receive camera frames asynchronously without polling or blocking the application.

---

# 7. Receiving Camera Frames

The `handleReadyRead()` function is responsible for receiving incoming camera messages.

```cpp
void ZMQCameraWorker::handleReadyRead()
```

Whenever the SUB socket becomes readable, this function executes.

Workflow:

```text
Socket Ready
      │
      ▼
Receive Message
      │
      ▼
Extract Envelope
      │
      ▼
Process Envelope
```

Inside the function, the worker continuously reads all available messages.

```cpp
while (true)
{
    zmq_msg_t msg;

    zmq_msg_init(&msg);

    int n =
        zmq_msg_recv(
            &msg,
            m_socket,
            ZMQ_DONTWAIT);

    ...
}
```

Each received message is stored as a ZeroMQ message object.

---

# 8. Reading the Frame Envelope

After a message is successfully received, the ZeroMQ message is converted into a `QByteArray`.

```cpp
QByteArray data(
    static_cast<char*>(zmq_msg_data(&msg)),
    zmq_msg_size(&msg));
```

The ZeroMQ message is then released.

```cpp
zmq_msg_close(&msg);
```

Finally, the received frame envelope is forwarded to the frame parser.

```cpp
handleFrameEnvelope(data);
```

Communication flow:

```text
ZeroMQ Message
       │
       ▼
QByteArray
       │
       ▼
handleFrameEnvelope()
```

At this stage, the Camera Worker has successfully received a complete camera message from the publisher.

The next stage is to extract the topic, track identifier, and RGB image data from the received frame envelope.
---

# 9. Frame Processing

After receiving a complete ZeroMQ message, the Camera Worker forwards the message to the `handleFrameEnvelope()` function for processing.

```cpp
handleFrameEnvelope(data);
```

The purpose of this function is to:

- Extract the topic
- Identify the video track
- Extract the RGB image payload
- Validate the received frame
- Convert the image into a `QImage`
- Emit the frame to the Qt application

The overall processing workflow is shown below.

```text
Received Message
        │
        ▼
Extract Topic
        │
        ▼
Extract Track ID
        │
        ▼
Extract RGB Payload
        │
        ▼
Validate Frame
        │
        ▼
Create QImage
        │
        ▼
Emit Frame
```

---

# 9.1 Verifying the Camera Topic

The Camera Worker first verifies that the received message belongs to the subscribed camera topic.

```cpp
const QByteArray topicPrefix(kTopicBase);

if (!envelope.startsWith(topicPrefix))
{
    return;
}
```

The expected topic format is

```text
camera.frame.<trackId>
```

Only messages beginning with this topic prefix are processed further.

Messages belonging to other topics are ignored.

---

# 9.2 Extracting the Track Identifier

Each published frame contains a unique track identifier.

The Camera Worker extracts this identifier from the received topic.

```cpp
QString trackId =
    QString::fromUtf8(
        envelope.mid(
            topicPrefix.size(),
            spaceIdx - topicPrefix.size()));
```

Example:

```text
Topic

camera.frame.track_01
```

Extracted Track ID

```text
track_01
```

The track identifier allows the Qt application to distinguish between multiple active camera streams.

---

# 9.3 Extracting the Image Payload

After extracting the topic, the remaining message contains the RGB image data.

```cpp
const QByteArray payload =
    envelope.mid(spaceIdx + 1);
```

Communication flow:

```text
ZeroMQ Message
      │
      ▼
Topic + RGB Payload
      │
      ├────────► Topic
      │
      └────────► RGB Image
```

The payload contains the raw RGB pixel values received from the Software Services.

---

# 10. Frame Validation

Before creating the image, the Camera Worker verifies that the received payload size matches the expected image dimensions.

```cpp
int expectedWidth  = 640;
int expectedHeight = 480;

int expectedBytes =
    expectedWidth *
    expectedHeight *
    3;
```

For an RGB image,

```text
Width  = 640 pixels

Height = 480 pixels

Channels = 3 (RGB)

Total Bytes

640 × 480 × 3

=

921600 Bytes
```

The payload is validated as follows.

```cpp
if (payload.size() != expectedBytes)
{
    return;
}
```

Only complete image frames are processed further.

Invalid or incomplete frames are discarded.

---

# 11. QImage Generation

Once the payload has been validated, the Camera Worker creates a `QImage`.

```cpp
QImage frame(
    reinterpret_cast<const uchar*>(payload.constData()),
    expectedWidth,
    expectedHeight,
    expectedWidth * 3,
    QImage::Format_RGB888);
```

The image is created using:

| Parameter | Description |
|-----------|-------------|
| Width | 640 pixels |
| Height | 480 pixels |
| Bytes Per Line | Width × 3 |
| Format | RGB888 |

Communication flow:

```text
RGB Payload
      │
      ▼
QImage
```

If the image creation fails,

```cpp
if (frame.isNull())
{
    return;
}
```

the frame is discarded.

---

# 12. Delivering Frames to the Qt Application

After successfully creating the `QImage`, the Camera Worker emits the image to the Qt application.

```cpp
emit newFrame(
    trackId,
    frame.copy());
```

The emitted signal contains:

- Track Identifier
- RGB Image

Communication flow:

```text
Camera Worker
       │
       ▼
newFrame(trackId, QImage)
       │
       ▼
Qt Camera Widget
       │
       ▼
Display Image
```

The Qt Camera Widget receives the signal and updates the displayed camera frame.

---

# 13. Overall Workflow

The complete execution flow of the Camera Worker is shown below.

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
       │
       ▼
Receive ZeroMQ Message
       │
       ▼
Extract Topic
       │
       ▼
Extract Track ID
       │
       ▼
Extract RGB Payload
       │
       ▼
Validate Payload
       │
       ▼
Create QImage
       │
       ▼
Emit newFrame()
       │
       ▼
Qt Camera Widget
       │
       ▼
Display Camera Frame
```

---

# Summary

The Camera Worker provides the communication bridge between the Software Services and the Qt application.

Its responsibilities include:

- Connecting to the camera publisher
- Subscribing to camera topics
- Receiving RGB image frames
- Extracting the track identifier
- Validating the received image
- Converting the image into a `QImage`
- Delivering the image to the Qt user interface

By separating camera reception into its own worker thread, image acquisition remains asynchronous and independent of the main Qt user interface, ensuring smooth and responsive video display.
At this point, the Camera Worker is ready to subscribe to camera topics and receive incoming image frames.

