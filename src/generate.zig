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

fn randomLat(rng: std.Random) f64 {
    const result = (rng.float(f64) * 180) - 90;
    assert(result >= -90);
    assert(result <= 90);
    return result;
}

fn randomLng(rng: std.Random) f64 {
    const result = (rng.float(f64) * 360) - 180;
    assert(result >= -180);
    assert(result <= 180);
    return result;
}

pub fn generate(writer: anytype, rng: std.Random, count: u32) !void {
    var json_writer = std.json.writeStream(writer, .{});
    try json_writer.beginObject();
    try json_writer.objectField("pairs");
    try json_writer.beginArray();
    for (0..count) |_| {
        try json_writer.write(CoordinatePair{
            .x0 = randomLat(rng),
            .y0 = randomLng(rng),
            .x1 = randomLat(rng),
            .y1 = randomLng(rng),
        });
    }
    try json_writer.endArray();
    try json_writer.endObject();

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
