// Mir.zig: Mor intermediate representation

// FIXME: this is all a wip and should be refactored
// but I am not doing it since I want to write the
// next self hosted version soon

const std = @import("std");

const Ast = @import("Ast.zig");
const Asm = @import("../coge/linux_x86_64.zig");
const lex = @import("lexer.zig");

const Self = @This();

ast: Ast,
gpa: std.mem.Allocator,
instructions: std.ArrayList(Instr),

// TODO: remove bp since it is only used for
// arguments and does not change within the func
// also should only have one StringHashMap with
// a struct containing information if it is a
// local variable or argument
const Context = struct {
    bp: u32,
    sp: u32,
    params: std.StringHashMap(u32),
    locals: std.StringHashMap(u32),

    fn clone(self: *Context) !Context {
        return .{
            .bp = self.bp,
            .sp = self.sp,
            .params = try self.params.clone(),
            .locals = try self.locals.clone(),
        };
    }

    fn pushVariableOnStack(self: *Context, mir: *Self, ident: []const u8) !void {
        if (self.locals.get(ident)) |local| {
            try mir.instructions.append(.{
                .tag = .push,
                .lhs = .{ .variable = self.sp - local },
            });
            return;
        }

        if (self.params.get(ident)) |param| {
            try mir.instructions.append(.{
                .tag = .push,
                .lhs = .{ .parameter = self.bp - param },
            });
            return;
        }

        std.debug.print("Error: use of unknown var [{s}]\n", .{ident});
        std.process.exit(1);
    }

    fn getVariableOperand(self: *Context, ident: []const u8) Operand {
        if (self.locals.get(ident)) |local| {
            return .{ .variable = self.sp - local };
        }
        if (self.params.get(ident)) |param| {
            return .{ .parameter = self.bp - param };
        }

        std.debug.print("Error: use of unknown var [{s}]\n", .{ident});
        std.process.exit(1);
    }

    fn setVariableFromStack(self: *Context, mir: *Self, ident: []const u8) !void {
        try mir.instructions.append(.{
            .tag = .pop,
            .lhs = .{ .register = 0 },
        });
        self.sp -= 8;

        if (self.locals.get(ident)) |local| {
            try mir.instructions.append(.{
                .tag = .mov,
                .lhs = .{ .variable = self.sp - local },
                .rhs = .{ .register = 0 },
            });

            return;
        }

        if (self.params.contains(ident)) {
            std.debug.print("Error: function params are immutable [{s}]\n", .{ident});
        } else {
            std.debug.print("Error: reassigning unknown variable [{s}]\n", .{ident});
        }
        std.process.exit(1);
    }
};

pub const Operand = union(enum) {
    indexed: u8,
    register: u8,
    variable: u32,
    parameter: u32,
    immediate: i64,

    fn print(self: Operand) void {
        switch (self) {
            .indexed => std.debug.print("[rg{d}]", .{self.indexed}),
            .register => std.debug.print("rg{d}", .{self.register}),
            .variable => std.debug.print("[sp + {d}]", .{self.variable}),
            .parameter => std.debug.print("[bp + {d}]", .{self.parameter}),
            .immediate => std.debug.print("{d}", .{self.immediate}),
        }
    }

    fn registerFromIdent(ident: []const u8) ?Operand {
        if (std.mem.eql(u8, ident, "rax")) {
            return .{ .register = 0b000 };
        } else if (std.mem.eql(u8, ident, "rcx")) {
            return .{ .register = 0b001 };
        } else if (std.mem.eql(u8, ident, "rdx")) {
            return .{ .register = 0b010 };
        } else if (std.mem.eql(u8, ident, "rbx")) {
            return .{ .register = 0b011 };
        } else if (std.mem.eql(u8, ident, "rsp")) {
            return .{ .register = 0b100 };
        } else if (std.mem.eql(u8, ident, "bpp")) {
            return .{ .register = 0b101 };
        } else if (std.mem.eql(u8, ident, "rsi")) {
            return .{ .register = 0b110 };
        } else if (std.mem.eql(u8, ident, "rdi")) {
            return .{ .register = 0b111 };
        }

        return null;
    }
};

