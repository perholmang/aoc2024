const std = @import("std");
const aoc = @import("helpers.zig");
const data = @embedFile("input.txt");
const Allocator = std.mem.Allocator;

fn prune(n: usize) usize {
    return n % 16777216;
}

fn mix(secret: usize, n: usize) usize {
    return secret ^ n;
}
fn last_digit(n: u64) u8 {
    return @as(u8, @intCast(n % (std.math.pow(u64, 10, 1))));
}

fn next_secret(number: usize) usize {
    const a = number * 64;
    const b = a ^ number;
    const c = prune(b);
    const d = @divFloor(c, 32);
    const e = prune(mix(c, d));
    const f = prune(mix(e, e * 2048));
    return f;
}

test "next_secret" {
    const a = next_secret(123);
    const b = next_secret(a);
    const c = next_secret(b);

    try std.testing.expectEqual(a, 15887950);
    try std.testing.expectEqual(b, 16495136);
    try std.testing.expectEqual(c, 527345);
}

fn nth_secret(initial: usize, n: usize) usize {
    var secret = initial;
    for (0..n) |_| {
        secret = next_secret(secret);
    }
    return secret;
}

fn highest_price(prices: []usize) usize {
    var highest: usize = 0;
    for (prices) |price| {
        if (price > highest) {
            highest = price;
        }
    }
    return highest;
}

const Key = @Vector(4, i8);

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    const part = try aoc.getPart(alloc);

    var lines_it = std.mem.splitSequence(u8, data, "\n");

    var hashmaps = std.ArrayList(std.AutoHashMap(Key, u8)).init(alloc);
    defer hashmaps.deinit();

    var prices_per_seq = std.AutoHashMap(Key, usize).init(alloc);
    var total_sum: usize = 0;

    while (lines_it.next()) |line| {
        var secret = try std.fmt.parseInt(usize, line, 10);
        var d = [4]i8{ 0, 0, 0, 0 };
        var prev_price: u8 = 0;

        var seq = std.AutoHashMap(Key, void).init(alloc);

        if (part == aoc.Part.part1) {
            total_sum += nth_secret(secret, 2000);
        } else {
            for (0..2001) |i| {
                const price = last_digit(secret);

                d[0] = d[1];
                d[1] = d[2];
                d[2] = d[3];
                d[3] = @as(i8, @intCast(price)) - @as(i8, @intCast(prev_price));

                if (i > 3) {
                    if (!seq.contains(d)) {
                        try seq.put(d, void{});
                        const existing = try prices_per_seq.getOrPut(d);
                        if (existing.found_existing) {
                            try prices_per_seq.put(d, existing.value_ptr.* + price);
                        } else {
                            try prices_per_seq.put(d, price);
                        }
                    }
                }

                secret = next_secret(secret);
                prev_price = price;
            }
        }
    }

    if (part == aoc.Part.part1) {
        std.debug.print("{d}\n", .{total_sum});
    } else {
        var best_price: usize = 0;
        var best_price_key: Key = undefined;
        var it = prices_per_seq.iterator();
        while (it.next()) |entry| {
            const value = entry.value_ptr.*;

            if (value > best_price) {
                best_price = value;
                best_price_key = entry.key_ptr.*;
            }
        }

        std.debug.print("{d}\n", .{best_price});
    }
}
