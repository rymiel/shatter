import { Card } from "@blueprintjs/core";
import React from "react";

export default function Section(props: {children: React.ReactNode, style?: React.CSSProperties}) {
  return <div style={{display: "flex", justifyContent: "center"}}>
    <Card style={props.style}>
      {props.children}
    </Card>
  </div>
}
