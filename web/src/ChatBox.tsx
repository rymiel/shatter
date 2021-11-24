import { RefObject, Component, createRef, useEffect } from 'react';

import { Button, Intent } from '@blueprintjs/core';

import App from './App';

interface ChatBoxProps {
  app: App;
  chatLines: string[];
}

interface ChatBoxState {
  message: string;
  isScrolledToBottom: boolean;
}

function ChatMessages(p: {chatLines: string[], isScrolledToBottom: boolean, scrollRef: RefObject<HTMLDivElement>}) {
  useEffect(() => {
    const out = p.scrollRef.current;
    if (!out) return;
    if (p.isScrolledToBottom) out.scrollTop = out.scrollHeight;
  });

  return <>
    {p.chatLines.map((i, j) =>
      <p key={j} dangerouslySetInnerHTML={{__html: i}} />
    )}
  </>;
}

export default class ChatBox extends Component<ChatBoxProps, ChatBoxState> {
  ref: RefObject<HTMLDivElement>;

  constructor(props: ChatBoxProps) {
    super(props);
    this.ref = createRef();
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
        <ChatMessages scrollRef={this.ref} isScrolledToBottom={this.state.isScrolledToBottom} chatLines={this.props.chatLines} />
      </div>
      <div id="chatLine">
        <input id="chatInput" onChange={this.handleChange} onKeyDown={this.handleKey} value={this.state.message} />
        <Button intent={Intent.PRIMARY} text="Chat" onClick={this.sendChat} />
      </div>
    </div>;
  }
}