pub const Instr = struct {
    tag: Tag,

    lhs: ?Operand = null,
    rhs: ?Operand = null,

    pub const Tag = enum {
        neg,
        xor,
        add,
        sub,
        div,
        mul,

        bit_or,
        bit_and,

        lea,
        mov,
        cmove,
        cmovne,
        cmovg,
        cmovge,
        cmovl,
        cmovle,

        cmp,
        jmp,
        je,

        pop,
        push,

        ret,
        call,
        syscall,

        fn unaryFrom(token: lex.Token.Tag) Tag {
            switch (token) {
                .minus => return .neg,
                else => std.debug.panic("Unknown unary expr kind: {any}\n", .{token}),
            }
        }

        fn binaryFrom(token: lex.Token.Tag) Tag {
            return switch (token) {
                .xor => .xor,
                .plus => .add,
                .minus => .sub,
                .slash => .div,
                .asterisk => .mul,

                .eq => .cmove,
                .not_eq => .cmovne,
                .less => .cmovl,
                .less_eq => .cmovle,
                .greater => .cmovg,
                .greater_eq => .cmovge,

                .con_or => .bit_or,
                .con_and => .bit_and,
                else => std.debug.panic("Unknown binary expr kind: {any}\n", .{token}),
            };
        }
    };
};

pub fn init(gpa: std.mem.Allocator, ast: Ast) Self {
    return .{
        .gpa = gpa,
        .ast = ast,
        .instructions = undefined,
    };
}

pub fn genInstructions(self: *Self) !void {
    self.instructions = std.ArrayList(Instr).init(self.gpa);

    var fns = std.AutoHashMap(usize, usize).init(self.gpa);
    defer fns.deinit();

    var ctx: Context = .{
        .bp = 0,
        .sp = 0,
        .params = std.StringHashMap(u32).init(self.gpa),
        .locals = std.StringHashMap(u32).init(self.gpa),
    };
    defer ctx.params.deinit();
    defer ctx.locals.deinit();

    // TODO: support multiple top level statements (like imports)

    // Entry point:
    try self.instructions.append(.{
        .tag = .call,
        .lhs = .{ .immediate = @intCast(self.ast.func_res.get("main").?) },
    });
    try self.instructions.append(.{
        .tag = .mov,
        .lhs = .{ .register = 0 },
        .rhs = .{ .immediate = 60 },
    });
    try self.instructions.append(.{
        .tag = .mov,
        .lhs = .{ .register = 7 },
        .rhs = .{ .immediate = 0 },
    });
    try self.instructions.append(.{ .tag = .syscall });

    for (self.ast.stmts.items) |stmt| {
        std.debug.print("Stmt: {any}\n", .{self.ast.nodes.items(.tag)[stmt]});
        try self.genFromStatement(stmt, &ctx, &fns);
    }

    // TODO: add init code for jumping to the main function

    for (self.instructions.items, 0..) |inst, i| {
        if (self.instructions.items[i].tag != .call) continue;
        var func = fns.get(@intCast(inst.lhs.?.immediate)).?;
        var call = i + 1;

        var is_neg: i64 = 1;

        if (func < call) {
            is_neg = -1;
            const tmp = func;
            func = call;
            call = tmp;
        }

        var bytes = try Asm.genCode(self.gpa, self.instructions.items[call..func]);
        const jump = is_neg * @as(i64, @intCast(bytes.items.len));
        self.instructions.items[i].lhs = .{ .immediate = jump };

        bytes.deinit();
    }
}

