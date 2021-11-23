import React from 'react';
import { Incoming } from "./Frame/Incoming";
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome'
import { faCircleCheck, faBomb } from '@fortawesome/free-solid-svg-icons'

interface ProfileProps {
  profile: Incoming.ReadyFrame
}

const PROFILE_CONTAINER_STYLE: React.CSSProperties = {
  alignItems: "center",
  display: "flex",
  flexDirection: "column",
  marginBottom: "1em"
}
const PROFILE_INNER_STYLE: React.CSSProperties = {
  display: "inline-flex",
  marginBottom: "1em"
}

export default function Profile(props: ProfileProps) {
  return <div style={PROFILE_CONTAINER_STYLE}>
    <div style={PROFILE_INNER_STYLE}>
      <img src={`https://crafatar.com/avatars/${props.profile.id}?size=24&overlay`} style={{marginRight: "1em"}}/>
      <span>Welcome, <b>{props.profile.name}</b>
        {props.profile.roles[0] && <FontAwesomeIcon icon={faCircleCheck} title="Thank you for being a tester!" />}
        {props.profile.roles[1] && <FontAwesomeIcon icon={faBomb} title="Yikes!" />}
      </span>
      <br />
    </div>
  </div>
}
