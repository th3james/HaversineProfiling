const std = @import("std");
const RndGen = std.Random.DefaultPrng;

const generate = @import("generate.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var args = try std.process.argsWithAllocator(allocator);

    defer args.deinit();

    _ = args.next(); // pop program name

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    var rand = RndGen.init(@as(u64, @bitCast(std.time.milliTimestamp())));

    _ = try generate.generate(stdout, rand.random(), 10);

    try stdout.flush();
}
