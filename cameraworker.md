# Camera Worker

## Overview

The **Camera Worker** is responsible for receiving decoded RGB image frames from the Software Services and forwarding them to the Qt application for display.

The worker inherits from **ZmqWorkerBase** and runs in its own worker thread managed by the **ZmqManager**. It communicates with the camera publisher using a **ZeroMQ SUB** socket. After subscribing to the required camera topics, the worker continuously receives image frames, extracts the camera track information, converts the received data into `QImage` objects, and forwards them to the Qt application.

Unlike the Command Worker or Watchdog Worker, the Camera Worker does not communicate directly with the Router Service. It subscribes to image frames published by the Camera Service after the WebRTC pipeline has decoded the incoming video stream.

### Responsibilities

- Connect to the Camera Publisher
- Subscribe to camera topics
- Receive RGB image frames
- Extract camera track information
- Validate received image frames
- Convert image data into `QImage`
- Forward image frames to the Qt application

---

# Architecture

The Camera Worker acts as the communication interface between the Camera Publisher and the Qt application.

```text
                Qt Application
                       │
        ┌──────────────┴──────────────┐
        │                             │
        ▼                             ▼
   ZmqManager                  Camera Widget
        │                             ▲
        ▼                             │
     Camera Worker ───────────────────┘
```

Component responsibilities:

- **ZmqManager**
  - Creates and manages the Camera Worker.
  - Starts and stops the worker thread during the application lifecycle.

- **Camera Worker**
  - Handles all camera communication.
  - Receives image frames from the Camera Publisher.
  - Converts the received image data into `QImage`.
  - Emits image frames to the Qt application.

- **Camera Widget**
  - Receives image frames emitted by the Camera Worker.
  - Displays the latest camera frame in the user interface.

---

# Communication Flow

The Camera Worker receives decoded RGB image frames published by the Camera Service.

```text
Camera Service
       │
       ▼
 ZeroMQ PUB Socket
       │
       ▼
 ZeroMQ SUB Socket
       │
       ▼
 Camera Worker
       │
       ▼
 emit newFrame()
       │
       ▼
 Camera Widget
```

The communication sequence is as follows:

1. The Camera Service publishes decoded RGB image frames.
2. The Camera Worker subscribes to the required camera topic.
3. The Camera Worker receives the published frame.
4. The received frame is converted into a `QImage`.
5. The processed frame is emitted to the Qt application.
6. The Camera Widget displays the latest image frame.

The Camera Worker is responsible only for receiving and processing image frames. Image rendering is handled by the Qt application.

---

# 1. Worker Initialization

During application startup, the **ZmqManager** creates the Camera Worker and starts its worker thread.

The initialization sequence consists of:

1. Reading the communication configuration.
2. Creating the ZeroMQ context.
3. Creating the SUB socket.
4. Connecting to the Camera Publisher.
5. Subscribing to the required camera topics.
6. Waiting for incoming image frames.

```text
Create Worker
      │
      ▼
Read Configuration
      │
      ▼
Create ZeroMQ Context
      │
      ▼
Create SUB Socket
      │
      ▼
Connect to Publisher
      │
      ▼
Subscribe to Camera Topics
      │
      ▼
Wait for Image Frames
```

---

## 1.1 Creating the Worker

The Camera Worker is created by the **ZmqManager** during application startup.

```cpp
CameraWorker::CameraWorker(QObject *parent)
    : ZmqWorkerBase(parent)
{
}
```

Since the worker inherits from **ZmqWorkerBase**, it automatically receives the common worker lifecycle interface shared by all communication workers.

---

## 1.2 Reading the Configuration

The worker reads the publisher endpoint from the application configuration.

```cpp
const QString host =
    ConfigReader::instance().value(
        "ZMQ",
        "Host",
        "127.0.0.1");

const QString port =
    ConfigReader::instance().value(
        "Camera",
        "PublisherPort",
        "6000");
```

Example configuration:

```text
Host : 127.0.0.1
Port : 6000
```

The endpoint becomes:

```text
tcp://127.0.0.1:6000
```

This endpoint is used to establish communication with the Camera Publisher.

---

## 1.3 Creating the SUB Socket

The Camera Worker creates a ZeroMQ context followed by a SUB socket.

```cpp
m_context = zmq_ctx_new();

m_socket = zmq_socket(
    m_context,
    ZMQ_SUB);
```

The SUB socket is used to receive published image frames from the Camera Service.

Unlike the DEALER socket used by the Command and Watchdog Workers, the SUB socket only receives published messages.

---

## 1.4 Connecting to the Camera Publisher

After creating the SUB socket, the worker establishes a connection with the Camera Publisher.

```cpp
zmq_connect(
    m_socket,
    endpoint.constData());
```

Communication flow:

```text
Camera Worker
       │
       ▼
 ZeroMQ SUB Socket
       │
       ▼
 Camera Publisher
```

Once the connection is established, the worker is ready to subscribe to camera topics.

---

## 1.5 Subscribing to Camera Topics

The Camera Worker subscribes to one or more camera topics to receive image frames.

Example:

```cpp
zmq_setsockopt(
    m_socket,
    ZMQ_SUBSCRIBE,
    topic,
    strlen(topic));
```

Typical topic format:

```text
camera.frame.<trackId>
```

Example:

```text
camera.frame.track_01
```

Only frames matching the subscribed topic are delivered to the Camera Worker.

---

## 1.6 Waiting for Image Frames

After subscribing to the required topics, the worker enters its receive loop.

```text
Connect to Publisher
        │
        ▼
Subscribe to Topics
        │
        ▼
Wait for Published Frames
```

The Camera Worker remains in this state until a new image frame is published by the Camera Service.

