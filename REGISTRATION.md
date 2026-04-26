### 🖥️ Registration Window: Full Command & Response Mapping

### 🖥️ Registration Window: Command & Response Mapping

<table>
  <tr>
    <th>S.NO</th>
    <th>Button</th>
    <th>UI Command (Sent to Robot)</th>
    <th>Robot Response (Sent to UI)</th>
  </tr>
  <tr>
    <td>1</td>
    <td><b>Start</b></td>
    <td>
      <pre><code>{
  "id": "&lt;cmd_id&gt;",
  "source": "UI_CMD",
  "target": "ROBOT_CMD",
  "widget": "Registration",
  "type": "COMMAND",
  "payload": {
    "action": "start"
  }
}</code></pre>
    </td>
    <td>
      <pre><code>{
  "id": "&lt;cmd_id&gt;",
  "source": "ROBOT_CMD",
  "target": "UI_CMD",
  "type": "RESPONSE",
  "payload": {
    "action": "start",
    "success": true,
    "message": "start executed successfully"
  }
}</code></pre>
    </td>
  </tr>
  <tr>
    <td>2</td>
    <td><b>Stop</b></td>
    <td>
      <pre><code>{
  "id": "&lt;cmd_id&gt;",
  "source": "UI_CMD",
  "target": "ROBOT_CMD",
  "widget": "Registration",
  "type": "COMMAND",
  "payload": {
    "action": "stop"
  }
}</code></pre>
    </td>
    <td>
      <pre><code>{
  "id": "&lt;cmd_id&gt;",
  "source": "ROBOT_CMD",
  "target": "UI_CMD",
  "type": "RESPONSE",
  "payload": {
    "action": "stop",
    "success": true,
    "message": "stop executed successfully"
  }
}</code></pre>
    </td>
  </tr>
  <tr>
    <td>3</td>
    <td><b>Home</b></td>
    <td>
      <pre><code>{
  "id": "&lt;cmd_id&gt;",
  "source": "UI_CMD",
  "target": "ROBOT_CMD",
  "widget": "Registration",
  "type": "COMMAND",
  "payload": {
    "action": "home"
  }
}</code></pre>
    </td>
    <td>
      <pre><code>{
  "id": "&lt;cmd_id&gt;",
  "source": "ROBOT_CMD",
  "target": "UI_CMD",
  "type": "RESPONSE",
  "payload": {
    "action": "home",
    "success": true,
    "message": "home executed successfully"
  }
}</code></pre>
    </td>
  </tr>
</table>
