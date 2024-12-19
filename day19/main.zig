const std = @import("std");
const aoc = @import("helpers.zig");
const data = @embedFile("input.txt");
const Allocator = std.mem.Allocator;

fn find_num_combinations(towel: []const u8, patterns: [][]const u8, memo: *std.StringHashMap(usize)) !usize {
    if (towel.len == 0) return 1;

    if (memo.get(towel)) |val| {
        return val;
    }

    var ways: usize = 0;
    for (patterns) |pattern| {
        if (towel.len < pattern.len) {
            continue;
        }
        if (std.mem.eql(u8, towel[0..pattern.len], pattern)) {
            ways += try find_num_combinations(towel[pattern.len..], patterns, memo);
        }
    }

    try memo.put(towel, ways);

    return ways;
}

fn matches_towel(towel: []const u8, patterns: [][]const u8) bool {
    if (towel.len == 0) {
        return true;
    }
    for (patterns) |pattern| {
        if (towel.len < pattern.len) {
            continue;
        }
        const idx = towel.len - pattern.len;
        if (std.mem.eql(u8, towel[idx..], pattern)) {
            const remaining_towel = towel[0..idx];
            if (matches_towel(remaining_towel, patterns)) {
                return true;
            }
        }
    }
    return false;
}

test "matches_towel" {
    //const towel = "brwrr";
    var patterns = std.ArrayList([]const u8).init(std.testing.allocator);
    try patterns.append("r");
    try patterns.append("wr");
    try patterns.append("b");
    try patterns.append("g");
    try patterns.append("bwu");
    try patterns.append("rb");
    try patterns.append("gb");
    try patterns.append("b");
    defer patterns.deinit();

    const result = matches_towel("bwurrg", patterns.items);
    try std.testing.expectEqual(true, result);
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    const part = try aoc.getPart(alloc);

    const parsed_data = try parse(alloc, data);
    const patterns = parsed_data.patterns;
    const towels = parsed_data.towels;

    var counter: usize = 0;
    var memo = std.StringHashMap(usize).init(alloc);

    for (towels) |towel| {
        if (part == aoc.Part.part2) {
            counter += try find_num_combinations(towel, patterns, &memo);
        } else {
            counter += @intFromBool(matches_towel(towel, patterns));
        }
    }
    std.debug.print("{d}\n", .{counter});
}

const ParsedData = struct {
    patterns: [][]const u8,
    towels: [][]const u8,
};

fn parse(alloc: Allocator, input: []const u8) !ParsedData {
    var reading_patterns: bool = true;
    var patterns = std.ArrayList([]const u8).init(alloc);
    var towels = std.ArrayList([]const u8).init(alloc);

    var lines_it = std.mem.splitSequence(u8, input, "\n");

    while (lines_it.next()) |line| {
        if (line.len < 2) {
            reading_patterns = false;
            continue;
        }
        if (reading_patterns) {
            var pattern_it = std.mem.splitSequence(u8, line, ", ");
            while (pattern_it.next()) |pattern| {
                try patterns.append(pattern);
            }
        } else {
            try towels.append(line);
        }
    }

    const patterns_arr = try patterns.toOwnedSlice();

    std.mem.sort([]const u8, patterns_arr, {}, longer);

    return ParsedData{ .patterns = patterns_arr, .towels = try towels.toOwnedSlice() };
}

fn longer(_: void, u: []const u8, v: []const u8) bool {
    return u.len > v.len;
}
