# WebRTC Channel

## 1. Overview

The WebRTC Channel is responsible for video streaming between the Robot and UI.

The channel uses:

* ROUTER-DEALER for signaling communication
* WebRTC for peer-to-peer video transport
* GStreamer for video decoding and frame processing
* ZeroMQ PUB-SUB for local frame distribution within the UI

The Router Service is used only during session establishment. Once the WebRTC connection is established, video data flows directly between the Robot and UI without passing through the Router.

---

## 2. Architecture

```text
                         ROUTER
                            │
                            │ Signaling
                            ▼

UI_CAMERA  ←────────────→  ROBOT_CAMERA
               WebRTC
                    │
                    ▼
             GStreamer
                    │
                    ▼
               ZMQ PUB
                    │
                    ▼
               ZMQ SUB
                    │
                    ▼
                Qt UI
```

| Component    | Responsibility                       |
| ------------ | ------------------------------------ |
| ROUTER       | Signaling communication              |
| UI_CAMERA    | Receives and processes video streams |
| ROBOT_CAMERA | Captures and streams video           |
| WebRTC       | Peer-to-peer video transport         |
| GStreamer    | Video decoding and frame processing  |
| PUB-SUB      | Local frame distribution             |
| Qt UI        | Video display                        |

---

## 3. Workflow

The following workflow describes the complete lifecycle of a video stream from session establishment to display in the Qt user interface.

```text
Registration
      │
      ▼
WebRTC Request
      │
      ▼
SDP Offer + ICE
      │
      ▼
SDP Answer + ICE
      │
      ▼
Peer Connection
      │
      ▼
Video Streaming
      │
      ▼
GStreamer Decoding
      │
      ▼
PUB-SUB Distribution
      │
      ▼
Qt Display
```

---

## 4. Dealer Registration

The WebRTC Channel uses the ROUTER-DEALER pattern for signaling communication.

The signaling architecture contains one ROUTER and two DEALERS.

```text
            ROUTER
               │
      ┌────────┴────────┐
      │                 │
      ▼                 ▼

 UI_CAMERA       ROBOT_CAMERA
```

Before a WebRTC session can be established, both camera services must register with the Router Service.

### 4.1 UI_CAMERA Registration

```text
UI_CAMERA
     │
 REGISTER
     │
     ▼
   ROUTER
```

```json
{
    "type": "REGISTER",
    "source": "UI_CAMERA",
    "target": "ROUTER",
    "payload":
    {
        "role": "UI_CAMERA"
    }
}
```

The Router stores the dealer identity and returns a `REGISTER_ACK`.

---

### 4.2 ROBOT_CAMERA Registration

```text
ROBOT_CAMERA
      │
  REGISTER
      │
      ▼
   ROUTER
```

```json
{
    "type": "REGISTER",
    "source": "ROBOT_CAMERA",
    "target": "ROUTER",
    "payload":
    {
        "role": "ROBOT_CAMERA"
    }
}
```

The Router stores the dealer identity and returns a `REGISTER_ACK`.

After both dealers are registered, signaling communication can begin.

---

## 5. WebRTC Request

Once registration is complete, UI_CAMERA initiates a WebRTC session.

```text
UI_CAMERA
     │
     ▼
   ROUTER
     │
     ▼
ROBOT_CAMERA
```

```json
{
    "type": "WEBRTC_REQUEST",
    "source": "UI_CAMERA",
    "target": "ROBOT_CAMERA"
}
```

The Router forwards the request to ROBOT_CAMERA.

The request instructs ROBOT_CAMERA to create a WebRTC Offer.

---

## 6. SDP Offer + ICE

### 6.1 What is ICE?

ICE (Interactive Connectivity Establishment) is a WebRTC mechanism used to discover network paths between two peers.

Before a direct connection can be established, both peers must know:

* IP Address
* Port Number
* Transport Protocol

This information is represented as ICE Candidates.

Example:

```text
IP Address : 192.168.1.10
Port       : 5000
Protocol   : UDP
```

The current implementation uses Non-Trickle ICE.

ICE candidates are gathered automatically by WebRTC and embedded directly into the SDP before transmission.

---

### 6.2 SDP Offer Generation

After receiving the WebRTC Request, ROBOT_CAMERA creates a WebRTC Peer Connection.

WebRTC automatically:

1. Creates an SDP Offer
2. Gathers ICE Candidates
3. Embeds ICE Candidates into the SDP Offer

```text
ROBOT_CAMERA
      │
      ▼
Create Peer Connection
      │
      ▼
Generate SDP Offer
      │
      ▼
Gather ICE Candidates
      │
      ▼
Embed ICE into SDP
      │
      ▼
WEBRTC_OFFER
```

The Offer is forwarded through the Router.

```text
ROBOT_CAMERA
      │
      ▼
   ROUTER
      │
      ▼
  UI_CAMERA
```

Example:

```json
{
    "type": "WEBRTC_OFFER",
    "payload":
    {
        "session_id": "session_001",
        "sdp": "<offer_sdp>"
    }
}
```

---

## 7. SDP Answer + ICE

UI_CAMERA receives the SDP Offer and configures its local Peer Connection.

WebRTC automatically:

1. Creates an SDP Answer
2. Gathers ICE Candidates
3. Embeds ICE Candidates into the SDP Answer

