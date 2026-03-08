const std = @import("std");

pub fn Vec(comptime size: comptime_int, comptime T: type) type {
    if (@typeInfo(T) != .float) @compileError(
        "Vec only supports floating point types, found " ++ @typeName(T),
    );
    return struct {
        const Self = @This();
        pub const V = @Vector(size, T);
        data: V,

        pub const ZERO = splat(0);

        // Accessors
        pub inline fn x(self: Self) T {
            return self.data[0];
        }

        pub inline fn y(self: Self) T {
            comptime if (size < 2) @compileError("Vector too small for .y()");
            return self.data[1];
        }

        pub inline fn z(self: Self) T {
            comptime if (size < 3) @compileError("Vector too small for .z()");
            return self.data[2];
        }

        pub inline fn w(self: Self) T {
            comptime if (size < 4) @compileError("Vector too small for .z()");
            return self.data[3];
        }

        pub fn swizzle(self: Self, comptime mask: []const u8) Vec(mask.len, T) {
            const indices: [mask.len]i32 = comptime blk: {
                var res: [mask.len]i32 = undefined;
                for (mask, 0..) |char, i| {
                    res[i] = switch (char) {
                        'x', 'r', 's' => 0,
                        'y', 'g', 't' => 1,
                        'z', 'b', 'p' => 2,
                        'w', 'a', 'q' => 3,
                        else => @compileError("Invalid swizzle component"),
                    };
                    if (res[i] >= size) @compileError("Swizzle index out of bounds");
                }
                break :blk res;
            };

            return Vec(mask.len, T).from(@shuffle(T, self.data, undefined, indices));
        }

        // Constructors
        pub inline fn splat(other: T) Self {
            return .{ .data = @splat(other) };
        }

        pub inline fn from(v: V) Self {
            return .{ .data = v };
        }

        // Base Methods
        pub inline fn add(self: Self, other: Self) Self {
            return from(self.data + other.data);
        }

        pub inline fn sub(self: Self, other: Self) Self {
            return from(self.data - other.data);
        }

        pub inline fn mul(self: Self, s: T) Self {
            return from(self.data * @as(V, @splat(s)));
        }

        pub inline fn div(self: Self, s: T) Self {
            return from(self.data / @as(V, @splat(s)));
        }

        pub inline fn abs(self: Self) Self {
            return from(@abs(self.data));
        }

        pub inline fn floor(self: Self) Self {
            return from(@floor(self.data));
        }

        pub inline fn round(self: Self) Self {
            return from(@round(self.data));
        }

        pub fn approxEq(self: Self, other: Self, epsilon: T) bool {
            return self.distanceSq(other) < (epsilon * epsilon);
        }

        pub inline fn dot(self: Self, other: Self) T {
            return @reduce(.Add, self.data * other.data);
        }

        pub inline fn lengthSq(self: Self) T {
            return self.dot(self);
        }

        pub inline fn length(self: Self) T {
            return @sqrt(self.lengthSq());
        }

        pub inline fn distanceSq(self: Self, other: Self) T {
            return other.sub(self).lengthSq();
        }

        pub inline fn distance(self: Self, other: Self) T {
            return @sqrt(self.distanceSq(other));
        }

        pub fn normalize(self: Self) Self {
            const lsq = self.lengthSq();
            if (lsq < 0.000001) return ZERO;
            const inv_len: V = @splat(1.0 / @sqrt(lsq));
            return from(self.data * inv_len);
        }

        pub inline fn project(self: Self, onto: Self) Self {
            const d = onto.dot(onto);
            if (d < 0.000001) return ZERO;
            return onto.mul(self.dot(onto) / d);
        }

        pub inline fn reject(self: Self, onto: Self) Self {
            return self.sub(self.project(onto));
        }

        pub inline fn clamp(self: Self, min_v: Self, max_v: Self) Self {
            return from(@max(min_v.data, @min(self.data, max_v.data)));
        }

        pub inline fn max(self: Self, other: Self) Self {
            return from(@max(self.data, other.data));
        }

        pub inline fn min(self: Self, other: Self) Self {
            return from(@min(self.data, other.data));
        }

        pub inline fn lerp(self: Self, target: Self, t: T) Self {
            const t_v: V = @splat(t);
            return from(self.data + (target.data - self.data) * t_v);
        }

        pub inline fn cross(self: Self, other: Self) if (size == 3) Self else T {
            if (size == 3) {
                const a = self.data;
                const b = other.data;
                // Indices for (y, z, x)
                const s1 = [_]i32{ 1, 2, 0 };
                // Indices for (z, x, y)
                const s2 = [_]i32{ 2, 0, 1 };

                const res = (@shuffle(T, a, undefined, s1) * @shuffle(T, b, undefined, s2)) -
                    (@shuffle(T, a, undefined, s2) * @shuffle(T, b, undefined, s1));
                return from(res);
            } else if (size == 2) {
                return self.x() * other.y() - self.y() * other.x();
            } else {
                @compileError("Cross product not defined for this size");
            }
        }

        pub fn moveTowards(self: Self, target: Self, max_distance: T) Self {
            const diff = target.sub(self);
            const dist_sq = diff.lengthSq();
            if (dist_sq == 0 or (max_distance >= 0 and dist_sq <= max_distance * max_distance)) {
                return target;
            }
            return self.add(diff.div(@sqrt(dist_sq)).mul(max_distance));
        }

        pub inline fn isWithinDistance(self: Self, other: Self, dist: T) bool {
            return self.distanceSq(other) <= (dist * dist);
        }

        pub inline fn reflect(self: Self, normal: Self) Self {
            // formula: self - 2 * (self dot normal) * normal
            const factor = self.dot(normal) * 2.0;
            return self.sub(normal.mul(factor));
        }

        // 2d  math
        pub fn rotate_2d(self: Self, angle: T) Self {
            comptime if (size != 2) @compileError("Only for 2d");
            const cos = std.math.cos(angle);
            const sin = std.math.sin(angle);
            return .{ .data = .{
                self.data[0] * cos - self.data[1] * sin,
                self.data[0] * sin + self.data[1] * cos,
            } };
        }

        pub fn rotateAround_2d(self: Self, pivot: Self, angle: T) Self {
            comptime if (size != 2) @compileError("Only for 2d");
            const shifted = self.sub(pivot);
            const rotated = shifted.rotate_2d(angle);
            return rotated.add(pivot);
        }

        pub fn rotate90_2d(self: Self) Self {
            comptime if (size != 2) @compileError("Only for 2d");
            return .{ .data = .{ -self.data[1], self.data[0] } };
        }

        pub inline fn angleBetween_2d(self: Self, b: Self) T {
            comptime if (size != 2) @compileError("Only for 2d");
            const diff = b.data - self.data;
            return std.math.atan2(diff[1], diff[0]);
        }

        // 3d Math
        pub fn rotate_3d(self: Self, axis: Self, angle: T) Self {
            comptime if (size != 3) @compileError("rotate_3d is only for 3D vectors");

            // Normalize axis to ensure rotation doesn't scale the vector
            const k = axis.normalize();
            const cos_theta = @cos(angle);
            const sin_theta = @sin(angle);

            // Rodrigues' formula:
            // v_rot = v*cos(θ) + (k x v)*sin(θ) + k*(k · v)*(1 - cos(θ))

            const term1 = self.mul(cos_theta);
            const term2 = k.cross(self).mul(sin_theta);
            const term3 = k.mul(k.dot(self) * (1.0 - cos_theta));

            return term1.add(term2).add(term3);
        }
    };
}

