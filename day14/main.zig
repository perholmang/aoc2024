const std = @import("std");
const aoc = @import("helpers.zig");
const data = @embedFile("input.txt");
const Allocator = std.mem.Allocator;

const TEST_INPUT =
    \\p=0,4 v=3,-3
    \\p=6,3 v=-1,-3
    \\p=10,3 v=-1,2
    \\p=2,0 v=2,-1
    \\p=0,0 v=1,3
    \\p=3,0 v=-2,-2
    \\p=7,6 v=-1,-3
    \\p=3,0 v=-1,-2
    \\p=9,3 v=2,3
    \\p=7,3 v=-1,2
    \\p=2,4 v=2,-3
    \\p=9,5 v=-3,-3
;

const Pos = @Vector(2, i32);

fn robot_position_after(initial: Pos, d: Pos, rows: usize, cols: usize, n: usize) Pos {
    const n_i32 = @as(i32, @intCast(n));
    const nx = @mod(initial[0] + (d[0] * n_i32), @as(i32, @intCast(cols)));
    const ny = @mod(initial[1] + (d[1] * n_i32), @as(i32, @intCast(rows)));

    return Pos{ nx, ny };
}

fn print_map(positions: std.AutoHashMap(
    Pos,
    bool,
), rows: usize, cols: usize) void {
    for (0..rows) |y| {
        for (0..cols) |x| {
            if (positions.contains(Pos{ @as(i32, @intCast(x)), @as(i32, @intCast(y)) })) {
                std.debug.print("#", .{});
            } else {
                std.debug.print(".", .{});
            }
        }
        std.debug.print("\n", .{});
    }
}

// try to find
fn check_density(position_hashmap: std.AutoHashMap(Pos, bool), rows: usize, cols: usize) bool {
    var next_match: usize = 13;

    for (0..rows) |y| {
        var count: u16 = 0;
        for (0..cols) |x| {
            if (position_hashmap.contains(Pos{ @as(i32, @intCast(x)), @as(i32, @intCast(y)) })) {
                count += 1;
            } else {
                count = 0;
            }

            if (count == next_match) {
                if (next_match == 17) {
                    return true;
                } else {
                    next_match += 2;
                }
            }
        }
    }
    return false;
}

// fn check_christmas_tree(positions: []Pos, rows: usize, cols: usize) bool {
//     for (0..rows) |row| {
//         const number_of_branches = 2 * row + 1;
//         for (0..number_of_branches) |branch| {
//             _ = branch;
//             const x = cols / 2 - (number_of_branches / 2);
//             _ = x;
//         }
//     }
// }

fn get_safety_factor(robots: []Robot, rows: usize, cols: usize) usize {
    var q1: usize = 0;
    var q2: usize = 0;
    var q3: usize = 0;
    var q4: usize = 0;

    const half_cols = cols / 2;
    const half_rows = rows / 2;

    for (robots) |robot| {
        const new_pos = robot_position_after(robot.position, robot.velocity, rows, cols, 100);

        if (new_pos[0] == half_cols or new_pos[1] == half_rows) {
            continue;
        }

        if (new_pos[0] < half_cols and new_pos[1] < half_rows) {
            q1 += 1;
        } else if (new_pos[0] < half_cols and new_pos[1] > half_rows) {
            q2 += 1;
        } else if (new_pos[0] > half_cols and new_pos[1] < half_rows) {
            q3 += 1;
        } else {
            q4 += 1;
        }
    }

    return q1 * q2 * q3 * q4;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    const part = try aoc.getPart(alloc);

    var input_parser = InputParser{ .input = data };
    const robots = try input_parser.parse(alloc);
    defer alloc.free(robots);

    if (part == aoc.Part.part1) {
        const safety_factor = get_safety_factor(robots, 103, 101);
        std.debug.print("{d}\n", .{safety_factor});
    } else {
        for (0..8000) |i| {
            var position_hashmap = std.AutoHashMap(Pos, bool).init(alloc);
            defer position_hashmap.deinit();

            for (robots) |robot| {
                const new_pos = robot_position_after(robot.position, robot.velocity, 103, 101, i);
                try position_hashmap.put(new_pos, true);
            }

            if (check_density(position_hashmap, 103, 101)) {
                std.debug.print("{d}\n", .{i});
            }
        }
    }
}

const Robot = struct {
    position: Pos,
    velocity: Pos,
};

const InputParser = struct {
    const State = enum { PosX, PosY, VelX, VelY };

    state: State = State.PosX,
    input: []const u8,
    idx: usize = 0,
    is_negative: bool = false,

    fn consumeNum(self: *InputParser) i32 {
        var num: i32 = 0;
        while (self.idx < self.input.len) {
            const c: u8 = self.input[self.idx];
            if (c >= '0' and c <= '9') {
                num = num * 10 + (c - '0');
                self.idx += 1;
            } else {
                break;
            }
        }
        self.idx -= 1;
        return num;
    }

    pub fn parse(self: *InputParser, alloc: Allocator) ![]Robot {
        var px: i32 = 0;
        var py: i32 = 0;
        var vx: i32 = 0;
        var vy: i32 = 0;

        var rows = std.ArrayList(Robot).init(alloc);

        while (self.idx < self.input.len) {
            defer self.idx += 1;
            const c: u8 = self.input[self.idx];
            const is_num = c >= '0' and c <= '9';
            const is_minus = c == '-';

            if (is_minus) {
                self.is_negative = true;
            }

            if (is_num) {
                const den: i32 = if (self.is_negative) -1 else 1;
                const num: i32 = self.consumeNum() * den;
                self.is_negative = false;
                switch (self.state) {
                    .PosX => {
                        px = num;
                        self.state = State.PosY;
                    },
                    .PosY => {
                        py = num;
                        self.state = State.VelX;
                    },
                    .VelX => {
                        vx = num;
                        self.state = State.VelY;
                    },
                    .VelY => {
                        vy = num;
                        self.state = State.PosX;

                        try rows.append(Robot{
                            .position = Pos{ px, py },
                            .velocity = Pos{ vx, vy },
                        });
                    },
                }
            }
        }

        return rows.toOwnedSlice();
    }
};

test "get_safety_factor" {
    var input_parser = InputParser{ .input = TEST_INPUT };
    const robots = try input_parser.parse(std.testing.allocator);
    defer std.testing.allocator.free(robots);

    const safety_factor = get_safety_factor(robots, 7, 11);
    try std.testing.expect(safety_factor == 12);
}
