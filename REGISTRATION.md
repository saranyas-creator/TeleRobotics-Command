# Mandatory Registration

The robot software must open the port and register itself before sending any other commands.

## 🔄 The Handshake Flow

### 1. Register Message (Robot -> Operator)
The robot sends this JSON object to identify itself.

| Header 1 | Header 2 | Header 3 |        |        | 
| -------- | -------- | -------- |--------|--------|
| Start    |          |          |        |        |
| STop     |          |          |        |        |

> [!IMPORTANT]
> This must be the first message sent after the connection is established.

```json
{
    "id": "REG_ROBOT_CMD",
    "source": "ROBOT_CMD",
    "target": "ROUTER",
    "type": "REGISTER",
    "priority": 1,
    "payload": {
        "role": "ROBOT_CMD"
    }
}

