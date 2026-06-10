"use client";

/**
 * CinematicReveal — scroll-scrubbed canvas frame sequence (React / Next.js).
 *
 * Usage:
 *   <CinematicReveal
 *     frameCount={150}
 *     framePath={(i) => `/frames/frame_${String(i).padStart(4, "0")}.jpg`}
 *     lines={[
 *       { text: "I AM IRON MAN.",     in: 0.0,  out: 0.30 },
 *       { text: "BUILD WITH DEVINI.", in: 0.34, out: 0.64 },
 *       { text: "I AM INEVITABLE.",   in: 0.70, out: 1.0  },
 *     ]}
 *   />
 *
 * Pair with Lenis at the app root:
 *   const lenis = new Lenis({ lerp: 0.08 });
 *   const raf = (t:number) => { lenis.raf(t); requestAnimationFrame(raf); };
 *   requestAnimationFrame(raf);
 */
import { useEffect, useRef } from "react";

type Line = { text: string; in: number; out: number };

export default function CinematicReveal({
  frameCount = 150,
  framePath = (i: number) => `/frames/frame_${String(i).padStart(4, "0")}.jpg`,
  lines = [],
  scrollVh = 500,
}: {
  frameCount?: number;
  framePath?: (i: number) => string;
  lines?: Line[];
  scrollVh?: number;
}) {
  const sectionRef = useRef<HTMLElement>(null);
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const lineRefs = useRef<(HTMLHeadingElement | null)[]>([]);
  const imagesRef = useRef<HTMLImageElement[]>([]);
  const frameRef = useRef(0);

  useEffect(() => {
    const canvas = canvasRef.current!;
    const ctx = canvas.getContext("2d", { alpha: false })!;
    const section = sectionRef.current!;

    // preload
    const images: HTMLImageElement[] = [];
    for (let i = 0; i < frameCount; i++) {
      const img = new Image();
      img.src = framePath(i + 1);
      images[i] = img;
    }
    imagesRef.current = images;

    const draw = (index: number) => {
      const img = images[index];
      if (!img?.complete || !img.naturalWidth) return;
      const cw = window.innerWidth, ch = window.innerHeight;
      const ir = img.naturalWidth / img.naturalHeight, cr = cw / ch;
      let dw, dh, dx, dy;
      if (ir > cr) { dh = ch; dw = ch * ir; dx = (cw - dw) / 2; dy = 0; }
      else { dw = cw; dh = cw / ir; dx = 0; dy = (ch - dh) / 2; }
      ctx.fillStyle = "#02030a";
      ctx.fillRect(0, 0, cw, ch);
      ctx.drawImage(img, dx, dy, dw, dh);
    };

    const resize = () => {
      const dpr = Math.min(window.devicePixelRatio || 1, 2);
      canvas.width = window.innerWidth * dpr;
      canvas.height = window.innerHeight * dpr;
      ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
      draw(frameRef.current);
    };

    let ticking = false;
    const render = () => {
      ticking = false;
      const rect = section.getBoundingClientRect();
      const scrollable = rect.height - window.innerHeight;
      const p = Math.min(Math.max(-rect.top / scrollable, 0), 1);

      const idx = Math.min(frameCount - 1, Math.floor(p * (frameCount - 1)));
      if (idx !== frameRef.current) { frameRef.current = idx; draw(idx); }

      lineRefs.current.forEach((el, i) => {
        if (!el) return;
        const { in: a, out: b } = lines[i];
        const mid = (a + b) / 2, half = (b - a) / 2;
        let o = 1 - Math.abs(p - mid) / half;
        o = Math.max(0, Math.min(1, o));
        el.style.opacity = String(o);
        el.style.transform = `translate(-50%, calc(-50% + ${(1 - o) * 24}px))`;
      });
    };
    const onScroll = () => { if (!ticking) { ticking = true; requestAnimationFrame(render); } };

    images[0].onload = () => draw(0);
    resize();
    onScroll();
    window.addEventListener("scroll", onScroll, { passive: true });
    window.addEventListener("resize", resize);
    return () => {
      window.removeEventListener("scroll", onScroll);
      window.removeEventListener("resize", resize);
    };
  }, [frameCount, framePath, lines]);

  return (
    <section ref={sectionRef} style={{ position: "relative", height: `${scrollVh}vh` }}>
      <div style={{ position: "sticky", top: 0, height: "100vh", overflow: "hidden", background: "#02030a" }}>
        <canvas ref={canvasRef} style={{ position: "absolute", inset: 0, width: "100%", height: "100%" }} />
        {lines.map((l, i) => (
          <h1
            key={i}
            ref={(el) => { lineRefs.current[i] = el; }}
            style={{
              position: "absolute", left: "50%", top: "50%",
              transform: "translate(-50%, -50%)", opacity: 0,
              fontWeight: 900, fontSize: "clamp(2.2rem, 8vw, 7rem)",
              letterSpacing: "0.02em", textAlign: "center", whiteSpace: "nowrap",
              color: i === lines.length - 1 ? "#ff3b30" : "#f4f6fb",
              textShadow: "0 0 40px rgba(255,59,48,0.4)", pointerEvents: "none",
            }}
          >
            {l.text}
          </h1>
        ))}
      </div>
    </section>
  );
}