---

# 2. Receiving Camera Frames

After subscribing to the required camera topics, the Camera Worker continuously listens for published image frames.

Whenever the Camera Service publishes a new frame, the Camera Worker receives the message, extracts the topic and image payload, validates the received data, and prepares it for display.

Communication flow:

```text
Camera Service
       │
Publish Image Frame
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

## 2.1 Camera Message Structure

Each published camera message consists of two parts:

- **Topic**
- **RGB Image Payload**

```text
┌─────────────────────────────┬────────────────────┐
│ Topic                       │ RGB Image Payload  │
└─────────────────────────────┴────────────────────┘
```

Example:

```text
Topic:
camera.frame.track_01

Payload:
RGB Image Data
```

The topic identifies the camera stream, while the payload contains the decoded RGB image.

---

## 2.2 Receiving the Message

The Camera Worker continuously waits for incoming published messages.

```cpp
while (isRunning())
{
    ...
}
```

The worker receives both the topic and the image payload through the SUB socket.

Example:

```cpp
zmq_recv(...)
```

Workflow:

```text
Publisher
     │
     ▼
Receive Topic
     │
     ▼
Receive Payload
```

Each published frame is processed independently.

---

## 2.3 Extracting the Topic

The first part of every received message is the topic.

Example:

```text
camera.frame.track_01
```

The worker extracts this topic before processing the image payload.

The topic uniquely identifies the camera stream that generated the image frame.

---

## 2.4 Extracting the Track ID

Each topic contains a unique camera track identifier.

Example:

```text
camera.frame.track_01
                 │
                 ▼
             track_01
```

The extracted Track ID allows the Qt application to associate the received frame with the correct camera view.

This enables the application to display multiple camera streams simultaneously.

---

## 2.5 Extracting the RGB Payload

After processing the topic, the worker extracts the RGB image payload.

```text
Topic
     │
     ▼
RGB Image Payload
```

The payload contains the decoded image generated by the Camera Service.

Unlike compressed video formats such as H264, the payload already contains RGB pixel data and is therefore ready for image creation.

---

# 3. Processing Camera Frames

Once the image payload has been extracted, the Camera Worker prepares it for display.

---

## 3.1 Validating the Received Frame

Before creating an image, the worker verifies that the received payload is valid.

Typical validation includes:

- Payload is not empty
- Image dimensions are valid
- Image buffer size matches the expected resolution

Invalid frames are discarded.

This prevents corrupted or incomplete image data from being displayed.

---

## 3.2 Creating the QImage

After validation, the RGB payload is converted into a Qt `QImage`.

Example:

```cpp
QImage image(...);
```

Communication flow:

```text
RGB Image Data
       │
       ▼
Create QImage
```

The resulting `QImage` represents the latest frame received from the camera stream.

---

## 3.3 Image Format

The Camera Worker processes decoded RGB image data.

Typical image format:

```text
RGB888
```

Each pixel consists of:

```text
Red
Green
Blue
```

Since the image has already been decoded by the Camera Service, no additional video decoding is required inside the Camera Worker.

---

# 4. Forwarding Frames to the Qt Application

After creating the `QImage`, the Camera Worker forwards the processed image to the Qt application.

The image is emitted through a Qt signal together with its corresponding Track ID.

```cpp
emit newFrame(trackId, image);
```

The emitted information contains:

- Camera Track ID
- Decoded RGB Image (`QImage`)

Example:

```text
Track ID : track_01

QImage
┌─────────────────────────┐
│                         │
│     RGB Image Frame     │
│                         │
└─────────────────────────┘
```

Communication flow:

```text
Published Frame
        │
        ▼
Extract Track ID
        │
        ▼
Create QImage
        │
        ▼
emit newFrame(trackId, image)
        │
        ▼
Qt Application
```

The Qt application receives the image and updates the corresponding camera view.

The Camera Worker is responsible only for receiving and processing image frames. Image rendering is handled by the Qt application.

---

## 4.1 Displaying Multiple Camera Streams

Each published frame contains a unique Track ID.

Example:

```text
camera.frame.track_01
camera.frame.track_02
camera.frame.track_03
```

The Track ID allows the Qt application to identify the source of each image frame and update the correct camera widget.

Example:

```text
track_01 ─────────► Camera View 1

track_02 ─────────► Camera View 2

track_03 ─────────► Camera View 3
```

This enables multiple camera streams to be displayed simultaneously.

---

# 5. Overall Workflow

The complete execution flow of the Camera Worker is shown below.

```text
Create Camera Worker
        │
        ▼
Read Configuration
        │
        ▼
Create ZeroMQ Context
        │
        ▼
Create SUB Socket
        │
        ▼
Connect to Camera Publisher
        │
        ▼
Subscribe to Camera Topics
        │
        ▼
Wait for Published Frames
        │
        ▼
Receive Topic
        │
        ▼
Extract Track ID
        │
        ▼
Receive RGB Payload
        │
        ▼
Validate Image
        │
        ▼
Create QImage
        │
        ▼
emit newFrame()
        │
        ▼
Qt Camera Widget
        │
        ▼
Display Image
```

---

# Summary

The Camera Worker provides the communication interface for receiving decoded camera frames from the Camera Service.

Its primary responsibilities include:

- Connecting to the Camera Publisher.
- Subscribing to camera topics.
- Receiving published image frames.
- Extracting the Track ID.
- Validating the received image.
- Converting the RGB payload into a `QImage`.
- Forwarding the processed image to the Qt application.

The Camera Worker is responsible for communication and image processing only. Displaying the received image is handled by the Qt application, allowing the communication layer and user interface to remain independent.
