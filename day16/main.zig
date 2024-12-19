const std = @import("std");
const aoc = @import("helpers.zig");
const data = @embedFile("input.txt");
const Allocator = std.mem.Allocator;

const directions = [_]Vec2{
    Vec2{ 0, 1 }, // down
    Vec2{ 1, 0 }, // right
    Vec2{ 0, -1 }, // up
    Vec2{ -1, 0 }, // left
};

const TEST =
    \\##########
    \\#.......E#
    \\#.######.#
    \\#S.......#
    \\##########
;

const TEST_REALLY_SIMPLE =
    \\#####
    \\#..E#
    \\#...#
    \\#S..#
    \\#####
;

const TEST_INPUT =
    \\###############
    \\#.......#....E#
    \\#.#.###.#.###.#
    \\#.....#.#...#.#
    \\#.###.#####.#.#
    \\#.#.#.......#.#
    \\#.#.#####.###.#
    \\#...........#.#
    \\###.#.#####.#.#
    \\#...#.....#.#.#
    \\#.#.#.###.#.#.#
    \\#.....#...#.#.#
    \\#.###.#.#.#.#.#
    \\#S..#.....#...#
    \\###############
;

const TEST_INPUT2 =
    \\#################
    \\#...#...#...#..E#
    \\#.#.#.#.#.#.#.#.#
    \\#.#.#.#...#...#.#
    \\#.#.#.#.###.#.#.#
    \\#...#.#.#.....#.#
    \\#.#.#.#.#.#####.#
    \\#.#...#.#.#.....#
    \\#.#.#####.#.###.#
    \\#.#.#.......#...#
    \\#.#.###.#####.###
    \\#.#.#...#.....#.#
    \\#.#.#.#####.###.#
    \\#.#.#.........#.#
    \\#.#.#.#########.#
    \\#S#.............#
    \\#################
;

const Vec2 = @Vector(2, i31);

const PosAndDir = struct {
    position: Vec2,
    direction: Vec2,
};

const DijkstraNode = struct {
    position: Vec2,
    direction: Vec2,
    cost: i64,
};

fn is_backwards(a: ?Vec2, b: Vec2) bool {
    if (a) |a_not_null| {
        return a_not_null[0] == -b[0] and a_not_null[1] == -b[1];
    } else {
        return false;
    }
}

fn get_cost(pos: Vec2, dir: Vec2, goal: Vec2) u31 {
    const diff = pos - goal + dir;

    return @max(@abs(diff[0]), @abs(diff[1]));
}

test "get_cost" {
    const c1 = get_cost(.{ 0, 0 }, .{ 1, 0 }, .{ 1, 0 }); // >, going right 0 turns
    std.debug.print("{d}\n", .{c1});
    try std.testing.expectEqual(c1, 0);

    const c2 = get_cost(.{ 0, 0 }, .{ 0, -1 }, .{ 0, 1 }); // ^, going down, 2 turns
    std.debug.print("{d}\n", .{c2});
    try std.testing.expectEqual(c2, 2);

    const c3 = get_cost(.{ 1, 0 }, .{ 1, 0 }, .{ 0, 0 }); // > going left, 2 turns
    std.debug.print("{d}\n", .{c3});
    try std.testing.expectEqual(c3, 2);

    const c4 = get_cost(.{ 0, 0 }, .{ 0, -1 }, .{ 1, 0 }); // ^ going right, 1 turn
    std.debug.print("{d}\n", .{c4});
    try std.testing.expectEqual(c4, 1);

    //const c4 = get_cost(.{ 0, 0 }, .{ 0, -1 }, .{ 0, 1 }); // 2 turns
}

fn lowerThan(context: void, a: DijkstraNode, b: DijkstraNode) std.math.Order {
    _ = context;
    return std.math.order(a.cost, b.cost);
}

const Queue = std.PriorityQueue(DijkstraNode, void, lowerThan);

const Bla = struct { cost: u64, came_from: std.ArrayList(Vec2) };

fn heuristic(_: Vec2, _: Vec2) u64 {
    return 0;
}