const Vec2 = Vec(2, f32);
const Vec3 = Vec(3, f32);

test "vec." {
    const vec3 = Vec3.splat(1);
    try std.testing.expectEqual(1, vec3.x());
    try std.testing.expectEqual(1, vec3.x());
    try std.testing.expectEqual(1, vec3.x());
}

test "Vec2: add and sub" {
    const v1 = Vec2.from(.{ 10.0, 5.0 });
    const v2 = Vec2.from(.{ 2.0, 3.0 });

    // Test addition
    const sum = v1.add(v2);
    try std.testing.expectEqual(12.0, sum.x());
    try std.testing.expectEqual(8.0, sum.y());

    // Test subtraction
    const diff = v1.sub(v2);
    try std.testing.expectEqual(8.0, diff.x());
    try std.testing.expectEqual(2.0, diff.y());

    // Test negative results
    const v3 = Vec2.from(.{ 0.0, 0.0 });
    const result = v3.sub(v2);
    try std.testing.expectEqual(-2.0, result.x());
    try std.testing.expectEqual(-3.0, result.y());
}

test "Vec2: dot, lengthSq, and length" {
    const v = Vec2.from(.{ 3.0, 4.0 });
    const v2 = Vec2.from(.{ 2.0, 1.0 });

    // Test dot product: (3*2) + (4*1) = 6 + 4 = 10
    try std.testing.expectEqual(@as(f32, 10.0), v.dot(v2));

    // Test lengthSq: (3*3) + (4*4) = 9 + 16 = 25
    try std.testing.expectEqual(@as(f32, 25.0), v.lengthSq());

    // Test length: sqrt(25) = 5
    try std.testing.expectEqual(@as(f32, 5.0), v.length());

    // Test zero vector
    const zero = Vec2.from(.{ 0.0, 0.0 });
    try std.testing.expectEqual(@as(f32, 0.0), zero.length());
}

