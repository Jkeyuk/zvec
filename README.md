# zvec Math Library for game dev and other things.

A **Ziggified** SIMD-accelerated 2D math library for game development and graphics. `zvec` provides high-performance `Vec2` and `Rect` primitives built directly on Zig's native `@Vector` types.

## Features

*   **⚡ SIMD Accelerated**: Leverages hardware-level vector instructions via `@Vector` for operations like addition, normalization, and collision checks.
*   **🎮 Game-Ready Rects**: Comprehensive AABB logic including intersections, merging, and point containment.
*   **🛠️ Idiomatic Zig**: Heavy use of `inline` functions and `@Vector` built-ins for maximum compiler optimization.
*   **📦 Zero Dependencies**: Only depends on the Zig Standard Library.

## API Overview

### Vec2


| Method | Description |
| :--- | :--- |
| `add/sub/mul/div` | Basic arithmetic (SIMD) |
| `dot/cross` | Vector products |
| `length/distance` | Euclidean distance (and squared versions) |
| `normalize` | Safely scales to unit length with epsilon check |
| `rotate/rotate90` | Angular transformations (radians) |
| `lerp/moveTowards` | Linear interpolation and steering |
| `reflect` | Bounces vector off a surface normal |
| `clamp/min/max` | Component-wise clamping and selection |


### Rect


| Method | Description |
| :--- | :--- |
| `center/end` | Calculate specific spatial points |
| `tr/bl` | Top-Right and Bottom-Left accessors |
| `collides` | Boolean AABB collision check |
| `contains(_p)` | Check if a point or another Rect is fully inside |
| `intersection` | Returns the overlapping Rect if it exists |
| `merge` | Returns the smallest Rect encapsulating both inputs |
| `expand/shrink` | Grow or tuck the edges relative to center |
| `translate/at` | Move the rectangle in 2D space |


## Installation

Add the code directly to your project or...

Add `zvec` to your `build.zig.zon` with `zig fetch `;

Then add as dependency
```zig
const zvec = b.dependency("zvec", .{
    .target = target,
    .optimize = optimize,
});
exe.root_module.addImport("zvec", zvec.module("zvec"));

```

```zig

```

## Quick Start

```zig
const zvec = @import("zvec");
const Vec2 = zvec.Vec2;

const a = Vec2.from(10.0, 20.0);
const b = Vec2.from(5.0, 5.0);

const sum = a.add(b);          // SIMD addition
const dist = a.distance(b);    // 15.811...
const norm = a.normalize();    // Unit vector (safe epsilon check)
const mid = a.lerp(b, 0.5);    // (1 - t) * a + t * b


const Rect = zvec.Rect;

const player = Rect.init(Vec2.from(0, 0), Vec2.from(32, 32));
const wall = Rect.init(Vec2.from(20, 0), Vec2.from(32, 32));

if (player.collides(wall)) {
    // Returns ?Rect of the overlapping area
    if (player.intersection(wall)) |inter| {
        const center = inter.center();
    }
}
```



