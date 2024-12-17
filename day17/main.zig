const std = @import("std");
const aoc = @import("helpers.zig");
const data = @embedFile("input.txt");
const Allocator = std.mem.Allocator;

const Instruction = enum { adv, bxl, bst, jnz, bxc, out, bdv, cdv };

const Computer = struct {
    registers: [3]u64 = undefined,
    ip: usize = 0,
    opcodes: []const u8 = undefined,
    out: std.ArrayList(u64),

    registers_start: [3]u64 = undefined,

    pub fn init(alloc: Allocator, a: u64, b: u64, c: u64, opcodes: []const u8) Computer {
        return Computer{
            .registers = .{ a, b, c },
            .registers_start = .{ a, b, c },
            .opcodes = opcodes,
            .out = std.ArrayList(u64).init(alloc),
        };
    }

    pub fn deinit(self: *Computer) void {
        self.out.deinit();
    }

    pub fn reset(self: *Computer, a: u64) void {
        self.ip = 0;
        self.registers[0] = a;
        self.registers[1] = 0;
        self.registers[2] = 0;
        self.registers_start = .{ a, 0, 0 };
        self.out.clearAndFree();
    }

    pub fn runWithExpectedOutput(self: *Computer, expected_output: []const u8) !void {
        while (self.ip < self.opcodes.len) {
            try self.next();

            if (!is_same(expected_output[0..self.out.items.len], self.out.items)) {
                return;
            }
        }
    }

    fn next(self: *Computer) !void {
        const opcode: Instruction = @enumFromInt(self.opcodes[self.ip]);
        const op = self.opcodes[self.ip + 1];
        const real_op = self.get_operand(opcode, op);
        //std.debug.print("opcode: {any} ({d}): op {d}, real_op: {d}\n", .{ opcode, self.opcodes[self.ip], op, real_op });

        var should_inc_ip = true;

        switch (opcode) {
            .adv => {
                const num = self.registers[0];
                const den = std.math.pow(u64, 2, real_op);
                self.registers[0] = @divTrunc(num, den);
            },
            // The bxl instruction (opcode 1) calculates the bitwise XOR of register B and the instruction's literal operand
            .bxl => {
                self.registers[1] = self.registers[1] ^ real_op;
            },
            // The bst instruction (opcode 2) calculates the value of its combo operand modulo 8
            .bst => {
                self.registers[1] = @mod(real_op, 8);
            },
            //The jnz instruction (opcode 3) does nothing if the A register is 0
            .jnz => {
                if (self.registers[0] != 0) {
                    self.ip = @as(u8, @intCast(real_op));
                    should_inc_ip = false;
                }
            },
            // The bxc instruction (opcode 4) calculates the bitwise XOR of register B and register C, then stores the result in register B
            .bxc => {
                self.registers[1] = self.registers[1] ^ self.registers[2];
            },
            // The out instruction (opcode 5) calculates the value of its combo operand modulo 8, then outputs that value
            .out => {
                const out_val = @mod(real_op, 8);
                try self.out.append(out_val);
            },
            .bdv => {
                const num = self.registers[0];
                const den = std.math.pow(u64, 2, real_op);
                self.registers[1] = @divTrunc(num, den);
            },
            .cdv => {
                const num = self.registers[0];
                const den = std.math.pow(u64, 2, real_op);
                self.registers[2] = @divTrunc(num, den);
            },
        }
        if (should_inc_ip) {
            self.ip += 2;
        }
    }

    pub fn run(self: *Computer) !void {
        while (self.ip < self.opcodes.len) {
            try self.next();

            // if (std.mem.eql(u64, &self.registers_start, &self.registers)) {
            //     //std.debug.print("loop\n", .{});
            //     return error.LoopDetected;
            // }
        }
    }

    fn get_operand(self: Computer, opcode: Instruction, op: u8) u64 {
        const is_combo: bool = switch (opcode) {
            .adv, .bdv, .cdv, .bst, .out => true,
            .bxl, .jnz => false,
            else => false,
        };

        // Combo operands 0 through 3 represent literal values 0 through 3
        if (!is_combo or op <= 3) {
            return op;
        }

        // Combo operand 4 represents the value of register A.
        // Combo operand 5 represents the value of register B.
        // Combo operand 6 represents the value of register C.
        if (op >= 4 and op <= 6) {
            return self.registers[op - 4];
        }

        // Combo operand 7 is reserved and will not appear in valid programs.
        if (op == 7) {
            @panic("Invalid operand");
        }

        unreachable;
    }
};

