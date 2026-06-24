# WebRTC Channel

## 1. Overview

The WebRTC Channel is responsible for video streaming between the Robot and UI.

The channel uses:

* ROUTER-DEALER for signaling communication
* WebRTC for peer-to-peer video transport
* ZeroMQ PUB-SUB for local frame distribution within the UI

The Router Service is used only during session establishment. Once the WebRTC connection is established, video data flows directly between the Robot and UI without passing through the Router.

---

## 2. Components

The WebRTC Channel consists of three services:

```text
UI_CAMERA
ROBOT_CAMERA
ROUTER
```

| Component    | Description                                             |
| ------------ | ------------------------------------------------------- |
| UI_CAMERA    | Receives video streams and distributes frames to the UI |
| ROBOT_CAMERA | Captures and streams video from the robot side          |
| ROUTER       | Handles signaling message exchange between UI and Robot |

---

## 3. Session Establishment

Before video streaming begins, a WebRTC session must be established.

### 3.1 Dealer Registration

The UI_CAMERA service first registers itself with the Router Service.

```text
UI_CAMERA
     │
     ▼
   ROUTER
```

**Registration Message**

```json
{
    "id": "msg_001",
    "type": "REGISTER",
    "source": "UI_CAMERA",
    "target": "ROUTER",
    "payload":
    {
        "role": "UI_CAMERA"
    }
}
```

After successful registration, the Router sends a `REGISTER_ACK`.

---

### 3.2 WebRTC Request

Once registration is complete, UI_CAMERA requests a WebRTC session.

```text
UI_CAMERA
     │
     ▼
   ROUTER
     │
     ▼
ROBOT_CAMERA
```

**Request Message**

```json
{
    "id": "msg_001",
    "type": "WEBRTC_REQUEST",
    "source": "UI_CAMERA",
    "target": "ROBOT_CAMERA"
}
```

The Router forwards the request to ROBOT_CAMERA.

---

### 3.3 SDP Offer

After receiving the request, ROBOT_CAMERA creates a WebRTC Offer.

```text
ROBOT_CAMERA
      │
      ▼
   ROUTER
      │
      ▼
  UI_CAMERA
```

**Offer Message**

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

### 3.4 SDP Answer

UI_CAMERA receives the offer and generates an SDP Answer.

```text
UI_CAMERA
     │
     ▼
   ROUTER
     │
     ▼
ROBOT_CAMERA
```

**Answer Message**

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

### 3.5 Peer Connection Established

After the SDP negotiation is completed, a direct WebRTC connection is established.

```text
UI_CAMERA  ←────────────→  ROBOT_CAMERA
                 WebRTC
```

At this point, the Router Service is no longer involved in media transport.

---

## 4. Video Streaming

Once the WebRTC connection is established, video packets are streamed directly from ROBOT_CAMERA to UI_CAMERA.

```text
ROBOT_CAMERA
      │
      ▼
 WebRTC Track
      │
      ▼
  UI_CAMERA
```

The UI_CAMERA service receives video tracks and creates a dedicated processing pipeline for each track.

---

## 5. Frame Processing

Incoming video packets are processed using GStreamer.

```text
WebRTC Track
      │
      ▼
GStreamer Pipeline
      │
      ▼
RGB Frames
```

The processing pipeline performs:

* RTP Depacketization
* H264 Parsing
* H264 Decoding
* Video Conversion
* Frame Scaling
* RGB Frame Generation

---

## 6. Frame Distribution

After decoding, frames are published locally using ZeroMQ PUB-SUB.

### 6.1 Publisher

UI_CAMERA acts as the publisher.

```text
Decoded Frame
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

### 6.2 Subscriber

Qt UI components subscribe to camera topics.

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

This allows the UI to receive frames from all active tracks.

---

## 7. Complete Communication Flow

```text
Phase 1 : Registration

UI_CAMERA
     │
     ▼
   ROUTER


Phase 2 : Signaling

UI_CAMERA
     │
     ▼
   ROUTER
     │
     ▼
ROBOT_CAMERA

SDP Offer / SDP Answer Exchange


Phase 3 : Video Streaming

UI_CAMERA  ←────────────→  ROBOT_CAMERA
                 WebRTC


Phase 4 : Frame Distribution

WebRTC
    │
    ▼
UI_CAMERA
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

---

## 8. Architecture Summary

The WebRTC Channel uses the Router-Dealer Channel only for signaling communication, including:

* Registration
* Session initiation
* SDP Offer exchange
* SDP Answer exchange

Once negotiation is complete, video data is streamed directly between UI_CAMERA and ROBOT_CAMERA through a WebRTC Peer Connection.

Decoded frames are then distributed locally to Qt UI components through a ZeroMQ PUB-SUB channel for display.
