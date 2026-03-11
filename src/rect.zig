const std = @import("std");
const Vec = @import("vec.zig").Vec;

pub fn Rect(comptime T: type) type {
    return struct {
        pub const Vec2 = Vec(2, T);
        const Self = @This();

        start: Vec2 = Vec2.ZERO,
        size: Vec2 = Vec2.ZERO,

        pub inline fn initV(start: Vec2, size: Vec2) Self {
            return .{ .start = start, .size = size };
        }

        pub inline fn init(px: T, py: T, sx: T, sy: T) Self {
            return initV(
                Vec2.from(.{ px, py }),
                Vec2.from(.{ sx, sy }),
            );
        }

        pub inline fn fromCenter(pos: Vec2, size: Vec2) Self {
            return .{
                .start = pos.sub(size.mul(0.5)),
                .size = size,
            };
        }

        pub inline fn at(self: Self, x: f32, y: f32) Self {
            var new = self;
            new.start = Vec2.from(.{ x, y });
            return new;
        }

        pub inline fn splat(value: f32) Self {
            return .{ .size = Vec2.splat(value) };
        }

        pub inline fn fromSize(w: f32, h: f32) Self {
            return .{ .size = Vec2.from(.{ w, h }) };
        }

        pub inline fn end(self: Self) Vec2 {
            return self.start.add(self.size);
        }

        pub inline fn tr(self: Self) Vec2 {
            return Vec2.from(.{ self.end().x(), self.start.y() });
        }

        pub inline fn bl(self: Self) Vec2 {
            return Vec2.from(.{ self.start.x(), self.end().y() });
        }

        pub inline fn center(self: Self) Vec2 {
            return self.start.add(self.size.mul(0.5));
        }

        pub inline fn midTop(self: Self) Vec2 {
            return Vec2.from(.{ self.center().x(), self.start.y() });
        }

        pub inline fn midBottom(self: Self) Vec2 {
            return Vec2.from(.{ self.center().x(), self.end().y() });
        }

        pub inline fn midLeft(self: Self) Vec2 {
            return Vec2.from(.{ self.start.x(), self.center().y() });
        }

        pub inline fn midRight(self: Self) Vec2 {
            return Vec2.from(.{ self.end().x(), self.center().y() });
        }

        /// Return [start x, y , size x, y]
        pub inline fn flatten(self: Self) @Vector(4, f32) {
            return .{
                self.start.x(),
                self.start.y(),
                self.size.x(),
                self.size.y(),
            };
        }

        pub inline fn merge(self: Self, r2: Self) Self {
            const new_start = self.start.min(r2.start);
            const new_end = self.end().max(r2.end());
            return Self.initV(new_start, new_end.sub(new_start));
        }

        pub inline fn includePoint(self: Self, point: Vec2) Self {
            const new_start = self.start.min(point);
            const new_end = self.end().max(point);
            return Self.initV(new_start, new_end.sub(new_start));
        }

        pub inline fn intersection(self: Self, r2: Self) ?Self {
            const inter_start = self.start.max(r2.start);
            const inter_end = self.end().min(r2.end());

            // Check if there is actual width and height
            if (@reduce(.And, inter_start.data < inter_end.data)) {
                return Self.initV(inter_start, inter_end.sub(inter_start));
            }
            return null;
        }

        pub inline fn collides(self: Self, r2: Self) bool {
            const s1 = self.start.data;
            const e1 = self.end().data;
            const s2 = r2.start.data;
            const e2 = r2.end().data;

            // Standard AABB collision check using vectors
            return @reduce(.And, s1 <= e2) and @reduce(.And, e1 >= s2);
        }

        pub inline fn contains_p(self: Self, point: Vec2) bool {
            const s = self.start.data;
            const e = self.end().data;
            const p = point.data;
            // Check if p >= s AND p <= e
            return @reduce(.And, p >= s) and @reduce(.And, p <= e);
        }

        pub inline fn contains(self: Self, r2: Self) bool {
            const s1 = self.start.data;
            const e1 = self.end().data;
            const s2 = r2.start.data;
            const e2 = r2.end().data;

            return @reduce(.And, s2 >= s1) and @reduce(.And, e2 <= e1);
        }

        pub inline fn add(self: Self, offset: Vec2) Self {
            return Self.initV(self.start.add(offset), self.size);
        }

        pub inline fn sub(self: Self, offset: Vec2) Self {
            return Self.initV(self.start.sub(offset), self.size);
        }

        pub inline fn expandVec2(self: Self, amount: Vec2) Self {
            // Start moves "out" by the amount (negative direction)
            // Size grows by double the amount (covers both sides)
            return Self.initV(
                self.start.sub(amount),
                self.size.add(amount.mul(2.0)),
            );
        }

        pub inline fn expand(self: Self, amount: f32) Self {
            return self.expandVec2(Vec2.splat(amount));
        }

        pub inline fn shrinkVec2(self: Self, offset: Vec2) Self {
            // Calculate new size: current_size - (offset * 2)
            const new_size_v = self.size.sub(offset.mul(2.0));
            const clamped_size = new_size_v.max(Vec2.ZERO);
            return Self.initV(self.start.add(offset), clamped_size);
        }

        pub inline fn shrink(self: Self, amount: f32) Self {
            // Use your existing splat method for the correct struct initialization
            return self.shrinkVec2(Vec2.splat(amount));
        }

        /// Assumes y-down
        pub inline fn pad(self: Self, top: f32, right: f32, bottom: f32, left: f32) Self {
            return Self.initV(
                self.start.add(Vec2.from(.{ left, top })),
                self.size.sub(Vec2.from(.{ left + right, top + bottom })),
            );
        }

        /// Assumes y-down
        pub inline fn margin(self: Self, top: f32, right: f32, bottom: f32, left: f32) Self {
            return Self.initV(
                self.start.sub(Vec2.from(.{ left, top })),
                self.size.add(Vec2.from(.{ left + right, top + bottom })),
            );
        }

        pub inline fn is_eq(self: Self, r2: Self) bool {
            const epsilon: f32 = 0.0001;
            const eps_v = Vec2.splat(epsilon);

            // Calculate absolute difference for both vectors
            const diff_start = @abs(self.start.data - r2.start.data);
            const diff_size = @abs(self.size.data - r2.size.data);

            // Returns true if all components are within the epsilon range
            return @reduce(.And, diff_start <= eps_v.data) and
                @reduce(.And, diff_size <= eps_v.data);
        }

        pub fn abs(self: Self) Self {
            const s = self.start.data;
            const e = self.end().data;
            const real_start = @min(s, e);
            const real_end = @max(s, e);
            return Self.initV(Vec2.from(real_start), Vec2.from(real_end - real_start));
        }

        pub inline fn closestPoint(self: Self, p: Vec2) Vec2 {
            return p.clamp(self.start, self.end());
        }
    };
}

