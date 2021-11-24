import { InputGroup } from '@blueprintjs/core';
import { Component } from 'react';
import App from '../App';
import Section from '../Util/Section';
import { ConnectButton } from './ConnectButton';

interface ConnectFormProps {
  app: App;
}

interface ConnectFormState {
  host?: string;
  port?: number;
}

export default class ConnectForm extends Component<ConnectFormProps, ConnectFormState> {
  constructor(props: ConnectFormProps) {
    super(props);
    this.state = {port: 25565};
    this.handleHostChange = this.handleHostChange.bind(this);
    this.handlePortChange = this.handlePortChange.bind(this);
    this.handleSubmit = this.handleSubmit.bind(this);
  }

  handleHostChange(ev: React.ChangeEvent<HTMLInputElement>) {
    this.setState({host: ev.currentTarget.value});
  }

  handlePortChange(ev: React.ChangeEvent<HTMLInputElement>) {
    this.setState({port: parseInt(ev.currentTarget.value)});
  }

  handleSubmit(ev: React.KeyboardEvent<HTMLInputElement>) {
    if (ev.key === 'Enter') {
      ev.preventDefault();
      if (this.state.host !== undefined && this.state.port !== undefined)
        this.props.app.connect(this.state.host, this.state.port);
    }
  }

  render() {
    return <Section style={{justifyContent: "center", display: "flex", marginBottom: "1em", width: "fitContent"}}>
      <InputGroup onKeyDown={this.handleSubmit} onChange={this.handleHostChange} placeholder="Host" />
      <InputGroup type="number" defaultValue="25565" size={5} onKeyDown={this.handleSubmit} onChange={this.handlePortChange} placeholder="Port" />
      <ConnectButton app={this.props.app} host={[this.state.host, this.state.port]} />
    </Section>;
  }
}
