import { Component } from 'react';
import App from '../App';
import { KnownUser, UserServerList } from '../Frame/Incoming';
import Profile from '../Profile';

interface KnownUserListProps {
  app: App;
  knownUsers: (KnownUser & UserServerList)[];
}

export default class KnownUserList extends Component<KnownUserListProps, Record<string, never>> {
  constructor(props: KnownUserListProps) {
    super(props);
    this.props.app.send({su: "knownu"});
  }

  render() {
    return <div style={{backgroundColor: "#333"}}>
      {this.props.knownUsers.map((e) => <div key={e.id} style={{display: "flex", alignItems: "center"}}>
        <Profile profile={e} />
        <div style={{marginLeft: "auto"}}><input type="button" value=">" style={{padding: 0, marginLeft: "1em"}} /></div>
      </div>)}
    </div>;
  }
}
