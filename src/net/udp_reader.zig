// udp_reader.zig
//
// Module - udp_reader
// Manage UDP read data
//
// Copyright (C) 2023 by G3UKB Bob Cowdery
//
// This program is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
//
// The authors can be reached by email at:
//
// bob@bobcowdery.plus.com

const std = @import("std");

const net = struct {
    usingnamespace @import("network.zig");
};

pub const Reader = struct {
    var terminate = false;

    fn loop(sock: *net.Socket, hwAddr: net.EndPoint, rb: *std.RingBuffer) !void {
        _ = hwAddr;
        // _ = sock;
        var n: u32 = 0;
        while (!terminate) {
            var data = std.mem.zeroes([1032]u8);
            var resp: net.Socket.ReceiveFrom = undefined;
            resp = try sock.receiveFrom(&data);
            if (resp.numberOfBytes == 1032) {
                try rb.writeSlice(&data);
            }
            //fn loop(ch: std.event.Channel(u32)) !void {
            //    while (ch.get_count == 0) {
            //        std.time.sleep(100000000);
            //    }
            //    std.debug.print("Reader loop exiting\n", .{});
            //}
            std.debug.print("Reader loop got {any}, {any}\n", .{ resp.numberOfBytes, resp.sender });
            n += 1;
            std.time.sleep(100000000);
        }
        std.debug.print("Reader loop exiting\n", .{});
    }

    pub fn term() void {
        std.debug.print("Term\n", .{});
        terminate = true;
    }
};

//fn reader_thrd(ch: std.event.Channel(u32)) !void {
fn reader_thrd(sock: *net.Socket, hwAddr: net.EndPoint, rb: *std.RingBuffer) !void {
    std.debug.print("Reader thread\n", .{});
    //try Reader.loop(ch);
    try Reader.loop(sock, hwAddr, rb);
}

//==================================================================================
// Thread startup
//pub fn reader_start(ch: std.event.Channel(u32)) std.Thread.SpawnError!std.Thread {
pub fn reader_start(sock: *net.Socket, hwAddr: net.EndPoint, rb: *std.RingBuffer) std.Thread.SpawnError!std.Thread {

    //return try std.Thread.spawn(.{}, reader_thrd, .{ch});
    return try std.Thread.spawn(.{}, reader_thrd, .{ sock, hwAddr, rb });
}
