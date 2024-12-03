const std = @import("std");
const aoc = @import("helpers.zig");
const data = @embedFile("input.txt");

const Mul = struct {
    lft: u32,
    rgt: u32,
};

const MulExtractor = struct {
    const State = enum { M, U, L, ParenOpen, ParenClose, Comma, Lft, Rgt };

    can_be_disabled: bool = false,
    is_disabled: bool = false,
    allocator: std.mem.Allocator,
    state: State = State.M,
    input: []const u8,
    idx: usize = 0,
    lft: u32 = 0,
    rgt: u32 = 0,
    const Self = @This();

    pub fn init(allocator: std.mem.Allocator, input: []const u8, can_be_disabled: bool) MulExtractor {
        return MulExtractor{ .input = input, .idx = 0, .allocator = allocator, .can_be_disabled = can_be_disabled };
    }

    fn reset(self: *MulExtractor) void {
        self.state = State.M;
        self.lft = 0;
        self.rgt = 0;
    }

    fn consumeNum(self: *MulExtractor) u32 {
        var num: u32 = 0;
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

    fn consumeDoOrDont(self: *MulExtractor) void {
        const maybe_dont = self.input[self.idx .. self.idx + 7];
        const maybe_do = self.input[self.idx .. self.idx + 4];
        if (std.mem.eql(u8, maybe_dont, "don't()")) {
            self.is_disabled = true;
            self.idx += 6;
        } else if (std.mem.eql(u8, maybe_do, "do()")) {
            self.is_disabled = false;
            self.idx += 3;
        }
    }

    pub fn extractMuls(self: *MulExtractor) !std.ArrayList(Mul) {
        var muls = std.ArrayList(Mul).init(self.allocator);

        while (self.idx < self.input.len) {
            defer self.idx += 1;
            const c: u8 = self.input[self.idx];
            const is_num = c >= '0' and c <= '9';

            switch (self.state) {
                .M => {
                    if (c == 'm') {
                        self.state = State.U;
                    } else if (c == 'd' and self.input[self.idx + 1] == 'o') {
                        self.consumeDoOrDont();
                    } else {
                        self.reset();
                    }
                },
                .U => {
                    if (c == 'u') self.state = State.L else self.reset();
                },
                .L => {
                    if (c == 'l') self.state = State.ParenOpen else self.reset();
                },
                .ParenOpen => {
                    if (c == '(') self.state = State.Lft else self.reset();
                },
                .Lft => {
                    if (is_num) {
                        self.lft = consumeNum(self);
                        self.state = State.Comma;
                    } else self.reset();
                },
                .Comma => {
                    if (c == ',') self.state = State.Rgt else self.reset();
                },
                .Rgt => {
                    if (is_num) {
                        self.rgt = consumeNum(self);
                        self.state = State.ParenClose;
                    } else self.reset();
                },
                .ParenClose => {
                    if (c == ')') {
                        if (!self.is_disabled or !self.can_be_disabled)
                            try muls.append(Mul{ .lft = self.lft, .rgt = self.rgt });
                        self.reset();
                    } else self.reset();
                },
            }
        }

        return muls;
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    const part = try aoc.getPart(alloc);

    var extractor = MulExtractor.init(
        alloc,
        data,
        part == aoc.Part.part2,
    );
    const muls = try extractor.extractMuls();
    var sum: u32 = 0;
    for (muls.items) |mul| {
        sum += mul.lft * mul.rgt;
    }
    std.debug.print("{d}\n", .{sum});
}