```text
UI_CAMERA
      │
      ▼
Receive SDP Offer
      │
      ▼
Create SDP Answer
      │
      ▼
Gather ICE Candidates
      │
      ▼
Embed ICE into SDP
      │
      ▼
WEBRTC_ANSWER
```

The Answer is forwarded through the Router.

```text
UI_CAMERA
     │
     ▼
   ROUTER
     │
     ▼
ROBOT_CAMERA
```

Example:

```json
{
    "type": "WEBRTC_ANSWER",
    "payload":
    {
        "session_id": "session_001",
        "sdp": "<answer_sdp>"
    }
}
```

---

## 8. Peer Connection Establishment

After exchanging SDP information and ICE candidates, WebRTC establishes a direct peer-to-peer connection.

```text
UI_CAMERA  ←────────────→  ROBOT_CAMERA
                 WebRTC
```

At this stage:

* Signaling is complete
* Router participation ends
* Direct media transport begins

The Router Service is no longer involved in video streaming.

---

## 9. Video Streaming

Once the Peer Connection is established, ROBOT_CAMERA begins transmitting video.

```text
ROBOT_CAMERA
      │
      ▼
 H264 RTP Packets
      │
      ▼
  UI_CAMERA
```

The UI_CAMERA service receives incoming WebRTC tracks.

Each track creates a dedicated decoding pipeline.

---

## 10. GStreamer Decoding Pipeline

### 10.1 What is GStreamer?

GStreamer is a multimedia processing framework used for video decoding, encoding, conversion, and streaming.

In this project, WebRTC delivers:

```text
Compressed H264 RTP Packets
```

These packets cannot be displayed directly by the Qt application.

They must first be converted into:

```text
RGB Image Frames
```

GStreamer performs this conversion.

---

### 10.2 Why GStreamer is Required

Without GStreamer:

```text
WebRTC Packet
      │
      ▼
Qt Display
```

is not possible.

Instead:

```text
WebRTC Packet
      │
      ▼
GStreamer
      │
      ▼
RGB Frame
      │
      ▼
Qt Display
```

GStreamer acts as the decoding engine between WebRTC and Qt.

---

### 10.3 Pipeline Flow

For every incoming WebRTC track, a dedicated pipeline is created.

```text
WebRTC Packet
      │
      ▼
appsrc
      │
      ▼
rtph264depay
      │
      ▼
h264parse
      │
      ▼
openh264dec
      │
      ▼
videoconvert
      │
      ▼
videoscale
      │
      ▼
appsink
      │
      ▼
RGB Frame
```

### 10.4 Pipeline Components

| Component    | Purpose                                        |
| ------------ | ---------------------------------------------- |
| appsrc       | Entry point for incoming WebRTC packets        |
| rtph264depay | Removes RTP headers and extracts H264 video    |
| h264parse    | Parses and validates the H264 stream           |
| openh264dec  | Decodes compressed H264 video                  |
| videoconvert | Converts decoded frames into RGB format        |
| videoscale   | Resizes frames to the required resolution      |
| appsink      | Delivers decoded RGB frames to the application |

Output:

```text
RGB Frame
```

---

## 11. PUB-SUB Distribution

### 11.1 What is PUB-SUB?

PUB-SUB (Publisher-Subscriber) is a messaging pattern used to distribute data to multiple consumers.

In this pattern:

* Publisher sends data
* Subscribers receive data
* Publisher does not need to know who the subscribers are

```text
Publisher
    │
    ▼
 Topic
    │
 ┌──┼───┬─────┐
 ▼  ▼   ▼     ▼

SUB SUB SUB SUB
```

This architecture allows multiple components to consume the same video stream.

Examples:

* Video Display Widget
* Recording Service
* Image Processing Module
* Future Analytics Components

---

### 11.2 Publisher

UI_CAMERA acts as the Publisher.

```text
RGB Frame
      │
      ▼
UI_CAMERA
      │
      ▼
 ZMQ PUB
```

Topic format:

```text
camera.frame.<trackId>
```

Example:

```text
camera.frame.track_01
```

---

### 11.3 Subscriber

Qt UI components act as Subscribers.

```text
ZMQ SUB
    │
    ▼
Qt Camera Widgets
```

Subscription:

```text
camera.frame.
```

Subscribers receive frames from all active tracks.

---

## 12. Qt Display

After receiving a frame from the PUB-SUB channel:

```text
ZMQ SUB
     │
     ▼
 RGB Frame
     │
     ▼
  QImage
     │
     ▼
 Qt Display
```

The frame is converted into a QImage and displayed in the application.

---

## 13. Architecture Summary

```text
Dealer Registration
        │
        ▼
WebRTC Request
        │
        ▼
SDP Offer + ICE
        │
        ▼
SDP Answer + ICE
        │
        ▼
Peer Connection
        │
        ▼
Video Streaming
        │
        ▼
GStreamer Decoding
        │
        ▼
PUB-SUB Distribution
        │
        ▼
Qt Display
```

The WebRTC Channel uses the Router-Dealer Channel only for signaling communication. Once SDP negotiation is completed, video data is streamed directly between UI_CAMERA and ROBOT_CAMERA through a WebRTC Peer Connection.

Incoming H264 RTP packets are decoded using GStreamer and converted into RGB image frames. These frames are then distributed through a ZeroMQ PUB-SUB channel and displayed by Qt UI components.
