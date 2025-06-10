// Timothy Ayers 2025-1-6
// Computer Enhance
// Learning Zig

const std = @import("std");

const OpCode = enum(u6) { mov = 0b100010, unknown };

const Mod = enum(u2) {
    mem = 0b00,
    mem_disp8 = 0b01,
    mem_disp16 = 0b10,
    register = 0b11,
};

const REG_BYTE = enum(u3) { al = 0b000, cl = 0b001, dl = 0b010, bl = 0b011, ah = 0b100, ch = 0b101, dh = 0b110, bh = 0b111 };
const REG_WORD = enum(u3) { ax = 0b000, cx = 0b001, dx = 0b010, bx = 0b011, sp = 0b100, bp = 0b101, si = 0b110, di = 0b111 };

//const Sign = enum(u1) { no_sign = 0b0, signed = 0b1 };
const OpsOn = enum(u1) { byte = 0b0, word = 0b1 };
const SrcDest = enum(u1) { src_in_reg = 0b0, dest_in_reg = 0b1 };
//const Rotate = enum(u1) { one = 0b0, cl_reg = 0b1 };
//const ZeroFlag = enum(u1) { clear = 0b0, set = 0b1 };

const Instruction = packed struct(u16) {
    W:          OpsOn,
    D:          SrcDest,
    OpCode:     OpCode,
    RM:         u3,
    Reg:        u3,
    Mod:       Mod,
};

const DispData = struct {
    low:    u8,
    high:   u8,
};

const Data = struct {
    low:    u8,
    high:   u8,
};

pub fn main() !void {
    std.debug.print("Sim86\n\n", .{});

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();
    var args = try std.process.argsWithAllocator(allocator);
    _ = args.next(); // skip first arg as that is the name of the executable

    const filename = args.next() orelse {
        std.debug.print("usage: sim86 <filename>\n", .{});
        return;
    };

    const file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();

    const stdout_file = std.io.getStdOut().writer();
    var buf_writer = std.io.bufferedWriter(stdout_file);
    const writer = buf_writer.writer();

    
    _ = try writer.print("; {s}\n", .{filename});
    _ = try writer.print("bits 16\n", .{});

    const reader = file.reader();

    while (reader.readStruct(Instruction)) |instruction| {
        _ = try writer.write(switch (instruction.OpCode) {
            .mov => "mov ",
            else => unreachable,
        });
        
        _ = try writer.write(" ");        
        _ = try writer.write(regRM(instruction.Mod, instruction.W, instruction.RM));
        _ = try writer.write(", ");
        _ = try writer.write(regAddr(instruction.W, instruction.Reg));
        _ = try writer.write("\n");

    } else |err| switch (err) {
        error.EndOfStream => {},
        else => std.debug.print("Error reading instruction: {}\n", .{err}),
    }

    try buf_writer.flush();
}

fn regRM(mod: Mod, w: OpsOn, address: u3) []const u8 {
    return switch (mod) {
        .register => regAddr(w, address),
        else => unreachable,
    };
}

fn regAddr(w: OpsOn, address: u3) []const u8 {
    return switch (w) {
        .byte => switch (@as(REG_BYTE, @enumFromInt(address))) {
            inline else => |variant| @tagName(variant),
        },
        .word => switch (@as(REG_WORD, @enumFromInt(address))) {
            inline else => |variant| @tagName(variant),
        },
    };
}
