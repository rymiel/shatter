import { TupleOf } from '../Util/util';

export interface ListedConnection {
  opened: string,
  id: number,
  profile?: {
    id: string,
    name: string
  },
  connection: {
    host: string,
    state: string,
    listening: string[],
    proxying: string[]
  } | string
}

export namespace Incoming {
  export interface ReadyFrame {
    name: string;
    id: string;
    r?: string;
    roles: TupleOf<boolean, 3>;
  }

  export interface ConnectionList {
    list: {
      "Shatter::WS": ListedConnection
    }[]
  }

  export interface EmulateChatBody {
    html: string;
    position: number;
  }

  export interface EmulateDisconnectBody {
    html: string;
  }
}
