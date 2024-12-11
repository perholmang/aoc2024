const std = @import("std");
const aoc = @import("helpers.zig");
const data = @embedFile("input.txt");
const Allocator = std.mem.Allocator;

test "get_first_digits" {
    const test_1 = get_first_digits(1234568811, 5);
    std.debug.print("test_1: {d}\n", .{test_1});
    try std.testing.expect(test_1 == 12345);
}

test "get_last_digits" {
    const test_1 = get_last_digits(1234568811, 5);
    std.debug.print("test_1: {d}\n", .{test_1});
    try std.testing.expect(test_1 == 68811);

    const test_2 = get_last_digits(100000, 5);
    std.debug.print("test_2: {d}\n", .{test_1});
    try std.testing.expect(test_2 == 0);
}

fn print_list(list: std.ArrayList(u64)) void {
    for (list.items) |item| {
        std.debug.print("{d} ", .{item});
    }
    std.debug.print("\n", .{});
}

fn get_last_digits(n: u64, num_digits: u64) u64 {
    return n % (std.math.pow(u64, 10, num_digits));
}

fn get_first_digits(n: u64, num_digits: u64) u64 {
    var num = n;
    var i = num_digits + 1;
    while (i > 1) {
        num /= 10;
        i -= 1;
    }
    return num;
}

fn count_digits(n: u64) u64 {
    var count: u64 = 0;
    var num = n;
    while (num != 0) {
        num /= 10;
        count += 1;
    }
    return count;
}

fn blink(list: std.ArrayList(u64)) !std.ArrayList(u64) {
    var new_list = std.ArrayList(u64).init(list.allocator);

    for (list.items) |item| {
        const num_digits = count_digits(item);
        if (item == 0) {
            try new_list.append(1);
        } else if (num_digits % 2 == 0) {
            const a = get_first_digits(item, num_digits / 2);
            const b = get_last_digits(item, num_digits / 2);
            try new_list.append(a);
            try new_list.append(b);
            //std.debug.print("a: {d}, b: {d}\n", .{ a, b });
        } else {
            try new_list.append(item * 2024);
        }
    }

    return new_list;
}

fn update_map(map: *std.AutoHashMap(u64, i64), k: u64, update_by: i64) !void {
    //std.debug.print("k: {d}, update_by: {d}\n", .{ k, update_by });
    const existing = map.get(k);

    if (existing) |e| {
        try map.put(k, @as(i64, e + @as(i64, update_by)));
    } else {
        try map.put(k, @as(i64, update_by));
    }
}

fn blink_with_map(allocator: Allocator, input: []const u8, num_times: usize) !u64 {
    var map = std.AutoHashMap(u64, comptime u64).init(allocator);
    var it = std.mem.splitSequence(u8, input, " ");
    while (it.next()) |item| {
        const num = try std.fmt.parseInt(u64, item, 10);
        try map.put(num, 1);
    }

    for (0..num_times) |_| {
        var new_items: std.AutoHashMap(u64, i64) = std.AutoHashMap(u64, i64).init(allocator);

        var iterator = map.iterator();

        while (iterator.next()) |entry| {
            const k = entry.key_ptr.*;
            const v = entry.value_ptr.*;
            const num_digits = count_digits(k);

            if (k == 0) {
                try update_map(&new_items, 1, @as(i64, @intCast(v)));
            } else if (num_digits % 2 == 0) {
                const a = get_first_digits(k, num_digits / 2);
                const b = get_last_digits(k, num_digits / 2);
                try update_map(&new_items, a, @as(i64, @intCast(v)));
                try update_map(&new_items, b, @as(i64, @intCast(v)));
            } else {
                const expanded_to = k * 2024;
                try update_map(&new_items, expanded_to, @as(i64, @intCast(v)));
            }

            try update_map(&new_items, k, -@as(i64, @intCast(v)));
        }

        var update_it = new_items.iterator();
        while (update_it.next()) |entry| {
            const k = entry.key_ptr.*;
            const v = entry.value_ptr.*;

            const existing = map.get(k);
            if (existing) |e| {
                const new_val = @as(i64, @intCast(e)) + v;
                try map.put(k, @as(u64, @as(u64, @intCast(new_val))));
            } else {
                try map.put(k, @as(u64, @as(u64, @intCast(v))));
            }
        }
    }

    var total_count: usize = 0;
    var sum_it = map.iterator();
    while (sum_it.next()) |entry| {
        total_count += @intCast(entry.value_ptr.*);
    }

    return total_count;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    const part = try aoc.getPart(alloc);

    const total_sum = try blink_with_map(alloc, data, if (part == aoc.Part.part1) 25 else 75);

    std.debug.print("{d}\n", .{total_sum});
}
