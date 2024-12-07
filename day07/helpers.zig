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