const Rectf = Rect(f32);

test "Rect: spatial points" {
    const rect = Rectf.init(10.0, 20.0, 100.0, 50.0);

    // end (bottom-right)
    const e = rect.end();
    try std.testing.expectEqual(@as(f32, 110.0), e.x());
    try std.testing.expectEqual(@as(f32, 70.0), e.y());

    // tr (top-right)
    const tr = rect.tr();
    try std.testing.expectEqual(@as(f32, 110.0), tr.x());
    try std.testing.expectEqual(@as(f32, 20.0), tr.y());

    // bl (bottom-left)
    const bl = rect.bl();
    try std.testing.expectEqual(@as(f32, 10.0), bl.x());
    try std.testing.expectEqual(@as(f32, 70.0), bl.y());

    // center
    const c = rect.center();
    // 10 + (100 * 0.5) = 60
    // 20 + (50 * 0.5) = 45
    try std.testing.expectEqual(@as(f32, 60.0), c.x());
    try std.testing.expectEqual(@as(f32, 45.0), c.y());
}

test "Rect: zero and negative size" {
    const r_zero = Rectf.initV(Rectf.Vec2.splat(5), Rectf.Vec2.ZERO);
    try std.testing.expectEqual(r_zero.start.x(), r_zero.center().x());

    const r_neg = Rectf.initV(Rectf.Vec2.ZERO, Rectf.Vec2.splat(-10));
    try std.testing.expectEqual(@as(f32, -10.0), r_neg.end().x());
    try std.testing.expectEqual(@as(f32, -5.0), r_neg.center().x());
}

