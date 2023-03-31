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

const net = struct {
    usingnamespace @import("net/network.zig");
};
const udp = struct {
    usingnamespace @import("net/udp_socket.zig");
};
const reader = struct {
    usingnamespace @import("net/udp_reader.zig");
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

    var hwAddr: net.EndPoint = undefined;
    var readerThrd: std.Thread = undefined;

    // Initialise WSDP
    try wdsp.init();

    // Initialise net
    try net.init();
    defer net.deinit();
    //std.debug.print("Endpoints: {}\n", .{net.getEndpointList()});

    // Open a broadcast socket
    var s: net.Socket = try udp.udp_open_bc_socket();
    // Run discover protocol
    hwAddr = try hw.Hardware.do_discover(&s);
    std.debug.print("Device addr: {}\n", .{hwAddr});
    // Revert socket
    try udp.udp_revert_socket();

    // Run reader thread
    //const reader_ch = std.event.Channel(u32);
    //readerThrd = try reader.reader_start(reader_ch);
    readerThrd = try reader.reader_start();

    // Run UI
    try ui.build();
    try ui.run();
    //std.time.sleep(1000000000);

    // Close everything
    try udp.udp_close_socket();
    //reader_ch.put(1);
    readerThrd.join();
}

pub fn run() !void {
    try wdsp.init();
}

test "ZigSDR" {
    try run();
}
