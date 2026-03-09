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

