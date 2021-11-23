import React from 'react';

import Auth from './Auth';
import Spinner from './Util/Spinner';
import ErrorC, { ErrorProps } from './Util/Error';
import Profile from './Profile';
import ServerList, { ListedServerProps, srv } from './ServerList';
import ConnectForm from './Connect/ConnectForm';
import ChatBox from './ChatBox';
import { Incoming, ListedConnection } from './Frame/Incoming';
import { Outgoing } from './Frame/Outgoing';
import ConnectionsList from './ConnectionsList';

const enum Stage {
  Loading, Authenticating, Joining, Playing, Stuck
}

interface AppState {
  callback: URLSearchParams;
  stage: Stage;
  errors: ErrorProps[];
  chatLines: string[];
  connections: ListedConnection[];
  servers: Map<string, ListedServerProps>;
  ws?: WebSocket;
  loadingState?: string;
  profile?: Incoming.ReadyFrame;
}

export default class App extends React.Component<Record<string, never>, AppState> {
  constructor(props: Record<string, never>) {
    super(props);

    const callback = new URLSearchParams(window.location.hash.substr(1));
    window.location.hash = "";
    this.state = {
      callback: callback,
      stage: Stage.Loading,
      errors: [],
      chatLines: [],
      connections: [],
      servers: new Map,
    };

    if (this.canAuth()) {
      let ws;
      if (process.env.HOT_REDIRECT) {
        ws = new WebSocket("ws://" + process.env.HOT_REDIRECT + "/wsp");
      } else {
        ws = new WebSocket(`${document.location.hostname === "localhost" ? "ws" : "wss"}://${document.location.host}/wsp`);
      }
      this.state = {...this.state, ws: ws, stage: Stage.Authenticating};
      if (callback.has("code")) ws.onopen = () => this.send({token: callback.get("code")!});
      else ws.onopen = () => this.send({rtoken: localStorage.getItem("r")!});
      ws.onmessage = (ev) => {
        const data = ev.data;
        if (typeof data === 'string') this.decodeFrame(JSON.parse(data));
      }
    }
  }

  canAuth() {
    return this.state.callback.has("code") || localStorage.getItem("r")
  }

  send(frame: Outgoing.Frame) {
    this.state.ws?.send(JSON.stringify(frame));
  }

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  decodeFrame(json: any) {
    if ("error" in json) {
      this.setState({
        errors: this.state.errors.concat({
          title: json.errortype ?? "Denied",
          description: json.error
        })
      });
      if (this.state.stage === Stage.Authenticating) {
        this.setState({stage: Stage.Stuck});
        localStorage.removeItem("r");
      }
    } else if ("log" in json) {
      const logMsg = json.log as string;
      console.log(logMsg);
      if (this.state.stage === Stage.Authenticating) {
        this.setState({loadingState: logMsg});
      }
    } else if ("emulate" in json) {
      const data = json.proxy;
      if (json.emulate === "Chat") {
        const chat = data as Incoming.EmulateChatBody
        if (chat.position !== 2) {
          const chatLine = chat.html.replace(/\n/, "<br/>")
          this.setState({chatLines: [...this.state.chatLines, chatLine]})
        }
      } else if (json.emulate === "Disconnect") {
        const message = data.html as string
        this.setState({errors: [...this.state.errors, {title: "Forced Disconnect", description: (<span dangerouslySetInnerHTML={{__html: message}}/>)}]})
      } else {
        console.log(`Unhandled proxy ${json.emulate}`);
        console.log(data);
      }
    } else if ("ready" in json) {
      let frame = json.ready as Incoming.ReadyFrame;
      if (frame.r) localStorage.setItem("r", frame.r);
      this.setState({stage: Stage.Joining, profile: frame});
    } else if ("servers" in json) {
      let frame = json.servers as [string, number][];
      let servers = this.state.servers;
      frame.forEach((e) => servers.set(srv(e), {host: e}));
      this.setState({servers: servers});
    } else if ("ping" in json) {
      const server = json.ping as [string, number];
      const favicon = json.data.favicon as string;
      const description = (json.description as string).replace("\n", "<br/>");

      let servers = this.state.servers;
      const indexedServer = servers.get(srv(server));
      if (indexedServer === undefined) return;

      indexedServer.favicon = favicon;
      indexedServer.description = description;
      this.setState({servers: servers});
    } else if ("list" in json) {
      this.setState({connections: (json as Incoming.ConnectionList).list.map(i => i['Shatter::WS'])});
    } else {
      console.log("Unhandled frame");
      console.log(json);
    }
  }

  connect(host: string, port: number) {
    this.send({
      host: host, port: port,
      listening: [],
      proxied: ["Chat", "Disconnect"]
    });
    this.setState({stage: Stage.Playing});
  }

  render() {
    return <>
      <h1>Shatter Web</h1>
      {this.state.errors.map((p, i) => <ErrorC key={i} {...p} />)}
      {!this.canAuth() && <Auth />}
      {this.state.stage === Stage.Authenticating && <Spinner text={this.state.loadingState} />}
      {this.state.stage === Stage.Joining && this.state.profile && <Profile profile={this.state.profile} />}
      {this.state.stage === Stage.Joining && <ServerList app={this} servers={this.state.servers}/>}
      {this.state.stage === Stage.Joining && <ConnectForm app={this} />}
      {this.state.stage === Stage.Playing && <ChatBox app={this} chatLines={this.state.chatLines} />}
      {this.state.profile && this.state.profile.roles[1] && <ConnectionsList app={this} connections={this.state.connections} />}
    </>
  }
}
