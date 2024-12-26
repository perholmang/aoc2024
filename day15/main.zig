const std = @import("std");
const aoc = @import("helpers.zig");
const data = @embedFile("input.txt");
const Allocator = std.mem.Allocator;

const Pos = @Vector(2, i31);

const UP = Pos{ -1, 0 };
const DOWN = Pos{ 1, 0 };
const LEFT = Pos{ 0, -1 };
const RIGHT = Pos{ 0, 1 };

const TEST_DOUBLE_MAP =
    \\#######
    \\#...#.#
    \\#.....#
    \\#..OO@#
    \\#..O..#
    \\#.....#
    \\#######
    \\
    \\<vv<<^^<<^^
;

// v<<^^<<^^

const TEST_INPUT_CUSTOM =
    \\########
    \\#......#
    \\#...O..#
    \\#...O..#
    \\#...O..#
    \\#..@O..#
    \\#......#
    \\########
    \\
    \\>>
;

const TEST_MOVE_UP =
    \\#######
    \\#...#.#
    \\#.....#
    \\#..OO.#
    \\#..O..#
    \\#..@..#
    \\#######
    \\
    \\^^
;
const TEST_INPUT_SIMPLE =
    \\########
    \\#..O.O.#
    \\##@.O..#
    \\#...O..#
    \\#.#.O..#
    \\#...O..#
    \\#......#
    \\########
    \\
    \\<^^>>>vv<v>>v<<
;

const TEST_INPUT =
    \\##########
    \\#..O..O.O#
    \\#......O.#
    \\#.OO..O.O#
    \\#..O@..O.#
    \\#O#..O...#
    \\#O..O..O.#
    \\#.OO.O.OO#
    \\#....O...#
    \\##########
    \\
    \\<vv>^<v^>v>^vv^v>v<>v^v<v<^vv<<<^><<><>>v<vvv<>^v^>^<<<><<v<<<v^vv^v>^
    \\vvv<<^>^v^^><<>>><>^<<><^vv^^<>vvv<>><^^v>^>vv<>v<<<<v<^v>^<^^>>>^<v<v
    \\><>vv>v^v^<>><>>>><^^>vv>v<^^^>>v^v^<^^>v^^>v^<^v>v<>>v^v^<v>v^^<^^vv<
    \\<<v<^>>^^^^>>>v^<>vvv^><v<<<>^^^vv^<vvv>^>v<^^^^v<>^>vvvv><>>v^<<^^^^^
    \\^><^><>>><>^^<<^^v>>><^<v>^<vv>>v>>>^v><>^v><<<<v>>v<v<v>vvv>^<><<>^><
    \\^>><>^v<><^vvv<^^<><v<<<<<><^v<<<><<<^^<v<^^^><^>>^<v^><<<^>>^v<v^v<v^
    \\>^>>^v>vv>^<<^v<>><<><<v<<v><>v<^vv<<<>^^v^>^^>>><<^v>>v^v><^^>>^<>vv^
    \\<><^^>^^^<><vvvvv^v<v<<>^v<v>v<<^><<><<><<<^^<<<^<<>><<><^^^>^^<>^>v<>
    \\^^>vv<^v^v<vv>^<><v<^v>^^^>>>^^vvv^>vvv<>>>^<^>>>>>^<<^v>^vvv<>^<><<v>
    \\v^^>>><<^^<>>^v^<v^vv<>v^<<>^<^v^v><^<<<><<^<v><v<>vv>>v><v^<vv<>v^<<^
;

const Move = struct {
    from: Pos,
    to: Pos,
};

fn get_move_vector(move: u8) Pos {
    return switch (move) {
        '<' => Pos{ 0, -1 },
        '>' => Pos{ 0, 1 },
        '^' => Pos{ -1, 0 },
        'v' => Pos{ 1, 0 },
        else => @panic("invalid move"),
    };
}

fn get_map_char(map: [][]u8, pos: Pos) u8 {
    const pos_x = @as(usize, @intCast(pos[1]));
    const pos_y = @as(usize, @intCast(pos[0]));
    return map[pos_y][pos_x];
}

