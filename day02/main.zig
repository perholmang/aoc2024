const std = @import("std");
const aoc = @import("helpers.zig");
const data = @embedFile("input.txt");

fn isValid(levels: []i32) bool {
    const is_increasing = levels[1] > levels[0];

    for (1..levels.len) |idx| {
        const diff = levels[idx] - levels[idx - 1];
        if (@abs(diff) < 1 or @abs(diff) > 3) {
            return false;
        }
        if (is_increasing and levels[idx] < levels[idx - 1] or !is_increasing and levels[idx] > levels[idx - 1]) {
            return false;
        }
    }

    return true;
}

fn isValidWithMargin(levels: []i32, alloc: std.mem.Allocator) !bool {
    for (0..levels.len) |idx| {
        if (isValid(try std.mem.concat(alloc, i32, &[_][]const i32{ levels[0..idx], levels[idx + 1 ..] }))) return true;
    }

    return false;
}

fn parseLevels(line: []const u8, alloc: std.mem.Allocator) ![]i32 {
    var list = std.ArrayList(i32).init(alloc);
    var idx: usize = 0;
    var it = std.mem.split(u8, line, " ");

    while (it.next()) |level| {
        defer idx += 1;
        const level_i = try std.fmt.parseInt(i32, level, 10);
        try list.append(level_i);
    }

    return list.toOwnedSlice();
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();

    var lines = std.mem.split(u8, data, "\n");
    var num_safe: usize = 0;
    const part = try aoc.getPart(alloc);

    while (lines.next()) |line| {
        if (line.len == 0) continue;
        const levels = try parseLevels(line, alloc);

        switch (part) {
            aoc.Part.part1 => {
                if (isValid(levels)) num_safe += 1;
            },
            aoc.Part.part2 => {
                if (try isValidWithMargin(levels, alloc)) num_safe += 1;
            },
        }
    }

    std.debug.print("{d}\n", .{num_safe});
}
