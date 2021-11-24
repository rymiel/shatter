interface SpinnerProps {
  text?: string;
}

const SPINNER_CONTAINER_STYLE: React.CSSProperties = {
  display: "flex",
  justifyContent: "center",
  alignItems: "center",
  flexDirection: "column",
  margin: "2em"
};

export default function Spinner(props: SpinnerProps) {
  return <div style={SPINNER_CONTAINER_STYLE}>
    <div id="spinner"></div>
    <span>{props.text ?? "???"}</span>
  </div>;
}
