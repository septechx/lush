const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

pub const Value = union(enum) {
    number: f64,
    string: []const u8,
    boolean: bool,
    object: std.StringHashMap(Value),
    array: ArrayList(Value),
};

pub const ParseError = error{
    UnexpectedChar,
    InvalidFormat,
    UnexpectedEnd,
    InvalidNumber,

    OutOfMemory,
};

pub fn parse(allocator: Allocator, input: []const u8) !Value {
    var parser = Parser{
        .allocator = allocator,
        .input = input,
        .pos = 0,
    };
    return parser.parseValue();
}

const Parser = struct {
    allocator: Allocator,
    input: []const u8,
    pos: usize,

    fn peek(self: *Parser) ?u8 {
        if (self.pos >= self.input.len) return null;
        return self.input[self.pos];
    }

    fn next(self: *Parser) ?u8 {
        if (self.pos >= self.input.len) return null;
        const ch = self.input[self.pos];
        self.pos += 1;
        return ch;
    }

    fn skipWhitespace(self: *Parser) void {
        while (self.peek()) |ch| {
            switch (ch) {
                ' ', '\t', '\n', '\r' => _ = self.next(),
                else => break,
            }
        }
    }

    fn parseValue(self: *Parser) ParseError!Value {
        self.skipWhitespace();
        const ch = self.peek() orelse return ParseError.UnexpectedEnd;

        switch (ch) {
            '(' => return self.parseObject(),
            '[' => return self.parseArray(),
            '"' => return self.parseString(),
            else => {
                if (std.ascii.isDigit(ch) or ch == '-') {
                    return self.parseNumber();
                } else if (std.mem.startsWith(u8, self.input[self.pos..], "true")) {
                    self.pos += 4;
                    return Value{ .boolean = true };
                } else if (std.mem.startsWith(u8, self.input[self.pos..], "false")) {
                    self.pos += 5;
                    return Value{ .boolean = false };
                }
                return ParseError.UnexpectedChar;
            },
        }
    }

    fn parseObject(self: *Parser) !Value {
        _ = self.next(); // Skip '('
        var map = std.StringHashMap(Value).init(self.allocator);
        errdefer map.deinit();

        while (true) {
            self.skipWhitespace();
            const ch = self.peek() orelse return ParseError.UnexpectedEnd;
            if (ch == ')') {
                _ = self.next();
                break;
            }

            const key = try self.parseIdentifier();
            self.skipWhitespace();

            const equals = self.next() orelse return ParseError.UnexpectedEnd;
            if (equals != '=') return ParseError.InvalidFormat;

            const value = try self.parseValue();
            try map.put(key, value);

            self.skipWhitespace();
            const comma = self.peek() orelse return ParseError.UnexpectedEnd;
            if (comma == ',') {
                _ = self.next();
            }
        }

        return Value{ .object = map };
    }

    fn parseArray(self: *Parser) !Value {
        _ = self.next(); // Skip '['
        var array = ArrayList(Value).init(self.allocator);
        errdefer array.deinit();

        while (true) {
            self.skipWhitespace();
            const ch = self.peek() orelse return ParseError.UnexpectedEnd;
            if (ch == ']') {
                _ = self.next();
                break;
            }

            const value = try self.parseValue();
            try array.append(value);

            self.skipWhitespace();
            const comma = self.peek() orelse return ParseError.UnexpectedEnd;
            if (comma == ',') {
                _ = self.next();
            }
        }

        return Value{ .array = array };
    }

    fn parseString(self: *Parser) !Value {
        _ = self.next(); // Skip '"'
        var str = ArrayList(u8).init(self.allocator);
        errdefer str.deinit();

        while (true) {
            const ch = self.next() orelse return ParseError.UnexpectedEnd;
            if (ch == '"') break;
            try str.append(ch);
        }

        return Value{ .string = try str.toOwnedSlice() };
    }

    fn parseNumber(self: *Parser) !Value {
        var numStr = ArrayList(u8).init(self.allocator);
        defer numStr.deinit();

        while (self.peek()) |ch| {
            switch (ch) {
                '0'...'9', '.', '-', 'e', 'E', '+' => {
                    try numStr.append(ch);
                    _ = self.next();
                },
                else => break,
            }
        }

        const num = std.fmt.parseFloat(f64, numStr.items) catch return ParseError.InvalidNumber;
        return Value{ .number = num };
    }

    fn parseIdentifier(self: *Parser) ![]const u8 {
        var ident = ArrayList(u8).init(self.allocator);
        errdefer ident.deinit();

        while (self.peek()) |ch| {
            switch (ch) {
                'a'...'z', 'A'...'Z', '0'...'9', '_' => {
                    try ident.append(ch);
                    _ = self.next();
                },
                else => break,
            }
        }

        return ident.toOwnedSlice();
    }
};