fn test_algo(a: u64) u64 {
    var b: u64 = @mod(a, 8);
    b = b ^ 7;
    const c = @divTrunc(a, std.math.pow(u64, 2, b));
    b = b ^ 7;
    b = b ^ c;

    return @mod(b, 8);
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    const part = try aoc.getPart(alloc);

    const opcodes = [_]u8{ 2, 4, 1, 7, 7, 5, 0, 3, 1, 7, 4, 1, 5, 5, 3, 0 };
    var pgm = Computer.init(alloc, 64012472, 0, 0, &opcodes);

    if (part == aoc.Part.part1) {
        try pgm.run();

        for (pgm.out.items, 0..) |n, i| {
            std.debug.print("{d}", .{n});
            if (i < pgm.out.items.len - 1) {
                std.debug.print(",", .{});
            }
        }
        std.debug.print("\n", .{});
    } else {
        var output: u64 = 0;
        check_algo(0, 8, &[_]u8{ 2, 4, 1, 7, 7, 5, 0, 3, 1, 7, 4, 1, 5, 5, 3, 0 }, 15, &output);

        if (output > 0) {
            std.debug.print("{d}\n", .{output});
        }
    }
}

fn is_same(opcodes: []const u8, output: []const u64) bool {
    if (opcodes.len != output.len) {
        return false;
    }

    for (opcodes, output) |a, b| {
        if (a != b) {
            return false;
        }
    }

    return true;
}

// If register C contains 9, the program 2,6 would set register B to 1.
test "sample_program1" {
    const alloc = std.testing.allocator;
    const opcodes = [_]u8{ 2, 6 };
    var test_c = Computer.init(alloc, 0, 0, 9, &opcodes);
    try test_c.run();
    defer test_c.deinit();
    //try std.testing.expectEqualSlices(u64, test_c.out.items, &[_]u64{6});
    try std.testing.expectEqual(test_c.registers[1], 1);
}

//If register A contains 10, the program 5,0,5,1,5,4 would output 0,1,2.
test "sample_program2" {
    const alloc = std.testing.allocator;
    const opcodes = [_]u8{ 5, 0, 5, 1, 5, 4 };
    var test_c = Computer.init(alloc, 10, 0, 0, &opcodes);
    defer test_c.deinit();

    try test_c.run();

    try std.testing.expectEqualSlices(u64, test_c.out.items, &[_]u64{ 0, 1, 2 });
}

// If register A contains 2024, the program 0,1,5,4,3,0 would output 4,2,5,6,7,7,7,7,3,1,0 and leave 0 in register A.
test "sample_program3" {
    const alloc = std.testing.allocator;
    const opcodes = [_]u8{ 0, 1, 5, 4, 3, 0 };
    var test_c = Computer.init(alloc, 2024, 0, 0, &opcodes);
    defer test_c.deinit();

    try test_c.run();
    try std.testing.expectEqual(test_c.registers[0], 0);
    try std.testing.expectEqualSlices(u64, test_c.out.items, &[_]u64{ 4, 2, 5, 6, 7, 7, 7, 7, 3, 1, 0 });
}

// If register B contains 29, the program 1,7 would set register B to 26.
test "sample_program4" {
    const alloc = std.testing.allocator;
    const opcodes = [_]u8{ 1, 7 };
    var test_c = Computer.init(alloc, 0, 29, 0, &opcodes);
    defer test_c.deinit();

    try test_c.run();
    try std.testing.expectEqual(test_c.registers[1], 26);
}

// If register B contains 2024 and register C contains 43690, the program 4,0 would set register B to 44354.
test "sample_program5" {
    const alloc = std.testing.allocator;
    const opcodes = [_]u8{ 4, 0 };
    var test_c = Computer.init(alloc, 0, 2024, 43690, &opcodes);
    defer test_c.deinit();

    try test_c.run();
    try std.testing.expectEqual(test_c.registers[1], 44354);
}

test "sample_program6" {
    const alloc = std.testing.allocator;
    const opcodes = [_]u8{ 0, 1, 5, 4, 3, 0 };
    var test_c = Computer.init(alloc, 729, 0, 0, &opcodes);
    defer test_c.deinit();

    try test_c.run();
    try std.testing.expectEqualSlices(u64, test_c.out.items, &[_]u64{ 4, 6, 3, 5, 6, 3, 5, 2, 1, 0 });
}

fn check_algo(start: usize, end: usize, numbers: []const u8, number_idx: usize, output: *usize) void {
    for (start..end + 1) |i| {
        if (test_algo(@as(u64, @intCast(i))) == numbers[number_idx]) {
            if (number_idx == 0) {
                output.* = i;
                return;
            }

            check_algo(i * 8, (i * 8) + 7, numbers, number_idx - 1, output);
        }
    }
}
