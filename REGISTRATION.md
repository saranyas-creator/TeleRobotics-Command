### 🖥️ Registration Window: Clean Command Mapping

| S.NO | Button | UI Command (Sent to Robot) | Robot Response (Sent to UI) |
| :--- | :--- | :--- | :--- |
| 1 | **Start** | `{ "id": "cmd_id", "source": "UI_CMD", "target": "ROBOT_CMD", "widget": "Registration", "type": "COMMAND", "payload": { "action": "start" } }` | `{ "id": "cmd_id", "source": "ROBOT_CMD", "target": "UI_CMD", "type": "RESPONSE", "payload": { "action": "start", "success": true, "message": "success" } }` |
| 2 | **Stop** | `{ "id": "cmd_id", "source": "UI_CMD", "target": "ROBOT_CMD", "widget": "Registration", "type": "COMMAND", "payload": { "action": "stop" } }` | `{ "id": "cmd_id", "source": "ROBOT_CMD", "target": "UI_CMD", "type": "RESPONSE", "payload": { "action": "stop", "success": true, "message": "success" } }` |
| 3 | **Home** | `{ "id": "cmd_id", "source": "UI_CMD", "target": "ROBOT_CMD", "widget": "Registration", "type": "COMMAND", "payload": { "action": "home" } }` | `{ "id": "cmd_id", "source": "ROBOT_CMD", "target": "UI_CMD", "type": "RESPONSE", "payload": { "action": "home", "success": true, "message": "success" } }` |
| 4 | **Reset** | `{ "id": "cmd_id", "source": "UI_CMD", "target": "ROBOT_CMD", "widget": "System", "type": "COMMAND", "payload": { "action": "reset" } }` | `{ "id": "cmd_id", "source": "ROBOT_CMD", "target": "UI_CMD", "type": "RESPONSE", "payload": { "action": "reset", "success": true, "message": "RESET_DONE" } }` |
