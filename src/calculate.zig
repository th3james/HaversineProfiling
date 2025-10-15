const std = @import("std");

fn advance_past_whitespace(json_reader: *std.Io.Reader) !void {
    while (true) {
        const byte = json_reader.peek(1) catch |err| switch (err) {
            error.EndOfStream => break,
            else => return err,
        };

        if (byte.len == 0) break; // End of stream

        switch (byte[0]) {
            ' ', '\t', '\n', '\r' => {
                _ = try json_reader.takeByteSigned();
            },
            else => break,
        }
    }
}

fn advance_to_first_pair(json_reader: *std.Io.Reader) !void {
    try advance_past_whitespace(json_reader);
    const byte = json_reader.peek(1) catch |err| switch (err) {
        error.EndOfStream => return error.UnexpectedEndOfStream,
        else => return err,
    };

    if (byte.len > 0 and byte[0] == '[') {
        _ = try json_reader.takeByteSigned();
        return;
    } else {
        return error.ExpectedArrayStart;
    }
}

fn read_next_pair(json_reader: *std.Io.Reader) !void {
    _ = json_reader;
}

pub fn calculate(json_reader: *std.Io.Reader) !void {
    advance_to_first_pair(json_reader);
    while (read_next_pair(json_reader)) |pair| {
        _ = pair;
        // do work
    } else |err| switch (err) {
        else => return err,
    }
}

test "advance_past_whitespace with spaces and tabs" {
    const test_input = "   \t\n\r{";

    const file = try std.fs.cwd().createFile("test_whitespace.tmp", .{ .read = true, .truncate = true });
    defer file.close();
    defer std.fs.cwd().deleteFile("test_whitespace.tmp") catch {};

    try file.writeAll(test_input);
    try file.seekTo(0);

    var buffer: [64]u8 = undefined;
    var reader_wrapper = file.reader(&buffer);

    try advance_past_whitespace(&reader_wrapper.interface);

    const next_byte = try reader_wrapper.interface.peek(1);
    try std.testing.expect(next_byte.len > 0);
    try std.testing.expect(next_byte[0] == '{');
}

test "advance_past_whitespace with no whitespace" {
    const test_input = "{\"test\": 123}";

    const file = try std.fs.cwd().createFile("test_no_whitespace.tmp", .{ .read = true, .truncate = true });
    defer file.close();
    defer std.fs.cwd().deleteFile("test_no_whitespace.tmp") catch {};

    try file.writeAll(test_input);
    try file.seekTo(0);

    var buffer: [64]u8 = undefined;
    var reader_wrapper = file.reader(&buffer);

    try advance_past_whitespace(&reader_wrapper.interface);

    const next_byte = try reader_wrapper.interface.peek(1);
    try std.testing.expect(next_byte.len > 0);
    try std.testing.expect(next_byte[0] == '{');
}

test "advance_past_whitespace with empty stream" {
    const test_input = "";

    const file = try std.fs.cwd().createFile("test_empty.tmp", .{ .read = true, .truncate = true });
    defer file.close();
    defer std.fs.cwd().deleteFile("test_empty.tmp") catch {};

    try file.writeAll(test_input);
    try file.seekTo(0);

    var buffer: [64]u8 = undefined;
    var reader_wrapper = file.reader(&buffer);

    try advance_past_whitespace(&reader_wrapper.interface);

    const next_byte = reader_wrapper.interface.peek(1) catch |err| switch (err) {
        error.EndOfStream => return, // Expected for empty stream
        else => return err,
    };
    try std.testing.expect(next_byte.len == 0);
}

test "advance_past_whitespace with only whitespace" {
    const test_input = "   \t\n\r   ";

    const file = try std.fs.cwd().createFile("test_only_whitespace.tmp", .{ .read = true, .truncate = true });
    defer file.close();
    defer std.fs.cwd().deleteFile("test_only_whitespace.tmp") catch {};

    try file.writeAll(test_input);
    try file.seekTo(0);

    var buffer: [64]u8 = undefined;
    var reader_wrapper = file.reader(&buffer);

    try advance_past_whitespace(&reader_wrapper.interface);

    const next_byte = reader_wrapper.interface.peek(1) catch |err| switch (err) {
        error.EndOfStream => return, // Expected for empty stream
        else => return err,
    };
    try std.testing.expect(next_byte.len == 0);
}
