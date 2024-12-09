const std = @import("std");
const aoc = @import("helpers.zig");
const data = @embedFile("input.txt");
const Allocator = std.mem.Allocator;

fn find_free_space(disk: []?usize, size: usize, max_idx: usize) ?usize {
    for (0..max_idx) |i| outer: {
        if (disk[i] == null) {
            for (0..size) |j| {
                if (disk[i + j] != null) {
                    break :outer;
                }
            }
            return i;
        }
    }
    return null;
}

fn defragment_grouped(alloc: Allocator, disk: []?usize) ![]?usize {
    const output = try alloc.dupe(?usize, disk);

    var lft: usize = 0;
    var rgt: usize = output.len - 1;

    var current_file_id: ?usize = null;
    var current_file_count: usize = 0;

    var skip: usize = 0;

    while (rgt > 0) {
        while (output[lft] != null) lft += 1;

        // skip any whitespace, keeping count to offset it when moving files
        while (output[rgt] == null) {
            rgt -= 1;
            skip += 1;
        }

        const rgt_c = output[rgt];

        if (current_file_id == null) {
            current_file_id = rgt_c;
        }

        // move left until we find a new file_id
        if (rgt_c == current_file_id and rgt_c != null) {
            current_file_count += 1;
            rgt -= 1;
            continue;
        } else {
            defer {
                current_file_id = null;
                current_file_count = 0;
                rgt += 1;
                skip = 0;
            }

            const free_space_idx = find_free_space(output, current_file_count, rgt + skip);

            if (free_space_idx) |i| {
                for (i..i + current_file_count) |j| {
                    output[j] = current_file_id;
                }
                for (0..current_file_count) |j| {
                    output[rgt + j + 1 + skip] = null;
                }
            } else {
                current_file_id = null;
                current_file_count = 0;
            }
        }

        lft += 1;
        rgt -= 1;
    }

    return output;
}

fn expand(alloc: Allocator, disk: []const u8) ![]?usize {
    var buffer = std.ArrayList(?usize).init(alloc);
    var idx: usize = 0;
    for (disk, 0..) |c, i| {
        const n = try std.fmt.parseInt(usize, &[_]u8{c}, 10);
        // free space;
        if (i % 2 == 1) {
            for (0..n) |_| {
                try buffer.append(null);
            }
        } else {
            for (0..n) |_| {
                try buffer.append(idx);
            }
            idx += 1;
        }
    }
    return buffer.items;
}

fn defragment(alloc: Allocator, disk: []?usize) ![]const ?usize {
    const output = try alloc.dupe(?usize, disk);

    var lft: usize = 0;
    var rgt: usize = output.len - 1;

    while (lft < rgt) {
        while (output[lft] != null) {
            lft += 1;
        }

        while (output[rgt] == null) {
            rgt -= 1;
        }

        if (lft > rgt) break;

        const lft_c = output[lft];
        const rgt_c = output[rgt];

        output[lft] = rgt_c;
        output[rgt] = lft_c;

        lft += 1;
        rgt -= 1;
    }

    return output;
}

fn calculate_checksum(disk: []const ?usize) !u128 {
    var sum: u128 = 0;
    for (disk, 0..) |c, i| {
        if (c == null) {
            continue;
        } else {
            sum += i * c.?;
        }
    }
    return sum;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    const part = try aoc.getPart(alloc);

    const expanded = try expand(alloc, data);
    const new_disk = if (part == aoc.Part.part1) try defragment(alloc, expanded) else try defragment_grouped(alloc, expanded);
    const checksum = try calculate_checksum(new_disk);

    std.debug.print("{d}\n", .{checksum});
}
