const std = @import("std");
const @"alpha-html" = @import("alpha-html");
const lua = @import("lua.zig");

fn tmpl_search(ast: @"alpha-html".ast.BlockStmt, ssrv: std.StringHashMap([]const u8)) !void {
    for (ast.body.items) |*el| {
        if (el.isBlock()) {
            try tmpl_search(el.block, ssrv);
            continue;
        }

        if (el.expression.expression == .text) {
            continue;
        }

        const key = el.expression.expression.symbol.value;

        const val = ssrv.get(key);

        if (val == null) {
            return error.VariableNotFound;
        }

        el.* = @"alpha-html".ast.Stmt{ .expression = .{ .expression = .{ .text = .{ .value = val.? } } } };
    }
}

pub fn parse(allocator: std.mem.Allocator, page: []const u8, path: []const u8) ![]const u8 {
    const dir = std.fs.path.dirname(path).?;
    const ssrv = try lua.srrv(allocator, dir);

    var html = @"alpha-html".Html.init(allocator);
    try html.parse(page);
    const ast = html.getAst();

    try tmpl_search(ast, ssrv);

    try html.lock();

    return try html.write(.{ .minify = false });
}
