// hw_control.zig
//
// Module - hw_control
// Manage discovery/run/stop hardware
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

pub const Hardware = struct {
    const port: u32 = 1024;
    const MAX_MSG: u32 = 63;
    var hwAddr: net.EndPoint = undefined;

    // Run discover protocol
    pub fn do_discover(sock: *net.Socket) !net.EndPoint {

        // Broadcast addr
        const bcAddr = net.EndPoint{
            .address = net.Address{ .ipv4 = net.Address.IPv4.broadcast },
            .port = port,
        };
        // Bind addr
        const bindAddr = net.EndPoint{
            .address = net.Address{ .ipv4 = net.Address.IPv4.mine },
            .port = 10001,
        };

        // Bind to our local machine IP
        try sock.bind(bindAddr);

        // Format discover packet
        var data = std.mem.zeroes([MAX_MSG]u8);
        data[0] = 0xEF;
        data[1] = 0xFE;
        data[2] = 0x02;

        // Send discover packet
        var e = try sock.sendTo(bcAddr, data[0..MAX_MSG]);
        std.debug.print("Discover sent {} bytes\n", .{e});

        // Read response
        hwAddr = try read_response(sock);
        return hwAddr;
    }

    // Start hardware streaming
    pub fn do_start(sock: *net.Socket, wbs: bool) !void {

        // Format start packet
        const data = [4]u8{ 0xEF, 0xFE, 0x04, 0x01 };
        if (!wbs) data[4] = 0x03;
        // Send start packet
        try sock.sendTo(&hwAddr, &data);
    }

    // Stop hardware streaming
    pub fn do_stop(sock: *net.Socket) !void {

        // Format stop packet
        const data = [4]u8{ 0xEF, 0xFE, 0x04, 0x00 };
        // Send stop packet
        try sock.sendTo(&hwAddr, &data);
    }

    // Read responses
    fn read_response(sock: *net.Socket) !net.EndPoint {
        var response: net.Socket.ReceiveFrom = undefined;
        var count: u32 = 2;
        var data = std.mem.zeroes([63]u8);
        var retry = true;
        while (retry) {
            response = sock.receiveFrom(&data) catch |err| {
                std.debug.print("Discover fail, retrying: {}\n", .{err});
                const stderr = std.io.getStdErr();
                _ = stderr;
                count -= 1;
                if (count <= 0) {
                    break;
                } else {
                    std.time.sleep(100000000);
                    continue;
                }
            };
            retry = false;
        }
        std.debug.print("Discover resp: {any}, {any}\n", .{ response.numberOfBytes, response.sender });
        return response.sender;
    }
};