test "Vec2: distance and distanceSq" {
    const p1 = Vec2.from(.{ 1.0, 1.0 });
    const p2 = Vec2.from(.{ 4.0, 5.0 });

    // Delta X = 3, Delta Y = 4
    // distanceSq = 3^2 + 4^2 = 9 + 16 = 25
    try std.testing.expectEqual(@as(f32, 25.0), p1.distanceSq(p2));

    // distance = sqrt(25) = 5
    try std.testing.expectEqual(@as(f32, 5.0), p1.distance(p2));

    // Test symmetry (distance from A to B should equal B to A)
    try std.testing.expectEqual(p1.distance(p2), p2.distance(p1));
}

test "rotate - 90 degrees counter-clockwise" {
    const v = Vec2.from(.{ 1.0, 0.0 });

    // 90 degrees in radians
    const angle = std.math.pi / 2.0;

    const rotated = v.rotate_2d(angle);

    // After 90 deg CCW, (1, 0) should be (0, 1)
    const expected = Vec2.from(.{ 0.0, 1.0 });
    const epsilon = 0.0001;

    try std.testing.expectApproxEqAbs(expected.x(), rotated.x(), epsilon);
    try std.testing.expectApproxEqAbs(expected.y(), rotated.y(), epsilon);
}

test "rotate - 180 degrees" {
    const v = Vec2.from(.{ 10.0, 5.0 });
    const angle = std.math.pi;

    const rotated = v.rotate_2d(angle);

    // After 180 deg, vector should be inverted
    const expected = Vec2.from(.{ -10.0, -5.0 });
    const epsilon = 0.0001;

    try std.testing.expectApproxEqAbs(expected.x(), rotated.x(), epsilon);
    try std.testing.expectApproxEqAbs(expected.y(), rotated.y(), epsilon);
}

test "rotate - full circle (360)" {
    const v = Vec2.from(.{ 1.23, 4.56 });
    const angle = std.math.pi * 2.0;

    const rotated = v.rotate_2d(angle);

    // Should be back where it started
    try std.testing.expectApproxEqAbs(v.x(), rotated.x(), 0.0001);
    try std.testing.expectApproxEqAbs(v.y(), rotated.y(), 0.0001);
}

test "rotate 90" {
    const v = Vec2.from(.{ 0, 1 });
    const rotated = v.rotate90_2d();

    // Should be back where it started
    try std.testing.expectApproxEqAbs(-1, rotated.x(), 0.0001);
    try std.testing.expectApproxEqAbs(0, rotated.y(), 0.0001);
    const rotated_again = rotated.rotate90_2d();
    try std.testing.expectApproxEqAbs(0, rotated_again.x(), 0.0001);
    try std.testing.expectApproxEqAbs(-1, rotated_again.y(), 0.0001);
}

test "rotate around" {
    const v = Vec2.from(.{ 0, 1 });
    const angle = std.math.pi;
    const rotated = v.rotateAround_2d(Vec2.splat(1), angle);

    // Should be back where it started
    try std.testing.expectApproxEqAbs(2, rotated.x(), 0.0001);
    try std.testing.expectApproxEqAbs(1, rotated.y(), 0.0001);
}

test "normalize - unit length and zero vector" {
    // 1. Test standard normalization: (3, 4) has length 5, so normalized is (3/5, 4/5)
    const v1 = Vec2.from(.{ 3.0, 4.0 });
    const normalized1 = v1.normalize();

    const expected_x: f32 = 0.6;
    const expected_y: f32 = 0.8;
    const epsilon = 0.0001;

    try std.testing.expectApproxEqAbs(expected_x, normalized1.x(), epsilon);
    try std.testing.expectApproxEqAbs(expected_y, normalized1.y(), epsilon);

    // Verify the resulting length is actually 1.0
    try std.testing.expectApproxEqAbs(@as(f32, 1.0), @sqrt(normalized1.lengthSq()), epsilon);

    // 2. Test zero vector: Should return itself (0, 0) to avoid NaN
    const v_zero = Vec2.ZERO;
    const normalized_zero = v_zero.normalize();

    try std.testing.expectEqual(@as(f32, 0.0), normalized_zero.x());
    try std.testing.expectEqual(@as(f32, 0.0), normalized_zero.y());
}

