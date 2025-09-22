const std = @import("std");
const assert = std.debug.assert;
const RndGen = std.Random.DefaultPrng;

const generate = @import("generate.zig");

fn printUsage() void {
    std.debug.print("Usage: haversine <generate>\n", .{});
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var args = try std.process.argsWithAllocator(allocator);

    defer args.deinit();

    _ = args.next(); // pop program name

    const command = args.next() orelse {
        printUsage();
        return;
    };

    if (std.mem.eql(u8, command, "generate")) {
        var stdout_buffer: [1024]u8 = undefined;
        var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
        const stdout = &stdout_writer.interface;

        var rand = RndGen.init(@as(u64, @bitCast(std.time.milliTimestamp())));

        const distance_avg = try generate.generate(stdout, rand.random(), 1000000);

        try stdout.print("\nExpected sum: {}", .{distance_avg});

        try stdout.flush();
    } else {
        std.debug.print("Unknown command {s}\n", .{command});
        printUsage();
        return;
    }
}
