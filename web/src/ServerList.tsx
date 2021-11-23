import React from 'react';
import App from './App';
import { ConnectButton } from './ConnectButton';

export interface ServerListProps {
  app: App;
  servers: Map<string, ListedServerProps>;
}
export interface ListedServerProps {
  host: [string, number];
  favicon?: string;
  description?: string;
}
export interface InherentServerProps {
  host: [string, number];
  name: string;
  app: App;
}
interface DetailedListedServerProps extends ListedServerProps {
  favicon: string;
  description: string;
}

const LIST_STYLE: React.CSSProperties = {
  alignItems: "center",
  display: "flex",
  flexDirection: "column",
  marginBottom: "1em"
}
const LIST_ITEM_STYLE: React.CSSProperties = {
  height: "64px"
}
const LIST_DESC_STYLE: React.CSSProperties = {
  ...LIST_ITEM_STYLE,
  display: "flex",
  flexDirection: "column"
}
const LIST_CONNECT_STYLE: React.CSSProperties = {
  ...LIST_ITEM_STYLE,
  marginLeft: "1em",
  verticalAlign: "middle"
}

export function srv(e: [string, number]): string {
  return `${e[0]}:${e[1]}`
}

function isDetailed(p: ListedServerProps): boolean {
  return (p.favicon !== undefined && p.favicon.startsWith("data:") && p.description !== undefined);
}

export default function ServerList(props: ServerListProps) {
  const list = Array.from(props.servers.entries()).map(([k, v]) =>
    isDetailed(v)
      ? <DetailedListedServer key={k} name={k} app={props.app} {...v as DetailedListedServerProps} />
      : <SimpleListedServer key={k} name={k} app={props.app} {...v} />
  );
  return <div style={LIST_STYLE}>
    {list}
  </div>
}

function DetailedListedServer(props: DetailedListedServerProps & InherentServerProps) {
  return <div style={{display: "flex"}}>
    <img style={{...LIST_ITEM_STYLE, marginRight: "1em"}}
      src={props.favicon} />
    <div style={LIST_DESC_STYLE}>
      <span>{props.name}</span>
      <div dangerouslySetInnerHTML={{__html: props.description}} />
    </div>
    <ConnectButton style={LIST_CONNECT_STYLE} {...props} />
  </div>
}

function SimpleListedServer(props: ListedServerProps & InherentServerProps) {
  return <div>
    <span>{props.name}</span>
    <ConnectButton style={{marginLeft: "1em"}} {...props} />
  </div>
}