fn apply_move(alloc: Allocator, map: [][]u8, robot_pos: Pos, move: u8) !Pos {
    const direction = get_move_vector(move);
    const robot_pos_x = @as(usize, @intCast(robot_pos[1]));
    const robot_pos_y = @as(usize, @intCast(robot_pos[0]));

    var boxes_to_move = std.ArrayList(Pos).init(alloc);
    var moves_to_check = std.ArrayList(Pos).init(alloc);
    defer moves_to_check.deinit();
    defer boxes_to_move.deinit();

    try moves_to_check.append(robot_pos + direction);

    while (moves_to_check.popOrNull()) |next| {
        const new_pos_x = @as(usize, @intCast(next[1]));
        const new_pos_y = @as(usize, @intCast(next[0]));

        if (map[new_pos_y][new_pos_x] == '#') return robot_pos;

        switch (map[new_pos_y][new_pos_x]) {
            '#' => return robot_pos,
            'O' => {
                try moves_to_check.append(next + direction);
                try boxes_to_move.append(next);
            },
            '[' => {
                try boxes_to_move.append(next);
                try moves_to_check.append(next + direction);
                if (std.meta.eql(direction, UP) or std.meta.eql(direction, DOWN)) {
                    try boxes_to_move.append(next + RIGHT);
                    try moves_to_check.append(next + direction + RIGHT);
                }
            },
            ']' => {
                try boxes_to_move.append(next);
                try moves_to_check.append(next + direction);

                if (std.meta.eql(direction, UP) or std.meta.eql(direction, DOWN)) {
                    try boxes_to_move.append(next + LEFT);
                    try moves_to_check.append(next + direction + LEFT);
                }
            },
            '.' => {},
            else => {},
        }
    }

    var moved = std.AutoHashMap(Pos, void).init(alloc);
    defer moved.deinit();

    var idx: usize = 1;
    while (idx <= boxes_to_move.items.len) : (idx += 1) {
        const box = boxes_to_move.items[boxes_to_move.items.len - idx];
        if (moved.contains(box)) {
            continue;
        }

        const box_new_pos = box + direction;
        const box_old_x = @as(usize, @intCast(box[1]));
        const box_old_y = @as(usize, @intCast(box[0]));
        const box_new_x = @as(usize, @intCast(box_new_pos[1]));
        const box_new_y = @as(usize, @intCast(box_new_pos[0]));
        const box_char = map[box_old_y][box_old_x];
        map[box_new_y][box_new_x] = box_char;
        map[box_old_y][box_old_x] = '.';

        try moved.put(box, void{});
    }

    const new_pos = robot_pos + direction;
    const new_robot_pos_x = @as(usize, @intCast(new_pos[1]));
    const new_robot_pos_y = @as(usize, @intCast(new_pos[0]));

    map[new_robot_pos_y][new_robot_pos_x] = '@';
    map[robot_pos_y][robot_pos_x] = '.';

    return new_pos;
}

fn print_map(map: [][]u8) void {
    for (map) |row| {
        for (row) |c| {
            std.debug.print("{c}", .{c});
        }
        std.debug.print("\n", .{});
    }
}

fn get_box_coordinate_sum(map: [][]u8) usize {
    var sum: usize = 0;
    for (map, 0..) |row, y| {
        for (row, 0..) |c, x| {
            if (c == 'O' or c == '[') {
                sum += (y * 100) + x;
            }
        }
    }
    return sum;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    const part = try aoc.getPart(alloc);

    const map_and_moves = try parse_data(alloc, data, part == aoc.Part.part2);
    const map = map_and_moves.map;
    var q = std.ArrayList(u8).init(alloc);
    for (0..map_and_moves.moves.len) |i| {
        try q.append(map_and_moves.moves[map_and_moves.moves.len - i - 1]);
    }

    var robot_pos = map_and_moves.robot_position;

    var moves: usize = 0;

    while (q.popOrNull()) |move| {
        robot_pos = try apply_move(alloc, map, robot_pos, move);
        moves += 1;
    }

    const total_sum = get_box_coordinate_sum(map);

    std.debug.print("{d}\n", .{total_sum});
}

const MapAndMoves = struct {
    map: [][]u8,
    moves: []u8,
    robot_position: @Vector(2, i31),
};

