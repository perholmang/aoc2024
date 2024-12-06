const std = @import("std");
const aoc = @import("helpers.zig");
const data = @embedFile("input.txt");
const Allocator = std.mem.Allocator;

const TEST_DATA =
    \\....#.....
    \\.........#
    \\........#.
    \\..#.......
    \\.......#..
    \\..........
    \\.#..^.....
    \\........#.
    \\#.........
    \\......#...
;
const GRID_SIZE = 130;

const Direction = enum {
    Up,
    Right,
    Down,
    Left,
};

const Guard = struct {
    pos: usize,
    direction: Direction,
    grid: []const u8,
    row_size: usize,

    const State = enum { Walk, Turn, Exit };

    pub fn init(grid: []const u8, row_size: usize) Guard {
        const start = findStart(grid);
        return .{ .pos = start.idx, .direction = start.direction, .grid = grid, .row_size = row_size };
    }

    fn will_loop(self: *Guard, allocator: Allocator) !bool {
        var visited = std.AutoHashMap(PosAndDir, void).init(allocator);

        while (true) {
            const direction = self.direction;
            const next = self.step();
            const key = .{ .idx = self.pos, .direction = direction };
            switch (next) {
                .Walk => {},
                .Turn => {
                    //const posAndDir: PosAndDir = .{ .idx = self.pos, .direction = direction };
                    if (visited.contains(key)) {
                        return true;
                    }

                    try visited.put(key, void{});
                },
                .Exit => return false,
            }
        }
    }

    fn find_visited_nodes(self: *Guard, allocator: Allocator) !std.AutoHashMap(usize, void) {
        var visited = std.AutoHashMap(usize, void).init(allocator);
        while (true) {
            try visited.put(self.pos, void{});
            const next = self.step();
            switch (next) {
                .Walk => {},
                .Turn => {},
                .Exit => return visited,
            }
        }

        unreachable;
    }

    fn step(self: *Guard) State {
        const x = @as(i32, @intCast(self.pos % self.row_size));
        const y = @as(i32, @intCast(self.pos / self.row_size));

        const nx = switch (self.direction) {
            Direction.Up, Direction.Down => x,
            Direction.Right => x + 1,
            Direction.Left => x - 1,
        };

        const ny = switch (self.direction) {
            .Left, .Right => y,
            .Down => y + 1,
            .Up => y - 1,
        };

        if (nx < 0 or ny < 0 or nx >= self.row_size or ny >= self.row_size) {
            return .Exit;
        }

        const next_idx = @as(usize, @intCast(ny)) * self.row_size + @as(usize, @intCast(nx));

        if (self.grid[next_idx] == '#') {
            self.direction = switch (self.direction) {
                Direction.Up => Direction.Right,
                Direction.Right => Direction.Down,
                Direction.Down => Direction.Left,
                Direction.Left => Direction.Up,
            };
            return .Turn;
        } else {
            self.pos = next_idx;
        }

        return .Walk;
    }
};

const PosAndDir = struct {
    idx: usize,
    direction: Direction,
};

fn findStart(
    grid: []const u8,
) PosAndDir {
    for (grid, 0..) |c, idx| {
        switch (c) {
            '^' => return .{ .idx = idx, .direction = Direction.Up },
            'v' => return .{ .idx = idx, .direction = Direction.Down },
            '<' => return .{ .idx = idx, .direction = Direction.Left },
            '>' => return .{ .idx = idx, .direction = Direction.Right },
            else => {},
        }
    }
    unreachable;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    const part = try aoc.getPart(alloc);
    const size = std.mem.replacementSize(u8, data, "\n", "");
    const grid = try alloc.alloc(u8, size);
    _ = std.mem.replace(u8, data, "\n", "", grid);

    var g = Guard.init(grid, GRID_SIZE);
    const visited_nodes = try g.find_visited_nodes(alloc);

    if (part == aoc.Part.part1) {
        std.debug.print("{d}\n", .{visited_nodes.count()});
        return;
    }

    var num_loops: usize = 0;
    for (grid, 0..) |c, idx| {
        if (!visited_nodes.contains(idx)) {
            continue;
        }
        if (c == '.') {
            grid[idx] = '#';
            var guard = Guard.init(grid, GRID_SIZE);
            if (try guard.will_loop(alloc)) {
                num_loops += 1;
            }
            grid[idx] = '.';
        }
    }

    std.debug.print("{d}\n", .{num_loops});

    // const visited = try traverse(alloc, grid, GRID_SIZE);

    // if (part == aoc.Part.part1) {
    //     std.debug.print("{d}\n", .{visited.?.count()});
    //     return;
    // }

    // std.debug.print("{d}\n", .{num_loops});
}
