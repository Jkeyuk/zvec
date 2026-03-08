const std = @import("std");
const Vec = @import("vec.zig").Vec;

const Vec2 = Vec(2, f32);
const V2 = Vec2.splat(2.0);

pub const Rect = struct {
    const Self = @This();

    start: Vec2 = Vec2.ZERO,
    size: Vec2 = Vec2.ZERO,

    pub inline fn init(start: Vec2, size: Vec2) Self {
        return .{ .start = start, .size = size };
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
        return Vec2.from(self.center().x(), self.start.y());
    }

    pub inline fn midBottom(self: Self) Vec2 {
        return Vec2.from(self.center().x(), self.end().y());
    }

    pub inline fn midLeft(self: Self) Vec2 {
        return Vec2.from(self.start.x(), self.center().y());
    }

    pub inline fn midRight(self: Self) Vec2 {
        return Vec2.from(self.end().x(), self.center().y());
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
        return Self.init(new_start, new_end.sub(new_start));
    }

    pub inline fn intersection(self: Self, r2: Self) ?Self {
        const inter_start = self.start.max(r2.start);
        const inter_end = self.end().min(r2.end());

        // Check if there is actual width and height
        if (@reduce(.And, inter_start.data < inter_end.data)) {
            return Self.init(inter_start, inter_end.sub(inter_start));
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

    pub inline fn translate(self: Self, offset: Vec2) Self {
        return Self.init(self.start.add(offset), self.size);
    }

    pub inline fn expandVec2(self: Self, amount: Vec2) Self {
        // Start moves "out" by the amount (negative direction)
        // Size grows by double the amount (covers both sides)
        return Self.init(
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
        return Self.init(self.start.add(offset), clamped_size);
    }

    pub inline fn shrink(self: Self, amount: f32) Self {
        // Use your existing splat method for the correct struct initialization
        return self.shrinkVec2(Vec2.splat(amount));
    }

    pub inline fn pad(self: Self, top: f32, right: f32, bottom: f32, left: f32) Self {
        return Self.init(
            self.start.add(Vec2.from(left, top)),
            self.size.sub(Vec2.from(left + right, top + bottom)),
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
        return Self.init(Vec2.from_v2(real_start), Vec2.from_v2(real_end - real_start));
    }

    pub inline fn closestPoint(self: Self, p: Vec2) Vec2 {
        return p.clamp(self.start, self.end());
    }
};

test "Rect: spatial points" {
    const rect = Rect.init(
        Vec2.from(.{ 10.0, 20.0 }),
        Vec2.from(.{ 100.0, 50.0 }),
    );

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
    const r_zero = Rect.init(Vec2.splat(5), Vec2.ZERO);
    try std.testing.expectEqual(r_zero.start.x(), r_zero.center().x());

    const r_neg = Rect.init(Vec2.ZERO, Vec2.splat(-10));
    try std.testing.expectEqual(@as(f32, -10.0), r_neg.end().x());
    try std.testing.expectEqual(@as(f32, -5.0), r_neg.center().x());
}

test "Rect: merge" {
    const r1 = Rect.init(Vec2.splat(0), Vec2.splat(10));
    const r2 = Rect.init(Vec2.splat(20), Vec2.splat(5));

    const merged = r1.merge(r2);

    // Should start at (0, 0) and end at (25, 25)
    // Size should be (25, 25)
    try std.testing.expectEqual(@as(f32, 0.0), merged.start.x());
    try std.testing.expectEqual(@as(f32, 0.0), merged.start.y());
    try std.testing.expectEqual(@as(f32, 25.0), merged.size.x());
    try std.testing.expectEqual(@as(f32, 25.0), merged.size.y());

    // Test overlapping merge
    const r3 = Rect.init(Vec2.from(.{ -5, 5 }), Vec2.splat(10));
    const merged2 = r1.merge(r3);

    // Min start: (-5, 0), Max end: (10, 15)
    // New size: (15, 15)
    try std.testing.expectEqual(@as(f32, -5.0), merged2.start.x());
    try std.testing.expectEqual(@as(f32, 0.0), merged2.start.y());
    try std.testing.expectEqual(@as(f32, 15.0), merged2.size.x());
    try std.testing.expectEqual(@as(f32, 15.0), merged2.size.y());
}

test "Rect: intersection" {
    const r1 = Rect.init(Vec2.splat(0), Vec2.splat(10));

    // Case 1: Partial overlap
    const r2 = Rect.init(Vec2.splat(5), Vec2.splat(10));
    if (r1.intersection(r2)) |inter| {
        try std.testing.expectEqual(@as(f32, 5.0), inter.start.x());
        try std.testing.expectEqual(@as(f32, 5.0), inter.start.y());
        try std.testing.expectEqual(@as(f32, 5.0), inter.size.x());
        try std.testing.expectEqual(@as(f32, 5.0), inter.size.y());
    } else {
        return error.ExpectedIntersection;
    }

    // Case 2: No overlap
    const r3 = Rect.init(Vec2.splat(20), Vec2.splat(5));
    try std.testing.expect(r1.intersection(r3) == null);

    // Case 3: One inside another
    const r4 = Rect.init(Vec2.splat(2), Vec2.splat(2));
    if (r1.intersection(r4)) |inter| {
        try std.testing.expectEqual(@as(f32, 2.0), inter.start.x());
        try std.testing.expectEqual(@as(f32, 2.0), inter.size.x());
    } else {
        return error.ExpectedIntersection;
    }

    // Case 4: Touching edges (No area = No intersection)
    const r5 = Rect.init(Vec2.from(.{ 10, 0 }), Vec2.from(.{ 10, 10 }));
    try std.testing.expect(r1.intersection(r5) == null);
}

test "test_rect_intersect" {
    const r1: Rect = Rect.splat(10);
    const r2: Rect = Rect.splat(10);
    const r3: Rect = Rect.splat(8).at(5, 5);
    const r4: Rect = Rect.splat(12).at(5, 5);
    const r5: Rect = Rect.splat(18).at(11, 11);

    var result = r1.intersection(r2);
    try std.testing.expectEqualDeep(r1, result);

    result = r1.intersection(r3);
    var expected = Rect.splat(5).at(5, 5);
    try std.testing.expectEqualDeep(expected, result);

    result = r1.intersection(r4);
    expected = Rect.splat(5).at(5, 5);
    try std.testing.expectEqualDeep(expected, result);

    result = r1.intersection(r5);
    try std.testing.expectEqual(null, result);
}

const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;

test "Rect: basic intersection" {
    const r1 = Rect.splat(10);
    const r2 = Rect.splat(10).at(5, 5);

    const result = r1.intersection(r2);

    try expect(result != null);
    try expect(result.?.is_eq(Rect.splat(5).at(5, 5)));
}

test "Rect: one contains another" {
    const big = Rect.splat(100).at(0, 0);
    const small = Rect.splat(10).at(20, 20);
    const result = big.intersection(small);

    try expect(result != null);
    // The intersection of a small box inside a big box is the small box itself
    try expect(result.?.is_eq(small));
    try expectEqual(true, big.contains(small));
}

test "Rect: no intersection (far apart)" {
    const r1 = Rect.splat(5);
    const r2 = Rect.splat(10).at(150, 150);

    const result = r1.intersection(r2);

    try expect(result == null);
    try expect(r1.collides(r2) == false);
}

test "Rect: edge touch (no intersection)" {
    // These boxes touch at x=10, but do not overlap.
    const r1 = Rect.splat(10);
    const r2 = Rect.splat(10).at(10, 0);

    const result = r1.intersection(r2);

    try expect(result == null);
    try expect(r1.collides(r2) == true);
}

test "Rect: collision detection" {
    const r1 = Rect.splat(10);
    const r2 = Rect.splat(10).at(9, 9);

    try expect(r1.collides(r2) == true);
    try expect(r2.collides(r1) == true);
}

test "Rect: flatten" {
    const r1 = Rect.fromSize(3, 4).at(1, 2);
    const flattened = r1.flatten();

    try expect(flattened[0] == 1);
    try expect(flattened[1] == 2);
    try expect(flattened[2] == 3);
    try expect(flattened[3] == 4);
}

test "Rect: collides edge cases" {
    // Reference Rect at (0,0) with size (10,10)
    const a = Rect.init(Vec2.splat(0), Vec2.splat(10));

    // 1. CLEAR COLLISION (Centered)
    const b = Rect.init(Vec2.splat(5), Vec2.splat(10));
    try std.testing.expect(a.collides(b));

    // 2. SEPARATED ON X ONLY (Aligned on Y)
    // Should be false.
    const c = Rect.init(Vec2.from(.{ 11, 0 }), Vec2.from(.{ 10, 10 }));
    try std.testing.expect(!a.collides(c));

    // 3. SEPARATED ON Y ONLY (Aligned on X)
    // Should be false.
    const d = Rect.init(Vec2.from(.{ 0, 11 }), Vec2.from(.{ 10, 10 }));
    try std.testing.expect(!a.collides(d));

    // 4. THE "DANGER ZONE": Separated on X, but Overlapping on Y
    // Rect E is at (15, 5).
    // X is far away (15 > 10), but Y is inside (5 is between 0 and 10).
    // Should be false.
    const e = Rect.init(Vec2.from(.{ 15, 5 }), Vec2.from(.{ 10, 10 }));
    try std.testing.expect(!a.collides(e));

    // 5. TOUCHING EDGES (Exact)
    // Depending on if you use <= or <, this should be true or false.
    // With your current <= logic, this is TRUE.
    const f = Rect.init(Vec2.from(.{ 10, 0 }), Vec2.from(.{ 10, 10 }));
    try std.testing.expect(a.collides(f));

    // 6. NEGATIVE COORDINATES
    const g = Rect.init(Vec2.from(.{ -5, -5 }), Vec2.from(.{ 10, 10 }));
    try std.testing.expect(a.collides(g));

    const h = Rect.init(Vec2.from(.{ -10, -10 }), Vec2.from(.{ 10, 10 }));
    try std.testing.expect(a.collides(h));
}

test "Rect: contains_p (point)" {
    const rect = Rect.init(Vec2.from(.{ 10, 10 }), Vec2.from(.{ 20, 20 })); // Bounds: 10,10 to 30,30

    // Inside
    try std.testing.expect(rect.contains_p(Vec2.from(.{ 15, 15 })));

    // On the edge (start)
    try std.testing.expect(rect.contains_p(Vec2.from(.{ 10, 10 })));

    // On the edge (end)
    try std.testing.expect(rect.contains_p(Vec2.from(.{ 30, 30 })));

    // Outside (just barely)
    try std.testing.expect(!rect.contains_p(Vec2.from(.{ 9.9, 15 })));
    try std.testing.expect(!rect.contains_p(Vec2.from(.{ 15, 30.1 })));
}

test "Rect: contains (another rect)" {
    const outer = Rect.init(Vec2.from(.{ 0, 0 }), Vec2.from(.{ 100, 100 }));

    // Fully inside
    const inner = Rect.init(Vec2.from(.{ 10, 10 }), Vec2.from(.{ 50, 50 }));
    try std.testing.expect(outer.contains(inner));

    // Identical rects
    try std.testing.expect(outer.contains(outer));

    // Peeking out (partial overlap)
    const peeking = Rect.init(Vec2.from(.{ 50, 50 }), Vec2.from(.{ 60, 60 })); // Ends at 110,110
    try std.testing.expect(!outer.contains(peeking));

    // Completely outside
    const outside = Rect.init(Vec2.from(.{ 200, 200 }), Vec2.from(.{ 10, 10 }));
    try std.testing.expect(!outer.contains(outside));
}

test "Rect: translate" {
    const rect = Rect.init(Vec2.from(.{ 10, 20 }), Vec2.from(.{ 100, 50 }));
    const offset = Vec2.from(.{ 5, -10 });

    const moved = rect.translate(offset);

    // Start: (10+5, 20-10) -> (15, 10)
    try std.testing.expectEqual(@as(f32, 15.0), moved.start.x());
    try std.testing.expectEqual(@as(f32, 10.0), moved.start.y());

    // Size should remain exactly the same
    try std.testing.expectEqual(@as(f32, 100.0), moved.size.x());
    try std.testing.expectEqual(@as(f32, 50.0), moved.size.y());

    // Test zero translation
    const stayed = rect.translate(Vec2.ZERO);
    try std.testing.expectEqual(rect.start.x(), stayed.start.x());
    try std.testing.expectEqual(rect.size.x(), stayed.size.x());
}

test "Rect: expand and expandVec2" {
    const rect = Rect.init(Vec2.from(.{ 100, 100 }), Vec2.from(.{ 50, 50 }));

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
    const amount = Vec2.from(.{ 5.0, 20.0 });
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

test "Rect: shrink" {
    const rect = Rect.init(Vec2.from(.{ 10, 10 }), Vec2.from(.{ 100, 100 }));

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

test "Rect: shrink & shrinkVec2" {
    const rect = Rect.init(Vec2.from(.{ 10, 10 }), Vec2.from(.{ 100, 100 }));

    // Case 1: Uniform shrink
    const shrunk = rect.shrink(10.0);
    // Start: 10 + 10 = 20
    // Size: 100 - (10 * 2) = 80
    try std.testing.expectEqual(@as(f32, 20.0), shrunk.start.x());
    try std.testing.expectEqual(@as(f32, 80.0), shrunk.size.x());

    // Case 2: Non-uniform shrinkVec2
    const s_vec = rect.shrinkVec2(Vec2.from(.{ 5, 20 }));
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