fn genFromStatement(
    self: *Self,
    stmt: usize,
    ctx: *Context,
    fns: *std.AutoHashMap(usize, usize),
) !void {
    const data = self.ast.nodes.items(.data)[stmt];

    switch (self.ast.nodes.items(.tag)[stmt]) {
        .mutable_declare, .constant_declare => {
            const tok = self.ast.nodes.items(.main)[data.lhs];
            const loc = self.ast.tokens.items(.loc)[tok];
            const ident = self.ast.source[loc.start..loc.end];

            try self.genFromExpression(data.rhs, ctx);
            try ctx.locals.put(ident, ctx.sp);
        },
        .assign_stmt => {
            try self.genFromExpression(data.rhs, ctx);

            switch (self.ast.nodes.items(.tag)[data.lhs]) {
                .ident => {
                    const tok = self.ast.nodes.items(.main)[data.lhs];
                    const loc = self.ast.tokens.items(.loc)[tok];

                    try ctx.setVariableFromStack(self, self.ast.source[loc.start..loc.end]);
                },
                .index_expr => {
                    const lhs = self.ast.nodes.items(.data)[data.lhs].lhs;
                    const rhs = self.ast.nodes.items(.data)[data.lhs].rhs;

                    const tok = self.ast.nodes.items(.main)[lhs];
                    const loc = self.ast.tokens.items(.loc)[tok];
                    const val = self.ast.source[loc.start..loc.end];

                    try self.instructions.append(.{
                        .tag = .pop,
                        .lhs = .{ .register = 3 },
                    });
                    ctx.sp -= 8;

                    // calculate index
                    try self.genFromExpression(rhs, ctx);
                    try self.instructions.append(.{
                        .tag = .pop,
                        .lhs = .{ .register = 0 },
                    });
                    ctx.sp -= 8;

                    // set type size (currently hardcoded as i64)
                    try self.instructions.append(.{
                        .tag = .mov,
                        .lhs = .{ .register = 1 },
                        .rhs = .{ .immediate = 8 },
                    });

                    // multiply type size with index
                    try self.instructions.append(.{
                        .tag = .mul,
                        .lhs = .{ .register = 0 },
                        .rhs = .{ .register = 1 },
                    });

                    // get array start
                    try self.instructions.append(.{
                        .tag = .lea,
                        .lhs = .{ .register = 1 },
                        .rhs = ctx.getVariableOperand(val),
                    });

                    // index + base = position
                    try self.instructions.append(.{
                        .tag = .add,
                        .lhs = .{ .register = 0 },
                        .rhs = .{ .register = 1 },
                    });

                    // mov array[position], expr
                    try self.instructions.append(.{
                        .tag = .mov,
                        .lhs = .{ .indexed = 0 },
                        .rhs = .{ .register = 3 },
                    });
                },
                else => @panic("ERROR(mir/assign): only indexed or ident as assign"),
            }
        },
        // TODO: have to create new scope within
        // because if a new variable does not get
        // deleted in the function the stack ptr
        // will get offsetet and all indexes will
        // be broken!
        .if_expr => {
            // cmp cond-1
            // je .blk -1
            //    ...
            //    jmp .end
            // cmp cond-2
            // je .blk -2
            //    ...
            //    jmp .end
            // .else
            //    ...
            // .end

            const cond = self.ast.conds.items[data.lhs];

            try self.genFromExpression(cond.if_cond, ctx);
            try self.instructions.append(.{
                .tag = .pop,
                .lhs = .{ .register = 0 },
            });
            ctx.sp -= 8;

            try self.instructions.append(.{
                .tag = .cmp,
                .lhs = .{ .register = 0 },
                .rhs = .{ .immediate = 0 },
            });
            try self.instructions.append(.{
                .tag = .je,
                .lhs = .{ .immediate = 0 },
            });

            var ptr = self.instructions.items.len;
            var jps = std.ArrayList(usize).init(self.gpa);

            for (cond.if_body.items) |body_stmt| {
                try self.genFromStatement(body_stmt, ctx, fns);
            }

            try self.instructions.append(.{
                .tag = .jmp,
                .lhs = .{ .immediate = 0 },
            });
            try jps.append(self.instructions.items.len);

            // NOTE: easiest and safest way to check the offset for the jmp since this will
            // be in the actual exectuable, probably not the most efficient way of doing it
            var bytes = try Asm.genCode(self.gpa, self.instructions.items[ptr..]);
            var jump = bytes.items.len;
            self.instructions.items[ptr - 1].lhs.?.immediate = @intCast(jump);
            bytes.deinit();

            for (cond.elif_ex.items) |idx| {
                const elif = self.ast.conds.items[idx];

                try self.genFromExpression(elif.if_cond, ctx);
                try self.instructions.append(.{
                    .tag = .pop,
                    .lhs = .{ .register = 0 },
                });
                ctx.sp -= 8;

                try self.instructions.append(.{
                    .tag = .cmp,
                    .lhs = .{ .register = 0 },
                    .rhs = .{ .immediate = 0 },
                });
                try self.instructions.append(.{
                    .tag = .je,
                    .lhs = .{ .immediate = 0 },
                });
                ptr = self.instructions.items.len;

                for (elif.if_body.items) |body_stmt| {
                    try self.genFromStatement(body_stmt, ctx, fns);
                }

                try self.instructions.append(.{
                    .tag = .jmp,
                    .lhs = .{ .immediate = 0 },
                });
                try jps.append(self.instructions.items.len);

                bytes = try Asm.genCode(self.gpa, self.instructions.items[ptr..]);
                jump = bytes.items.len;
                self.instructions.items[ptr - 1].lhs.?.immediate = @intCast(jump);
                bytes.deinit();
            }

            for (cond.el_body.items) |body_stmt| {
                try self.genFromStatement(body_stmt, ctx, fns);
            }

            for (jps.items) |jmp| {
                bytes = try Asm.genCode(self.gpa, self.instructions.items[jmp..]);
                jump = bytes.items.len;
                self.instructions.items[jmp - 1].lhs.?.immediate = @intCast(jump);
                bytes.deinit();
            }

            jps.deinit();
        },
        .while_expr => {
            // cmp cond
            // je 0
            //    ...
            // jmp start

            const loop = self.ast.loops.items[data.lhs];
            const size = self.instructions.items.len;

            try self.genFromExpression(loop.cond, ctx);
            try self.instructions.append(.{
                .tag = .pop,
                .lhs = .{ .register = 0 },
            });
            ctx.sp -= 8;

            try self.instructions.append(.{
                .tag = .cmp,
                .lhs = .{ .register = 0 },
                .rhs = .{ .immediate = 0 },
            });
            try self.instructions.append(.{
                .tag = .je,
                .lhs = .{ .immediate = 0 },
            });
            const ptr = self.instructions.items.len;

            var while_ctx = try ctx.clone();

            for (loop.body.items) |loop_stmt| {
                try self.genFromStatement(loop_stmt, &while_ctx, fns);
            }

            var iter = while_ctx.locals.iterator();
            while (iter.next()) |kv| {
                if (ctx.locals.contains(kv.key_ptr.*)) {
                    try ctx.locals.put(kv.key_ptr.*, kv.value_ptr.*);
                } else {
                    try self.instructions.append(.{ .tag = .pop, .lhs = .{ .register = 0 } });
                }
            }

            while_ctx.params.deinit();
            while_ctx.locals.deinit();

            try self.instructions.append(.{
                .tag = .jmp,
                .lhs = .{ .immediate = 0 },
            });

            const len = self.instructions.items.len;
            const eval = try Asm.genCode(self.gpa, self.instructions.items[size..ptr]);
            const eval_size = eval.items.len;

            const body = try Asm.genCode(self.gpa, self.instructions.items[ptr..]);
            const body_size = body.items.len;

            self.instructions.items[ptr - 1].lhs.?.immediate = @intCast(body_size);
            self.instructions.items[len - 1].lhs.?.immediate = -@as(i64, @intCast(eval_size + body_size));

            eval.deinit();
            body.deinit();
        },
        .macro_call_expr => {
            const man = self.ast.nodes.items(.main)[data.lhs];
            const loc = self.ast.tokens.items(.loc)[man];
            const lit = self.ast.source[loc.start..loc.end];

            if (std.mem.eql(u8, lit, "asm")) {
                try self.genFromMacroCall(&self.ast.calls.items[data.rhs], ctx);
            } else {
                std.debug.print("{s}\n", .{lit});
                @panic("Error: invalid compile macro");
            }
        },
        .function_declare => {
            const fident = self.ast.nodes.items(.main)[data.lhs];
            const floc = self.ast.tokens.items(.loc)[fident];
            try fns.put(stmt, self.instructions.items.len);

            std.debug.print("   FUNC: {s}\n", .{self.ast.source[floc.start..floc.end]});

            try self.instructions.append(.{
                .tag = .push,
                .lhs = .{ .register = 5 },
            });
            try self.instructions.append(.{
                .tag = .mov,
                .lhs = .{ .register = 5 },
                .rhs = .{ .register = 4 },
            });

            var func_ctx: Context = .{
                .bp = 0,
                .sp = 0,
                .params = std.StringHashMap(u32).init(self.gpa),
                .locals = std.StringHashMap(u32).init(self.gpa),
            };
            defer func_ctx.params.deinit();
            defer func_ctx.locals.deinit();

            for (self.ast.funcs.items(.args)[data.rhs].items) |param| {
                const tok = self.ast.nodes.items(.data)[param].lhs;
                const loc = self.ast.tokens.items(.loc)[tok];
                const val = self.ast.source[loc.start..loc.end];

                try func_ctx.params.put(val, func_ctx.bp);
                func_ctx.bp += 8;
            }

            const ret_typ = self.ast.funcs.items(.return_type)[data.rhs];
            func_ctx.bp += if (ret_typ != .invalid) 16 else 8;

            for (self.ast.funcs.items(.body)[data.rhs].items) |func_stmt| {
                try self.genFromStatement(func_stmt, &func_ctx, fns);
            }

            try self.instructions.append(.{
                .tag = .mov,
                .lhs = .{ .register = 4 },
                .rhs = .{ .register = 5 },
            });
            try self.instructions.append(.{
                .tag = .pop,
                .lhs = .{ .register = 5 },
            });
            try self.instructions.append(.{ .tag = .ret });
        },
        .return_stmt => {
            if (data.lhs != std.math.maxInt(usize)) {
                const idx = self.instructions.items.len;
                std.debug.print("RET: {any}\n", .{data.lhs});

                try self.genFromExpression(data.lhs, ctx);
                for (self.instructions.items[idx..]) |ins| {
                    std.debug.print("RET: {any}\n", .{ins});
                }

                try self.instructions.append(.{
                    .tag = .pop,
                    .lhs = .{ .register = 0 },
                });
                try self.instructions.append(.{
                    .tag = .mov,
                    .lhs = .{ .parameter = 16 },
                    .rhs = .{ .register = 0 },
                });
            }

            try self.instructions.append(.{
                .tag = .mov,
                .lhs = .{ .register = 4 },
                .rhs = .{ .register = 5 },
            });
            try self.instructions.append(.{
                .tag = .pop,
                .lhs = .{ .register = 5 },
            });
            try self.instructions.append(.{ .tag = .ret });
        },
        .call_expr => {
            const ident = self.ast.nodes.items(.main)[data.lhs];
            const loc = self.ast.tokens.items(.loc)[ident];
            const val = self.ast.source[loc.start..loc.end];

            const flok = self.ast.func_res.get(val).?;
            const func = self.ast.nodes.items(.data)[flok].rhs;
            const rett = self.ast.funcs.items(.return_type)[func];

            const call = self.ast.calls.items[data.rhs];
            var offset: i64 = 0;

            for (call.args.items) |arg| {
                // NOTE: putting everything on the stack
                try self.genFromExpression(arg, ctx);

                offset += 8;
                ctx.sp -= 8;
            }

            if (rett != .invalid) {
                try self.instructions.append(.{
                    .tag = .sub,
                    .lhs = .{ .register = 4 },
                    .rhs = .{ .immediate = 8 },
                });
                offset += 8;
            }

            try self.instructions.append(.{
                .tag = .call,
                .lhs = .{ .immediate = @intCast(flok) },
            });

            if (rett != .invalid) {
                try self.instructions.append(.{
                    .tag = .pop,
                    .lhs = .{ .register = 0 },
                });
            }
            try self.instructions.append(.{
                .tag = .add,
                .lhs = .{ .register = 4 },
                .rhs = .{ .immediate = offset },
            });
        },
        else => {
            std.debug.print("MISSING IMPL\n", .{});
        },
    }
}

