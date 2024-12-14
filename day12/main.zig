const std = @import("std");
const aoc = @import("helpers.zig");
const data = @embedFile("input.txt");
const Allocator = std.mem.Allocator;

const Pos = @Vector(2, usize); // x,y

fn get_number_of_sides(positions: []const Pos) !usize {
    var num_sides: usize = 0;

    for (positions) |pos| {
        const up = @subWithOverflow(pos, Pos{ 0, 1 });
        const down = @addWithOverflow(pos, Pos{ 0, 1 });
        const left = @subWithOverflow(pos, Pos{ 1, 0 });
        const right = @addWithOverflow(pos, Pos{ 1, 0 });

        const up_left = @subWithOverflow(pos, Pos{ 1, 1 });
        const down_right = @addWithOverflow(pos, Pos{ 1, 1 });
        const up_right = @subWithOverflow(pos + Pos{ 1, 0 }, Pos{ 0, 1 });
        const down_left = @subWithOverflow(pos + Pos{ 0, 1 }, Pos{ 1, 0 });

        const up_is_oob = up[1][0] == 1 or up[1][1] == 1;
        const down_is_oob = down[1][0] == 1 or down[1][1] == 1;
        const left_is_oob = left[1][0] == 1 or left[1][1] == 1;
        const right_is_oob = right[1][0] == 1 or right[1][1] == 1;
        const up_left_is_oob = up_left[1][0] == 1 or up_left[1][1] == 1;
        const down_right_is_oob = down_right[1][0] == 1 or down_right[1][1] == 1;
        const up_right_is_oob = up_right[1][0] == 1 or up_right[1][1] == 1;
        const down_left_is_oob = down_left[1][0] == 1 or down_left[1][1] == 1;

        const up_is_same = !up_is_oob and array_contains(Pos, positions[0..], up[0]);
        const down_is_same = !down_is_oob and array_contains(Pos, positions[0..], down[0]);
        const left_is_same = !left_is_oob and array_contains(Pos, positions[0..], left[0]);
        const right_is_same = !right_is_oob and array_contains(Pos, positions[0..], right[0]);
        const up_left_is_same = !up_left_is_oob and array_contains(Pos, positions[0..], up_left[0]);
        const down_right_is_same = !down_right_is_oob and array_contains(Pos, positions[0..], down_right[0]);
        const up_right_is_same = !up_right_is_oob and array_contains(Pos, positions[0..], up_right[0]);
        const down_left_is_same = !down_left_is_oob and array_contains(Pos, positions[0..], down_left[0]);

        const needs_upper_left = (!up_is_same and !left_is_same) or (up_is_same and left_is_same and !up_left_is_same);
        const needs_upper_right = (!up_is_same and !right_is_same) or (up_is_same and right_is_same and !up_right_is_same);
        const needs_lower_left = (!down_is_same and !left_is_same) or (down_is_same and left_is_same and !down_left_is_same);
        const needs_lower_right = (!down_is_same and !right_is_same) or (down_is_same and right_is_same and !down_right_is_same);

        num_sides += if (needs_upper_left) 1 else 0;
        num_sides += if (needs_upper_right) 1 else 0;
        num_sides += if (needs_lower_left) 1 else 0;
        num_sides += if (needs_lower_right) 1 else 0;
    }

    return num_sides;
}

fn get_perimeter_size(pos: Pos, grid: []const u8, row_size: usize) usize {
    const x = pos[0];
    const y = pos[1];
    var perimeter: usize = 0;
    const plot_type = grid[y * row_size + x];

    perimeter += if (x == 0 or (grid[y * row_size + x - 1] != plot_type)) 1 else 0;
    perimeter += if (x >= row_size - 1 or (grid[y * row_size + x + 1] != plot_type)) 1 else 0;
    perimeter += if (y == 0 or (grid[(y - 1) * row_size + x] != plot_type)) 1 else 0;
    perimeter += if (y >= row_size - 1 or (grid[(y + 1) * row_size + x] != plot_type)) 1 else 0;

    return perimeter;
}

