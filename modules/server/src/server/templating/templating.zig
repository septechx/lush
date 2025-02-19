const std = @import("std");
const @"alpha-html" = @import("alpha-html");
const lua = @import("lua.zig");

fn tmpl_search(ast: @"alpha-html".ast.BlockStmt, ssrv: std.StringHashMap([]const u8)) !void {
    for (ast.body.items) |*el| {
        if (el.isBlock()) {
            tmpl_search(el.block);
            continue;
        }
        if (el.element().? == .TEMPLATE) {
            const key = el.expression.expression.symbol.value;
            const val = ssrv.get(key);

            if (!val) {
                return error.VariableNotFound;
            }

            el.* = @"alpha-html".ast.Stmt{ .expression = .{ .expression = .{ .text = val.? } } };
        }
    }
}

pub fn parse(page: []const u8, path: []const u8, allocator: std.mem.Allocator) ![]const u8 {
    const dir = std.fs.path.dirname(path).?;
    const ssrv = lua.srrv(allocator, dir);

    const html = @"alpha-html".Html.init(allocator);
    try html.parse(page);
    const ast = html.getAst();

    try tmpl_search(ast, ssrv);

    try html.lock();

    return try html.write(.{ .minify = false });
}
