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

const Vec2 = @Vector(2, i31);

const PosAndDir = struct {
    position: Vec2,
    direction: Vec2,
};

const DijkstraNode = struct {
    position: Vec2,
    direction: Vec2,
    cost: usize,
};

fn is_backwards(a: ?Vec2, b: Vec2) bool {
    if (a) |a_not_null| {
        return a_not_null[0] == -b[0] and a_not_null[1] == -b[1];
    } else {
        return false;
    }
}

fn lowerThan(context: void, a: DijkstraNode, b: DijkstraNode) std.math.Order {
    _ = context;
    return std.math.order(a.cost, b.cost);
}

const Queue = std.PriorityQueue(DijkstraNode, void, lowerThan);

const CheapestCost = struct { cost: u64, came_from: ?Vec2 };

const DijkstraResult = struct {
    cheapest_cost: usize,
    points_visited: std.AutoHashMap(Vec2, void),
};

fn dijkstra(alloc: Allocator, map: []const []const u8, start: Vec2, goal: Vec2) !?DijkstraResult {
    var visited = std.AutoHashMap(PosAndDir, void).init(alloc);
    var cost_map = std.AutoHashMap(Vec2, CheapestCost).init(alloc);
    for (map, 0..) |row, y| {
        for (row, 0..) |_, x| {
            if (start[0] == x and start[1] == y) {
                try cost_map.put(Vec2{ @intCast(x), @intCast(y) }, .{ .cost = 0, .came_from = null });
            } else {
                try cost_map.put(Vec2{ @intCast(x), @intCast(y) }, .{ .cost = std.math.maxInt(u64), .came_from = null });
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

        if (std.meta.eql(curr.position, goal)) {
            return .{
                .cheapest_cost = @as(usize, @intCast(curr.cost)),
                .points_visited = try find_visited_nodes(alloc, cost_map, goal),
            };
        }

        if (visited.contains(.{ .position = curr.position, .direction = curr.direction })) {
            continue;
        }

        try visited.put(.{ .position = curr.position, .direction = curr.direction }, void{});

        for (directions) |dir| {
            const next_pos = curr.position + dir;

            if (is_backwards(curr.direction, dir)) {
                continue;
            }

            if (next_pos[0] < 0 or next_pos[0] >= map[0].len or next_pos[1] < 0 or next_pos[1] >= map.len) {
                continue;
            }

            const nx = @as(usize, @intCast(next_pos[0]));
            const ny = @as(usize, @intCast(next_pos[1]));

            if (map[ny][nx] == '#') {
                continue;
            }

            if (cost_map.get(next_pos)) |prev_cost| {
                const new_cost = @as(u64, @intCast(curr.cost + 1));

                if (new_cost < prev_cost.cost) {
                    try cost_map.put(next_pos, .{ .cost = new_cost, .came_from = curr.position });
                }
            }

            try pq.add(DijkstraNode{
                .position = curr.position + dir,
                .direction = dir,
                .cost = curr.cost + 1,
            });
        }
    }

    return null;
}

fn find_visited_nodes(
    alloc: Allocator,
    cost_map: std.AutoHashMap(Vec2, CheapestCost),
    goal: Vec2,
) !std.AutoHashMap(Vec2, void) {
    var ret = std.AutoHashMap(Vec2, void).init(alloc);

    var q = std.ArrayList(Vec2).init(alloc);
    defer q.deinit();
    try q.append(goal);

    var count: usize = 0;

    while (q.popOrNull()) |next| {
        const from = cost_map.get(next) orelse unreachable;
        count += 1;

        try ret.put(next, void{});
        if (from.came_from) |from_not_null| {
            try q.append(from_not_null);
        }
    }

    return ret;
}

fn create_map(alloc: Allocator, rows: usize, cols: usize) ![][]u8 {
    var ret = try alloc.alloc([]u8, rows);
    for (0..rows) |y| {
        ret[y] = try alloc.alloc(u8, cols);
        for (0..cols) |x| {
            ret[y][x] = '.';
        }
    }
    return ret;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    const part = try aoc.getPart(alloc);

    const rows = 71;
    const cols = 71;

    const output = try create_map(alloc, rows, cols);

    try parse(output, 1024);

    if (part == aoc.Part.part1) {
        const result = try dijkstra(alloc, output, Vec2{ 0, 0 }, Vec2{ 70, 70 });
        std.debug.print("{d}\n", .{result.?.cheapest_cost});
    } else {
        var i: usize = 1024;
        const step_size = 40;
        var first_fail_idx: usize = 0;
        while (true) {
            defer i += step_size;
            if (try try_step(alloc, output, i)) {} else {
                for (1..step_size) |j| {
                    if (!try try_step(alloc, output, i - step_size + j)) {
                        first_fail_idx = i - step_size + j;
                        break;
                    }
                }
                break;
            }
        }

        const pos = find_input_line(first_fail_idx);
        std.debug.print("{s}\n", .{pos.?});
    }
}

fn try_step(alloc: Allocator, output: [][]u8, step: usize) !bool {
    for (output, 0..) |row, y| {
        for (row, 0..) |_, x| {
            output[y][x] = '.';
        }
    }
    try parse(output, step);
    const result = try dijkstra(alloc, output, Vec2{ 0, 0 }, Vec2{ 70, 70 });
    if (result) |_| {
        return true;
    }
    return false;
}

fn find_input_line(i: usize) ?[]const u8 {
    var lines_it = std.mem.splitSequence(u8, data, "\n");
    var steps: usize = 1;
    while (lines_it.next()) |line| {
        defer steps += 1;
        if (steps == i) {
            return line;
        }
    }
    return null;
}

fn parse(output: [][]u8, max_steps: usize) !void {
    var lines_it = std.mem.splitSequence(u8, data, "\n");
    var steps: usize = 1;
    while (lines_it.next()) |line| {
        defer steps += 1;
        var it = std.mem.splitSequence(u8, line, ",");
        const x = it.next() orelse continue;
        const y = it.next() orelse continue;

        const x_i = try std.fmt.parseInt(u8, x, 10);
        const y_i = try std.fmt.parseInt(u8, y, 10);

        output[y_i][x_i] = '#';

        if (steps >= max_steps) {
            break;
        }
    }
}
