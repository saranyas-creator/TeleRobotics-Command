# Mandatory Registration

The robot software must open the port and register itself before sending any other commands.

## 🔄 The Handshake Flow

### 1. Register Message (Robot -> Operator)
The robot sends this JSON object to identify itself.
### Registration Window

| S.NO | ButtonName | Command | Response 1 | Response 2 | Response 3 |
| :--- | :--- | :--- | :--- | :--- | :--- |
| 1 | **Start** | `CMD_START` | Initializing | Ready | Running |
| 2 | **Stop** | `CMD_STOP` | Braking | Stopped | Idle |
| 3 | **Home** | `CMD_HOME` | Moving | Calibrating | At Home |
| 4 | **Reset** | `CMD_RESET` | Clearing | Rebooting | Ready |

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

