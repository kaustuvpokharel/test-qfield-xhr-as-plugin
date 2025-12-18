import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Dialogs
import org.qfield

Item {
  id: root

  // logging
  ListModel { id: logModel }

  function ts() {
    const d = new Date()
    const pad = (n) => (n < 10 ? "0" : "") + n
    return pad(d.getHours()) + ":" + pad(d.getMinutes()) + ":" + pad(d.getSeconds())
  }

  function log(msg) {
    logModel.append({ t: ts(), m: String(msg) })
    console.log("[XHR Tester]", msg)
  }

  function readyStateName(st) {
    switch (st) {
      case 0: return "Unsent"
      case 1: return "Opened"
      case 2: return "HeadersReceived"
      case 3: return "Loading"
      case 4: return "Done"
      default: return "?"
    }
  }

  // ------------ XHR instance (resettable) ------------
  property var xhr: null

  Component {
    id: xhrComponent

    XmlHttpRequest {
      // properties backed by QJSValue in C++
      onreadystatechange: function() {
        root.log("onreadystatechange: state=" + root.readyStateName(readyState) + " (" + readyState + "), status=" + status)
      }
      ondownloadprogress: function(received, total) {
        root.log("ondownloadprogress: " + received + " / " + total)
      }
      onuploadprogress: function(sent, total) {
        root.log("onuploadprogress: " + sent + " / " + total)
      }
      onredirected: function(url) {
        root.log("onredirected: " + url)
      }
      ontimeout: function() {
        root.log("ontimeout")
      }
      onaborted: function() {
        root.log("onaborted")
      }
      onerror: function(code, message) {
        root.log("onerror: code=" + code + " message=" + message)
      }
    }
  }

  function ensureXhr() {
    if (xhr) return
    xhr = xhrComponent.createObject(root)
    root.log("XmlHttpRequest created")
  }

  function resetXhr() {
    if (xhr) {
      try { xhr.abort() } catch(e) {}
      xhr.destroy()
      xhr = null
    }
    ensureXhr()
  }

  // ------------ tiny dark UI helpers ------------
  readonly property color bg: "#121212"
  readonly property color card: "#1a1a1a"
  readonly property color field: "#0f0f0f"
  readonly property color border: "#2b2b2b"
  readonly property color fg: "#f3f3f3"
  readonly property color muted: "#b8b8b8"
  readonly property color accent: "#7CFC00" // “debug green”
  readonly property int r: 10

  component Card : Frame {
    Layout.fillWidth: true
    padding: 12
    background: Rectangle {
      radius: root.r
      color: root.card
      border.color: root.border
      border.width: 1
    }
  }

  component H2 : Label {
    color: root.fg
    font.pixelSize: 16
    font.bold: true
    elide: Label.ElideRight
  }

  component H3 : Label {
    color: root.fg
    font.pixelSize: 13
    font.bold: true
    elide: Label.ElideRight
  }

  component HelpText : Label {
    Layout.fillWidth: true
    color: root.muted
    wrapMode: Label.Wrap
    font.pixelSize: 12
  }

  component DarkButton : Button {
    Layout.preferredHeight: 40
    contentItem: Label {
      text: parent.text
      color: root.fg
      font.pixelSize: 13
      horizontalAlignment: Text.AlignHCenter
      verticalAlignment: Text.AlignVCenter
      elide: Label.ElideRight
    }
    background: Rectangle {
      radius: 999
      color: parent.down ? "#2b2b2b" : "#222222"
      border.color: parent.hovered ? root.accent : root.border
      border.width: 1
    }
  }

  component DarkTextField : TextField {
    Layout.preferredHeight: 40
    color: root.fg
    placeholderTextColor: "#7c7c7c"
    selectByMouse: true
    background: Rectangle {
      radius: 8
      color: root.field
      border.color: parent.activeFocus ? root.accent : root.border
      border.width: 1
    }
  }

  component DarkTextArea : TextArea {
    color: root.fg
    placeholderTextColor: "#7c7c7c"
    selectByMouse: true
    wrapMode: TextArea.Wrap
    background: Rectangle {
      radius: 8
      color: root.field
      border.color: parent.activeFocus ? root.accent : root.border
      border.width: 1
    }
  }

  component DarkComboBox : ComboBox {
    Layout.preferredHeight: 40
    contentItem: Label {
      text: parent.displayText
      color: root.fg
      verticalAlignment: Text.AlignVCenter
      leftPadding: 10
      elide: Label.ElideRight
    }
    background: Rectangle {
      radius: 8
      color: root.field
      border.color: parent.activeFocus ? root.accent : root.border
      border.width: 1
    }
    indicator: Canvas {
      width: 14; height: 14
      anchors.right: parent.right
      anchors.rightMargin: 10
      anchors.verticalCenter: parent.verticalCenter
      onPaint: {
        const ctx = getContext("2d")
        ctx.clearRect(0,0,width,height)
        ctx.beginPath()
        ctx.moveTo(2,4); ctx.lineTo(12,4); ctx.lineTo(7,10); ctx.closePath()
        ctx.fillStyle = root.fg
        ctx.fill()
      }
    }
    popup: Popup {
      y: parent.height + 4
      width: parent.width
      implicitHeight: Math.min(contentItem.implicitHeight + 8, 260)
      background: Rectangle {
        radius: 8
        color: root.card
        border.color: root.border
        border.width: 1
      }
      contentItem: ListView {
        clip: true
        model: parent.delegateModel
        currentIndex: parent.highlightedIndex
        delegate: ItemDelegate {
          width: ListView.view.width
          text: modelData
          contentItem: Label {
            text: parent.text
            color: root.fg
            elide: Label.ElideRight
          }
          background: Rectangle {
            color: parent.highlighted ? "#2a2a2a" : "transparent"
          }
        }
      }
    }
  }

  // ------------ UI entry button ------------
  Rectangle {
    id: toolbarButton
    width: 40; height: 40
    radius: 8
    color: "#2b2b2b"
    border.color: "#cfcfcf"
    border.width: 1

    Text {
      anchors.centerIn: parent
      text: "XHR"
      color: "white"
      font.bold: true
      font.pixelSize: 12
    }

    MouseArea {
      anchors.fill: parent
      onClicked: {
        ensureXhr()
        panel.open()
      }
    }
  }

  // main panel
  Popup {
    id: panel
    parent: iface.mainWindow().contentItem
    modal: true
    focus: true

    width: Math.min(parent.width * 0.96, 860)
    height: Math.min(parent.height * 0.96, 920)
    x: Math.round((parent.width - width) / 2)
    y: Math.round((parent.height - height) / 2)

    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    background: Rectangle {
      color: root.bg
      radius: 14
      border.color: root.border
      border.width: 1
    }

    Overlay.modal: Rectangle { color: "#000000"; opacity: 0.55 }

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: 14
      spacing: 12

      // header
      RowLayout {
        Layout.fillWidth: true
        spacing: 10

        H2 { Layout.fillWidth: true; text: "XmlHttpRequest Tester" }

        DarkButton { text: "Reset XHR"; onClicked: resetXhr() }
        DarkButton { text: "Close"; onClicked: panel.close() }
      }

      HelpText {
        text:
          "Goal: validate core XmlHttpRequest behavior (readyState, headers, JSON/text, redirect, timeout, abort, multipart).\n" +
          "Tip: if text inside fields is invisible, you are still running an old plugin zip — uninstall/reinstall and restart QField."
      }

      // scrollable content (prevents layouts from collapsing/overlapping on small screens)
      ScrollView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true

        contentItem: ColumnLayout {
          width: panel.width - 28
          spacing: 12

          // REQUEST
          Card {
            ColumnLayout {
              spacing: 10
              H3 { text: "Request" }

              GridLayout {
                columns: 3
                columnSpacing: 10
                rowSpacing: 10
                Layout.fillWidth: true

                DarkComboBox {
                  id: methodBox
                  model: ["GET", "POST", "PUT", "DELETE", "HEAD"]
                  Layout.preferredWidth: 140
                }

                DarkTextField {
                  id: urlField
                  Layout.fillWidth: true
                  placeholderText: "https://httpbin.org/anything"
                  text: "https://httpbin.org/anything"
                }

                DarkTextField {
                  id: timeoutField
                  Layout.preferredWidth: 140
                  inputMethodHints: Qt.ImhDigitsOnly
                  placeholderText: "timeout ms (0 = off)"
                  text: "0"
                }
              }

              DarkTextArea {
                id: headersArea
                Layout.fillWidth: true
                Layout.preferredHeight: 90
                placeholderText: "Headers (one per line)\nExample:\nContent-Type: application/json\nAuthorization: Bearer <token>"
                text: ""
              }

              RowLayout {
                Layout.fillWidth: true
                spacing: 10

                DarkButton {
                  Layout.fillWidth: true
                  text: "Send (text/json)"
                  onClicked: { ensureXhr(); root.sendTextOrJson() }
                }

                DarkButton {
                  text: "GET /get"
                  onClicked: {
                    ensureXhr()
                    methodBox.currentIndex = 0
                    urlField.text = "https://httpbin.org/get"
                    timeoutField.text = "0"
                    headersArea.text = ""
                    bodyArea.text = ""
                    root.sendTextOrJson()
                  }
                }

                DarkButton {
                  text: "Redirect"
                  onClicked: {
                    ensureXhr()
                    methodBox.currentIndex = 0
                    urlField.text = "https://httpbin.org/redirect/1"
                    timeoutField.text = "0"
                    headersArea.text = ""
                    bodyArea.text = ""
                    root.sendTextOrJson()
                  }
                }

                DarkButton {
                  text: "Timeout"
                  onClicked: {
                    ensureXhr()
                    methodBox.currentIndex = 0
                    urlField.text = "https://httpbin.org/delay/5"
                    timeoutField.text = "1000"
                    headersArea.text = ""
                    bodyArea.text = ""
                    root.sendTextOrJson()
                  }
                }

                DarkButton { text: "Abort"; onClicked: { if (xhr) xhr.abort() } }
              }
            }
          }

          // BODY + MULTIPART
          RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Card {
              Layout.fillWidth: true
              ColumnLayout {
                spacing: 10
                H3 { text: "Body (Text / JSON)" }
                DarkTextArea {
                  id: bodyArea
                  Layout.fillWidth: true
                  Layout.preferredHeight: 210
                  placeholderText: "If POST/PUT: paste JSON here (string)."
                  text: "{\n  \"hello\": \"qfield\",\n  \"when\": \"" + (new Date()).toISOString() + "\"\n}"
                }
                HelpText {
                  text:
                    "This button sends the body as a raw string (no QVariantMap conversion). " +
                    "If you want JSON parsing in C++, set Content-Type: application/json and return JSON from server."
                }
              }
            }

            Card {
              Layout.fillWidth: true
              ColumnLayout {
                spacing: 10
                H3 { text: "Multipart upload" }

                HelpText {
                  text:
                    "Important: core XmlHttpRequest blocks uploading arbitrary local files for safety.\n" +
                    "To test multipart: copy the file INTO the current QField project folder (or QFieldCloud local folder) and pick it from there."
                }

                RowLayout {
                  Layout.fillWidth: true
                  spacing: 10
                  DarkTextField {
                    id: fileField
                    Layout.fillWidth: true
                    placeholderText: "Picked file URL (file:///...)"
                    text: ""
                  }
                  DarkButton { text: "Pick…"; onClicked: fileDialog.open() }
                }

                RowLayout {
                  Layout.fillWidth: true
                  spacing: 10
                  DarkTextField {
                    id: uploadNameField
                    Layout.fillWidth: true
                    placeholderText: "file field name"
                    text: "file"
                  }
                  DarkTextField {
                    id: uploadNoteField
                    Layout.fillWidth: true
                    placeholderText: "note"
                    text: "Hello from QField plugin"
                  }
                }

                RowLayout {
                  Layout.fillWidth: true
                  spacing: 10
                  DarkButton {
                    Layout.fillWidth: true
                    text: "Upload to httpbin.org/post"
                    onClicked: {
                      ensureXhr()
                      methodBox.currentIndex = 1 // POST
                      urlField.text = "https://httpbin.org/post"
                      root.sendMultipart()
                    }
                  }
                  DarkButton { text: "Abort"; onClicked: { if (xhr) xhr.abort() } }
                }
              }
            }
          }

          // RESPONSE
          Card {
            ColumnLayout {
              spacing: 8
              H3 { text: "Response" }

              RowLayout {
                Layout.fillWidth: true
                spacing: 12
                Label {
                  Layout.fillWidth: true
                  color: root.fg
                  text: xhr ? ("status: " + xhr.status + " " + xhr.statusText) : "status: (no xhr)"
                  elide: Label.ElideRight
                }
                Label {
                  Layout.fillWidth: true
                  color: root.muted
                  text: xhr ? ("type: " + xhr.responseType) : ""
                  horizontalAlignment: Text.AlignRight
                  elide: Label.ElideRight
                }
              }

              Label {
                Layout.fillWidth: true
                color: root.muted
                text: xhr ? ("url: " + xhr.responseUrl) : ""
                elide: Label.ElideRight
              }

              ScrollView {
                Layout.fillWidth: true
                Layout.preferredHeight: 220
                clip: true
                contentItem: DarkTextArea {
                  readOnly: true
                  text: xhr ? xhr.responseText : ""
                }
              }
            }
          }

          // LOG
          Card {
            ColumnLayout {
              spacing: 10
              H3 { text: "Event log" }

              RowLayout {
                Layout.fillWidth: true
                spacing: 10
                DarkButton { text: "Clear"; onClicked: logModel.clear() }
                DarkButton { text: "Run mini self-test"; onClicked: root.runSelfTest() }
                Item { Layout.fillWidth: true }
                Label {
                  color: root.muted
                  text: xhr ? ("readyState: " + root.readyStateName(xhr.readyState)) : ""
                }
              }

              Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 260
                radius: 10
                color: root.field
                border.color: root.border
                border.width: 1

                ListView {
                  anchors.fill: parent
                  anchors.margins: 8
                  model: logModel
                  clip: true
                  delegate: Text {
                    width: ListView.view.width
                    color: root.fg
                    font.pixelSize: 12
                    text: "[" + t + "] " + m
                    wrapMode: Text.Wrap
                  }
                }
              }
            }
          }
        }
      }
    }

    onOpened: root.log("Panel opened")
    onClosed: root.log("Panel closed")
  }

  FileDialog {
    id: fileDialog
    title: "Pick a file to upload"
    onAccepted: {
      fileField.text = selectedFile.toString()
      root.log("Picked file: " + fileField.text)
    }
  }

  //request helpers
  function applyHeaders() {
    const lines = headersArea.text.split("\n")
    for (let i = 0; i < lines.length; i++) {
      const line = lines[i].trim()
      if (!line) continue
      const idx = line.indexOf(":")
      if (idx <= 0) {
        root.log("Header parse skipped: " + line)
        continue
      }
      const k = line.slice(0, idx).trim()
      const v = line.slice(idx + 1).trim()
      xhr.setRequestHeader(k, v)
    }
  }

  function sendTextOrJson() {
    if (!xhr) return

    const method = methodBox.currentText
    const url = urlField.text.trim()
    const ms = parseInt(timeoutField.text || "0")

    root.log("open(" + method + ", " + url + "), timeout=" + ms + "ms")
    xhr.open(method, url)
    xhr.timeout = isNaN(ms) ? 0 : ms

    applyHeaders()

    const hasCT = headersArea.text.toLowerCase().indexOf("content-type:") !== -1
    const body = bodyArea.text

    if (!hasCT && body && body.trim().length > 0 && method !== "GET" && method !== "HEAD") {
      xhr.setRequestHeader("Content-Type", "application/json")
    }

    xhr.send(body)
  }

  function sendMultipart() {
    if (!xhr) return

    const fileUrl = fileField.text.trim()
    if (!fileUrl) {
      root.log("No file selected; pick a local file first.")
      iface.mainWindow().displayToast("Pick a local file first (file:///...)")
      return
    }

    const method = methodBox.currentText
    const url = urlField.text.trim()
    const ms = parseInt(timeoutField.text || "0")

    root.log("open(" + method + ", " + url + ") multipart, timeout=" + ms + "ms")
    xhr.open(method, url)
    xhr.timeout = isNaN(ms) ? 0 : ms

    applyHeaders()

    // DO NOT force Content-Type: multipart/form-data here.
    // If you set it without boundary, some stacks get confused.
    // Core will auto-switch to multipart when it sees file:// values.
    // xhr.setRequestHeader("Content-Type", "multipart/form-data")

    const body = {}
    body[uploadNameField.text.trim() || "file"] = fileUrl
    body["note"] = uploadNoteField.text
    body["ts"] = (new Date()).toISOString()

    xhr.send(body)
  }

  // mini self-test
  property int selfTestStep: 0
  Timer {
    id: selfTestTimer
    interval: 250
    repeat: false
    onTriggered: root.nextSelfTestStep()
  }

  function runSelfTest() {
    ensureXhr()
    selfTestStep = 0
    log("=== self-test start ===")
    nextSelfTestStep()
  }

  function nextSelfTestStep() {
    if (!xhr) return
    selfTestStep += 1

    if (selfTestStep === 1) {
      methodBox.currentIndex = 0
      urlField.text = "https://httpbin.org/get"
      timeoutField.text = "0"
      headersArea.text = ""
      bodyArea.text = ""
      sendTextOrJson()
      selfTestTimer.start()
      return
    }

    if (selfTestStep === 2) {
      methodBox.currentIndex = 0
      urlField.text = "https://httpbin.org/redirect/1"
      timeoutField.text = "0"
      headersArea.text = ""
      bodyArea.text = ""
      sendTextOrJson()
      selfTestTimer.start()
      return
    }

    if (selfTestStep === 3) {
      methodBox.currentIndex = 0
      urlField.text = "https://httpbin.org/delay/5"
      timeoutField.text = "1000"
      headersArea.text = ""
      bodyArea.text = ""
      sendTextOrJson()
      selfTestTimer.start()
      return
    }

    log("=== self-test queued requests done (watch log for callbacks) ===")
  }

  // Signals (in case QJSValue callback properties don't fire)
  Connections {
    target: xhr
    function onReadyStateChanged() {
      root.log("signal readyStateChanged: " + (xhr ? root.readyStateName(xhr.readyState) : "?"))
    }
    function onResponseChanged() {
      if (!xhr) return
      root.log("signal responseChanged: status=" + xhr.status + " bytes=" + (xhr.responseText ? xhr.responseText.length : 0))
    }
  }

  Component.onCompleted: {
    iface.mainWindow().displayToast("XHR Tester plugin loaded")
    iface.addItemToPluginsToolbar(toolbarButton)
    ensureXhr()
    log("Plugin loaded; toolbar button added")
  }
}