test "Vec2: angleBetween (Y-Down)" {
    const origin = Vec2.from(.{ 0.0, 0.0 });
    const tolerance = 0.000001;

    // Right: 0 radians
    const right = Vec2.from(.{ 1.0, 0.0 });
    try std.testing.expectApproxEqAbs(
        @as(f32, 0.0),
        origin.angleBetween_2d(right),
        tolerance,
    );

    // Down: π/2 radians (90 degrees) - because Y increases downwards
    const down = Vec2.from(.{ 0.0, 1.0 });
    try std.testing.expectApproxEqAbs(
        @as(f32, std.math.pi / 2.0),
        origin.angleBetween_2d(down),
        tolerance,
    );

    // Up: -π/2 radians (-90 degrees) - because Y decreases upwards
    const up = Vec2.from(.{ 0.0, -1.0 });
    try std.testing.expectApproxEqAbs(
        @as(f32, -std.math.pi / 2.0),
        origin.angleBetween_2d(up),
        tolerance,
    );

    // Left: π radians (180 degrees)
    const left = Vec2.from(.{ -1.0, 0.0 });
    try std.testing.expectApproxEqAbs(
        @as(f32, std.math.pi),
        origin.angleBetween_2d(left),
        tolerance,
    );
}

test "Vec2: clamp, max, and min" {
    const v = Vec2.from(.{ 10.0, -5.0 });
    const low = Vec2.from(.{ 0.0, 0.0 });
    const high = Vec2.from(.{ 5.0, 5.0 });

    // Test clamp:
    // X: 10.0 clamped between 0 and 5 -> 5.0
    // Y: -5.0 clamped between 0 and 5 -> 0.0
    const clamped = v.clamp(low, high);
    try std.testing.expectEqual(@as(f32, 5.0), clamped.x());
    try std.testing.expectEqual(@as(f32, 0.0), clamped.y());

    // Test max: Takes the highest X and highest Y from both
    const a = Vec2.from(.{ 10.0, 2.0 });
    const b = Vec2.from(.{ 3.0, 8.0 });
    const max_v = a.max(b);
    try std.testing.expectEqual(@as(f32, 10.0), max_v.x());
    try std.testing.expectEqual(@as(f32, 8.0), max_v.y());

    // Test min: Takes the lowest X and lowest Y from both
    const min_v = a.min(b);
    try std.testing.expectEqual(@as(f32, 3.0), min_v.x());
    try std.testing.expectEqual(@as(f32, 2.0), min_v.y());
}

test "Vec2: lerp" {
    const start = Vec2.from(.{ 0.0, 10.0 });
    const end = Vec2.from(.{ 10.0, 20.0 });
    const tolerance = 0.000001;

    // Test t = 0.0 (Should be start)
    const at_zero = start.lerp(end, 0.0);
    try std.testing.expectEqual(start.x(), at_zero.x());
    try std.testing.expectEqual(start.y(), at_zero.y());

    // Test t = 0.5 (Should be midpoint: 5.0, 15.0)
    const mid = start.lerp(end, 0.5);
    try std.testing.expectApproxEqAbs(@as(f32, 5.0), mid.x(), tolerance);
    try std.testing.expectApproxEqAbs(@as(f32, 15.0), mid.y(), tolerance);

    // Test t = 1.0 (Should be end)
    const at_one = start.lerp(end, 1.0);
    try std.testing.expectEqual(end.x(), at_one.x());
    try std.testing.expectEqual(end.y(), at_one.y());

    // Test t = 0.25
    const quarter = start.lerp(end, 0.25);
    try std.testing.expectApproxEqAbs(@as(f32, 2.5), quarter.x(), tolerance);
    try std.testing.expectApproxEqAbs(@as(f32, 12.5), quarter.y(), tolerance);
}

