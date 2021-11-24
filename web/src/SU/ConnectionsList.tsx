import { Component } from 'react';
import App from '../App';
import { ListedConnection } from '../Frame/Incoming';

interface ConnectionsListState {
  flipflop: boolean;
  interval?: number;
}
interface ConnectionsListProps {
  app: App;
  connections: ListedConnection[];
}

export default class ConnectionsList extends Component<ConnectionsListProps, ConnectionsListState> {
  constructor(props: ConnectionsListProps) {
    super(props);
    this.state = {flipflop: false};
    this.refreshList = this.refreshList.bind(this);
  }

  refreshList() {
    this.props.app.send({su: "list"});
    this.setState(s => ({flipflop: !s.flipflop}));
  }

  componentDidMount() {
    this.setState({interval: window.setInterval(this.refreshList, 1000)});
  }

  componentWillUnmount() {
    window.clearInterval(this.state.interval);
  }

  render() {
    return <div>
      <span style={{backgroundColor: this.state.flipflop ? "red" : "green"}}>...</span>
      <div style={{backgroundColor: "#333"}}>
        {this.props.connections.map((e, i) =>
          <ListedConnectedUser key={i} connection={e} />
        )}
      </div>
    </div>;
  }
}

function ListedConnectedUser(p: {connection: ListedConnection}) {
  const e = p.connection;
  return <div>
    <span>[{e.id}] </span>
    {e.profile ? <span title={e.profile.id}><b>{e.profile.name}</b> </span> : <span>[unknown]</span>}
    <span>{e.opened} </span>
    <span>{JSON.stringify(e.connection)}</span>
  </div>;
}
