const std = @import("std");
const aoc = @import("helpers.zig");
const data = @embedFile("input.txt");
const Allocator = std.mem.Allocator;

const NodeWithCost = struct {
    x: i64,
    y: i64,
    cost: i64,
};

const Node = struct {
    x: i64,
    y: i64,
};

const Button = struct {
    dx: i64,
    dy: i64,
    cost: i64,
};

fn lowerThan(context: void, a: NodeWithCost, b: NodeWithCost) std.math.Order {
    _ = context;
    return std.math.order(a.cost, b.cost);
}

const Queue = std.PriorityQueue(NodeWithCost, void, lowerThan);

fn dijkstra(alloc: Allocator, buttons: []Button, goal: Node) !?NodeWithCost {
    var visited = std.AutoHashMap(Node, void).init(alloc);

    var pq = Queue.init(alloc, {});
    defer pq.deinit();

    try pq.add(NodeWithCost{ .x = 0, .y = 0, .cost = 0 });

    while (pq.count() > 0) {
        const curr = pq.remove();

        if (visited.contains(.{ .x = curr.x, .y = curr.y })) {
            continue;
        }

        try visited.put(.{ .x = curr.x, .y = curr.y }, void{});

        if (curr.x == goal.x and curr.y == goal.y) {
            return curr;
        }

        if (curr.x > goal.x or curr.y > goal.y) {
            continue;
        }

        for (buttons) |button| {
            try pq.add(NodeWithCost{ .x = curr.x + button.dx, .y = curr.y + button.dy, .cost = curr.cost + button.cost });
        }
    }
    return null;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    const part = try aoc.getPart(alloc);

    var parser = InputParser{ .input = data };
    const rows = try parser.parse(alloc);
    var total_cost: i64 = 0;

    for (rows.items) |row| {
        //const node = try dijkstra(alloc, &buttons, Node{ .x = row.goal.x, .y = row.goal.y });

        const cost = solve_machine(row, if (part == aoc.Part.part2) 10000000000000 else 0);
        if (cost) |n| {
            total_cost += n;
        }
    }
    std.debug.print("{d}\n", .{total_cost});
}

const ClawMachine = struct {
    buttonA: Node,
    buttonB: Node,
    goal: Node,
};

const InputParser = struct {
    const State = enum { AX, AY, BX, BY, PriceX, PriceY };

    state: State = State.AX,
    input: []const u8,
    idx: usize = 0,

    fn consumeNum(self: *InputParser) i64 {
        var num: i64 = 0;
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

    pub fn parse(self: *InputParser, alloc: Allocator) !std.ArrayList(ClawMachine) {
        var ax: i64 = 0;
        var ay: i64 = 0;
        var bx: i64 = 0;
        var by: i64 = 0;
        var price_x: i64 = 0;
        var price_y: i64 = 0;

        var rows = std.ArrayList(ClawMachine).init(alloc);

        while (self.idx < self.input.len) {
            defer self.idx += 1;
            const c: u8 = self.input[self.idx];
            const is_num = c >= '0' and c <= '9';

            if (is_num) {
                const num = self.consumeNum();

                switch (self.state) {
                    .AX => {
                        ax = num;
                        self.state = State.AY;
                    },
                    .AY => {
                        ay = num;
                        self.state = State.BX;
                    },
                    .BX => {
                        bx = num;
                        self.state = State.BY;
                    },
                    .BY => {
                        by = num;
                        self.state = State.PriceX;
                    },
                    .PriceX => {
                        price_x = num;
                        self.state = State.PriceY;
                    },
                    .PriceY => {
                        price_y = num;
                        self.state = State.AX;

                        try rows.append(ClawMachine{
                            .buttonA = Node{ .x = ax, .y = ay },
                            .buttonB = Node{ .x = bx, .y = by },
                            .goal = Node{ .x = price_x, .y = price_y },
                        });
                    },
                }
            }
        }

        return rows;
    }
};

fn solve_machine(machine: ClawMachine, offset: i64) ?i64 {
    const ax = machine.buttonA.x;
    const ay = machine.buttonA.y;
    const bx = machine.buttonB.x;
    const by = machine.buttonB.y;
    const gx = machine.goal.x + offset;
    const gy = machine.goal.y + offset;

    const det = ax * by - bx * ay;
    const a = @divFloor(gx * by - gy * bx, det);
    const b = @divFloor(ax * gy - ay * gx, det);

    if (ax * a + bx * b == gx and ay * a + by * b == gy) {
        return a * 3 + b;
    } else {
        return null;
    }
}
