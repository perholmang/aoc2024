const std = @import("std");
const aoc = @import("helpers.zig");
const data = @embedFile("input.txt");
const Allocator = std.mem.Allocator;

fn matches_design(design: []const u8, patterns: [][]const u8) bool {
    if (design.len == 0) {
        return true;
    }
    for (patterns) |pattern| {
        if (design.len < pattern.len) {
            continue;
        }
        const idx = design.len - pattern.len;
        //std.debug.print("Checking design: '{s}' {s}\n", .{ design[idx..], pattern });
        if (std.mem.eql(u8, design[idx..], pattern)) {
            const remaining_design = design[0..idx];
            //std.debug.print("-> MATCH: '{s}' {s}\n", .{ design[idx..], pattern });
            if (matches_design(remaining_design, patterns)) {
                return true;
            }
        }
    }
    return false;
}

test "matches_design" {
    //const design = "brwrr";
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

    const result = matches_design("bwurrg", patterns.items);
    try std.testing.expectEqual(true, result);
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    const part = try aoc.getPart(alloc);
    _ = part;

    const parsed_data = try parse(alloc, data);
    const patterns = parsed_data.patterns;
    const designs = parsed_data.designs;

    // std.debug.print("{s}\n", .{patterns});

    var possible_designs: usize = 0;
    for (designs) |design| {
        if (matches_design(design, patterns)) {
            std.debug.print("Matched design: {s}\n", .{design});
            possible_designs += 1;
        }
    }
    std.debug.print("{d}\n", .{possible_designs});
}

const ParsedData = struct {
    patterns: [][]const u8,
    designs: [][]const u8,
};

fn parse(alloc: Allocator, input: []const u8) !ParsedData {
    var reading_patterns: bool = true;
    var patterns = std.ArrayList([]const u8).init(alloc);
    var designs = std.ArrayList([]const u8).init(alloc);

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
            try designs.append(line);
        }
    }

    const patterns_arr = try patterns.toOwnedSlice();

    std.mem.sort([]const u8, patterns_arr, {}, longer);

    return ParsedData{ .patterns = patterns_arr, .designs = try designs.toOwnedSlice() };
}

fn longer(_: void, u: []const u8, v: []const u8) bool {
    return u.len > v.len;
}
