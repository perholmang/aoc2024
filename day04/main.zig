const std = @import("std");
const aoc = @import("helpers.zig");
const data = @embedFile("input.txt");

const XmasFinder = struct {
    input: []const u8,
    num_lines: usize,

    const Direction = enum {
        Up,
        Down,
        Left,
        Right,
        UpLeft,
        UpRight,
        DownLeft,
        DownRight,
    };

    const Directions = [_]Direction{ Direction.Up, Direction.Down, Direction.Left, Direction.Right, Direction.UpLeft, Direction.UpRight, Direction.DownLeft, Direction.DownRight };

    pub fn init(input: []const u8, num_lines: usize) XmasFinder {
        return XmasFinder{
            .input = input,
            .num_lines = num_lines,
        };
    }

    fn toIdx(self: *XmasFinder, row: usize, col: usize) usize {
        return row * self.num_lines + col;
    }

    fn toRowAndCol(self: *XmasFinder, idx: usize) [2]usize {
        const x = idx % self.num_lines;
        const y = idx / self.num_lines;
        return [2]usize{ y, x };
    }

    pub fn countCrossMas(self: *XmasFinder) usize {
        var num_found: usize = 0;
        for (0..self.input.len) |i| {
            const pos = self.toRowAndCol(i);
            const c = self.input[i];
            if (c != 'A') {
                continue;
            }
            if (pos[0] <= 0 or pos[0] >= self.num_lines - 1 or pos[1] <= 0 or pos[1] >= self.num_lines - 1) {
                continue;
            }

            const ul = self.toIdx(pos[0] - 1, pos[1] - 1);
            const ur = self.toIdx(pos[0] + 1, pos[1] - 1);
            const dl = self.toIdx(pos[0] - 1, pos[1] + 1);
            const dr = self.toIdx(pos[0] + 1, pos[1] + 1);

            const left_to_right = (self.input[ul] == 'M' and self.input[dr] == 'S') or (self.input[ul] == 'S' and self.input[dr] == 'M');
            const right_to_left = (self.input[ur] == 'M' and self.input[dl] == 'S') or (self.input[ur] == 'S' and self.input[dl] == 'M');

            if (left_to_right and right_to_left) {
                num_found += 1;
            }
        }

        return num_found;
    }

    pub fn countXmas(self: *XmasFinder) usize {
        var num_found: usize = 0;
        for (0..self.input.len) |i| {
            const c = self.input[i];
            if (c == 'X') {
                for (Directions) |dir| {
                    if (self.findWord("XMAS", i, dir)) {
                        num_found += 1;
                    }
                }
            }
        }
        return num_found;
    }

    fn findWord(self: *XmasFinder, word: []const u8, idx: usize, dir: Direction) bool {
        const x = idx % self.num_lines;
        const y = idx / self.num_lines;
        const num_lines_i32 = @as(i32, @intCast(self.num_lines));

        for (0..word.len) |i| {
            const i_i32 = @as(i32, @intCast(i));

            const nx = switch (dir) {
                Direction.Up => @as(i32, @intCast(x)),
                Direction.Down => @as(i32, @intCast(x)),
                Direction.Left => @as(i32, @intCast(x)) - i_i32,
                Direction.Right => @as(i32, @intCast(x)) + i_i32,
                Direction.UpLeft => @as(i32, @intCast(x)) - i_i32,
                Direction.UpRight => @as(i32, @intCast(x)) + i_i32,
                Direction.DownLeft => @as(i32, @intCast(x)) - i_i32,
                Direction.DownRight => @as(i32, @intCast(x)) + i_i32,
            };

            const ny = switch (dir) {
                Direction.Up => @as(i32, @intCast(y)) - i_i32,
                Direction.Down => @as(i32, @intCast(y)) + i_i32,
                Direction.Left => @as(i32, @intCast(y)),
                Direction.Right => @as(i32, @intCast(y)),
                Direction.UpLeft => @as(i32, @intCast(y)) - i_i32,
                Direction.UpRight => @as(i32, @intCast(y)) - i_i32,
                Direction.DownLeft => @as(i32, @intCast(y)) + i_i32,
                Direction.DownRight => @as(i32, @intCast(y)) + i_i32,
            };

            if (nx < 0 or nx >= num_lines_i32 or ny < 0 or ny >= num_lines_i32) {
                return false;
            }

            const new_idx = ny * num_lines_i32 + nx;

            if (self.input[@intCast(new_idx)] != word[i]) {
                return false;
            }
        }

        return true;
    }
};

// const DATA = "MMMSXXMASMMSAMXMSMSAAMXSXMAAMMMSAMASMSMXXMASAMXAMMXXAMMXXAMASMSMSASXSSSAXAMASAAAMAMMMXMMMMMXMXAXMASX";
//const DATA = ".M.S........A..MSMS..M.S.MAA....A.ASMSM..M.S.M..............S.S.S.S.S..A.A.A.A..M.M.M.M.M...........";

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    const part = try aoc.getPart(alloc);

    const size = std.mem.replacementSize(u8, data, "\n", "");
    const output = try alloc.alloc(u8, size);
    _ = std.mem.replace(u8, data, "\n", "", output);

    var finder = XmasFinder.init(output, 140);
    const num_xmas = if (part == aoc.Part.part2) finder.countCrossMas() else finder.countXmas();

    std.debug.print("{d}\n", .{num_xmas});
}
