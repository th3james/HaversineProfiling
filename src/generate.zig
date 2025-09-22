const std = @import("std");
const assert = std.debug.assert;
const testing = std.testing;
const RndGen = std.Random.DefaultPrng;
const referenceHaversine = @import("reference_haversine.zig").referenceHaversine;

const Coordinates = struct {
    x: f64,
    y: f64,
};

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

fn randomSpreadLng(rng: std.Random, cluster_lng: f64, spread: f64) f64 {
    assert(cluster_lng >= -180);
    assert(cluster_lng <= 180);
    const noise = (rng.float(f64) - 0.5) * spread;
    const result = cluster_lng + noise;
    return std.math.clamp(result, -180, 180);
}

fn randomSpreadLat(rng: std.Random, cluster_lat: f64, spread: f64) f64 {
    assert(cluster_lat >= -90);
    assert(cluster_lat <= 90);
    const noise = (rng.float(f64) - 0.5) * spread;
    const result = cluster_lat + noise;
    return std.math.clamp(result, -90, 90);
}

pub fn generate(pair_writer: *std.Io.Writer, rng: std.Random, count: u32) !f64 {
    const CLUSTER_COUNT = 8;
    var clusters: [CLUSTER_COUNT]Coordinates = undefined;
    for (0..CLUSTER_COUNT) |i| {
        clusters[i] = Coordinates{
            .x = randomLng(rng),
            .y = randomLat(rng),
        };
    }

    var distance_sum: f64 = 0.0;
    var json_writer: std.json.Stringify = .{
        .writer = pair_writer,
    };
    try json_writer.beginObject();
    try json_writer.objectField("pairs");
    try json_writer.beginArray();
    const SPREAD = 3.0;
    for (0..count) |i| {
        const source_cluster = clusters[i % CLUSTER_COUNT];
        const dest_cluster = clusters[rng.intRangeLessThan(u8, 0, CLUSTER_COUNT-1)];
        const pair = CoordinatePair{
            .x0 = randomSpreadLng(rng, source_cluster.x, SPREAD),
            .y0 = randomSpreadLat(rng, source_cluster.y, SPREAD),
            .x1 = randomSpreadLng(rng, dest_cluster.x, SPREAD),
            .y1 = randomSpreadLat(rng, dest_cluster.y, SPREAD),
        };
        try json_writer.write(pair);
        distance_sum += referenceHaversine(pair.x0, pair.y0, pair.x1, pair.y1);
    }
    try json_writer.endArray();
    try json_writer.endObject();

    return distance_sum / @as(f64, @floatFromInt(count));
}

fn testRng() std.Random.Xoroshiro128 {
    return std.Random.Xoroshiro128.init(testing.random_seed);
}

test "generates valid JSON with a pairs key" {
    var point_buffer = try std.array_list.Aligned(u8, null).initCapacity(testing.allocator, 15);
    defer point_buffer.deinit(testing.allocator);
    var point_buffer_allocating_writer = std.Io.Writer.Allocating.fromArrayList(testing.allocator, &point_buffer);
    defer point_buffer_allocating_writer.deinit();

    var rng = testRng();
    _ = try generate(&point_buffer_allocating_writer.writer, rng.random(), 0);

    const written_data = point_buffer_allocating_writer.written();

    const result = try std.json.parseFromSlice(
        CoordinatePairs,
        testing.allocator,
        written_data,
        .{},
    );
    defer result.deinit();
}

test "respects the count" {
    var point_buffer = try std.array_list.Aligned(u8, null).initCapacity(testing.allocator, 500);
    defer point_buffer.deinit(testing.allocator);
    var point_buffer_allocating_writer = std.Io.Writer.Allocating.fromArrayList(testing.allocator, &point_buffer);
    defer point_buffer_allocating_writer.deinit();

    var rng = testRng();
    const count = rng.random().intRangeAtMost(u32, 0, 3);
    assert(count < 4);

    _ = try generate(&point_buffer_allocating_writer.writer, rng.random(), count);

    const written_data = point_buffer_allocating_writer.written();

    const result = try std.json.parseFromSlice(
        CoordinatePairs,
        testing.allocator,
        written_data,
        .{},
    );
    defer result.deinit();
    try std.testing.expectEqual(count, result.value.pairs.len);
}

test "returns the reference average" {
    var point_buffer = try std.array_list.Aligned(u8, null).initCapacity(testing.allocator, 400);
    defer point_buffer.deinit(testing.allocator);
    var point_buffer_allocating_writer = std.Io.Writer.Allocating.fromArrayList(testing.allocator, &point_buffer);
    defer point_buffer_allocating_writer.deinit();

    var rand = RndGen.init(1);
    const result_avg = try generate(&point_buffer_allocating_writer.writer, rand.random(), 2);

    try std.testing.expectEqual(8649.899195741775, result_avg);
}
