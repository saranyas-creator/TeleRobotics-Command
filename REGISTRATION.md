# 🤖 Registration & System Control

This page covers the initial handshake and the core system controls (Start, Stop, Home, Reset) for the **Registration Window**.

---

## 📡 Port Configuration
> [!IMPORTANT]
> The operator software (ROUTER) binds to the port; the robot (DEALER) must connect.

| Setting | Value |
| :--- | :--- |
| **Host** | `127.0.0.1` |
| **Port** | `5555` |
| **Protocol** | TCP/IP (ZeroMQ) |

---

## 🛠️ Button Command Reference
This table summarizes the actions available in the **Registration Window**.

| S.NO | Button Name | Action (Payload) | UI Behavior | Robot Response Expected |
| :---: | :--- | :--- | :--- | :--- |
| 1 | **Start** | `start` | Sends `COMMAND` | `start executed successfully` |
| 2 | **Stop** | `stop` | Sends `COMMAND` | `stop executed successfully` |
| 3 | **Home** | `home` | Sends `COMMAND` | `home executed successfully` |
| 4 | **Reset** | `reset` | Enabled on Error | `RESET_DONE` |

---

## 🔄 Reset Logic Flow
The Reset button has specific safety logic:
1. **Initial State:** Disabled.
2. **Error State:** If a watchdog reports an error, the affected subsystem turns **Red** and Reset is **Enabled**.
3. **Action:** Clicking Reset sends the command and **Disables** the button.
4. **Timeout:** If no response is received, the button **Re-enables** so the user can try again.

### Reset Command (UI -> Robot)
```json
{
    "id": "cmd_1772871779368",
    "source": "UI_CMD",
    "target": "ROBOT_CMD",
    "type": "COMMAND",
    "widget": "System",
    "priority": 1,
    "payload": {
        "action": "reset"
    }
}
