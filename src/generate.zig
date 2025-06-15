const std = @import("std");
const assert = std.debug.assert;
const testing = std.testing;

const CoordinatePair = struct {
    x0: f64,
    y0: f64,
    x1: f64,
    y1: f64,
};

const CoordinatePairs = struct { pairs: []CoordinatePair };

pub fn generate(writer: anytype, rng: std.Random, count: u32) !void {
    _ = rng;
    try writer.writeAll("{\"pairs\": [");
    for (0..count) |i| {
        if (i > 0) {
            try writer.writeAll(",{\"x0\": 0, \"y0\": 0, \"x1\": 0, \"y1\": 0}");
        } else {
            try writer.writeAll("{\"x0\": 0, \"y0\": 0, \"x1\": 0, \"y1\": 0}");
        }
    }

    try writer.writeAll("]}");
}

fn testRng() std.Random.Xoroshiro128 {
    return std.Random.Xoroshiro128.init(testing.random_seed);
}

test "generates valid JSON with a pairs key" {
    var buffer = std.ArrayList(u8).init(testing.allocator);
    defer buffer.deinit();

    var rng = testRng();
    try generate(buffer.writer(), rng.random(), 0);

    const result = try std.json.parseFromSlice(
        CoordinatePairs,
        testing.allocator,
        buffer.items,
        .{},
    );
    defer result.deinit();
}

test "respects the count" {
    var buffer = std.ArrayList(u8).init(testing.allocator);
    defer buffer.deinit();

    var rng = testRng();
    const count = rng.random().intRangeAtMost(u32, 0, 3);
    assert(count < 4);
    try generate(buffer.writer(), rng.random(), count);

    const result = try std.json.parseFromSlice(
        CoordinatePairs,
        testing.allocator,
        buffer.items,
        .{},
    );
    defer result.deinit();
    try std.testing.expectEqual(count, result.value.pairs.len);
}
