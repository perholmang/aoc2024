const std = @import("std");
const aoc = @import("helpers.zig");
const data = @embedFile("input_test.txt");
const Allocator = std.mem.Allocator;

fn prune(n: usize) usize {
    return n % 16777216;
}

fn mix(secret: usize, n: usize) usize {
    return secret ^ n;
}
fn last_digit(n: u64) u64 {
    return n % (std.math.pow(u64, 10, 1));
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

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    const part = try aoc.getPart(alloc);
    _ = part;

    var lines_it = std.mem.splitSequence(u8, data, "\n");
    var sum: usize = 0;
    while (lines_it.next()) |line| {
        const initial = try std.fmt.parseInt(u32, line, 10);
        const secret = nth_secret(initial, 2000);
        const result = secret;
        std.debug.print("last digit: {d}: {d}\n", .{ result, last_digit(result) });
        sum += result;
    }
    std.debug.print("{d}\n", .{sum});
}

// fn parse(alloc: Allocator, input: []const u8) !ParsedData {
//     var reading_patterns: bool = true;
//     var patterns = std.ArrayList([]const u8).init(alloc);
//     var towels = std.ArrayList([]const u8).init(alloc);

//     var lines_it = std.mem.splitSequence(u8, input, "\n");

//     while (lines_it.next()) |line| {
//         if (line.len < 2) {
//             reading_patterns = false;
//             continue;
//         }
//         if (reading_patterns) {
//             var pattern_it = std.mem.splitSequence(u8, line, ", ");
//             while (pattern_it.next()) |pattern| {
//                 try patterns.append(pattern);
//             }
//         } else {
//             try towels.append(line);
//         }
//     }

//     const patterns_arr = try patterns.toOwnedSlice();

//     std.mem.sort([]const u8, patterns_arr, {}, longer);

//     return ParsedData{ .patterns = patterns_arr, .towels = try towels.toOwnedSlice() };
// }