test "Rectf: merge" {
    const r1 = Rectf.initV(Rectf.Vec2.splat(0), Rectf.Vec2.splat(10));
    const r2 = Rectf.initV(Rectf.Vec2.splat(20), Rectf.Vec2.splat(5));

    const merged = r1.merge(r2);

    // Should start at (0, 0) and end at (25, 25)
    // Size should be (25, 25)
    try std.testing.expectEqual(@as(f32, 0.0), merged.start.x());
    try std.testing.expectEqual(@as(f32, 0.0), merged.start.y());
    try std.testing.expectEqual(@as(f32, 25.0), merged.size.x());
    try std.testing.expectEqual(@as(f32, 25.0), merged.size.y());

    // Test overlapping merge
    const r3 = Rectf.initV(Rectf.Vec2.from(.{ -5, 5 }), Rectf.Vec2.splat(10));
    const merged2 = r1.merge(r3);

    // Min start: (-5, 0), Max end: (10, 15)
    // New size: (15, 15)
    try std.testing.expectEqual(@as(f32, -5.0), merged2.start.x());
    try std.testing.expectEqual(@as(f32, 0.0), merged2.start.y());
    try std.testing.expectEqual(@as(f32, 15.0), merged2.size.x());
    try std.testing.expectEqual(@as(f32, 15.0), merged2.size.y());
}

test "Rectf: intersection" {
    const r1 = Rectf.initV(Rectf.Vec2.splat(0), Rectf.Vec2.splat(10));

    // Case 1: Partial overlap
    const r2 = Rectf.initV(Rectf.Vec2.splat(5), Rectf.Vec2.splat(10));
    if (r1.intersection(r2)) |inter| {
        try std.testing.expectEqual(@as(f32, 5.0), inter.start.x());
        try std.testing.expectEqual(@as(f32, 5.0), inter.start.y());
        try std.testing.expectEqual(@as(f32, 5.0), inter.size.x());
        try std.testing.expectEqual(@as(f32, 5.0), inter.size.y());
    } else {
        return error.ExpectedIntersection;
    }

    // Case 2: No overlap
    const r3 = Rectf.initV(Rectf.Vec2.splat(20), Rectf.Vec2.splat(5));
    try std.testing.expect(r1.intersection(r3) == null);

    // Case 3: One inside another
    const r4 = Rectf.initV(Rectf.Vec2.splat(2), Rectf.Vec2.splat(2));
    if (r1.intersection(r4)) |inter| {
        try std.testing.expectEqual(@as(f32, 2.0), inter.start.x());
        try std.testing.expectEqual(@as(f32, 2.0), inter.size.x());
    } else {
        return error.ExpectedIntersection;
    }

    // Case 4: Touching edges (No area = No intersection)
    const r5 = Rectf.initV(Rectf.Vec2.from(.{ 10, 0 }), Rectf.Vec2.from(.{ 10, 10 }));
    try std.testing.expect(r1.intersection(r5) == null);
}

