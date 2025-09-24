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
        const usage = "Usage: haversine generate <filename> <point_count>\n";
        const filename = args.next() orelse {
            std.debug.print(usage, .{});
            return;
        };

        const point_count_str = args.next() orelse {
            std.debug.print(usage, .{});
            return;
        };

        const point_count = std.fmt.parseInt(u32, point_count_str, 10) catch {
            std.debug.print("Invalid point count: {s}\n", .{point_count_str});
            return;
        };

        var file_buffer: [1024]u8 = undefined;
        const file = try std.fs.cwd().createFile(filename, .{ .read = true, .truncate = true });
        defer file.close();
        var file_writer = file.writer(&file_buffer);

        var rand = RndGen.init(@as(u64, @bitCast(std.time.milliTimestamp())));

        const distance_avg = try generate.generate(&file_writer.interface, rand.random(), point_count);

        try file_writer.interface.flush();
        std.debug.print("\nExpected sum: {}", .{distance_avg});
    } else {
        std.debug.print("Unknown command {s}\n", .{command});
        printUsage();
        return;
    }
}
