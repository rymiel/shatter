import React, { SyntheticEvent } from 'react';

export default function Auth() {
  function submitAuth(e: SyntheticEvent) {
    e.preventDefault();
    const nonce = Math.floor(Math.random() * 1000000000).toString(16);
    window.location.href = "https://login.live.com/oauth20_authorize.srf" +
      "?client_id=618fb7d2-7ac4-4925-b5b8-989d407f00d5" +
      "&redirect_uri=" + encodeURIComponent(window.location.origin + "/") +
      "&response_type=code+id_token&scope=xboxlive.signin+offline_access+openid+email" +
      "&nonce=" + nonce +
      "&response_mode=fragment";
  }

  return <div style={{display: "flex"}}>
    <input type="button" onClick={submitAuth} style={{margin: "auto"}} value="Authenticate with Microsoft" />
  </div>
}