test "test_rect_intersect" {
    const r1: Rectf = Rectf.splat(10);
    const r2: Rectf = Rectf.splat(10);
    const r3: Rectf = Rectf.splat(8).at(5, 5);
    const r4: Rectf = Rectf.splat(12).at(5, 5);
    const r5: Rectf = Rectf.splat(18).at(11, 11);

    var result = r1.intersection(r2);
    try std.testing.expectEqualDeep(r1, result);

    result = r1.intersection(r3);
    var expected = Rectf.splat(5).at(5, 5);
    try std.testing.expectEqualDeep(expected, result);

    result = r1.intersection(r4);
    expected = Rectf.splat(5).at(5, 5);
    try std.testing.expectEqualDeep(expected, result);

    result = r1.intersection(r5);
    try std.testing.expectEqual(null, result);
}

const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;

test "Rectf: basic intersection" {
    const r1 = Rectf.splat(10);
    const r2 = Rectf.splat(10).at(5, 5);

    const result = r1.intersection(r2);

    try expect(result != null);
    try expect(result.?.is_eq(Rectf.splat(5).at(5, 5)));
}

test "Rectf: one contains another" {
    const big = Rectf.splat(100).at(0, 0);
    const small = Rectf.splat(10).at(20, 20);
    const result = big.intersection(small);

    try expect(result != null);
    // The intersection of a small box inside a big box is the small box itself
    try expect(result.?.is_eq(small));
    try expectEqual(true, big.contains(small));
}

test "Rectf: no intersection (far apart)" {
    const r1 = Rectf.splat(5);
    const r2 = Rectf.splat(10).at(150, 150);

    const result = r1.intersection(r2);

    try expect(result == null);
    try expect(r1.collides(r2) == false);
}

test "Rectf: edge touch (no intersection)" {
    // These boxes touch at x=10, but do not overlap.
    const r1 = Rectf.splat(10);
    const r2 = Rectf.splat(10).at(10, 0);

    const result = r1.intersection(r2);

    try expect(result == null);
    try expect(r1.collides(r2) == true);
}

test "Rectf: collision detection" {
    const r1 = Rectf.splat(10);
    const r2 = Rectf.splat(10).at(9, 9);

    try expect(r1.collides(r2) == true);
    try expect(r2.collides(r1) == true);
}

test "Rectf: flatten" {
    const r1 = Rectf.fromSize(3, 4).at(1, 2);
    const flattened = r1.flatten();

    try expect(flattened[0] == 1);
    try expect(flattened[1] == 2);
    try expect(flattened[2] == 3);
    try expect(flattened[3] == 4);
}

test "Rectf: collides edge cases" {
    // Reference Rectf at (0,0) with size (10,10)
    const a = Rectf.initV(Rectf.Vec2.splat(0), Rectf.Vec2.splat(10));

    // 1. CLEAR COLLISION (Centered)
    const b = Rectf.initV(Rectf.Vec2.splat(5), Rectf.Vec2.splat(10));
    try std.testing.expect(a.collides(b));

    // 2. SEPARATED ON X ONLY (Aligned on Y)
    // Should be false.
    const c = Rectf.initV(Rectf.Vec2.from(.{ 11, 0 }), Rectf.Vec2.from(.{ 10, 10 }));
    try std.testing.expect(!a.collides(c));

    // 3. SEPARATED ON Y ONLY (Aligned on X)
    // Should be false.
    const d = Rectf.initV(Rectf.Vec2.from(.{ 0, 11 }), Rectf.Vec2.from(.{ 10, 10 }));
    try std.testing.expect(!a.collides(d));

    // 4. THE "DANGER ZONE": Separated on X, but Overlapping on Y
    // Rectf E is at (15, 5).
    // X is far away (15 > 10), but Y is inside (5 is between 0 and 10).
    // Should be false.
    const e = Rectf.initV(Rectf.Vec2.from(.{ 15, 5 }), Rectf.Vec2.from(.{ 10, 10 }));
    try std.testing.expect(!a.collides(e));

    // 5. TOUCHING EDGES (Exact)
    // Depending on if you use <= or <, this should be true or false.
    // With your current <= logic, this is TRUE.
    const f = Rectf.initV(Rectf.Vec2.from(.{ 10, 0 }), Rectf.Vec2.from(.{ 10, 10 }));
    try std.testing.expect(a.collides(f));

    // 6. NEGATIVE COORDINATES
    const g = Rectf.initV(Rectf.Vec2.from(.{ -5, -5 }), Rectf.Vec2.from(.{ 10, 10 }));
    try std.testing.expect(a.collides(g));

    const h = Rectf.initV(Rectf.Vec2.from(.{ -10, -10 }), Rectf.Vec2.from(.{ 10, 10 }));
    try std.testing.expect(a.collides(h));
}

