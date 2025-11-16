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

fn expect_and_consume_char(json_reader: *std.Io.Reader, expected_char: u8) !void {
    try advance_past_whitespace(json_reader);

    const byte = json_reader.peek(1) catch |err| switch (err) {
        error.EndOfStream => return error.UnexpectedEndOfStream,
        else => return err,
    };

    if (byte[0] == expected_char) {
        _ = try json_reader.takeByteSigned();
        return;
    } else {
        return error.UnexpectedCharacter;
    }
}

test "expect_and_consume_char with valid char advances" {
    const test_input = " {\"";
    var fixed_reader = std.Io.Reader.fixed(test_input);
    var buffer: [4]u8 = undefined;
    var limited = std.Io.Reader.Limited.init(&fixed_reader, @enumFromInt(test_input.len), &buffer);

    try expect_and_consume_char(&limited.interface, '{');

    const next_byte = try limited.interface.peek(1);
    try std.testing.expectEqual('"', next_byte[0]);
}

test "advance_into_object when not object returns error" {
    const test_input = "\"";
    var fixed_reader = std.Io.Reader.fixed(test_input);
    var buffer: [4]u8 = undefined;
    var limited = std.Io.Reader.Limited.init(&fixed_reader, @enumFromInt(test_input.len), &buffer);

    try std.testing.expectError(error.UnexpectedCharacter, expect_and_consume_char(&limited.interface, 'a'));
}

const Pair = struct {
    x0: f64,
    y0: f64,
    x1: f64,
    y1: f64,
};

fn read_pair(json_reader: *std.Io.Reader) !Pair {
    const result = Pair{
        .x0 = 0,
        .y0 = 0,
        .x1 = 0,
        .y1 = 0,
    };
    try expect_and_consume_char(json_reader, '{');
    try expect_and_consume_char(json_reader, '}');

    return result;
}


test "read_pair when valid succeeds" {
    const test_input = "{ \"x0\": 1.2, \"y0\": 2.3, \"x1\": 3.4, \"y1\": 4.5 }";
    var fixed_reader = std.Io.Reader.fixed(test_input);
    var buffer: [4]u8 = undefined;
    var limited = std.Io.Reader.Limited.init(&fixed_reader, @enumFromInt(test_input.len), &buffer);

    const pair = try read_pair(&limited.interface);

    try std.testing.expectEqual(1.2, pair.x0);
    try std.testing.expectEqual(2.3, pair.y0);
    try std.testing.expectEqual(3.4, pair.x1);
    try std.testing.expectEqual(4.5, pair.y1);
}

pub fn calculate(json_reader: *std.Io.Reader) !void {
    try expect_and_consume_char(json_reader, '[');

    while(true) {
        try advance_past_whitespace(json_reader);
        const next_char = try json_reader.peek(1);

        if (next_char == ']') {
            break;
        }

        try read_pair(json_reader);
    }

    try expect_and_consume_char(json_reader, ']');
}