fn parse_data(alloc: Allocator, input: []const u8, double: bool) !MapAndMoves {
    var lines_it = std.mem.splitSequence(u8, input, "\n");
    var reading_moves = false;
    var map = std.ArrayList([]u8).init(alloc);
    var moves = std.ArrayList(u8).init(alloc);
    var robot_position = @Vector(2, i31){ 0, 0 };

    defer moves.deinit();
    defer map.deinit();

    while (lines_it.next()) |line| {
        if (line.len < 2) {
            reading_moves = true;
            continue;
        }

        if (!reading_moves) {
            const size: usize = if (double) 2 else 1;
            const mut: []u8 = try alloc.alloc(u8, line.len * size);
            //@memcpy(mut, line);
            for (0..line.len) |i| {
                const c = line[i];
                switch (c) {
                    '#' => {
                        mut[i * size] = '#';
                        if (double) mut[i * 2 + 1] = '#';
                    },
                    '.' => {
                        mut[i * size] = '.';
                        if (double) mut[i * 2 + 1] = '.';
                    },
                    'O' => {
                        if (double) {
                            mut[i * size] = '[';
                            mut[i * size + 1] = ']';
                        } else {
                            mut[i * size] = 'O';
                        }
                    },
                    '@' => {
                        mut[i * size] = '@';
                        if (double) mut[i * size + 1] = '.';
                    },
                    else => {
                        std.debug.print("invalid char: {c}\n", .{c});
                        @panic("invalid char");
                    },
                }
            }

            for (line, 0..) |c, x| {
                if (c == '@') {
                    if (double) {
                        robot_position = @Vector(2, i31){ @as(i31, @intCast(map.items.len)), @as(i31, @intCast(x * 2)) };
                    } else {
                        robot_position = @Vector(2, i31){ @as(i31, @intCast(map.items.len)), @as(i31, @intCast(x)) };
                    }
                }
            }
            try map.append(mut);
        } else {
            for (line) |c| {
                try moves.append(c);
            }
        }
    }

    return .{
        .map = try map.toOwnedSlice(),
        .moves = try moves.toOwnedSlice(),
        .robot_position = robot_position,
    };
}

// test "small_example" {
//     const alloc = std.testing.allocator;
//     const map_and_moves = try parse_data(alloc, TEST_INPUT_SIMPLE, false);
//     defer alloc.free(map_and_moves.map);
//     defer alloc.free(map_and_moves.moves);

//     defer {
//         for (map_and_moves.map) |row| {
//             alloc.free(row);
//         }
//     }

//     const map = map_and_moves.map;
//     var moves: usize = 0;
//     var q = std.ArrayList(u8).init(alloc);
//     defer q.deinit();
//     for (0..map_and_moves.moves.len) |i| {
//         try q.append(map_and_moves.moves[map_and_moves.moves.len - i - 1]);
//     }

//     var robot_pos = map_and_moves.robot_position;

//     while (q.popOrNull()) |move| {
//         std.debug.print("{c}\n", .{move});
//         robot_pos = try apply_move(alloc, map, robot_pos, move);
//         moves += 1;
//         print_map(map);
//     }

//     const total_sum = get_box_coordinate_sum(map);

//     try std.testing.expectEqual(total_sum, 2028);
// }

test "double_map" {
    const alloc = std.testing.allocator;
    const map_and_moves = try parse_data(alloc, TEST_DOUBLE_MAP, true);
    defer alloc.free(map_and_moves.map);
    defer alloc.free(map_and_moves.moves);

    defer {
        for (map_and_moves.map) |row| {
            alloc.free(row);
        }
    }

    const map = map_and_moves.map;
    var moves: usize = 0;
    var q = std.ArrayList(u8).init(alloc);
    defer q.deinit();
    for (0..map_and_moves.moves.len) |i| {
        try q.append(map_and_moves.moves[map_and_moves.moves.len - i - 1]);
    }

    var robot_pos = map_and_moves.robot_position;

    std.debug.print("robot: {d}\n", .{robot_pos});

    print_map(map);

    while (q.popOrNull()) |move| {
        std.debug.print("{c}\n", .{move});
        robot_pos = try apply_move(alloc, map, robot_pos, move);
        moves += 1;
        print_map(map);
    }

    //const total_sum = get_box_coordinate_sum(map);

    //try std.testing.expectEqual(total_sum, 2028);
}

// test "move_up" {
//     const alloc = std.testing.allocator;
//     const map_and_moves = try parse_data(alloc, TEST_MOVE_UP, true);
//     defer alloc.free(map_and_moves.map);
//     defer alloc.free(map_and_moves.moves);

//     defer {
//         for (map_and_moves.map) |row| {
//             alloc.free(row);
//         }
//     }

//     const map = map_and_moves.map;
//     var moves: usize = 0;
//     var q = std.ArrayList(u8).init(alloc);
//     defer q.deinit();
//     for (0..map_and_moves.moves.len) |i| {
//         try q.append(map_and_moves.moves[map_and_moves.moves.len - i - 1]);
//     }

//     var robot_pos = map_and_moves.robot_position;

//     std.debug.print("robot: {d}\n", .{robot_pos});

//     print_map(map);

//     while (q.popOrNull()) |move| {
//         std.debug.print("{c}\n", .{move});
//         robot_pos = try apply_move(alloc, map, robot_pos, move);
//         moves += 1;
//         print_map(map);
//     }

//     //const total_sum = get_box_coordinate_sum(map);

//     //try std.testing.expectEqual(total_sum, 2028);
// }
