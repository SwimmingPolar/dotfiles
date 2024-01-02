import paper from "paper";
import React, { useEffect, useRef } from "react";
import styled from "styled-components";
import { useBrushTool } from "./hooks";

const Container = styled.div`
  display: flex;
  justify-content: center;
  align-items: flex-end; /* Align items at the bottom */
  height: 90vh;
`;

const Editor = styled.canvas`
  width: 720px;
  height: 720px;
  margin: 0 20px;
  border: 1px solid #000;
`;

const Minimap = styled.canvas`
  width: 360px;
  height: 360px;
  border: 1px solid #000;
`;

const SCALE = 0.5;

const App = () => {
  const brush = useBrushTool();
  const editorRef = useRef<HTMLCanvasElement>(null);
  const minimapRef = useRef<HTMLCanvasElement>(null);

  useEffect(() => {
    // Setup editor scope
    paper.setup(editorRef.current!);

    // Setup minimap scope
    const minimapScope = new paper.PaperScope();
    minimapScope.setup(minimapRef.current!);
    // Scale minimap view
    minimapScope.project.view.scale(SCALE, new minimapScope.Point(0, 0));

    const cloneLayer = () => {
      const editor = paper.project.activeLayer;
      const minimap = minimapScope.project.activeLayer;

      // Remove children and copy existing paths
      minimap.removeChildren();
      editor.copyTo(minimapScope.project.activeLayer);

      // Remove cursor from minimap
      // Only 1 compound path exists in minimap (= index 0)
      const compoundPath = minimap.children[0].children;
      const cursor = compoundPath.find((path) => path.name === "cursor 1");
      cursor?.remove();
    };

    // Update minimap on drawEnd
    paper.PaperScope.get(1).project.activeLayer.on("drawEnd", cloneLayer);

    // Initial cloning of existing paths
    cloneLayer();
  }, [brush]);

  useEffect(() => {
    brush.activate();
  }, [brush]);

  return (
    <React.StrictMode>
      <Container>
        <Editor ref={editorRef} />
        <Minimap ref={minimapRef} />
      </Container>
    </React.StrictMode>
  );
};

export default App;