test "Rectf: contains_p (point)" {
    const rect = Rectf.initV(Rectf.Vec2.from(.{ 10, 10 }), Rectf.Vec2.from(.{ 20, 20 })); // Bounds: 10,10 to 30,30

    // Inside
    try std.testing.expect(rect.contains_p(Rectf.Vec2.from(.{ 15, 15 })));

    // On the edge (start)
    try std.testing.expect(rect.contains_p(Rectf.Vec2.from(.{ 10, 10 })));

    // On the edge (end)
    try std.testing.expect(rect.contains_p(Rectf.Vec2.from(.{ 30, 30 })));

    // Outside (just barely)
    try std.testing.expect(!rect.contains_p(Rectf.Vec2.from(.{ 9.9, 15 })));
    try std.testing.expect(!rect.contains_p(Rectf.Vec2.from(.{ 15, 30.1 })));
}

test "Rectf: contains (another rect)" {
    const outer = Rectf.initV(Rectf.Vec2.from(.{ 0, 0 }), Rectf.Vec2.from(.{ 100, 100 }));

    // Fully inside
    const inner = Rectf.initV(Rectf.Vec2.from(.{ 10, 10 }), Rectf.Vec2.from(.{ 50, 50 }));
    try std.testing.expect(outer.contains(inner));

    // Identical rects
    try std.testing.expect(outer.contains(outer));

    // Peeking out (partial overlap)
    const peeking = Rectf.initV(Rectf.Vec2.from(.{ 50, 50 }), Rectf.Vec2.from(.{ 60, 60 })); // Ends at 110,110
    try std.testing.expect(!outer.contains(peeking));

    // Completely outside
    const outside = Rectf.initV(Rectf.Vec2.from(.{ 200, 200 }), Rectf.Vec2.from(.{ 10, 10 }));
    try std.testing.expect(!outer.contains(outside));
}

test "Rectf: translate" {
    const rect = Rectf.initV(Rectf.Vec2.from(.{ 10, 20 }), Rectf.Vec2.from(.{ 100, 50 }));
    const offset = Rectf.Vec2.from(.{ 5, -10 });

    const moved = rect.add(offset);

    // Start: (10+5, 20-10) -> (15, 10)
    try std.testing.expectEqual(@as(f32, 15.0), moved.start.x());
    try std.testing.expectEqual(@as(f32, 10.0), moved.start.y());

    // Size should remain exactly the same
    try std.testing.expectEqual(@as(f32, 100.0), moved.size.x());
    try std.testing.expectEqual(@as(f32, 50.0), moved.size.y());

    // Test zero translation
    const stayed = rect.add(Rectf.Vec2.ZERO);
    try std.testing.expectEqual(rect.start.x(), stayed.start.x());
    try std.testing.expectEqual(rect.size.x(), stayed.size.x());
}

