import { faCircleCheck, faBomb } from '@fortawesome/free-solid-svg-icons';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';

import { KnownUser } from "./Frame/Incoming";

interface ProfileProps {
  profile: KnownUser;
}

export default function Profile(props: ProfileProps) {
  return <>
      <img src={`https://crafatar.com/avatars/${props.profile.id}?size=24&overlay`} style={{margin: "0 0.5em"}} />
      <span style={{display: "inline-block"}}>
        {props.profile.roles[0] && <FontAwesomeIcon icon={faCircleCheck} title="Thank you for being a tester!" />}
        {props.profile.roles[1] && <FontAwesomeIcon icon={faBomb} title="Yikes!" />}
        <b>{props.profile.name ?? "[unknown]"}</b>
      </span>
    </>;
}
