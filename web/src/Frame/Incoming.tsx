import { TupleOf } from '../Util/util';


export namespace Incoming {
  export interface ReadyFrame {
    name: string;
    id: string;
    roles: TupleOf<boolean, 3>;
  }

  export interface EmulateChatBody {
    html: string;
    position: number;
  }

  export interface EmulateDisconnectBody {
    html: string;
  }
}