fn genFromExpression(self: *Self, expr: usize, ctx: *Context) !void {
    const data = self.ast.nodes.items(.data)[expr];
    const main = self.ast.nodes.items(.main)[expr];
    // NOTE: expression evaluation *ALWAYS* puts something on the stack
    defer ctx.sp += 8;

    switch (self.ast.nodes.items(.tag)[expr]) {
        .num_expr => {
            const loc = self.ast.tokens.items(.loc)[main];
            const lit = self.ast.source[loc.start..loc.end];
            const num = try std.fmt.parseInt(i64, lit, 10);

            try self.instructions.append(.{ .tag = .push, .lhs = .{ .immediate = num } });
        },
        .ident => {
            const loc = self.ast.tokens.items(.loc)[main];
            try ctx.pushVariableOnStack(self, self.ast.source[loc.start..loc.end]);
        },
        .binary_expr => {
            try self.genFromExpression(data.lhs, ctx);
            try self.genFromExpression(data.rhs, ctx);

            try self.instructions.append(.{
                .tag = .pop,
                .lhs = .{ .register = 0 },
            });
            try self.instructions.append(.{
                .tag = .pop,
                .lhs = .{ .register = 1 },
            });
            ctx.sp -= 16;

            switch (self.ast.tokens.items(.tag)[main]) {
                .eq, .not_eq, .less, .less_eq, .greater, .greater_eq => {
                    try self.instructions.append(.{
                        .tag = .mov,
                        .lhs = .{ .register = 2 },
                        .rhs = .{ .immediate = 0 },
                    });
                    try self.instructions.append(.{
                        .tag = .cmp,
                        .lhs = .{ .register = 0 },
                        .rhs = .{ .register = 1 },
                    });

                    try self.instructions.append(.{
                        .tag = Instr.Tag.binaryFrom(self.ast.tokens.items(.tag)[main]),
                        .lhs = .{ .register = 2 },
                        .rhs = .{ .immediate = 1 },
                    });

                    try self.instructions.append(.{
                        .tag = .push,
                        .lhs = .{ .register = 2 },
                    });
                },
                .con_or, .con_and => {
                    try self.instructions.append(.{
                        .tag = .mov,
                        .lhs = .{ .register = 2 },
                        .rhs = .{ .immediate = 0 },
                    });
                    try self.instructions.append(.{
                        .tag = Instr.Tag.binaryFrom(self.ast.tokens.items(.tag)[main]),
                        .lhs = .{ .register = 0 },
                        .rhs = .{ .register = 1 },
                    });
                    try self.instructions.append(.{
                        .tag = .cmp,
                        .lhs = .{ .register = 0 },
                        .rhs = .{ .immediate = 0 },
                    });

                    try self.instructions.append(.{
                        .tag = .cmovne,
                        .lhs = .{ .register = 2 },
                        .rhs = .{ .immediate = 1 },
                    });

                    try self.instructions.append(.{
                        .tag = .push,
                        .lhs = .{ .register = 2 },
                    });
                },
                else => {
                    try self.instructions.append(.{
                        .tag = Instr.Tag.binaryFrom(self.ast.tokens.items(.tag)[main]),
                        .lhs = .{ .register = 0 },
                        .rhs = .{ .register = 1 },
                    });
                    try self.instructions.append(.{
                        .tag = .push,
                        .lhs = .{ .register = 0 },
                    });
                },
            }
        },
        .unary_expr => {
            const tag = Instr.Tag.unaryFrom(self.ast.tokens.items(.tag)[main]);

            try self.genFromExpression(data.lhs, ctx);

            try self.instructions.append(.{
                .tag = .pop,
                .lhs = .{ .register = 0 },
            });
            ctx.sp -= 8;

            try self.instructions.append(.{
                .tag = tag,
                .lhs = .{ .register = 0 },
            });
            try self.instructions.append(.{
                .tag = .push,
                .lhs = .{ .register = 0 },
            });
        },
        .call_expr => {
            const ident = self.ast.nodes.items(.main)[data.lhs];
            const loc = self.ast.tokens.items(.loc)[ident];
            const val = self.ast.source[loc.start..loc.end];

            const flok = self.ast.func_res.get(val).?;
            const func = self.ast.nodes.items(.data)[flok].rhs;
            const rett = self.ast.funcs.items(.return_type)[func];

            const call = self.ast.calls.items[data.rhs];
            var offset: i64 = 0;

            for (call.args.items) |arg| {
                // NOTE: putting everything on the stack
                try self.genFromExpression(arg, ctx);

                ctx.sp -= 8;
                offset += 8;
            }

            if (rett != .invalid) {
                try self.instructions.append(.{
                    .tag = .sub,
                    .lhs = .{ .register = 4 },
                    .rhs = .{ .immediate = 8 },
                });
            }

            try self.instructions.append(.{
                .tag = .call,
                .lhs = .{ .immediate = @intCast(flok) },
            });

            if (rett != .invalid) {
                try self.instructions.append(.{
                    .tag = .pop,
                    .lhs = .{ .register = 0 },
                });
            }

            try self.instructions.append(.{
                .tag = .add,
                .lhs = .{ .register = 4 },
                .rhs = .{ .immediate = offset },
            });

            if (rett != .invalid) {
                try self.instructions.append(.{
                    .tag = .push,
                    .lhs = .{ .register = 0 },
                });
            }
        },
        .array_declare => {
            const array = self.ast.arras.items[main];
            const len = array.elements.items.len;

            for (array.elements.items, 0..) |_, i| {
                try self.genFromExpression(array.elements.items[len - i - 1], ctx);
            }

            ctx.sp -= 8;
        },
        // TODO: holy hack this is bad! Change this as soon as possible!
        .index_expr => {
            const ident = self.ast.nodes.items(.main)[data.lhs];
            const loc = self.ast.tokens.items(.loc)[ident];
            const val = self.ast.source[loc.start..loc.end];

            // calculate index
            try self.genFromExpression(data.rhs, ctx);
            try self.instructions.append(.{
                .tag = .pop,
                .lhs = .{ .register = 0 },
            });
            ctx.sp -= 8;

            // set type size (currently hardcoded as i64)
            try self.instructions.append(.{
                .tag = .mov,
                .lhs = .{ .register = 1 },
                .rhs = .{ .immediate = 8 },
            });

            // multiply type size with index
            try self.instructions.append(.{
                .tag = .mul,
                .lhs = .{ .register = 0 },
                .rhs = .{ .register = 1 },
            });

            // get array start
            try self.instructions.append(.{
                .tag = .lea,
                .lhs = .{ .register = 1 },
                .rhs = ctx.getVariableOperand(val),
            });

            // index + base = position
            try self.instructions.append(.{
                .tag = .add,
                .lhs = .{ .register = 0 },
                .rhs = .{ .register = 1 },
            });

            // push array[position]
            try self.instructions.append(.{
                .tag = .push,
                .lhs = .{ .indexed = 0 },
            });
        },
        else => {
            std.debug.print(
                "TODO: not implement expr {any}\n",
                .{self.ast.nodes.items(.tag)[expr]},
            );
            std.process.exit(1);
        },
    }
}

