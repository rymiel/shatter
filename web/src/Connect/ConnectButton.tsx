import React from 'react';
import App from '../App';

export interface ConnectButtonProps {
  host?: [string?, number?];
  style?: React.CSSProperties
  app: App;
}

export function ConnectButton(props: ConnectButtonProps) {
  const onClick = () => {
    const host = props.host;
    if (host !== undefined && host[0] !== undefined && host[1] !== undefined)
      props.app.connect(...host as [string, number]);
  };
  return <input type="button" value="Connect!" style={props.style} onClick={onClick} />;
}
