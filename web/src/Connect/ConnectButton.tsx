import { Button, Intent } from '@blueprintjs/core';
import App, { Stage } from '../App';

export interface ConnectButtonProps {
  host?: [string?, number?];
  style?: React.CSSProperties;
  app: App;
}

export function ConnectButton(props: ConnectButtonProps) {
  const connecting = props.app.state.stage === Stage.Connecting;
  const onClick = () => {
    const host = props.host;
    if (host !== undefined && host[0] !== undefined && host[1] !== undefined && !connecting)
      props.app.connect(...host as [string, number]);
  };
  return <Button text="Connect!" intent={Intent.SUCCESS} style={props.style} loading={connecting} onClick={onClick} />;
}
