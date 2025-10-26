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

test "advance_past_whitespace with spaces and tabs" {
    const test_input = "   \t\n\r{";
    var fixed_reader = std.Io.Reader.fixed(test_input);
    var buffer: [16]u8 = undefined;
    var limited = std.Io.Reader.Limited.init(&fixed_reader, @enumFromInt(test_input.len), &buffer);

    try advance_past_whitespace(&limited.interface);

    const next_byte = try limited.interface.peek(1);
    try std.testing.expect(next_byte.len > 0);
    try std.testing.expectEqual('{', next_byte[0]);
}

test "advance_past_whitespace with no whitespace" {
    const test_input = "{\"test\": 123}";
    var fixed_reader = std.Io.Reader.fixed(test_input);
    var buffer: [16]u8 = undefined;
    var limited = std.Io.Reader.Limited.init(&fixed_reader, @enumFromInt(test_input.len), &buffer);

    try advance_past_whitespace(&limited.interface);

    const next_byte = try limited.interface.peek(1);
    try std.testing.expect(next_byte.len > 0);
    try std.testing.expectEqual('{', next_byte[0]);
}

test "advance_past_whitespace with empty stream" {
    const test_input = "";
    var fixed_reader = std.Io.Reader.fixed(test_input);
    var buffer: [16]u8 = undefined;
    var limited = std.Io.Reader.Limited.init(&fixed_reader, @enumFromInt(test_input.len), &buffer);

    try advance_past_whitespace(&limited.interface);

    const next_byte = limited.interface.peek(1) catch |err| switch (err) {
        error.EndOfStream => return, // Expected for empty stream
        else => return err,
    };
    try std.testing.expectEqual(0, next_byte.len);
}

test "advance_past_whitespace with only whitespace" {
    const test_input = "   \t\n\r   ";
    var fixed_reader = std.Io.Reader.fixed(test_input);
    var buffer: [64]u8 = undefined;
    var limited = std.Io.Reader.Limited.init(&fixed_reader, @enumFromInt(test_input.len), &buffer);

    try advance_past_whitespace(&limited.interface);

    const next_byte = limited.interface.peek(1) catch |err| switch (err) {
        error.EndOfStream => return, // Expected for empty stream
        else => return err,
    };
    try std.testing.expectEqual(0, next_byte.len);
}

fn advance_into_array(json_reader: *std.Io.Reader) !void {
    try advance_past_whitespace(json_reader);
    const byte = json_reader.peek(1) catch |err| switch (err) {
        error.EndOfStream => return error.UnexpectedEndOfStream,
        else => return err,
    };

    if (byte[0] == '[') {
        _ = try json_reader.takeByteSigned();
        return;
    } else {
        return error.ExpectedArrayStart;
    }
}

test "advance_into_array when array" {
    const test_input = "[{";
    var fixed_reader = std.Io.Reader.fixed(test_input);
    var buffer: [4]u8 = undefined;
    var limited = std.Io.Reader.Limited.init(&fixed_reader, @enumFromInt(test_input.len), &buffer);

    try advance_into_array(&limited.interface);

    const next_byte = try limited.interface.peek(1);
    try std.testing.expectEqual('{', next_byte[0]);
}

test "advance_into_array when not array" {
    const test_input = "{";
    var fixed_reader = std.Io.Reader.fixed(test_input);
    var buffer: [4]u8 = undefined;
    var limited = std.Io.Reader.Limited.init(&fixed_reader, @enumFromInt(test_input.len), &buffer);

    try std.testing.expectError(error.ExpectedArrayStart,  advance_into_array(&limited.interface));
}

fn advance_into_object(json_reader: *std.Io.Reader) !void {
    try advance_past_whitespace(json_reader);

    const byte = json_reader.peek(1) catch |err| switch (err) {
        error.EndOfStream => return error.UnexpectedEndOfStream,
        else => return err,
    };

    if (byte[0] == '{') {
        _ = try json_reader.takeByteSigned();
        return;
    } else {
        return error.ExpectedObjectStart;
    }
}

test "advance_into_object when object" {
    const test_input = " {\"";
    var fixed_reader = std.Io.Reader.fixed(test_input);
    var buffer: [4]u8 = undefined;
    var limited = std.Io.Reader.Limited.init(&fixed_reader, @enumFromInt(test_input.len), &buffer);

    try advance_into_object(&limited.interface);

    const next_byte = try limited.interface.peek(1);
    try std.testing.expectEqual('"', next_byte[0]);
}

test "advance_into_object when not object" {
    const test_input = "\"";
    var fixed_reader = std.Io.Reader.fixed(test_input);
    var buffer: [4]u8 = undefined;
    var limited = std.Io.Reader.Limited.init(&fixed_reader, @enumFromInt(test_input.len), &buffer);

    try std.testing.expectError(error.ExpectedObjectStart,  advance_into_object(&limited.interface));
}


fn read_next_pair(json_reader: *std.Io.Reader) !void {
    try advance_into_object(json_reader);
}

pub fn calculate(json_reader: *std.Io.Reader) !void {
    try advance_into_array(json_reader);
    while (read_next_pair(json_reader)) |pair| {
        _ = pair;
        // do work
    } else |err| switch (err) {
        else => return err,
    }
}
