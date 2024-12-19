const std = @import("std");

pub fn getPart(alloc: std.mem.Allocator) !Part {
    const env_map = try alloc.create(std.process.EnvMap);
    env_map.* = try std.process.getEnvMap(alloc);
    const env_part = env_map.get("part") orelse "part1";
    if (std.mem.eql(u8, env_part, "part2")) return Part.part2 else return Part.part1;
}

pub const Part = enum {
    part1,
    part2,
};

pub fn removeNewlines(alloc: std.mem.Allocator, data: []const u8) ![]u8 {
    const size = std.mem.replacementSize(u8, data, "\n", "");
    const output = try alloc.alloc(u8, size);
    _ = std.mem.replace(u8, data, "\n", "", output);
    return output;
}

pub fn toRowAndCol(row_size: usize, idx: usize) @Vector(2, i32) {
    const x = @as(i32, @intCast(idx % row_size));
    const y = @as(i32, @intCast(idx / row_size));

    return @Vector(2, i32){ y, x };
}

pub fn toIdx(row_size: usize, pos: @Vector(2, i32)) usize {
    return pos[0] * row_size + pos[1];
}