test "Rectf: expand and expandVec2" {
    const rect = Rectf.initV(Rectf.Vec2.from(.{ 100, 100 }), Rectf.Vec2.from(.{ 50, 50 }));

    // Case 1: expand (uniform)
    const expanded = rect.expand(10.0);
    // Start: 100 - 10 = 90
    // Size: 50 + (10 * 2) = 70
    try std.testing.expectEqual(@as(f32, 90.0), expanded.start.x());
    try std.testing.expectEqual(@as(f32, 70.0), expanded.size.x());
    // Center should remain (125, 125)
    try std.testing.expectEqual(@as(f32, 125.0), expanded.center().x());
    try std.testing.expectEqual(@as(f32, 125.0), expanded.center().y());

    // Case 2: expandVec2 (non-uniform)
    const amount = Rectf.Vec2.from(.{ 5.0, 20.0 });
    const expanded_v = rect.expandVec2(amount);
    // X: Start 100-5=95, Size 50+10=60
    // Y: Start 100-20=80, Size 50+40=90
    try std.testing.expectEqual(@as(f32, 95.0), expanded_v.start.x());
    try std.testing.expectEqual(@as(f32, 60.0), expanded_v.size.x());
    try std.testing.expectEqual(@as(f32, 80.0), expanded_v.start.y());
    try std.testing.expectEqual(@as(f32, 90.0), expanded_v.size.y());

    // Case 3: Negative expansion (shrinking via expand)
    const shrunk = rect.expand(-5.0);
    // Start: 100 - (-5) = 105
    // Size: 50 + (-10) = 40
    try std.testing.expectEqual(@as(f32, 105.0), shrunk.start.x());
    try std.testing.expectEqual(@as(f32, 40.0), shrunk.size.x());
}

test "Rectf: shrink" {
    const rect = Rectf.initV(Rectf.Vec2.from(.{ 10, 10 }), Rectf.Vec2.from(.{ 100, 100 }));

    // Normal shrink
    const shrunk = rect.shrink(10.0);
    // Start: 10 + 10 = 20
    // Size: 100 - 20 = 80
    try std.testing.expectEqual(@as(f32, 20.0), shrunk.start.x());
    try std.testing.expectEqual(@as(f32, 80.0), shrunk.size.x());

    // Over-shrink (should clamp size to 0,0)
    const tiny = rect.shrink(60.0);
    // 100 - (60 * 2) = -20 -> clamped to 0
    try std.testing.expectEqual(@as(f32, 0.0), tiny.size.x());
    try std.testing.expectEqual(@as(f32, 0.0), tiny.size.y());
}

test "Rectf: shrink & shrinkVec2" {
    const rect = Rectf.initV(Rectf.Vec2.from(.{ 10, 10 }), Rectf.Vec2.from(.{ 100, 100 }));

    // Case 1: Uniform shrink
    const shrunk = rect.shrink(10.0);
    // Start: 10 + 10 = 20
    // Size: 100 - (10 * 2) = 80
    try std.testing.expectEqual(@as(f32, 20.0), shrunk.start.x());
    try std.testing.expectEqual(@as(f32, 80.0), shrunk.size.x());

    // Case 2: Non-uniform shrinkVec2
    const s_vec = rect.shrinkVec2(Rectf.Vec2.from(.{ 5, 20 }));
    // X: 10 + 5 = 15 | 100 - 10 = 90
    // Y: 10 + 20 = 30 | 100 - 40 = 60
    try std.testing.expectEqual(@as(f32, 15.0), s_vec.start.x());
    try std.testing.expectEqual(@as(f32, 90.0), s_vec.size.x());
    try std.testing.expectEqual(@as(f32, 30.0), s_vec.start.y());
    try std.testing.expectEqual(@as(f32, 60.0), s_vec.size.y());

    // Case 3: Over-shrink (Clamping to ZERO)
    const crushed = rect.shrink(60.0);
    // 100 - 120 = -20 -> clamped to 0
    try std.testing.expectEqual(@as(f32, 0.0), crushed.size.x());
    try std.testing.expectEqual(@as(f32, 0.0), crushed.size.y());
    // Start still moves even if size is 0
    try std.testing.expectEqual(@as(f32, 70.0), crushed.start.x());
}

