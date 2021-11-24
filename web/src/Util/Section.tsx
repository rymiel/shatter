import { Card } from "@blueprintjs/core";
import { ReactNode, CSSProperties } from "react";

export default function Section(props: {children: ReactNode, style?: CSSProperties}) {
  return <div style={{display: "flex", justifyContent: "center"}}>
    <Card style={props.style}>
      {props.children}
    </Card>
  </div>;
}
