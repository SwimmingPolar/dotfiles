import { useEffect, useRef } from "react";
import "./App.css";

function App() {
  const containerRef = useRef<HTMLDivElement>(null);
  const cardRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const container = containerRef.current;
    const card = cardRef.current;

    const handleMouseMove = (event: MouseEvent) => {
      const { clientX, clientY } = event;
      const { left, top, width, height } = container!.getBoundingClientRect();
      const [centerX, centerY] = [left + width / 2, top + height / 2];

      const deltaX = clientX - centerX;
      const deltaY = clientY - centerY;

      const rotateY = (deltaX / width) * 30; // Sensitivity for Y rotation
      const rotateX = (-deltaY / height) * 30; // Sensitivity for X rotation

      card!.style.transform = `rotateX(${rotateX}deg) rotateY(${rotateY}deg)`;
    };

    container?.addEventListener("mousemove", handleMouseMove);
    return () => {
      container?.removeEventListener("mousemove", handleMouseMove);
    };
  }, []);
  return (
    <div className="card-container" ref={containerRef}>
      <div className="card" ref={cardRef}>
        <span>C A R D</span>
      </div>
    </div>
  );
}

export default App;