test "Vec2: Rotation and Angles (Y-up)" {
    const right = Vec2.from(.{ 1.0, 0.0 });
    const tolerance = 0.000001;

    // rotate90: (1, 0) -> (0, 1) [Up]
    const up = right.rotate90_2d();
    try std.testing.expectEqual(@as(f32, 0.0), up.x());
    try std.testing.expectEqual(@as(f32, 1.0), up.y());

    // rotate CCW: (1, 0) rotated by 90 deg (π/2) -> (0, 1) [Up]
    const rotated_up = right.rotate_2d(std.math.pi / 2.0);
    try std.testing.expectApproxEqAbs(@as(f32, 0.0), rotated_up.x(), tolerance);
    try std.testing.expectApproxEqAbs(@as(f32, 1.0), rotated_up.y(), tolerance);

    // angleBetween: Origin to (0, 1) should be 90 deg (π/2)
    const origin = Vec2.from(.{ 0.0, 0.0 });
    try std.testing.expectApproxEqAbs(@as(f32, std.math.pi / 2.0), origin.angleBetween_2d(up), tolerance);

    // rotateAround: Rotate (2, 0) around (1, 0) by 180 deg (π) -> (0, 0)
    const p = Vec2.from(.{ 2.0, 0.0 });
    const pivot = Vec2.from(.{ 1.0, 0.0 });
    const flipped = p.rotateAround_2d(pivot, std.math.pi);
    try std.testing.expectApproxEqAbs(@as(f32, 0.0), flipped.x(), tolerance);
    try std.testing.expectApproxEqAbs(@as(f32, 0.0), flipped.y(), tolerance);
}

test "Vec2: mul and div" {
    const v = Vec2.from(.{ 4.0, -2.0 });
    const tolerance = 0.000001;

    // Test multiplication: (4 * 2.5, -2 * 2.5) = (10, -5)
    const scaled = v.mul(2.5);
    try std.testing.expectEqual(@as(f32, 10.0), scaled.x());
    try std.testing.expectEqual(@as(f32, -5.0), scaled.y());

    // Test division: (4 / 2, -2 / 2) = (2, -1)
    const halved = v.div(2.0);
    try std.testing.expectEqual(@as(f32, 2.0), halved.x());
    try std.testing.expectEqual(@as(f32, -1.0), halved.y());

    // Test precision with fractional division
    const thirded = v.div(3.0);
    try std.testing.expectApproxEqAbs(@as(f32, 1.333333), thirded.x(), tolerance);
    try std.testing.expectApproxEqAbs(@as(f32, -0.666666), thirded.y(), tolerance);
}

test "Vec2: moveTowards" {
    const start = Vec2.from(.{ 0.0, 0.0 });
    const target = Vec2.from(.{ 10.0, 0.0 });
    const tolerance = 0.000001;

    // 1. Partial move: Move 3 units toward (10, 0)
    const partial = start.moveTowards(target, 3.0);
    try std.testing.expectApproxEqAbs(@as(f32, 3.0), partial.x(), tolerance);
    try std.testing.expectApproxEqAbs(@as(f32, 0.0), partial.y(), tolerance);

    // 2. Reach target: Move 15 units toward (10, 0) - should cap at 10
    const reached = start.moveTowards(target, 15.0);
    try std.testing.expectEqual(@as(f32, 10.0), reached.x());
    try std.testing.expectEqual(@as(f32, 0.0), reached.y());

    // 3. Diagonal move: Move 5 units toward (3, 4)
    // The distance is 5, so moving 5 should land exactly on (3, 4)
    const diag_target = Vec2.from(.{ 3.0, 4.0 });
    const diag_move = start.moveTowards(diag_target, 5.0);
    try std.testing.expectApproxEqAbs(@as(f32, 3.0), diag_move.x(), tolerance);
    try std.testing.expectApproxEqAbs(@as(f32, 4.0), diag_move.y(), tolerance);

    // 4. Already there
    const stayed = target.moveTowards(target, 5.0);
    try std.testing.expectEqual(target.x(), stayed.x());
    try std.testing.expectEqual(target.y(), stayed.y());
}

test "Vec2: isWithinDistance" {
    const p1 = Vec2.from(.{ 0.0, 0.0 });
    const p2 = Vec2.from(.{ 3.0, 4.0 }); // Distance is exactly 5}.0

    // 1. Inside the radius (5.1 > 5.0)
    try std.testing.expect(p1.isWithinDistance(p2, 5.1));

    // 2. Exactly on the boundary (5.0 == 5.0)
    try std.testing.expect(p1.isWithinDistance(p2, 5.0));

    // 3. Outside the radius (4.9 < 5.0)
    try std.testing.expect(!p1.isWithinDistance(p2, 4.9));

    // 4. Test with a different origin
    const p3 = Vec2.from(.{ 10.0, 10.0 });
    const p4 = Vec2.from(.{ 11.0, 10.0 }); // Distance is 1}.0
    try std.testing.expect(p3.isWithinDistance(p4, 1.5));
    try std.testing.expect(!p3.isWithinDistance(p4, 0.5));
}

