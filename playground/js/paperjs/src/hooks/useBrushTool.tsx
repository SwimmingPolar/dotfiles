import paper from "paper";
import { useCallback, useMemo } from "react";

const strokeColor = "black";
const strokeWidth = 3;

let cursor: paper.Path;

export const useBrushTool = () => {
  const tool = useMemo(() => new paper.Tool(), []);
  tool.minDistance = 3;

  const createBrushCursor = useCallback(
    (point: paper.Point, radius: number, name: string) => {
      return new paper.Path.Circle({
        center: point,
        radius,
        strokeColor,
        strokeWidth,
        name,
      });
    },
    []
  );

  const paintBrushCursor = useCallback(
    (event: paper.MouseEvent) => {
      // 이전 cursor 제거
      cursor?.remove();
      // 새로운 cursor 생성
      cursor = createBrushCursor(event.point, 10, "cursor");
    },
    [createBrushCursor]
  );

  // 마우스 움직임
  tool.onMouseMove = paintBrushCursor;

  tool.onMouseDown = (event: paper.MouseEvent) => {
    // Create new path
    createBrushCursor(event.point, Math.random() * 30 + 10, "path");

    // Update minimap
    paper.PaperScope.get("1").project.activeLayer.emit("drawEnd", {});
  };

  return tool;
};
