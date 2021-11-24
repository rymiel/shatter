import { TupleOf } from '../Util/util';

export type Roles = TupleOf<boolean, 3>;

export interface ListedConnection {
  opened: string;
  id: number;
  profile?: {
    id: string;
    name: string;
  };
  connection: {
    host: string;
    state: string;
    listening: string[];
    proxying: string[];
  } | string;
}

export interface KnownUser {
  id: string;
  name?: string;
  roles: Roles;
}

export interface UserServerList {
  servers: {
    id: number;
    srv: [string, number];
  }[];
}

export namespace Incoming {
  export interface ReadyFrame extends KnownUser {
    r?: string;
  }

  export interface ConnectionList {
    su: {
      list: {
        "Shatter::WS": ListedConnection;
      }[];
    };
  }

  export interface KnownUserList {
    su: {
      knownu: (KnownUser & UserServerList)[];
    };
  }

  export interface EmulateChatBody {
    html: string;
    position: number;
  }

  export interface EmulateDisconnectBody {
    html: string;
  }
}
