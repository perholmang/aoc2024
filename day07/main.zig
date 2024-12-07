const std = @import("std");
const aoc = @import("helpers.zig");
const data = @embedFile("input.txt");
const Allocator = std.mem.Allocator;

fn count_digits(n: u64) u64 {
    var count: u64 = 0;
    var num = n;
    while (num != 0) {
        num /= 10;
        count += 1;
    }
    return count;
}
fn plus(a: u64, b: u64) u64 {
    return a + b;
}

fn mul(a: u64, b: u64) u64 {
    return a * b;
}

fn concat(_: Allocator, a: u64, b: u64) !u64 {
    var buf: [100]u8 = undefined;
    const w = try std.fmt.bufPrint(&buf, comptime "{d}{d}", .{ a, b });
    return try std.fmt.parseInt(u64, w, 10);
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    const part = try aoc.getPart(alloc);
    _ = part;

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

        const is_valid = try valid_backwards(numbers.items, sum);
        if (is_valid) total_sum += sum;
    }

    //const valid = try valid_equation(alloc, &numbers, 3267);
    std.debug.print("{d}\n", .{total_sum});
}

fn valid_backwards(numbers: []u64, target: u64) !bool {
    if (numbers.len == 1) {
        return numbers[0] == target;
    }

    const last = numbers[numbers.len - 1];
    const digits_in_target = count_digits(last);
    const last_digits = target % std.math.pow(u64, 10, digits_in_target);
    const remain = target / std.math.pow(u64, 10, digits_in_target);

    if (last_digits == last) {
        if (try valid_backwards(numbers[0 .. numbers.len - 1], remain)) {
            return true;
        }
    }

    const r = @subWithOverflow(target, last);
    if (r[1] == 1) {
        return false;
    }

    if (target - last > 0) {
        if (try valid_backwards(numbers[0 .. numbers.len - 1], target - last)) {
            return true;
        }
    }

    if (target % last == 0) {
        if (try valid_backwards(
            numbers[0 .. numbers.len - 1],
            target / last,
        )) {
            return true;
        }
    }

    return false;
}

test "valid_equation" {
    //var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    //const alloc = gpa.allocator();

    //var numbers = [_]u64{ 1, 2, 3, 4, 5, 6 };
    //try std.testing.expect(try valid_backwards(&numbers, 90) == true);

    var numbers2 = [_]u64{ 22, 22 };
    try std.testing.expect(try valid_backwards(&numbers2, 2222) == true);

    //var numbers2 = [_]u64{ 22, 22 };
    //try std.testing.expect(try valid_backwards(&numbers2, 2222) == true);
}
