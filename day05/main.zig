const std = @import("std");
const aoc = @import("helpers.zig");
const data = @embedFile("input.txt");
const Allocator = std.mem.Allocator;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    const part = try aoc.getPart(alloc);

    const result = try parse(alloc, data);

    var sum: u32 = 0;

    for (result.pages_to_print.items) |list| {
        if (try checkPageList(alloc, list, result.page_ordering_rules)) {
            sum += if (part == aoc.Part.part1) list.items[list.items.len / 2] else 0;
        } else {
            const fixed_list = try fixPageList(alloc, list, result.page_ordering_rules);
            sum += if (part == aoc.Part.part2) fixed_list.items[fixed_list.items.len / 2] else 0;
        }
    }

    std.debug.print("{d}\n", .{sum});
}

const ParseResult = struct {
    page_ordering_rules: std.AutoHashMap(u16, std.ArrayList(u16)),
    pages_to_print: std.ArrayList(std.ArrayList(u16)),
};

pub fn fixPageList(allocator: Allocator, list: std.ArrayList(u16), page_ordering_rules: std.AutoHashMap(u16, std.ArrayList(u16))) !std.ArrayList(u16) {
    var fifo = std.fifo.LinearFifo(u16, .Dynamic).init(allocator);
    defer fifo.deinit();

    var printed_pages = std.ArrayList(u16).init(allocator);

    for (list.items) |page| {
        try fifo.writeItem(page);
    }

    while (fifo.readItem()) |page| {
        const rules = page_ordering_rules.get(page);

        if (inSlice(u16, printed_pages.items, page)) {
            continue;
        }

        if (rules) |r| {
            var needs_fix = false;
            try fifo.writeItem(page);
            for (r.items) |dependency| {
                if (inSlice(u16, list.items, dependency) and !inSlice(u16, printed_pages.items, dependency)) {
                    try fifo.writeItem(dependency);
                    needs_fix = true;
                }
            }
            if (!needs_fix) _ = fifo.readItem();
            if (!needs_fix) try printed_pages.append(page);
        } else {
            try printed_pages.append(page);
        }
    }

    return printed_pages;
}

pub fn checkPageList(allocator: Allocator, list: std.ArrayList(u16), page_ordering_rules: std.AutoHashMap(u16, std.ArrayList(u16))) !bool {
    var printed_pages = std.ArrayList(u16).init(allocator);

    for (list.items) |page| {
        const rules = page_ordering_rules.get(page);

        if (rules) |r| {
            for (r.items) |dependency| {
                if (inSlice(u16, list.items, dependency) and !inSlice(u16, printed_pages.items, dependency)) {
                    return false;
                }
            }
        } else {}

        try printed_pages.append(page);
    }

    return true;
}

fn parse(allocator: Allocator, input: []const u8) !ParseResult {
    var page_ordering_rules = std.AutoHashMap(u16, std.ArrayList(u16)).init(allocator);
    var parts = std.mem.splitSequence(u8, input, "\n");
    var pages_to_print = std.ArrayList(std.ArrayList(u16)).init(allocator);

    while (parts.next()) |line| {
        if (std.mem.containsAtLeast(u8, line, 1, "|")) {
            var bla = std.mem.splitSequence(u8, line, "|");
            const lft = bla.next() orelse continue;
            const rgt = bla.next() orelse continue;
            const lft_i = try std.fmt.parseInt(u16, lft, 10);
            const rgt_i = try std.fmt.parseInt(u16, rgt, 10);

            const v = try page_ordering_rules.getOrPut(rgt_i);

            if (!v.found_existing) {
                v.value_ptr.* = std.ArrayList(u16).init(allocator);
            }
            try v.value_ptr.append(lft_i);
        } else if (std.mem.containsAtLeast(u8, line, 1, ",")) {
            var list = std.ArrayList(u16).init(allocator);

            var split = std.mem.splitSequence(u8, line, ",");
            while (split.next()) |page| {
                const page_i = try std.fmt.parseInt(u16, page, 10);
                try list.append(page_i);
            }

            try pages_to_print.append(list);
        }
    }

    return .{ .page_ordering_rules = page_ordering_rules, .pages_to_print = pages_to_print };
}

pub fn inSlice(comptime T: type, haystack: []const T, needle: T) bool {
    for (haystack) |thing| {
        if (thing == needle) {
            return true;
        }
    }
    return false;
}
