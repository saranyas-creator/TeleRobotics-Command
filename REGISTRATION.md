### 🖥️ Registration Window: Full Command & Response Mapping

| S.NO | Button | UI Command (Sent to Robot) | Robot Response (Sent to UI) |
| :--- | :--- | :--- | :--- |
| 1 | **Start** | `{<br>"id": "cmd_id",<br>"source": "UI_CMD",<br>"target": "ROBOT_CMD",<br>"widget": "Registration",<br>"type": "COMMAND",<br>"payload": {"action": "start"}<br>}` | `{<br>"id": "cmd_id",<br>"source": "ROBOT_CMD",<br>"target": "UI_CMD",<br>"type": "RESPONSE",<br>"payload": {<br>"action": "start",<br>"success": true,<br>"message": "start executed successfully"<br>}<br>}` |
| 2 | **Stop** | `{<br>"id": "cmd_id",<br>"source": "UI_CMD",<br>"target": "ROBOT_CMD",<br>"widget": "Registration",<br>"type": "COMMAND",<br>"payload": {"action": "stop"}<br>}` | `{<br>"id": "cmd_id",<br>"source": "ROBOT_CMD",<br>"target": "UI_CMD",<br>"type": "RESPONSE",<br>"payload": {<br>"action": "stop",<br>"success": true,<br>"message": "stop executed successfully"<br>}<br>}` |
| 3 | **Home** | `{<br>"id": "cmd_id",<br>"source": "UI_CMD",<br>"target": "ROBOT_CMD",<br>"widget": "Registration",<br>"type": "COMMAND",<br>"payload": {"action": "home"}<br>}` | `{<br>"id": "cmd_id",<br>"source": "ROBOT_CMD",<br>"target": "UI_CMD",<br>"type": "RESPONSE",<br>"payload": {<br>"action": "home",<br>"success": true,<br>"message": "home executed successfully"<br>}<br>}` |
| 4 | **Reset** | `{<br>"id": "cmd_id",<br>"source": "UI_CMD",<br>"target": "ROBOT_CMD",<br>"widget": "System",<br>"type": "COMMAND",<br>"payload": {"action": "reset"}<br>}` | `{<br>"id": "cmd_id",<br>"source": "ROBOT_CMD",<br>"target": "UI_CMD",<br>"type": "RESPONSE",<br>"payload": {<br>"action": "reset",<br>"success": true,<br>"message": "RESET_DONE"<br>}<br>}` |

---

> [!TIP]
> **Pro Tip:** In the table above, the `<br>` tags are used to force the JSON onto new lines so the table doesn't grow infinitely wide. On your GitHub Pages site, this will appear as a clean, vertical code block inside the cell.
