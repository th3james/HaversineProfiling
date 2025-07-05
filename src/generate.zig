const std = @import("std");
const assert = std.debug.assert;
const testing = std.testing;
const RndGen = std.Random.DefaultPrng;

const CoordinatePair = struct {
    x0: f64,
    y0: f64,
    x1: f64,
    y1: f64,
};

const CoordinatePairs = struct { pairs: []CoordinatePair };


const LNG_RANGE = 360;
const LNG_OFFSET = LNG_RANGE / 2;
fn randomLng(rng: std.Random) f64 {
    const result = (rng.float(f64) * LNG_RANGE) - LNG_OFFSET;
    assert(result >= -180);
    assert(result <= 180);
    return result;
}

const LAT_RANGE = 180;
const LAT_OFFSET = LAT_RANGE / 2;
fn randomLat(rng: std.Random) f64 {
    const result = (rng.float(f64) * LAT_RANGE) - LAT_OFFSET;
    assert(result >= -90);
    assert(result <= 90);
    return result;
}

pub fn generate(pair_writer: anytype, rng: std.Random, count: u32) !f64 {
    var json_writer = std.json.writeStream(pair_writer, .{});
    try json_writer.beginObject();
    try json_writer.objectField("pairs");
    try json_writer.beginArray();
    for (0..count) |_| {
        try json_writer.write(CoordinatePair{
            .x0 = randomLng(rng),
            .y0 = randomLat(rng),
            .x1 = randomLng(rng),
            .y1 = randomLat(rng),
        });
    }
    try json_writer.endArray();
    try json_writer.endObject();

    return 4.4;
}

fn testRng() std.Random.Xoroshiro128 {
    return std.Random.Xoroshiro128.init(testing.random_seed);
}

test "generates valid JSON with a pairs key" {
    var point_buffer = std.ArrayList(u8).init(testing.allocator);
    defer point_buffer.deinit();

    var rng = testRng();
    _ = try generate(point_buffer.writer(), rng.random(), 0);

    const result = try std.json.parseFromSlice(
        CoordinatePairs,
        testing.allocator,
        point_buffer.items,
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

    _ = try generate(buffer.writer(), rng.random(), count);

    const result = try std.json.parseFromSlice(
        CoordinatePairs,
        testing.allocator,
        buffer.items,
        .{},
    );
    defer result.deinit();
    try std.testing.expectEqual(count, result.value.pairs.len);
}

test  "returns the reference average" {
    var buffer = std.ArrayList(u8).init(testing.allocator);
    defer buffer.deinit();

    var rand = RndGen.init(1);
    const result_avg = try generate(buffer.writer(), rand.random(), 2);

    try std.testing.expectEqual(3.4, result_avg);
}
