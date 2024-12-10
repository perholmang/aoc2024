const std = @import("std");
const aoc = @import("helpers.zig");
const data = @embedFile("input.txt");
const Allocator = std.mem.Allocator;

pub fn getNeighbours(pos_idx: usize, col_size: usize) ![]usize {
    var idx: usize = 0;
    var neighbours: [4]usize = undefined;

    const x = pos_idx % col_size;
    const y = pos_idx / col_size;

    // up
    if (y > 0) {
        neighbours[idx] = pos_idx - col_size;
        idx += 1;
    }

    // down
    if (y < col_size - 1) {
        neighbours[idx] = pos_idx + col_size;
        idx += 1;
    }

    // left
    if (x > 0) {
        neighbours[idx] = pos_idx - 1;
        idx += 1;
    }

    // right
    if (x < col_size - 1) {
        neighbours[idx] = pos_idx + 1;
        idx += 1;
    }

    return try std.heap.page_allocator.dupe(usize, neighbours[0..idx]);
}

const TrailheadScoreFinder = struct {
    map: []u8,
    trails_found: usize = 0,
    col_size: usize,
    trailhead_ends: std.AutoHashMap(usize, void),

    pub fn init(map: []u8, col_size: usize) TrailheadScoreFinder {
        return TrailheadScoreFinder{
            .map = map,
            .col_size = col_size,
            .trailhead_ends = std.AutoHashMap(usize, void).init(std.heap.page_allocator),
        };
    }

    const TrailheadResult = struct {
        rating: usize,
        score: usize,
    };

    pub fn findTrailheadScore(
        self: *TrailheadScoreFinder,
        starting_pos: usize,
    ) !TrailheadResult {
        self.trailhead_ends = std.AutoHashMap(usize, void).init(std.heap.page_allocator);
        self.trails_found = 0;
        try self.nextOrDone(starting_pos, 1);

        return .{ .rating = self.trails_found, .score = self.trailhead_ends.count() };
    }

    pub fn nextOrDone(self: *TrailheadScoreFinder, idx: usize, next_height: u8) !void {
        const neighbours = try getNeighbours(idx, self.col_size);

        for (neighbours) |n| {
            if (self.map[n] == '.') {
                continue;
            }
            const n_height = self.map[n] - '0';
            if (n_height == next_height) {
                if (next_height == 9) {
                    self.trails_found += 1;
                    try self.trailhead_ends.put(n, void{});
                } else {
                    try self.nextOrDone(n, next_height + 1);
                }
            }
        }
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    const part = try aoc.getPart(alloc);
    const map = try aoc.removeNewlines(alloc, data);

    var finder = TrailheadScoreFinder.init(map, 40);
    var total: usize = 0;

    for (map, 0..) |cell, idx| {
        if (cell == '0') {
            const trailhead = try finder.findTrailheadScore(idx);
            total += if (part == aoc.Part.part1) trailhead.score else trailhead.rating;
        }
    }

    std.debug.print("{d}\n", .{total});
}
