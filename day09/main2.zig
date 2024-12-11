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

fn defragment_grouped(alloc: Allocator, disk: []FileOrFreeSpace) ![]FileOrFreeSpace {
    //const output = try alloc.dupe(FileOrFreeSpace, disk);
    const output = std.ArrayList(FileOrFreeSpace).init(alloc);
    var free_space_q = std.fifo.LinearFifo(FileOrFreeSpace, .Dynamic).init(alloc);
    defer free_space_q.deinit();

    for (0..disk.len) |i| {
        if (disk[i].file_id == null) {
            std.debug.print("{any}\n", .{disk[i]});
            try free_space_q.writeItem(disk[i]);
        }
    }

    std.debug.print("{any}\n", .{free_space_q});

    for (0..disk.len) |i| {
        const current = disk[disk.len - i - 1];
        if (current.file_id) |curr| {
            std.debug.print("{d} {d}\n", .{ curr, current.count });
            // find free space
            for (0..free_space_q.count) |j| {
                const f = free_space_q.peekItem(j);
                if (f.count >= current.count) {
                    std.debug.print("free space at {d} {d}\n", .{ j, f.count });
                    output.append(.{ .file_id = curr, .count = current.count });

                    if (f.count > curr.count) {
                        output.append(.{ .file_id = null, .count = f.count - curr.count });
                    }
                }
            }
        } else {
            continue;
        }
    }

    return output;
}

const FileOrFreeSpace = struct {
    file_id: ?usize,
    count: usize,
};

fn expand(alloc: Allocator, disk: []const u8) ![]FileOrFreeSpace {
    var buffer = std.ArrayList(FileOrFreeSpace).init(alloc);
    var file_id: usize = 0;
    for (disk, 0..) |c, i| {
        const n = try std.fmt.parseInt(usize, &[_]u8{c}, 10);
        // free space;
        if (i % 2 == 1) {
            try buffer.append(.{ .file_id = null, .count = n });
        } else {
            try buffer.append(.{ .file_id = file_id, .count = n });
            file_id += 1;
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
    _ = part;

    const test_data = "2333133121414131402";

    const expanded = try expand(alloc, test_data);
    //const new_disk = if (part == aoc.Part.part1) try defragment(alloc, expanded) else try defragment_grouped(alloc, expanded);
    const new_disk = try defragment_grouped(alloc, expanded);
    std.debug.print("{any}\n", .{new_disk});
    //const checksum = try calculate_checksum(new_disk);

    //std.debug.print("{d}\n", .{checksum});
}
