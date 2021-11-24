import { H2 } from "@blueprintjs/core";

export interface ErrorProps {
  title: string;
  description?: string | JSX.Element;
}

const ERR_STYLE: React.CSSProperties = {
  color: "#ff6a6a",
  fontWeight: "bold",
  textAlign: "center"
};

export default function Error(props: ErrorProps) {
  return <div>
    <H2 style={ERR_STYLE}>{props.title}</H2>
    <p style={ERR_STYLE}>{props.description}</p>
  </div>;
}