const BfsItem = struct {
    position: Vec2,
    came_from: ?Vec2,
    //path: std.ArrayList(Vec2),

    points_in_path: []Vec2,

    came_from_direction: Vec2,
    cost: usize,
};

const PathToGoal = struct {
    points: []Vec2,
    cost: usize,
};

fn bfs(alloc: Allocator, map: [][]const u8, start: Vec2, goal: Vec2, max_cost: usize) ![]PathToGoal {
    var visited = std.AutoHashMap(PosAndDir, usize).init(alloc);
    var pq = std.ArrayList(BfsItem).init(alloc);
    defer pq.deinit();

    try pq.append(.{
        .position = start,
        .came_from = null,
        .came_from_direction = Vec2{ 1, 0 },
        //.path = std.ArrayList(Vec2).init(alloc),
        .points_in_path = try alloc.alloc(Vec2, 1000),
        .cost = 0,
    });

    var paths = std.ArrayList(PathToGoal).init(alloc);
    defer paths.deinit();

    var cheapest_cost: usize = std.math.maxInt(usize);
    var iteration: usize = 0;

    while (pq.popOrNull()) |curr| {
        if (std.meta.eql(curr.position, goal)) {
            if (curr.cost <= cheapest_cost) {
                std.debug.print("found goal! {d}\n", .{curr.cost});
                cheapest_cost = curr.cost;
                try paths.append(PathToGoal{ .points = curr.points_in_path, .cost = curr.cost });
                //print_map_with_steps(map, curr.points_in_path);
            }

            continue;
        }

        if (visited.get(PosAndDir{ .direction = curr.came_from_direction, .position = curr.position })) |prev_cost| {
            if (curr.cost > prev_cost) {
                continue;
            } else {
                try visited.put(PosAndDir{ .direction = curr.came_from_direction, .position = curr.position }, curr.cost);
            }
        } else {
            try visited.put(PosAndDir{ .direction = curr.came_from_direction, .position = curr.position }, curr.cost);
        }

        if (curr.cost > cheapest_cost or curr.cost > max_cost) {
            continue;
        }
        defer iteration += 1;

        if (iteration % 10000 == 0) {
            std.debug.print("Iteration: {d} {d} cost: {d}\n", .{ iteration, curr.position, curr.cost });
        }

        for (directions) |dir| {
            var num_added: usize = 0;
            const next_pos: Vec2 = curr.position + dir;

            const num_turns = get_cost(curr.position, curr.came_from_direction, next_pos);
            const next_cost = (num_turns * 1000) + 1;

            if (next_pos[0] < 0 or next_pos[0] >= map[0].len or next_pos[1] < 0 or next_pos[1] > map.len) {
                continue;
            }

            if (curr.came_from) |came_from| {
                if (std.meta.eql(next_pos, came_from)) {
                    continue;
                }
            }

            const nx = @as(usize, @intCast(next_pos[0]));
            const ny = @as(usize, @intCast(next_pos[1]));

            if (map[ny][nx] == '#') {
                continue;
            }

            if (!array_contains(Vec2, curr.points_in_path, next_pos)) {
                const new_points = try alloc.alloc(Vec2, curr.points_in_path.len + 1);
                @memcpy(new_points[0..curr.points_in_path.len], curr.points_in_path);
                new_points[curr.points_in_path.len] = next_pos;

                try pq.append(BfsItem{
                    .position = next_pos,
                    .came_from = curr.position,
                    .points_in_path = new_points,
                    .came_from_direction = dir,
                    .cost = curr.cost + next_cost,
                });
                num_added += 1;
            }
        }
    }

    var ret = std.ArrayList(PathToGoal).init(alloc);
    defer ret.deinit();

    for (paths.items) |path| {
        if (path.cost == cheapest_cost) {
            try ret.append(path);
        }
    }

    return ret.toOwnedSlice();
}

