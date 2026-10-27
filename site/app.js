(() => {
  const canvas = document.getElementById("path-canvas");
  if (!canvas) return;

  const context = canvas.getContext("2d");
  if (!context) return;

  const cols = 18;
  const rows = 13;
  const cell = canvas.width / cols;
  const goal = { x: 15, y: 9 };
  const reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  let obstacles = new Set();
  let visited = [];
  let path = [];
  let animationStart = performance.now();
  let lastLayout = 0;

  const key = (x, y) => `${x},${y}`;

  function rebuildObstacles() {
    obstacles = new Set();
    const patterns = [
      [4, 2], [4, 3], [4, 4], [4, 5], [5, 5], [6, 5],
      [9, 1], [9, 2], [9, 3], [9, 4], [8, 4], [7, 4], [6, 4],
      [12, 6], [12, 7], [12, 8], [12, 9], [12, 10],
      [2, 8], [3, 8], [4, 8], [5, 8], [6, 8],
      [14, 2], [15, 2], [16, 2],
    ];
    for (const [x, y] of patterns) {
      obstacles.add(key(x, y));
    }
    obstacles.delete(key(goal.x, goal.y));
  }

  function heuristic(a, b) {
    const dx = Math.abs(a.x - b.x);
    const dy = Math.abs(a.y - b.y);
    return dx + dy + (Math.SQRT2 - 2) * Math.min(dx, dy);
  }

  function findPath(start) {
    const open = [{ ...start, g: 0, f: heuristic(start, goal), parent: null }];
    const seen = new Set();
    const order = [];

    while (open.length > 0) {
      open.sort((a, b) => a.f - b.f);
      const current = open.shift();
      const currentKey = key(current.x, current.y);
      if (seen.has(currentKey)) continue;
      seen.add(currentKey);
      order.push(current);

      if (current.x === goal.x && current.y === goal.y) {
        const result = [];
        let cursor = current;
        while (cursor) {
          result.unshift({ x: cursor.x, y: cursor.y });
          cursor = cursor.parent;
        }
        return { order, result };
      }

      const directions = [
        [1, 0], [-1, 0], [0, 1], [0, -1],
        [1, 1], [1, -1], [-1, 1], [-1, -1],
      ];

      for (const [dx, dy] of directions) {
        const x = current.x + dx;
        const y = current.y + dy;
        const nextKey = key(x, y);
        if (x < 0 || x >= cols || y < 0 || y >= rows) continue;
        if (obstacles.has(nextKey) || seen.has(nextKey)) continue;
        if (dx !== 0 && dy !== 0) {
          if (obstacles.has(key(current.x + dx, current.y)) ||
              obstacles.has(key(current.x, current.y + dy))) {
            continue;
          }
        }
        const cost = dx !== 0 && dy !== 0 ? Math.SQRT2 : 1;
        open.push({
          x,
          y,
          g: current.g + cost,
          f: current.g + cost + heuristic({ x, y }, goal),
          parent: current,
        });
      }
    }
    return { order, result: [] };
  }

  function roundRect(x, y, width, height, radius) {
    context.beginPath();
    context.roundRect(x, y, width, height, radius);
  }

  function drawGrid() {
    context.strokeStyle = "rgba(211, 236, 222, 0.075)";
    context.lineWidth = 1;
    for (let x = 1; x < cols; x += 1) {
      context.beginPath();
      context.moveTo(x * cell, 0);
      context.lineTo(x * cell, canvas.height);
      context.stroke();
    }
    for (let y = 1; y < rows; y += 1) {
      context.beginPath();
      context.moveTo(0, y * cell);
      context.lineTo(canvas.width, y * cell);
      context.stroke();
    }
  }

  function drawCell(x, y, fill, inset = 3, radius = 4) {
    roundRect(
      x * cell + inset,
      y * cell + inset,
      cell - inset * 2,
      cell - inset * 2,
      radius
    );
    context.fillStyle = fill;
    context.fill();
  }

  function draw(timestamp) {
    const elapsed = reducedMotion ? 10000 : timestamp - animationStart;
    const visitedCount = Math.min(visited.length, Math.floor(elapsed / 11));
    const pathCount = Math.max(0, Math.floor((elapsed - 650) / 65));

    context.clearRect(0, 0, canvas.width, canvas.height);
    drawGrid();

    for (let i = 0; i < visitedCount; i += 1) {
      const node = visited[i];
      drawCell(node.x, node.y, "rgba(55, 216, 154, 0.12)", 5);
    }

    for (const obstacle of obstacles) {
      const [x, y] = obstacle.split(",").map(Number);
      drawCell(x, y, "rgba(169, 179, 173, 0.21)", 4);
      context.fillStyle = "rgba(255, 111, 97, 0.22)";
      context.fillRect(x * cell + cell * 0.43, y * cell + cell * 0.2, 2, cell * 0.6);
    }

    drawCell(0, 12, "rgba(255, 201, 102, 0.9)", 7, 8);
    drawCell(goal.x, goal.y, "rgba(255, 201, 102, 0.9)", 7, 8);

    if (pathCount > 1) {
      const shown = path.slice(0, Math.min(path.length, pathCount));
      context.beginPath();
      shown.forEach((node, index) => {
        const x = node.x * cell + cell / 2;
        const y = node.y * cell + cell / 2;
        if (index === 0) context.moveTo(x, y);
        else context.lineTo(x, y);
      });
      context.strokeStyle = "#8ff0c2";
      context.lineWidth = Math.max(3, cell * 0.13);
      context.lineJoin = "round";
      context.lineCap = "round";
      context.shadowColor = "rgba(143, 240, 194, 0.5)";
      context.shadowBlur = 14;
      context.stroke();
      context.shadowBlur = 0;
    }

    if (elapsed > 4300) {
      animationStart = timestamp;
    }
    requestAnimationFrame(draw);
  }

  function reset() {
    rebuildObstacles();
    const search = findPath({ x: 0, y: 12 });
    visited = search.order;
    path = search.result;
    animationStart = performance.now();
  }

  function resize() {
    const width = canvas.clientWidth;
    if (!width || width === lastLayout) return;
    lastLayout = width;
    canvas.width = Math.round(width * Math.min(window.devicePixelRatio || 1, 2));
    canvas.height = Math.round(canvas.width * rows / cols);
    reset();
  }

  window.addEventListener("resize", resize);
  canvas.addEventListener("click", reset);
  resize();
  if (!lastLayout) {
    canvas.width = 720;
    canvas.height = 520;
    reset();
  }
  requestAnimationFrame(draw);
})();
