import React from 'react';
import App from './App';

interface ChatBoxProps {
  app: App;
  chatLines: string[];
}

interface ChatBoxState {
  message: string;
  isScrolledToBottom: boolean
}

function ChatMessages(p: {chatLines: string[], scrollRef: React.RefObject<HTMLDivElement>}) {
  React.useEffect(() => {
    const out = p.scrollRef.current;
    if (!out) return;
    out.scrollTop = out.scrollHeight;
  })

  return <>
    {p.chatLines.map((i, j) =>
      <p key={j} dangerouslySetInnerHTML={{__html: i}}></p>
    )}
  </>
}

export default class ChatBox extends React.Component<ChatBoxProps, ChatBoxState> {
  ref: React.RefObject<HTMLDivElement>;
  constructor(props: ChatBoxProps) {
    super(props);
    this.ref = React.createRef();
    this.state = {message: "", isScrolledToBottom: false};
    this.handleChange = this.handleChange.bind(this);
    this.handleKey = this.handleKey.bind(this);
    this.handleScroll = this.handleScroll.bind(this);
    this.sendChat = this.sendChat.bind(this);

  }

  sendChat() {
    const message = this.state.message.trim();
    if (message.length > 0) {
      this.props.app.send({
        emulate: "Chat",
        proxy: {chat: message}
      });
    }
    this.setState({message: ""});
  }

  handleChange(ev: React.ChangeEvent<HTMLInputElement>) {
    this.setState({message: ev.currentTarget.value});
  }

  handleScroll(ev: React.UIEvent<HTMLInputElement>) {
    const out = ev.currentTarget;
    this.setState({isScrolledToBottom: (out.scrollHeight - out.clientHeight <= out.scrollTop + 1)});
  }

  handleKey(ev: React.KeyboardEvent<HTMLInputElement>) {
    if (ev.key === 'Enter') {
      this.sendChat();
      ev.preventDefault();
    }
  }

  render() {
    return <div id="controlBox">
      <div id="chatBox" onScroll={this.handleScroll} ref={this.ref}>
        <ChatMessages scrollRef={this.ref} chatLines={this.props.chatLines} />
      </div>
      <div id="chatLine">
        <input id="chatInput" onChange={this.handleChange} onKeyDown={this.handleKey} value={this.state.message} />
        <input type="button" value="Chat" onClick={this.sendChat} />
      </div>
    </div>
  }
}