fn dijkstra(alloc: Allocator, map: [][]const u8, start: Vec2, _: Vec2) !std.AutoHashMap(Vec2, Bla) {
    var visited = std.AutoHashMap(PosAndDir, void).init(alloc);
    var cost_map = std.AutoHashMap(Vec2, Bla).init(alloc);
    for (map, 0..) |row, y| {
        for (row, 0..) |_, x| {
            if (start[0] == x and start[1] == y) {
                try cost_map.put(Vec2{ @intCast(x), @intCast(y) }, .{ .cost = 0, .came_from = std.ArrayList(Vec2).init(alloc) });
            } else {
                try cost_map.put(Vec2{ @intCast(x), @intCast(y) }, .{ .cost = std.math.maxInt(u64), .came_from = std.ArrayList(Vec2).init(alloc) });
            }
        }
    }

    var pq = Queue.init(alloc, {});
    defer pq.deinit();

    try pq.add(DijkstraNode{
        .position = start,
        .direction = Vec2{ 1, 0 },
        .cost = 0,
    });

    while (pq.count() > 0) {
        const curr = pq.remove();

        //const x = @as(usize, @intCast(curr.position[0]));
        //const y = @as(usize, @intCast(curr.position[1]));

        //std.debug.print("[{c}] {d}\n", .{ map[y][x], curr.position });

        if (visited.contains(.{ .position = curr.position, .direction = curr.direction })) {
            continue;
        }

        try visited.put(.{ .position = curr.position, .direction = curr.direction }, void{});

        for (directions) |dir| {
            const next_pos = curr.position + dir;

            if (is_backwards(curr.direction, dir)) {
                continue;
            }

            if (std.meta.eql(curr.position, Vec2{ 6, 1 })) {
                //std.debug.print("curr: {d} {d} {d}\n", .{ curr.position, dir, next_pos });
                continue;
            }

            if (next_pos[0] < 0 or next_pos[0] >= map[0].len or next_pos[1] < 0 or next_pos[1] > map.len) {
                continue;
            }

            const nx = @as(usize, @intCast(next_pos[0]));
            const ny = @as(usize, @intCast(next_pos[1]));

            const num_turns = get_cost(curr.position, curr.direction, next_pos);
            const next_cost = (num_turns * 1000) + 1;

            if (map[ny][nx] == '#') {
                continue;
            }

            if (cost_map.get(next_pos)) |prev_cost| {
                const new_cost = @as(u64, @intCast(curr.cost + next_cost));

                if (new_cost <= prev_cost.cost) {
                    var new_came_from = try prev_cost.came_from.clone();
                    try new_came_from.append(curr.position);

                    try cost_map.put(next_pos, .{ .cost = new_cost, .came_from = new_came_from });
                }
            }

            try pq.add(DijkstraNode{
                .position = curr.position + dir,
                .direction = dir,
                .cost = curr.cost + next_cost,
            });
        }
    }

    return cost_map;
}

fn backtrack(
    alloc: Allocator,
    cost_map: std.AutoHashMap(Vec2, Bla),
    _: Vec2,
    goal: Vec2,
) !std.AutoHashMap(Vec2, u8) {
    var ret = std.AutoHashMap(Vec2, u8).init(alloc);

    var q = std.ArrayList(Vec2).init(alloc);
    defer q.deinit();
    try q.append(goal);

    var count: usize = 0;

    while (q.popOrNull()) |next| {
        const from = cost_map.get(next) orelse unreachable;
        count += 1;

        try ret.put(next, 'O');

        for (from.came_from.items) |node| {
            try q.append(node);
            //std.debug.print("{d} ", .{dir});
            // const dx: i31 = dir[0];
            // const dy: i31 = dir[1];

            // var char: u8 = 'a';
            // if (dx == -1) {
            //     char = '<';
            // } else if (dx == 1) {
            //     char = '>';
            // } else if (dy == -1) {
            //     char = '^';
            // } else if (dy == 1) {
            //     char = 'v';
            // }

            //next_pos = next_step.prev_node;

        }
    }

    std.debug.print("Count: {d}\n", .{count});

    // while (!std.meta.eql(next_pos, start)) {
    //     if (cost_map.get(next_pos)) |next_step| {
    //         for (next_step.directions.items) |dir| {
    //             //std.debug.print("{d} ", .{dir});
    //             const dx: i31 = dir[0];
    //             const dy: i31 = dir[1];

    //             var char: u8 = 'a';
    //             if (dx == -1) {
    //                 char = '<';
    //             } else if (dx == 1) {
    //                 char = '>';
    //             } else if (dy == -1) {
    //                 char = '^';
    //             } else if (dy == 1) {
    //                 char = 'v';
    //             }

    //             try ret.put(next_pos, char);

    //             next_pos = next_step.prev_node;
    //         }
    //     } else {
    //         unreachable;
    //     }
    // }

    return ret;
}

