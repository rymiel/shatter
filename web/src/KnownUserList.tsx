import React from 'react';
import App from './App';
import { KnownUser, UserServerList } from './Frame/Incoming';
import Profile from './Profile';

interface KnownUserListState {
  showing: boolean;
}
interface KnownUserListProps {
  app: App;
  knownUsers: (KnownUser & UserServerList)[];
}

export default class KnownUserList extends React.Component<KnownUserListProps, KnownUserListState> {
  constructor(props: KnownUserListProps) {
    super(props);
    this.state = {showing: false};
    this.handleClick = this.handleClick.bind(this);
    this.refreshList = this.refreshList.bind(this);
  }

  refreshList() {
    this.props.app.send({su: "knownu"});
  }

  handleClick() {
    if (!this.state.showing) {
      this.refreshList();
    }
    this.setState({showing: !this.state.showing})
  }

  render() {
    return <div>
      <input type="button" value="KNU" onClick={this.handleClick}></input>
      {this.state.showing && <div style={{backgroundColor: "#333"}}>
        {this.props.knownUsers.map((e) => <div key={e.id} style={{display: "flex", alignItems: "center"}}>
          <Profile profile={e} />
          <div style={{marginLeft: "auto"}}><input type="button" value=">" style={{padding: 0, marginLeft: "1em"}} /></div>
        </div>)}
      </div>}
    </div>
  }
}
