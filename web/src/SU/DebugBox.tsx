import { Button, ButtonGroup, Collapse } from "@blueprintjs/core";
import { Component } from "react";
import App from "../App";
import ConnectionsList from "./ConnectionsList";
import KnownUserList from "./KnownUserList";

const LABELS = ["CON", "KNU"] as const;

interface DebugBoxProps {
  app: App;
}

interface DebugBoxState {
  showing: boolean;
  active: number;
}

export default class DebugBox extends Component<DebugBoxProps, DebugBoxState> {

  constructor(props: DebugBoxProps) {
    super(props);
    this.state = {active: 0, showing: false};
    this.handleClick = this.handleClick.bind(this);
  }

  handleClick(idx: number) {
    this.setState(s => ({showing: s.showing ? s.active !== idx : true, active: idx}));
  }

  render() {
    return <div style={{position: "absolute", "top": 0, "left": 0}}>
      <ButtonGroup>
        {LABELS.map((i, j) => <Button key={i} text={i} active={this.state.showing && this.state.active === j} onClick={() => this.handleClick(j)} />)}
      </ButtonGroup>

      <Collapse isOpen={this.state.showing}>
        {this.state.active === 0 && <ConnectionsList app={this.props.app} connections={this.props.app.state.connections} />}
        {this.state.active === 1 && <KnownUserList app={this.props.app} knownUsers={this.props.app.state.knownUsers} />}
      </Collapse>
    </div>;
  }
}
