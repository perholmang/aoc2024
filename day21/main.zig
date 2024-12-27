const std = @import("std");
const aoc = @import("helpers.zig");
const data = @embedFile("input.txt");
const Allocator = std.mem.Allocator;

const Vec2 = @Vector(2, i31);

const numpad = "789456123x0A";
const dirpad = "x^A<v>";

fn next_dirpad_key(key: u8, direction: u8) ?u8 {
    const key_idx = for (dirpad, 0..) |c, index| {
        if (c == key) break index;
    } else unreachable;

    switch (direction) {
        '<' => {
            if (key == '^') {
                return null;
            }
            return dirpad[key_idx - 1];
        },
        '>' => return dirpad[key_idx + 1],
        '^' => {
            if (key == '<') {
                return null;
            }
            return dirpad[key_idx - 3];
        },
        'v' => return dirpad[key_idx + 3],
        else => unreachable,
    }
}

fn next_numpad_key(key: u8, direction: u8) ?u8 {
    const key_idx = for (numpad, 0..) |c, index| {
        if (c == key) break index;
    } else unreachable;

    switch (direction) {
        '<' => {
            if (key == '0') {
                return null;
            }
            return numpad[key_idx - 1];
        },
        '>' => return numpad[key_idx + 1],
        '^' => return numpad[key_idx - 3],
        'v' => {
            if (key == '1') {
                return null;
            }
            return numpad[key_idx + 3];
        },
        else => unreachable,
    }
}

fn all_dirpad_paths(alloc: Allocator, from: u8, to: u8) ![][]const u8 {
    var ret = std.ArrayList([]const u8).init(alloc);

    const to_idx = for (dirpad, 0..) |c, index| {
        if (c == to) break index;
    } else unreachable;

    const to_x = to_idx % 3;
    const to_y = to_idx / 3;

    const Q = struct {
        key: u8,
        path: std.ArrayList(u8),
    };

    var q = std.ArrayList(Q).init(alloc);
    defer q.deinit();
    try q.append(.{
        .key = from,
        .path = std.ArrayList(u8).init(alloc),
    });

    while (q.popOrNull()) |next| {
        const from_idx = for (dirpad, 0..) |c, index| {
            if (c == next.key) break index;
        } else unreachable;

        if (next.key == to) {
            try ret.append(next.path.items);
            continue;
        }

        const next_x = from_idx % 3;
        const next_y = from_idx / 3;
        const dx: i31 = @as(i31, @intCast(next_x)) - @as(i31, @intCast(to_x));
        const dy: i31 = @as(i31, @intCast(next_y)) - @as(i31, @intCast(to_y));

        if (@abs(dx) > 0) {
            const d: u8 = if (dx > 0) '<' else '>';
            if (next_dirpad_key(next.key, d)) |next_key| {
                var path = try next.path.clone();
                try path.append(d);
                try q.append(.{
                    .key = next_key,
                    .path = path,
                });
            }
        }

        if (@abs(dy) > 0) {
            const d: u8 = if (dy > 0) '^' else 'v';
            if (next_dirpad_key(next.key, d)) |next_key| {
                var path = try next.path.clone();
                try path.append(d);
                try q.append(.{
                    .key = next_key,
                    .path = path,
                });
            }
        }
    }

    return ret.toOwnedSlice();
}

fn all_numpad_paths(alloc: Allocator, from: u8, to: u8) ![][]const u8 {
    var ret = std.ArrayList([]const u8).init(alloc);

    const to_idx = for (numpad, 0..) |c, index| {
        if (c == to) break index;
    } else unreachable;

    const to_x = to_idx % 3;
    const to_y = to_idx / 3;

    const Q = struct {
        key: u8,
        path: std.ArrayList(u8),
    };

    var q = std.ArrayList(Q).init(alloc);
    defer q.deinit();
    try q.append(.{
        .key = from,
        .path = std.ArrayList(u8).init(alloc),
    });

    while (q.popOrNull()) |next| {
        const from_idx = for (numpad, 0..) |c, index| {
            if (c == next.key) break index;
        } else unreachable;

        if (next.key == to) {
            try ret.append(next.path.items);
            continue;
        }

        const next_x = from_idx % 3;
        const next_y = from_idx / 3;
        const dx: i31 = @as(i31, @intCast(next_x)) - @as(i31, @intCast(to_x));
        const dy: i31 = @as(i31, @intCast(next_y)) - @as(i31, @intCast(to_y));

        if (@abs(dx) > 0) {
            const d: u8 = if (dx > 0) '<' else '>';
            if (next_numpad_key(next.key, d)) |next_key| {
                var path = try next.path.clone();
                try path.append(d);
                try q.append(.{
                    .key = next_key,
                    .path = path,
                });
            }
        }

        if (@abs(dy) > 0) {
            const d: u8 = if (dy > 0) '^' else 'v';
            if (next_numpad_key(next.key, d)) |next_key| {
                var path = try next.path.clone();
                try path.append(d);
                try q.append(.{
                    .key = next_key,
                    .path = path,
                });
            }
        }
    }

    return ret.toOwnedSlice();
}

