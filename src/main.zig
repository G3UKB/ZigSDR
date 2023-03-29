// main.zig
//
// Module - main
// Entry point fr application
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
//

pub const enable_dev_tools = false;

const std = @import("std");
const expect = std.testing.expect;

const capy = @import("capy");
pub usingnamespace capy.cross_platform;

const network = struct {
    usingnamespace @import("net/network.zig");
};
const net = struct {
    usingnamespace @import("net/udp_socket.zig");
};
const hw = struct {
    usingnamespace @import("net/hw_control.zig");
};
const wdsp = struct {
    usingnamespace @import("sdr/wdsp.zig");
};
const ui = struct {
    usingnamespace @import("ui/main_window.zig");
};

pub fn main() !void {
    std.log.info("ZigSDR running...", .{});

    // Initialise WSDP
    try wdsp.init();

    // Try net
    //try net.udp_open_bc_socket();
    //try net.udp_revert_socket();
    //try net.udp_close_socket();

    //try network.init();
    var r = try hw.do_discover();

    //var thread = try std.Thread.spawn(.{}, hw.do_discover, .{});
    //_ = thread;

    std.debug.print("Discover resp: {}", .{r});
    //defer network.deinit();

    //try net.init();
    //defer net.deinit();

    //const sock = try net.connectToHost(std.heap.page_allocator, "tcpbin.com", 4242, .tcp);
    //defer sock.close();

    //const msg = "Hi from socket!\n";
    //try sock.writer().writeAll(msg);

    //var buf: [128]u8 = undefined;
    //std.debug.print("Echo: {s}", .{buf[0..try sock.reader().readAll(buf[0..msg.len])]});

    // Run UI
    try ui.build();
    try ui.run();
}

pub fn run() !void {
    try wdsp.init();
}

test "ZigSDR" {
    try run();
}