fn get_plot_neighbours(alloc: Allocator, pos: Pos, grid: []const u8, row_size: usize) ![]Pos {
    const x = pos[0];
    const y = pos[1];
    var neighbours = std.ArrayList(Pos).init(alloc);
    const plot_type = grid[y * row_size + x];

    if (x > 0 and grid[y * row_size + x - 1] == plot_type) {
        try neighbours.append(.{ x - 1, y });
    }
    if (x < row_size - 1 and grid[y * row_size + x + 1] == plot_type) {
        try neighbours.append(.{ x + 1, y });
    }
    if (y > 0 and grid[(y - 1) * row_size + x] == plot_type) {
        try neighbours.append(.{ x, y - 1 });
    }
    if (y < grid.len / row_size - 1 and grid[(y + 1) * row_size + x] == plot_type) {
        try neighbours.append(.{ x, y + 1 });
    }

    return neighbours.toOwnedSlice();
}

const PlotRegion = struct { type: u8, area: usize, perimeter: usize, sides: usize };
const PlotItem = struct { pos: Pos, came_from: ?u8 };

fn get_regions(alloc: Allocator, grid: []const u8, row_size: usize) ![]PlotRegion {
    var visited = std.AutoHashMap(Pos, void).init(alloc);
    var stack = std.ArrayList(PlotItem).init(alloc);
    defer stack.deinit();
    defer visited.deinit();

    for (grid, 0..) |_, i| {
        try stack.append(PlotItem{ .pos = .{ i % row_size, i / row_size }, .came_from = null });
    }

    var current_perimeter: usize = 0;
    var current_plot: ?u8 = null;
    var current_area: usize = 0;
    var pos_in_region = std.ArrayList(Pos).init(alloc);
    defer pos_in_region.deinit();

    var regions = std.ArrayList(PlotRegion).init(alloc);

    while (stack.popOrNull()) |plot_item| {
        const pos = plot_item.pos;
        const plot_type = grid[pos[1] * row_size + pos[0]];

        if (visited.contains(pos)) {
            continue;
        }

        try visited.put(pos, void{});

        const plot_neighbours = try get_plot_neighbours(alloc, pos, grid, row_size);
        for (plot_neighbours) |neighbour| {
            if (!visited.contains(neighbour)) {
                try stack.append(PlotItem{ .pos = neighbour, .came_from = plot_type });
            }
        }

        // if we're in a new plot - add the current tracked one to the regions list
        if ((current_plot != null and plot_type != current_plot or (plot_item.came_from == null and current_plot != null))) {
            try regions.append(PlotRegion{ .type = current_plot.?, .area = current_area, .perimeter = current_perimeter, .sides = try get_number_of_sides(pos_in_region.items) });
            current_area = 0;
            current_perimeter = 0;
            pos_in_region = std.ArrayList(Pos).init(alloc);
        }

        current_plot = plot_type;
        current_area += 1;
        current_perimeter += get_perimeter_size(pos, grid, row_size);
        try pos_in_region.append(pos);
    }

    try regions.append(PlotRegion{ .type = current_plot.?, .area = current_area, .perimeter = current_perimeter, .sides = try get_number_of_sides(pos_in_region.items) });

    return regions.toOwnedSlice();
}

fn get_total_price(regions: []const PlotRegion, discount: bool) usize {
    var total_price: usize = 0;
    for (regions) |region| {
        total_price += region.area * if (discount) region.sides else region.perimeter;
    }
    return total_price;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    const part = try aoc.getPart(alloc);

    const grid = try aoc.removeNewlines(alloc, data);
    const row_size = 140;

    var total_price: usize = 0;
    const regions = try get_regions(alloc, grid, row_size);
    for (regions) |region| {
        total_price += region.area * if (part == aoc.Part.part2) region.sides else region.perimeter;
    }

    std.debug.print("{d}\n", .{total_price});
}

fn array_contains(comptime T: type, haystack: []const T, needle: T) bool {
    for (haystack) |element|
        if (std.meta.eql(element, needle))
            return true;
    return false;
}
