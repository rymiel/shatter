import React from 'react';

export interface ErrorProps {
  title: string
  description?: string | JSX.Element
}

const ERR_STYLE: React.CSSProperties = {
  color: "#ff6a6a",
  fontWeight: "bold",
  textAlign: "center"
}

export default function Error(props: ErrorProps) {
  return <div>
    <h2 style={ERR_STYLE}>{props.title}</h2>
    <p style={ERR_STYLE}>{props.description}</p>
  </div>
}
