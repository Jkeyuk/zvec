# zvec Math Library for game dev and other things.

A **Ziggified** SIMD-accelerated 2D math library for game development and graphics. `zvec` provides high-performance `Vec2` and `Rect` primitives built directly on Zig's native `@Vector` types.

## Features

*   **⚡ SIMD Accelerated**: Leverages hardware-level vector instructions via `@Vector` for operations like addition, normalization, and collision checks.
*   **🎮 Game-Ready Rects**: Comprehensive AABB logic including intersections, merging, and point containment.
*   **🛠️ Idiomatic Zig**: Heavy use of `inline` functions and `@Vector` built-ins for maximum compiler optimization.
*   **📦 Zero Dependencies**: Only depends on the Zig Standard Library.

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


## Quick Start

```zig
const Vec3 = Vec(3, f32);

const v1 = Vec3.initV(.{ 1.0, 2.0, 3.0 });
const v2 = Vec3.splat(10.0);

const result = v1.add(v2); // (11.0, 12.0, 13.0)
const dot_product = v1.dot(v2);

// Swizzling support
const v2_swizzled = v1.swizzle("zyx"); // (3.0, 2.0, 1.0)


const RectF = Rect(f32);

const player_bounds = RectF.init(0, 0, 32, 32);
const enemy_bounds = RectF.init(20, 20, 32, 32);

if (player_bounds.collides(enemy_bounds)) {
    // Handle collision
}

const union_rect = player_bounds.merge(enemy_bounds);

```

## 📖 API Overview
Type	Key Methods
Vec(n, T)	add, sub, mul, div, dot, cross, normalize, lerp, swizzle
Rect(T)	collides, contains, intersection, merge, expand, center, at