test "Vec cross product 2D vs 3D" {

    // Test 2D: Returns a scalar (T)
    const v2a = Vec2.from(.{ 1.0, 0.0 });
    const v2b = Vec2.from(.{ 0.0, 1.0 });
    const result2d = v2a.cross(v2b);

    try std.testing.expectApproxEqAbs(1.0, result2d, 0.0001);

    // Test 3D: Returns a vector (Vec3)
    const v3a = Vec3.from(.{ 1.0, 0.0, 0.0 }); // Right
    const v3b = Vec3.from(.{ 0.0, 1.0, 0.0 }); // Up
    const result3d = v3a.cross(v3b); // Forward (Z)

    try std.testing.expect(@TypeOf(result3d) == Vec3);
    try std.testing.expectApproxEqAbs(0.0, result3d.x(), 0.0001);
    try std.testing.expectApproxEqAbs(0.0, result3d.y(), 0.0001);
    try std.testing.expectApproxEqAbs(1.0, result3d.z(), 0.0001);
}

test "Vec2: cross product" {
    const right = Vec2.from(.{ 1.0, 0.0 });
    const up = Vec2.from(.{ 0.0, 1.0 });

    // Right cross Up should be 1.0 (Positive in Y-up)
    try std.testing.expectEqual(@as(f32, 1.0), right.cross(up));

    // Up cross Right should be -1.0
    try std.testing.expectEqual(@as(f32, -1.0), up.cross(right));

    // Parallel vectors should be 0.0
    try std.testing.expectEqual(@as(f32, 0.0), right.cross(right));
}
test "Vec2: reflect" {
    const tolerance = 0.000001;

    // 1. Bouncing off a floor (Normal is UP: 0, 1)
    // Incoming: (1, -1) [Moving Right and Down]
    // Expected: (1, 1)  [Moving Right and Up]
    const incoming_floor = Vec2.from(.{ 1.0, -1.0 });
    const floor_normal = Vec2.from(.{ 0.0, 1.0 });
    const reflected_floor = incoming_floor.reflect(floor_normal);

    try std.testing.expectApproxEqAbs(@as(f32, 1.0), reflected_floor.x(), tolerance);
    try std.testing.expectApproxEqAbs(@as(f32, 1.0), reflected_floor.y(), tolerance);

    // 2. Bouncing off a wall (Normal is LEFT: -1, 0)
    // Incoming: (1, 0) [Moving straight Right]
    // Expected: (-1, 0) [Moving straight Left]
    const incoming_wall = Vec2.from(.{ 1.0, 0.0 });
    const wall_normal = Vec2.from(.{ -1.0, 0.0 });
    const reflected_wall = incoming_wall.reflect(wall_normal);

    try std.testing.expectApproxEqAbs(@as(f32, -1.0), reflected_wall.x(), tolerance);
    try std.testing.expectApproxEqAbs(@as(f32, 0.0), reflected_wall.y(), tolerance);
}

test "Vec rotation 3D" {
    const pi = std.math.pi;

    const v = Vec3.from(.{ 1.0, 0.0, 0.0 }); // Pointing Right (X)
    const axis = Vec3.from(.{ 0.0, 0.0, 1.0 }); // Rotating around Z

    const rotated = v.rotate_3d(axis, pi / 2.0);

    // Should be approx { 0.0, 1.0, 0.0 } (Pointing Up / Y)
    try std.testing.expectApproxEqAbs(0.0, rotated.x(), 0.0001);
    try std.testing.expectApproxEqAbs(1.0, rotated.y(), 0.0001);
    try std.testing.expectApproxEqAbs(0.0, rotated.z(), 0.0001);
}

test "vec.swizle" {
    const v3 = Vec(3, f32).from(.{ 1.0, 2.0, 3.0 });
    const v2 = v3.swizzle("xy");
    const v4 = v3.swizzle("yz");
    try std.testing.expectEqual(Vec2.from(.{ 1.0, 2.0 }), v2);
    try std.testing.expectEqual(Vec2.from(.{ 2.0, 3.0 }), v4);
}