const MapAndStartPos = struct { map: [][]const u8, start_pos: Vec2, end_pos: Vec2 };

fn create_map(
    alloc: Allocator,
    input: anytype,
) !MapAndStartPos {
    var lines_it = std.mem.splitSequence(u8, input, "\n");
    var out = std.ArrayList([]const u8).init(alloc);
    var start_pos = Vec2{ 0, 0 };
    var end_pos = Vec2{ 0, 0 };
    var line_num: usize = 0;
    while (lines_it.next()) |line| {
        for (line, 0..) |c, x| {
            if (c == 'S') {
                start_pos = Vec2{ @intCast(x), @intCast(line_num) };
            }
            if (c == 'E') {
                end_pos = Vec2{ @intCast(x), @intCast(line_num) };
            }
        }
        //@memcpy(mut, line);
        try out.append(line);
        line_num += 1;
    }

    return MapAndStartPos{ .map = try out.toOwnedSlice(), .start_pos = start_pos, .end_pos = end_pos };
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    const part = try aoc.getPart(alloc);

    const map_and_start_pos = try create_map(alloc, data);

    const cost_map = try dijkstra(alloc, map_and_start_pos.map, map_and_start_pos.start_pos, map_and_start_pos.end_pos);

    if (part == aoc.Part.part1) {
        const cost = cost_map.get(map_and_start_pos.end_pos) orelse unreachable;
        std.debug.print("{d}\n", .{cost.cost});
    } else {
        const bfs_result = try bfs(alloc, map_and_start_pos.map, map_and_start_pos.start_pos, map_and_start_pos.end_pos, 101492);

        var point_map = std.AutoHashMap(Vec2, void).init(alloc);
        for (bfs_result) |path| {
            for (path.points) |pos| {
                try point_map.put(pos, void{});
            }
        }

        std.debug.print("Point map: {d}\n", .{point_map.count()});
    }
}

fn print_map(map: [][]const u8) void {
    for (map) |row| {
        for (row) |col| {
            std.debug.print("{c}", .{col});
        }
        std.debug.print("\n", .{});
    }
}

fn print_map_with_steps_as_map(map: [][]const u8, steps: std.AutoHashMap(Vec2, void), current: Vec2) void {
    for (map, 0..) |row, y| {
        for (row, 0..) |col, x| {
            if (std.meta.eql(current, Vec2{ @as(i31, @intCast(x)), @as(i31, @intCast(y)) })) {
                std.debug.print("{c}", .{'X'});
                continue;
            }
            if (steps.get(Vec2{ @as(i31, @intCast(x)), @as(i31, @intCast(y)) })) |_| {
                std.debug.print("{c}", .{'O'});
            } else {
                std.debug.print("{c}", .{col});
            }
        }
        std.debug.print("\n", .{});
    }
    std.debug.print("\n", .{});
}

fn print_map_with_steps(map: [][]const u8, path: []Vec2) void {
    for (map, 0..) |row, y| {
        for (row, 0..) |col, x| {
            const pos = Vec2{ @as(i31, @intCast(x)), @as(i31, @intCast(y)) };
            if (array_contains(Vec2, path, pos)) {
                std.debug.print("{c}", .{'O'});
            } else {
                std.debug.print("{c}", .{col});
            }
        }
        std.debug.print("\n", .{});
    }
}

fn array_contains(comptime T: type, haystack: []const T, needle: T) bool {
    for (haystack) |element|
        if (std.meta.eql(element, needle))
            return true;
    return false;
}
