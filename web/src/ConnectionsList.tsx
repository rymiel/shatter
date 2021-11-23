import React from 'react';
import App from './App';
import { ListedConnection } from './Frame/Incoming';

interface ConnectionsListState {
  showing: boolean;
  flipflop: boolean;
  interval?: number;
}
interface ConnectionsListProps {
  app: App;
  connections: ListedConnection[];
}

export default class ConnectionsList extends React.Component<ConnectionsListProps, ConnectionsListState> {
  constructor(props: ConnectionsListProps) {
    super(props);
    this.state = {showing: false, flipflop: false};
    this.handleClick = this.handleClick.bind(this);
    this.refreshList = this.refreshList.bind(this);
  }

  refreshList() {
    this.props.app.send({su: "list"});
    this.setState({flipflop: !this.state.flipflop});
  }

  handleClick() {
    if (!this.state.showing) {
      this.refreshList();
      this.setState({interval: window.setInterval(this.refreshList, 1000)})
    } else if (this.state.interval) {
      window.clearInterval(this.state.interval);
    }
    this.setState({showing: !this.state.showing})
  }

  render() {
    return <div>
      <input type="button" value="CON" onClick={this.handleClick}></input>
      {this.state.showing && <span style={{backgroundColor: this.state.flipflop ? "red" : "green"}}>...</span>}
      {this.state.showing && <div style={{backgroundColor: "#333"}}>
        {this.props.connections.map((e, i) =>
          <ListedConnectedUser key={i} connection={e} />
        )}
      </div>}
    </div>
  }
}

function ListedConnectedUser(p: {connection: ListedConnection}) {
  const e = p.connection;
  return <div>
    <span>[{e.id}] </span>
    {e.profile ? <span title={e.profile.id}><b>{e.profile.name}</b> </span> : <span>[unknown]</span>}
    <span>{e.opened} </span>
    <span>{JSON.stringify(e.connection)}</span>
  </div>
}
