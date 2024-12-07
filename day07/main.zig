const std = @import("std");
const aoc = @import("helpers.zig");
const data = @embedFile("input.txt");
const Allocator = std.mem.Allocator;

fn valid_equation(alloc: Allocator, numbers: []u64, sum: u64) !bool {
    if (numbers.len == 2) {
        return numbers[0] + numbers[1] == sum or numbers[0] * numbers[1] == sum;
    }

    for (numbers, 0..) |_, i| {
        if (i + 1 >= numbers.len) {
            break;
        }

        const na = [1]u64{numbers[i] + numbers[i + 1]};
        const new_arr_a = try std.mem.concat(alloc, u64, &[_][]const u64{ &na, numbers[i + 2 ..] });
        if (try valid_equation(alloc, new_arr_a, sum)) {
            return true;
        }

        const nb = [1]u64{numbers[i] * numbers[i + 1]};
        const new_arr_b = try std.mem.concat(alloc, u64, &[_][]const u64{ &nb, numbers[i + 2 ..] });

        if (try valid_equation(alloc, new_arr_b, sum)) {
            return true;
        }
    }

    return false;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    const part = try aoc.getPart(alloc);
    _ = part;

    //var numbers = [_]u32{ 81, 40, 27 };

    var lines_it = std.mem.splitSequence(u8, data, "\n");
    var total_sum: u64 = 0;

    while (lines_it.next()) |line| {
        if (line.len == 0) continue;

        var parts = std.mem.splitSequence(u8, line, ":");
        const parts_sum = parts.next() orelse continue;
        const parts_nums = parts.next() orelse continue;

        const sum = try std.fmt.parseInt(u64, parts_sum, 10);

        var numbers = std.ArrayList(u64).init(alloc);
        var it = std.mem.splitSequence(u8, parts_nums, " ");
        while (it.next()) |num| {
            if (num.len == 0) continue;
            const size = std.mem.replacementSize(u8, num, " ", "");
            const output = try alloc.alloc(u8, size);
            _ = std.mem.replace(u8, num, " ", "", output);

            const num_i = try std.fmt.parseInt(u64, output, 10);
            try numbers.append(num_i);
        }

        const is_valid = try valid_equation(alloc, numbers.items, sum);
        if (is_valid) total_sum += sum;
    }

    //const valid = try valid_equation(alloc, &numbers, 3267);
    std.debug.print("{d}\n", .{total_sum});
}