test "Rectf mid-points" {
    // Center is (5, 5)
    const rect = Rectf.initV(Rectf.Vec2.ZERO, Rectf.Vec2.from(.{ 10.0, 10.0 }));

    // Mid Top: (5, 0)
    try std.testing.expectEqual(@Vector(2, f32){ 5.0, 0.0 }, rect.midTop().data);

    // Mid Bottom: (5, 10)
    try std.testing.expectEqual(@Vector(2, f32){ 5.0, 10.0 }, rect.midBottom().data);

    // Mid Left: (0, 5)
    try std.testing.expectEqual(@Vector(2, f32){ 0.0, 5.0 }, rect.midLeft().data);

    // Mid Right: (10, 5)
    try std.testing.expectEqual(@Vector(2, f32){ 10.0, 5.0 }, rect.midRight().data);
}

test "Rectf.includePoint" {
    // 1. Initialize a 10x10 rect starting at (10, 10). End point is (20, 20).
    const rect = Rectf.initV(
        Rectf.Vec2.from(.{ 10.0, 10.0 }),
        Rectf.Vec2.from(.{ 10.0, 10.0 }),
    );

    // 2. Include a point that expands the 'end' (Bottom-Right)
    // Point: (25, 30)
    // New start: min(10, 25) = 10
    // New end: max(20, 30) = 30
    // New size: (25-10, 30-10) = (15, 20)
    const p1 = Rectf.Vec2.from(.{ 25.0, 30.0 });
    const expanded_br = rect.includePoint(p1);

    try std.testing.expectEqual(@as(f32, 10.0), expanded_br.start.x());
    try std.testing.expectEqual(@as(f32, 10.0), expanded_br.start.y());
    try std.testing.expectEqual(@as(f32, 15.0), expanded_br.size.x());
    try std.testing.expectEqual(@as(f32, 20.0), expanded_br.size.y());
    try std.testing.expectEqual(@as(f32, 30.0), expanded_br.end().y());

    // 3. Include a point that expands the 'start' (Top-Left)
    // Point: (0, 5)
    // New start: min(10, 0) = 0, min(10, 5) = 5
    // New size relative to previous end (25, 30): (25-0, 30-5) = (25, 25)
    const p2 = Rectf.Vec2.from(.{ 0.0, 5.0 });
    const expanded_tl = expanded_br.includePoint(p2);

    try std.testing.expectEqual(@as(f32, 0.0), expanded_tl.start.x());
    try std.testing.expectEqual(@as(f32, 5.0), expanded_tl.start.y());
    try std.testing.expectEqual(@as(f32, 25.0), expanded_tl.size.x());
    try std.testing.expectEqual(@as(f32, 25.0), expanded_tl.size.y());

    // 4. Verify a point already inside does not change the Rectf
    const p3 = Rectf.Vec2.from(.{ 12.0, 12.0 });
    const no_change = expanded_tl.includePoint(p3);

    try std.testing.expect(no_change.is_eq(expanded_tl));
}

test "Rectf.abs" {
    // 1. Test a rect with negative size (start at 10, size -20)
    // start = 10, 10 | end = -10, -10
    const neg_rect = Rectf.initV(
        Rectf.Vec2.from(.{ 10.0, 10.0 }),
        Rectf.Vec2.from(.{ -20.0, -20.0 }),
    );

    const abs_rect = neg_rect.abs();

    // After abs: real_start should be -10, real_end 10, size 20
    try std.testing.expectEqual(@as(f32, -10.0), abs_rect.start.x());
    try std.testing.expectEqual(@as(f32, -10.0), abs_rect.start.y());
    try std.testing.expectEqual(@as(f32, 20.0), abs_rect.size.x());
    try std.testing.expectEqual(@as(f32, 20.0), abs_rect.size.y());

    // 2. Test that a already positive rect remains unchanged
    const pos_rect = Rectf.initV(Rectf.Vec2.from(.{ 0.0, 0.0 }), Rectf.Vec2.from(.{ 5.0, 5.0 }));
    try std.testing.expect(pos_rect.abs().is_eq(pos_rect));
}