fn genFromMacroCall(self: *Self, macro_call: *Ast.Call, ctx: *Context) !void {
    for (macro_call.args.items) |arg| {
        if (self.ast.nodes.items(.tag)[arg] != .str_expr) @panic("ERROR: macro expected str_expr");

        const loc = self.ast.tokens.items(.loc)[self.ast.nodes.items(.main)[arg]];
        const val = self.ast.source[loc.start..loc.end];

        var it = std.mem.split(u8, val, " ");
        const op = it.next().?;

        var instr: Instr = .{ .tag = .mov };

        if (std.mem.eql(u8, op, "mov")) {
            instr.tag = .mov;
            instr.lhs = parseOperand(ctx, it.next().?, true, false);
            instr.rhs = parseOperand(ctx, it.next().?, false, true);
        } else if (std.mem.eql(u8, op, "lea")) {
            instr.tag = .lea;
            instr.lhs = parseOperand(ctx, it.next().?, true, false);
            instr.rhs = parseOperand(ctx, it.next().?, false, false);
        } else if (std.mem.eql(u8, op, "syscall")) {
            instr.tag = .syscall;
        } else {
            std.debug.print("Error(mir/asm): asm instruction[{s} not implemented", .{op});
            std.process.exit(1);
        }

        try self.instructions.append(instr);
    }
}

fn parseOperand(ctx: *Context, ident: []const u8, is_lhs: bool, parseable: bool) Operand {
    const off: usize = if (is_lhs) 1 else 0;
    const val = ident[0 .. ident.len - off];

    if (Operand.registerFromIdent(val)) |reg| {
        return reg;
    }

    if (!parseable) return ctx.getVariableOperand(val);

    const number = std.fmt.parseInt(i64, ident, 10) catch {
        return ctx.getVariableOperand(ident);
    };

    return .{ .immediate = number };
}
