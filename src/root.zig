const std = @import("std");

pub const Vec = @import("vec.zig").Vec;
pub const Rect = @import("rect.zig").Rect;

test {
    _ = @import("vec.zig");
    _ = @import("rect.zig");
}
