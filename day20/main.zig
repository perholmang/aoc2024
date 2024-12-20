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
const Vec4 = @Vector(4, i31);

const PosAndDir = struct {
    position: Vec2,
    direction: Vec2,
};

const DijkstraNode = struct { position: Vec2, direction: Vec2, cost: usize };

const Queue = std.PriorityQueue(DijkstraNode, void, lowerThan);

const CheapestCost = struct { cost: u64, came_from: ?Vec2 };

const DijkstraResult = struct {
    cheapest_cost: usize,
    points_visited: std.AutoHashMap(Vec2, void),
    cost_map: std.AutoHashMap(Vec2, CheapestCost),
    goals: []usize,
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

const VisitedWithCheating = struct { position: Vec2, direction: Vec2, cheats_left: bool };

fn queue_contains(node: Vec2, q: Queue) bool {
    for (q.items) |item| {
        if (std.meta.eql(item.position, node)) {
            return true;
        }
    }
    return false;
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

fn get_reachable(alloc: Allocator, from: Vec2, points_in_path: []Vec2, steps: usize) ![]Vec2 {
    var ret = std.ArrayList(Vec2).init(alloc);
    for (points_in_path) |point| {
        if (std.meta.eql(from, point)) {
            continue;
        }
        const steps_between = @abs(point[0] - from[0]) + @abs(point[1] - from[1]);
        if (steps_between <= steps) {
            try ret.append(point);
        }
    }

    return try ret.toOwnedSlice();
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    const part = try aoc.getPart(alloc);
    _ = part;
    const rows = 141;
    const cols = 141;

    const output = try create_map(alloc, rows, cols);
    const start_and_end = try parse(output);

    var results = std.AutoHashMap(usize, usize).init(alloc);

    const base_result = try dijkstra_orig(alloc, output, start_and_end.start, start_and_end.end);

    var points_in_path = std.ArrayList(Vec2).init(alloc);
    var it = base_result.?.points_visited.iterator();
    while (it.next()) |point| {
        try points_in_path.append(point.key_ptr.*);
    }

    var num_cheats: usize = 0;
    const min_savings = 99;

    //const checked_points = std.AutoHashMap(PosAndDir, void).init(alloc);

    for (points_in_path.items) |point| {
        const reachable = try get_reachable(alloc, point, points_in_path.items, 20);
        const orig_cost = base_result.?.cost_map.get(point) orelse unreachable;

        for (reachable) |r| {
            const point_cost = base_result.?.cost_map.get(r).?.cost;
            const steps_between = @abs(point[0] - r[0]) + @abs(point[1] - r[1]);
            const new_cost = point_cost + steps_between;
            if (new_cost >= orig_cost.cost) {
                continue;
            }

            const savings = orig_cost.cost - new_cost;

            if (savings < min_savings) {
                continue;
            }
            if (results.get(savings)) |curr| {
                try results.put(savings, curr + 1);
            } else {
                try results.put(savings, 1);
            }
            num_cheats += 1;
        }
    }

    std.debug.print("{d}\n", .{num_cheats});
}

const StartAndEnd = struct { start: Vec2, end: Vec2 };

fn parse(output: [][]u8) !StartAndEnd {
    var start: Vec2 = undefined;
    var end: Vec2 = undefined;
    var lines_it = std.mem.splitSequence(u8, data, "\n");
    var y: usize = 0;
    while (lines_it.next()) |line| {
        defer y += 1;
        for (line, 0..) |c, x| {
            output[y][x] = c;
            if (c == 'S') {
                start = Vec2{ @as(i31, @intCast(x)), @as(i31, @intCast(y)) };
            }
            if (c == 'E') {
                end = Vec2{ @as(i31, @intCast(x)), @as(i31, @intCast(y)) };
            }
        }
    }

    return StartAndEnd{ .start = start, .end = end };
}

fn dijkstra_orig(alloc: Allocator, map: []const []const u8, start: Vec2, goal: Vec2) !?DijkstraResult {
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
            const goals = [_]usize{};
            return .{
                .cheapest_cost = @as(usize, @intCast(curr.cost)),
                .points_visited = try find_visited_nodes(alloc, cost_map, goal),
                .goals = &goals,
                .cost_map = cost_map,
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

fn array_contains(comptime T: type, haystack: []const T, needle: T) bool {
    for (haystack) |element|
        if (std.meta.eql(element, needle))
            return true;
    return false;
}
