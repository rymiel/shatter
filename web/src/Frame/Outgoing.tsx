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

  interface EmulateChatFrame {
    emulate: "Chat";
    proxy: { chat: string; };
  }

  export type Frame = ConnectFrame | TokenFrame | EmulateChatFrame;
}