fn build_dirpad_seq(alloc: Allocator, keys: []const u8, idx: usize, prev: u8, path: []const u8, result: *std.ArrayList([]const u8)) !void {
    if (keys.len == idx) {
        try result.append(path);
        return;
    }

    const paths = try all_dirpad_paths(alloc, prev, keys[idx]);

    for (paths) |p| {
        var new_path = std.ArrayList(u8).init(alloc);
        try new_path.appendSlice(path);
        try new_path.appendSlice(p);
        try new_path.append('A');
        try build_dirpad_seq(alloc, keys, idx + 1, keys[idx], try new_path.toOwnedSlice(), result);
    }
}

fn build_numpad_seq(alloc: Allocator, keys: []const u8, idx: usize, prev: u8, path: []const u8, result: *std.ArrayList([]const u8)) !void {
    if (keys.len == idx) {
        try result.append(path);
        return;
    }

    const paths = try all_numpad_paths(alloc, prev, keys[idx]);

    for (paths) |p| {
        var new_path = std.ArrayList(u8).init(alloc);
        try new_path.appendSlice(path);
        try new_path.appendSlice(p);
        try new_path.append('A');
        try build_numpad_seq(alloc, keys, idx + 1, keys[idx], try new_path.toOwnedSlice(), result);
    }
}

fn split_keys(alloc: Allocator, keys: []const u8) ![][]const u8 {
    var sub_keys = std.ArrayList([]const u8).init(alloc);
    defer sub_keys.deinit();
    var sub_key = std.ArrayList(u8).init(alloc);
    defer sub_key.deinit();

    for (keys) |c| {
        if (c == 'A') {
            try sub_key.append(c);
            try sub_keys.append(try sub_key.toOwnedSlice());
            sub_key.clearAndFree();
        } else {
            try sub_key.append(c);
        }
    }

    try sub_keys.append(try sub_key.toOwnedSlice());

    return sub_keys.toOwnedSlice();
}

const Cache = std.StringHashMap(usize);

fn shortest_seq(alloc: Allocator, keys: []const u8, depth: usize, cache: *Cache) !usize {
    if (depth == 0) {
        return keys.len;
    }

    const cacheKey = try std.fmt.allocPrint(alloc, "{s}{d}", .{ keys, depth });

    if (cache.get(cacheKey)) |val| {
        return val;
    }

    const sub_keys = try split_keys(alloc, keys);

    var total: usize = 0;
    for (sub_keys) |sub_key| {
        var seqs = std.ArrayList([]const u8).init(std.heap.page_allocator);
        defer seqs.deinit();
        try build_dirpad_seq(std.heap.page_allocator, sub_key, 0, 'A', "", &seqs);

        var min: usize = std.math.maxInt(usize);
        for (seqs.items) |seq| {
            const len = try shortest_seq(alloc, seq, depth - 1, cache);
            if (len < min) {
                min = len;
            }
        }

        total += min;
    }

    try cache.put(cacheKey, total);

    return total;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    const part = try aoc.getPart(alloc);

    var codes = std.ArrayList([]const u8).init(alloc);
    var lines_it = std.mem.splitSequence(u8, data, "\n");
    while (lines_it.next()) |line| {
        var it = std.mem.splitSequence(u8, line, "   ");
        while (it.next()) |code| {
            try codes.append(code);
        }
    }

    const depth: usize = if (part == aoc.Part.part2) 25 else 2;

    var cache = Cache.init(alloc);

    var total_complexity: usize = 0;
    for (codes.items) |code| {
        const numeric_code = try std.fmt.parseInt(u32, code[0 .. code.len - 1], 10);
        var seqs = std.ArrayList([]const u8).init(alloc);
        try build_numpad_seq(alloc, code, 0, 'A', "", &seqs);

        var shortest: usize = std.math.maxInt(usize);
        for (seqs.items) |path| {
            const len = try shortest_seq(alloc, path, depth, &cache);
            if (len < shortest) {
                shortest = len;
            }
        }

        const complexity = shortest * numeric_code;
        total_complexity += complexity;
    }

    std.debug.print("{d}\n", .{total_complexity});
}
