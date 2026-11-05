(() => {
  "use strict";
  const $ = (id) => document.getElementById(id),
    canvas = $("plasma"),
    ctx = canvas.getContext("2d", { alpha: false }),
    screen = $("screen");
  const palettes = {
    dream: [
      "#100a36",
      "#3322a3",
      "#b21fbe",
      "#ff527d",
      "#ffb267",
      "#ffeea3",
      "#83e1d0",
      "#3453bd",
    ],
    fire: [
      "#180924",
      "#6b133c",
      "#d73347",
      "#ff7538",
      "#ffd16b",
      "#fff4be",
      "#f76567",
    ],
    ocean: [
      "#020b27",
      "#113087",
      "#3d3dc4",
      "#7964e8",
      "#4ac9ed",
      "#8bfff0",
      "#147aab",
    ],
    candy: [
      "#211047",
      "#8b19c9",
      "#ff3598",
      "#ffab78",
      "#ecff78",
      "#62f8bb",
      "#25afc4",
    ],
    green: ["#030f13", "#064a42", "#14a575", "#85df6b", "#e2ffb4", "#369b74"],
    mono: ["#080e24", "#273657", "#778ba2", "#dfe8dd", "#9fadd0", "#39446e"],
  };
  const ids = [
    "width",
    "height",
    "density",
    "gap",
    "speed",
    "scale",
    "complexity",
    "cycle",
  ];
  let state = {},
    lut = [],
    W = 0,
    H = 0,
    time = 0,
    playing = !matchMedia("(prefers-reduced-motion: reduce)").matches,
    last = 0,
    fpsTime = 0,
    frames = 0,
    mouse = { x: 0.5, y: 0.5, strength: 0, target: 0 };
  function palette() {
    const p = palettes[$("palette").value];
    $("swatches").style.background =
      "linear-gradient(90deg," + p.join(",") + ")";
    lut = Array.from({ length: 1024 }, (_, i) => {
      const n = (i / 1024) * p.length,
        a = p[Math.floor(n)],
        b = p[(Math.floor(n) + 1) % p.length],
        f = n % 1;
      const rgb = [1, 3, 5].map((k) =>
        Math.round(
          parseInt(a.slice(k, k + 2), 16) * (1 - f) +
            parseInt(b.slice(k, k + 2), 16) * f,
        ),
      );
      return "rgb(" + rgb.join(",") + ")";
    });
  }
  function read() {
    ids.forEach((id) => {
      state[id] = +$(id).value;
      let v = state[id];
      $(id + "Out").textContent =
        id === "width" || id === "height"
          ? v + " px"
          : id === "density"
            ? v + "%"
            : id === "speed"
              ? (v / 100).toFixed(2) + "×"
              : id === "scale"
                ? (v / 100).toFixed(2) + "×"
                : v + "%";
    });
  }
  function resize() {
    const r = screen.getBoundingClientRect();
    W = Math.max(1, Math.round(r.width));
    H = Math.max(1, Math.round(r.height));
    canvas.width = W;
    canvas.height = H;
  }
  function render(dt) {
    if (playing) time += (dt * state.speed) / 100;
    mouse.strength += (mouse.target - mouse.strength) * Math.min(1, dt * 5);
    const bw = (state.width * 100) / state.density,
      bh = (state.height * 100) / state.density,
      cols = Math.ceil(W / bw),
      rows = Math.ceil(H / bh),
      sc = state.scale / 100,
      t = time,
      c = state.complexity / 100,
      gap = state.gap / 100;
    ctx.fillStyle = "#08080b";
    ctx.fillRect(0, 0, W, H);
    const aspect = W / H;
    for (let y = 0; y < rows; y++) {
      const ny = (y + 0.5) / rows;
      for (let x = 0; x < cols; x++) {
        const nx = (x + 0.5) / cols,
          px = (nx - 0.5) * aspect * sc * 7,
          py = (ny - 0.5) * sc * 7;
        let v =
          Math.sin(px * 1.4 + t * 0.9) +
          Math.sin(py * 1.7 - t * 0.7) +
          Math.sin((px + py) * 0.8 + t * 0.5);
        const cx = px + Math.sin(t * 0.36) * 2,
          cy = py + Math.cos(t * 0.29) * 2;
        v += Math.sin(Math.hypot(cx, cy) * 2.1 - t * 1.2);
        v +=
          c *
          (Math.sin(px * 2.7 + Math.sin(py * 1.8 + t)) +
            Math.cos(py * 2.4 + Math.cos(px + t * 0.7)));
        if ($("pointer").checked && mouse.strength > 0.001) {
          const d = Math.hypot((nx - mouse.x) * aspect, ny - mouse.y);
          v += Math.sin(d * 27 - t * 2) * Math.exp(-d * 3) * mouse.strength * 2;
        }
        const phase = v / (8 + 4 * c) + 0.5 + ((t * state.cycle) / 100) * 0.08,
          index = ((Math.floor(phase * 1024) % 1024) + 1024) % 1024;
        ctx.fillStyle = lut[index];
        ctx.fillRect(
          Math.floor(x * bw),
          Math.floor(y * bh),
          Math.max(1, Math.ceil(bw * (1 - gap))),
          Math.max(1, Math.ceil(bh * (1 - gap))),
        );
      }
    }
    $("gridInfo").textContent =
      cols + " × " + rows + " / " + (cols * rows).toLocaleString() + " BLOCKS";
  }
  function frame(now) {
    const dt = Math.min((now - last) / 1000 || 0, 0.05);
    last = now;
    if (!document.hidden) {
      render(dt);
      frames++;
      if (now - fpsTime > 700) {
        $("fps").textContent = Math.round((frames * 1000) / (now - fpsTime));
        fpsTime = now;
        frames = 0;
      }
    }
    requestAnimationFrame(frame);
  }
  function updatePlay() {
    $("pause").textContent = playing ? "Ⅱ Pause" : "▶ Play";
    $("pause").setAttribute(
      "aria-label",
      playing ? "Pause animation" : "Play animation",
    );
    $("live").textContent = playing ? "LIVE RENDER" : "FRAME HELD";
    $("dot").style.background = playing ? "var(--accent)" : "#999";
  }
  function toggle() {
    playing = !playing;
    updatePlay();
  }
  function custom() {
    document
      .querySelectorAll("[data-preset]")
      .forEach((b) => b.classList.remove("active"));
  }
  ids.forEach((id) =>
    $(id).addEventListener("input", () => {
      read();
      custom();
    }),
  );
  $("palette").addEventListener("change", () => {
    palette();
    custom();
  });
  $("crt").addEventListener("change", () =>
    screen.classList.toggle("crt", $("crt").checked),
  );
  $("pause").onclick = toggle;
  const presets = {
    classic: {
      width: 12,
      height: 12,
      density: 100,
      gap: 4,
      speed: 65,
      scale: 100,
      complexity: 55,
      cycle: 20,
      palette: "dream",
    },
    lava: {
      width: 8,
      height: 8,
      density: 100,
      gap: 0,
      speed: 40,
      scale: 65,
      complexity: 70,
      cycle: 12,
      palette: "fire",
    },
    ocean: {
      width: 6,
      height: 12,
      density: 110,
      gap: 4,
      speed: 35,
      scale: 130,
      complexity: 38,
      cycle: 15,
      palette: "ocean",
    },
    pixel: {
      width: 28,
      height: 28,
      density: 95,
      gap: 18,
      speed: 115,
      scale: 150,
      complexity: 85,
      cycle: 50,
      palette: "candy",
    },
  };
  function apply(name) {
    const p = presets[name];
    ids.forEach((id) => ($(id).value = p[id]));
    $("palette").value = p.palette;
    read();
    palette();
    custom();
    document
      .querySelector('[data-preset="' + name + '"]')
      .classList.add("active");
  }
  document
    .querySelectorAll("[data-preset]")
    .forEach((b) => (b.onclick = () => apply(b.dataset.preset)));
  $("reset").onclick = () => {
    const d = {
      width: 25,
      height: 25,
      density: 100,
      gap: 0,
      speed: 50,
      scale: 75,
      complexity: 50,
      cycle: 35,
    };
    ids.forEach((id) => ($(id).value = d[id]));
    $("palette").value = "dream";
    read();
    palette();
    custom();
    time = 0;
    $("crt").checked = false;
    $("pointer").checked = false;
    screen.classList.remove("crt");
  };
  $("random").onclick = () => {
    ids.forEach((id) => {
      const el = $(id);
      el.value = Math.round(+el.min + Math.random() * (el.max - el.min));
    });
    $("palette").value = Object.keys(palettes)[Math.floor(Math.random() * 6)];
    read();
    palette();
    custom();
  };
  function toast(message) {
    $("toast").textContent = message;
    $("toast").classList.remove("hidden");
    clearTimeout(toast.timer);
    toast.timer = setTimeout(() => $("toast").classList.add("hidden"), 2600);
  }
  async function full() {
    try {
      if (document.fullscreenElement) await document.exitFullscreen();
      else if (screen.requestFullscreen) await screen.requestFullscreen();
      else toast("Fullscreen is unavailable in this browser.");
    } catch {
      toast("Fullscreen is unavailable in this view.");
    }
  }
  $("fullscreen").onclick = full;
  $("snapshot").onclick = () => {
    render(0);
    const copy = document.createElement("canvas");
    copy.width = W;
    copy.height = H;
    const c = copy.getContext("2d");
    c.drawImage(canvas, 0, 0);
    if ($("crt").checked) {
      c.fillStyle = "#0003";
      for (let y = 2; y < H; y += 3) c.fillRect(0, y, W, 1);
      const shade = c.createRadialGradient(
        W / 2,
        H / 2,
        Math.min(W, H) * 0.2,
        W / 2,
        H / 2,
        Math.max(W, H) * 0.65,
      );
      shade.addColorStop(0, "#0000");
      shade.addColorStop(1, "#0008");
      c.fillStyle = shade;
      c.fillRect(0, 0, W, H);
    }
    copy.toBlob((blob) => {
      if (!blob) {
        toast("Could not create snapshot.");
        return;
      }
      const url = URL.createObjectURL(blob),
        a = document.createElement("a");
      a.href = url;
      a.download = "plasma-" + Date.now() + ".png";
      a.click();
      setTimeout(() => URL.revokeObjectURL(url), 10000);
      toast("Snapshot saved.");
    }, "image/png");
  };
  screen.addEventListener("pointermove", (e) => {
    const r = screen.getBoundingClientRect();
    mouse.x = (e.clientX - r.left) / r.width;
    mouse.y = (e.clientY - r.top) / r.height;
    mouse.target = 1;
  });
  screen.addEventListener("pointerleave", () => (mouse.target = 0));
  screen.addEventListener("pointerup", (e) => {
    if (e.pointerType === "touch") mouse.target = 0;
  });
  document.addEventListener("keydown", (e) => {
    if (
      /INPUT|SELECT|BUTTON|TEXTAREA/.test(document.activeElement.tagName) ||
      e.ctrlKey ||
      e.metaKey ||
      e.altKey
    )
      return;
    if (e.code === "Space") {
      e.preventDefault();
      toggle();
    } else if (e.key.toLowerCase() === "f") {
      e.preventDefault();
      full();
    }
  });
  new ResizeObserver(resize).observe(screen);
  document.addEventListener("visibilitychange", () => {
    last = performance.now();
    fpsTime = last;
    frames = 0;
  });
  read();
  palette();
  resize();
  updatePlay();
  requestAnimationFrame(frame);
})();
