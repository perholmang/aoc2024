const std = @import("std");
const aoc = @import("helpers.zig");
const data = @embedFile("input.txt");
const Allocator = std.mem.Allocator;

const Pos = @Vector(2, i32);

const TEST_DATA =
    \\............
    \\........0...
    \\.....0......
    \\.......0....
    \\....0.......
    \\......A.....
    \\............
    \\............
    \\........A...
    \\.........A..
    \\............
    \\............
;

const TEST_DATA_T =
    \\T.........
    \\...T......
    \\.T........
    \\..........
    \\..........
    \\..........
    \\..........
    \\..........
    \\..........
    \\..........
;

fn findFrequencies(alloc: Allocator, grid: []const u8, freq: u8) ![]usize {
    //var frequencies = []u8{};
    var freq_list = std.ArrayList(usize).init(alloc);

    for (grid, 0..) |cell, i| {
        if (cell == '.') {
            continue;
        }

        if (cell == freq) {
            try freq_list.append(i);
        }
    }

    return freq_list.items;
}

fn findOffset(row_size: usize, idx: usize, other_idx: usize) [2]i32 {
    const pos = aoc.toRowAndCol(row_size, idx);
    const other_pos = aoc.toRowAndCol(row_size, other_idx);

    const x: i32 = @as(i32, @intCast(pos[1])) - @as(i32, @intCast(other_pos[1]));
    const y: i32 = @as(i32, @intCast(pos[0])) - @as(i32, @intCast(other_pos[0]));

    return [2]i32{ x, y };
}

fn findAntinodes(alloc: Allocator, grid: []const u8, row_size: usize, updated_model: bool) !std.AutoHashMap(Pos, void) {
    var antinodes_map = std.AutoHashMap(Pos, void).init(alloc);

    for (grid, 0..) |cell, i| {
        if (cell == '.') {
            continue;
        }

        const pos = aoc.toRowAndCol(row_size, i);
        const other = try findFrequencies(alloc, grid, cell);

        for (other) |other_idx| {
            if (i == other_idx) {
                continue;
            }

            const other_pos = aoc.toRowAndCol(row_size, other_idx);
            const offset = other_pos - pos;

            var a = pos - offset;

            if (a[0] >= 0 and a[0] < row_size and a[1] >= 0 and a[1] < row_size) {
                try antinodes_map.put(a, void{});
            }

            if (updated_model) {
                try antinodes_map.put(other_pos, void{});
                while (a[0] >= 0 and a[0] < row_size and a[1] >= 0 and a[1] < row_size) {
                    try antinodes_map.put(a, void{});
                    a = a - offset;
                }
            }
        }
    }

    return antinodes_map;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    const part = try aoc.getPart(alloc);
    const col_size = 50;

    const grid = try aoc.removeNewlines(alloc, data);

    const antinodes = try findAntinodes(alloc, grid, col_size, part == aoc.Part.part2);

    std.debug.print("{d}\n", .{antinodes.count()});
}