test "Rectf.closestPoint" {
    const rect = Rectf.initV(
        Rectf.Vec2.from(.{ 0.0, 0.0 }),
        Rectf.Vec2.from(.{ 10.0, 10.0 }),
    );

    // 1. Point outside (Top-Left)
    const p_tl = Rectf.Vec2.from(.{ -5.0, -5.0 });
    const close_tl = rect.closestPoint(p_tl);
    try std.testing.expectEqual(@as(f32, 0.0), close_tl.x());
    try std.testing.expectEqual(@as(f32, 0.0), close_tl.y());

    // 2. Point outside (Bottom-Right)
    const p_br = Rectf.Vec2.from(.{ 15.0, 20.0 });
    const close_br = rect.closestPoint(p_br);
    try std.testing.expectEqual(@as(f32, 10.0), close_br.x());
    try std.testing.expectEqual(@as(f32, 10.0), close_br.y());

    // 3. Point already inside (should return the point itself)
    const p_in = Rectf.Vec2.from(.{ 5.0, 5.0 });
    const close_in = rect.closestPoint(p_in);
    try std.testing.expectEqual(@as(f32, 5.0), close_in.x());
    try std.testing.expectEqual(@as(f32, 5.0), close_in.y());

    // 4. Point on an edge
    const p_edge = Rectf.Vec2.from(.{ 10.0, 5.0 });
    const close_edge = rect.closestPoint(p_edge);
    try std.testing.expectEqual(@as(f32, 10.0), close_edge.x());
    try std.testing.expectEqual(@as(f32, 5.0), close_edge.y());
}

test "Rectf.margin (Outward Expansion)" {
    // 1. Create a 100x100 rect starting at (50, 50)
    // End is (150, 150)
    const rect = Rectf.initV(
        Rectf.Vec2.from(.{ 50.0, 50.0 }),
        Rectf.Vec2.from(.{ 100.0, 100.0 }),
    );

    // 2. Apply outward padding (margins)
    // top: 10, right: 20, bottom: 30, left: 40
    const padded = rect.margin(10.0, 20.0, 30.0, 40.0);

    // New start moves "left" and "up":
    // x: 50 - 40 (left) = 10.0
    // y: 50 - 10 (top)  = 40.0
    try std.testing.expectEqual(@as(f32, 10.0), padded.start.x());
    try std.testing.expectEqual(@as(f32, 40.0), padded.start.y());

    // New size grows:
    // width:  100 + (40 + 20) = 160.0
    // height: 100 + (10 + 30) = 140.0
    try std.testing.expectEqual(@as(f32, 160.0), padded.size.x());
    try std.testing.expectEqual(@as(f32, 140.0), padded.size.y());

    // 3. Verify the new 'end' point
    // x: 150 + 20 (right) = 170.0
    // y: 150 + 30 (bottom) = 180.0
    try std.testing.expectEqual(@as(f32, 170.0), padded.end().x());
    try std.testing.expectEqual(@as(f32, 180.0), padded.end().y());
}

test "Rectf.pad (inward Expansion)" {
    const rect = Rectf.initV(
        Rectf.Vec2.ZERO,
        Rectf.Vec2.from(.{ 100.0, 100.0 }),
    );

    // top: 10, right: 20, bottom: 30, left: 40
    const padded = rect.pad(10.0, 20.0, 30.0, 40.0);

    try std.testing.expectEqual(@as(f32, 40.0), padded.start.x());
    try std.testing.expectEqual(@as(f32, 10.0), padded.start.y());

    try std.testing.expectEqual(@as(f32, 40.0), padded.size.x());
    try std.testing.expectEqual(@as(f32, 60.0), padded.size.y());

    try std.testing.expectEqual(@as(f32, 80.0), padded.end().x());
    try std.testing.expectEqual(@as(f32, 70.0), padded.end().y());
}
