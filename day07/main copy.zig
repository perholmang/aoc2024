const std = @import("std");
const aoc = @import("helpers.zig");
const data = @embedFile("input.txt");
const Allocator = std.mem.Allocator;

fn get_new_arr(alloc: Allocator, numbers: []u128, i: usize) ![]u128 {
    const na = [1]u128{numbers[i] + numbers[i + 1]};
    const new_arr_a = try std.mem.concat(alloc, u128, &[_][]const u128{ &na, numbers[i + 2 ..] });
    return new_arr_a;
}

fn valid_equation(alloc: Allocator, numbers: []u128, sum: u128) !bool {
    if (numbers.len == 2) {
        const plus = @mulWithOverflow(numbers[0], numbers[1]);
        if (plus[1] == 1) {
            return false;
        }

        if (plus[0] == sum) {
            return true;
        }

        const z = @mulWithOverflow(numbers[0], numbers[1]);

        if (z[1] == 1) {
            return false;
        }
        return z[0] == sum;

        //std.debug.print("{d} {d}\n", .{ numbers[0], numbers[1] });
        //return numbers[0] + numbers[1] == sum or numbers[0] * numbers[1] == sum;
    }

    for (0..numbers.len - 1) |i| {
        if (i + 1 >= numbers.len) {
            break;
        }

        //if (numbers[i] > sum or numbers[i + 1] > sum or numbers[i] + numbers[i + 1] > sum) {
        //    continue;
        //}

        //const na = [1]u128{numbers[i] + numbers[i + 1]};
        //const new_arr_a = try std.mem.concat(alloc, u128, &[_][]const u128{ &na, numbers[i + 2 ..] });

        const a = numbers[i];
        const b = numbers[i + 1];

        //std.debug.print("{d} + {d}\n", .{ a, b });

        const a_plus_b = @addWithOverflow(a, b);

        if (a_plus_b[1] == 1) {
            continue;
        }

        numbers[i + 1] = a_plus_b[0];

        //numbers[i + 1] = a + b;
        if (try valid_equation(alloc, numbers[i + 1 ..], sum)) {
            return true;
        }

        //std.debug.print("{d} * {d}\n", .{ a, b });

        const z = @mulWithOverflow(a, b);

        if (z[1] == 1) {
            continue;
        }
        numbers[i + 1] = z[0];
        if (try valid_equation(alloc, numbers[i + 1 ..], sum)) {
            return true;
        }
        // const nb = [1]u128{numbers[i] * numbers[i + 1]};
        // const new_arr_b = try std.mem.concat(alloc, u128, &[_][]const u128{ &nb, numbers[i + 2 ..] });

    }

    return false;
}

fn valid_equation_arraylist(alloc: Allocator, numbers: []u128, sum: u128) !bool {
    if (numbers.len == 2) {
        const plus = @mulWithOverflow(numbers[0], numbers[1]);
        if (plus[1] == 1) {
            return false;
        }

        if (plus[0] == sum) {
            return true;
        }

        const z = @mulWithOverflow(numbers[0], numbers[1]);

        if (z[1] == 1) {
            return false;
        }
        return z[0] == sum;

        //std.debug.print("{d} {d}\n", .{ numbers[0], numbers[1] });
        //return numbers[0] + numbers[1] == sum or numbers[0] * numbers[1] == sum;
    }

    for (0..numbers.len - 1) |i| {
        if (i + 1 >= numbers.len) {
            break;
        }

        //if (numbers[i] > sum or numbers[i + 1] > sum or numbers[i] + numbers[i + 1] > sum) {
        //    continue;
        //}

        const na = [1]u128{numbers[i] + numbers[i + 1]};
        const new_arr_a = try std.mem.concat(alloc, u128, &[_][]const u128{ &na, numbers[i + 2 ..] });

        //numbers[i + 1] = a_plus_b[0];

        //numbers[i + 1] = a + b;
        if (try valid_equation(alloc, new_arr_a, sum)) {
            return true;
        }

        //std.debug.print("{d} * {d}\n", .{ a, b });

        //const z = @mulWithOverflow(a, b);

        const nb = [1]u128{numbers[i] * numbers[i + 1]};
        const new_arr_b = try std.mem.concat(alloc, u128, &[_][]const u128{ &nb, numbers[i + 2 ..] });
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

    const TEST_DATA =
        \\190: 10 19
        \\3267: 81 40 27
        \\83: 17 5
        \\156: 15 6
        \\7290: 6 8 6 15
        \\161011: 16 10 13
        \\192: 17 8 14
        \\21037: 9 7 18 13
        \\292: 11 6 16 20
    ;

    _ = TEST_DATA;

    var lines_it = std.mem.splitSequence(u8, data, "\n");
    var total_sum: u128 = 0;

    while (lines_it.next()) |line| {
        if (line.len == 0) continue;

        //std.debug.print("--> {s}\n", .{line});

        var parts = std.mem.splitSequence(u8, line, ":");
        const parts_sum = parts.next() orelse continue;
        const parts_nums = parts.next() orelse continue;

        const sum = try std.fmt.parseInt(u128, parts_sum, 10);

        var numbers = std.ArrayList(u128).init(alloc);
        var it = std.mem.splitSequence(u8, parts_nums, " ");
        while (it.next()) |num| {
            if (num.len == 0) continue;

            const size = std.mem.replacementSize(u8, num, " ", "");
            const output = try alloc.alloc(u8, size);
            _ = std.mem.replace(u8, num, " ", "", output);

            const num_i = try std.fmt.parseInt(u128, output, 10);
            try numbers.append(num_i);
        }

        const is_valid = try valid_equation_arraylist(alloc, numbers.items, sum);
        std.debug.print("{s} {any}\n", .{ line, is_valid });
        if (is_valid) total_sum += sum;
    }

    //const valid = try valid_equation(alloc, &numbers, 3267);
    std.debug.print("{d}\n", .{total_sum});
}
