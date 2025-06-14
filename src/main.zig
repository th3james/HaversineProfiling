const std = @import("std");

const generate = @import("generate.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var args = try std.process.argsWithAllocator(allocator);

    defer args.deinit();

    _ = args.next(); // pop program name

    const stdout = std.io.getStdOut().writer();

    try generate.generate(stdout);
}
