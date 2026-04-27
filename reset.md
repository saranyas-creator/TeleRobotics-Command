# Registration Window

| S.NO | Button | Response 1<br>(UI To Robot) | Response 2<br>(Robot to UI) | Response 3<br>(Robot to UI) |
| :--- | :--- | :--- | :--- | :--- |
| 1 | **Reset** | <pre>{<br>  "id": "cmd_1772871779368",<br>  "source": "UI_CMD",<br>  "target": "ROBOT_CMD",<br>  "type": "COMMAND",<br>  "widget": "System",<br>  "priority": 1,<br>  "payload": {<br>    "action": "reset"<br>  }<br>}</pre> | <pre>{<br>  "id": "cmd_1772871779368",<br>  "source": "ROBOT_CMD",<br>  "target": "UI_CMD",<br>  "type": "RESPONSE",<br>  "priority": 1,<br>  "payload": {<br>    "action": "reset",<br>    "success": true,<br>    "message": "RESET_RECEIVED"<br>  }<br>}</pre> | <pre>{<br>  "id": "cmd_1772871779368",<br>  "source": "ROBOT_CMD",<br>  "target": "UI_CMD",<br>  "type": "RESPONSE",<br>  "priority": 1,<br>  "payload": {<br>    "action": "reset",<br>    "success": true,<br>    "message": "RESET_DONE"<br>  }<br>}</pre> |
