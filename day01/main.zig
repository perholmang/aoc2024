const std = @import("std");
const data = @embedFile("input.txt");
const aoc = @import("helpers.zig");

fn similarityScore(left: []u32, right: []u32) u32 {
    var lft: usize = 0;
    var rgt: usize = 0;
    var similarity_score: u32 = 0;

    while (lft < left.len and rgt < right.len) {
        if (left[lft] == right[rgt]) {
            rgt += 1;
            similarity_score += left[lft];
            continue;
        } else if (left[lft] > right[rgt]) {
            rgt += 1;
        } else {
            lft += 1;
        }
    }

    return similarity_score;
}

fn totalDistance(left: []u32, right: []u32) u32 {
    var total: u32 = 0;
    for (0..left.len) |idx| {
        const diff = @abs(@as(i32, @intCast(left[idx])) - @as(i32, @intCast(right[idx])));
        total += diff;
    }
    return total;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();

    var lines_it = std.mem.splitSequence(u8, data, "\n");

    var left = std.ArrayList(u32).init(alloc);
    var right = std.ArrayList(u32).init(alloc);

    while (lines_it.next()) |line| {
        var it = std.mem.splitSequence(u8, line, "   ");

        const a = it.next() orelse continue;
        const b = it.next() orelse continue;

        const a_i = try std.fmt.parseInt(u32, a, 10);
        const b_i = try std.fmt.parseInt(u32, b, 10);

        try left.append(a_i);
        try right.append(b_i);
    }

    std.mem.sort(u32, left.items, {}, comptime std.sort.asc(u32));
    std.mem.sort(u32, right.items, {}, comptime std.sort.asc(u32));

    switch (try aoc.getPart(alloc)) {
        aoc.Part.part1 => {
            std.debug.print("{d}\n", .{totalDistance(left.items, right.items)});
        },
        aoc.Part.part2 => {
            std.debug.print("{d}\n", .{similarityScore(left.items, right.items)});
        },
    }
}
