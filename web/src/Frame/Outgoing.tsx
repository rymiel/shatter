export namespace Outgoing {
  interface ConnectFrame {
    host: string;
    port: number;
    listening: string[];
    proxied: string[];
  }

  interface TokenFrame {
    token: string;
  }

  interface RefreshTokenFrame {
    rtoken: string;
  }

  interface EmulateChatFrame {
    emulate: "Chat";
    proxy: { chat: string };
  }

  interface SuActionFrame {
    su: "list" | "knownu";
  }

  export type Frame = ConnectFrame | TokenFrame | RefreshTokenFrame | EmulateChatFrame | SuActionFrame;
}
