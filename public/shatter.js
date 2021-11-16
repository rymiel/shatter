var ws;

function el(id) {
  return document.getElementById(id);
}

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
  if (el`chatInput`.value.length > 0)
    wsSend({emulate: "Chat", proxy: {chat: el`chatInput`.value}});
  el`chatInput`.value = "";
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

  if (callback.has("error"))
    reportError(callback.get("error"), callback.get("error_description"));

  function connect(_event) {
    ws.send(JSON.stringify({
      host: el`hostInput`.value || "play.vanillarite.com",
      port: parseInt(el`portInput`.value),
      listening: [],
      proxied: ["Chat", "Disconnect"]
    }));
    el`connectBox`.style = "display: none;";
    el`controlBox`.style = "";
    el`chatSubmit`.onclick = sendChat;
    submit(el`chatInput`, sendChat);
  }

  if (callback.has("code")) {
    el`auth`.hidden = true;
    el`authSubmit`.hidden = true;
    ws = new WebSocket(`${document.location.hostname === "localhost" ? "ws" : "wss"}://${document.location.host}/wsp`);
    ws.onopen = function() {
      el`middle`.hidden = false;
      wsSend({token: callback.get("code")});
    }

    ws.onmessage = function(message) {
      let data = JSON.parse(message.data);
      if (data.error) {
        reportError(data.errortype || "Denied", data.error);
        el`middle`.hidden = true;
      } else if (data.emulate === "Chat") {
        let position = data.proxy.position;
        if (position !== 2) {
          let preserveScroll = isScrolledToBottom(el`chatBox`);
          el`chatBox`.innerHTML += "<p>" + data.proxy.html + "</p>";
          if (preserveScroll) el`chatBox`.scrollTop = el`chatBox`.scrollHeight
        }
      } else if (data.emulate === "Disconnect") {
        reportError("Forced Disconnect", data.proxy.html);
      } else if (data.offer) {
        let offer = document.createElement("input");
        offer.setAttribute("type", "button");
        offer.setAttribute("value", "Request access");
        offer.setAttribute("onclick", `mOffer("${data.offer}");`);
        document.body.appendChild(offer);
        console.log(offer.onclick);
      } else if (data.ready) {
        el`connectBox`.style = "";
        el`middle`.hidden = true;
        submit(el`hostInput`, connect);
        submit(el`portInput`, connect);
        el`connect`.onclick = connect;
      } else if (data.log) {
        el`progress`.innerText = data.log;
      }
    }
    
    ws.onclose = function(closeEvent) {
      closeReason = `Lost connection. (${closeEvent.code}; ${closeEvent.reason})`
      if (!closeEvent.reason.includes("Closed due to above error")) reportError("Disconnected", closeReason);
      el`chatSubmit`.disabled = true;
      el`chatInput`.disabled = true;
    }
  }

  el`authSubmit`.onclick = function() {
    let nonce = Math.floor(Math.random() * 1000000000).toString(16);
    window.location.href = "https://login.live.com/oauth20_authorize.srf" +
      "?client_id=618fb7d2-7ac4-4925-b5b8-989d407f00d5" +
      "&redirect_uri=" + encodeURIComponent(window.location.origin + "/") + 
      "&response_type=code+id_token&scope=xboxlive.signin+offline_access+openid+email" +
      "&nonce=" + nonce +
      "&response_mode=fragment";
  }
});