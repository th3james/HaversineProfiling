const std = @import("std");
const testing = std.testing;

pub fn generate(writer: anytype) !void {
    try writer.writeAll("sup");
}

test "generates valid JSON" {
    var buffer = std.ArrayList(u8).init(testing.allocator);
    defer buffer.deinit();

    try generate(buffer.writer());

    _ = try std.json.parseFromSlice(
        std.json.Value,
        testing.allocator,
        buffer.items,
        .{},
    );
}
