var ws, chatBox, hostInput, portInput, chatInput, connectBox, controlBox, chatSubmit;

function isScrolledToBottom(out) {
  return out.scrollHeight - out.clientHeight <= out.scrollTop + 1;
}

function reportError(title, description) {
  if (description === undefined) {
    description = title;
    title = "Unknown error!";
  }
  document.body.innerHTML += `<h2 class="err">${title}</h2>`
  document.body.innerHTML += `<p class="err">${description}</p>`;
}

function mOffer(me) {
  fetch(me, { method: "POST" });
}

function wsSend(jsonPayload) {
  ws.send(JSON.stringify(jsonPayload));
}

function sendChat() {
  if (chatInput.value.length > 0)
    wsSend({emulate: "Chat", proxy: {chat: chatInput.value}});
  chatInput.value = "";
}

function submit(el, closure) {
  el.addEventListener("keypress", function(event) {
    if (event.keyCode == 13) {
      event.preventDefault();
      closure();
    }
  });
}

window.addEventListener('load', (_event) => {
  let callback = new URLSearchParams(window.location.hash.substr(1));
  window.location.hash = "";
  chatBox = document.getElementById("chatBox");
  hostInput = document.getElementById("hostInput");
  portInput = document.getElementById("portInput");
  chatInput = document.getElementById("chatInput");
  connectBox = document.getElementById("connectBox");
  controlBox = document.getElementById("controlBox");
  chatSubmit = document.getElementById("chatSubmit");

  if (callback.has("error"))
    reportError(callback.get("error"), callback.get("error_description"));

  function connect(_event) {
    ws.send(JSON.stringify({
      host: hostInput.value || "play.vanillarite.com",
      port: parseInt(portInput.value),
      listening: [],
      proxied: ["Chat"]
    }));
    connectBox.style = "display: none;";
    controlBox.style = "";
    chatSubmit.onclick = sendChat;
    submit(chatInput, sendChat);
  }

  if (callback.has("code")) {
    document.getElementById("auth").hidden = true;
    document.getElementById("authSubmit").hidden = true;
    ws = new WebSocket(`${document.location.host === "localhost" ? "ws" : "wss"}://${document.location.host}/wsp`);
    ws.onopen = function() {
      document.getElementById("middle").hidden = false;
      wsSend({token: callback.get("code")});
    }

    ws.onmessage = function(message) {
      let data = JSON.parse(message.data);
      if (data.error) {
        reportError("Denied", data.error);
        document.getElementById("middle").hidden = true;
      } else if (data.emulate === "Chat") {
        let position = data.proxy.position;
        if (position !== 2) {
          let preserveScroll = isScrolledToBottom(chatBox);
          chatBox.innerHTML += "<p>" + data.proxy.html + "</p>";
          if (preserveScroll) chatBox.scrollTop = chatBox.scrollHeight
        }
      } else if (data.offer) {
        let offer = document.createElement("input");
        offer.setAttribute("type", "button");
        offer.setAttribute("value", "Request access");
        offer.setAttribute("onclick", `mOffer("${data.offer}");`);
        document.body.appendChild(offer);
        console.log(offer.onclick);
      } else if (data.ready) {
        connectBox.style = "";
        document.getElementById("middle").hidden = true;
        submit(hostInput, connect);
        submit(portInput, connect);
        document.getElementById("connect").onclick = connect;
      } else if (data.log) {
        document.getElementById("progress").innerText = data.log;
      }
    }
    
    ws.onclose = function(closeEvent) {
      closeReason = `Lost connection. (${closeEvent.code}; ${closeEvent.reason})`
      reportError("Disconnected", closeReason);
      chatSubmit.disabled = true;
      chatInput.disabled = true;
    }
  }

  document.getElementById("authSubmit").onclick = function() {
    let nonce = Math.floor(Math.random() * 1000000000).toString(16);
    window.location.href = "https://login.live.com/oauth20_authorize.srf" +
      "?client_id=618fb7d2-7ac4-4925-b5b8-989d407f00d5" +
      "&redirect_uri=" + encodeURIComponent(window.location.origin + "/") + 
      "&response_type=code+id_token&scope=xboxlive.signin+offline_access+openid+email" +
      "&nonce=" + nonce +
      "&response_mode=fragment";
  }
});