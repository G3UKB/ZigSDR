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

const globals = struct {
    usingnamespace @import("common/globals.zig");
};
const defs = struct {
    usingnamespace @import("common/common_defs.zig");
};
const net = struct {
    usingnamespace @import("net/network.zig");
};
const udp = struct {
    usingnamespace @import("net/udp_socket.zig");
};
const reader = struct {
    usingnamespace @import("net/udp_reader.zig");
};
const pipeline = struct {
    usingnamespace @import("pipeline/pipeline.zig");
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

    var sock: net.Socket = undefined;
    var hwAddr: net.EndPoint = undefined;
    var pipelineThrd: std.Thread = undefined;
    var readerThrd: std.Thread = undefined;
    var iq_mut = std.Thread.Mutex{};
    var iq_cond = std.Thread.Condition{};

    // Initialise WSDP (creates wisdom file if not exist)
    try wdsp.init();
    // Open a DSP receiver channel
    try wdsp.wdsp_open_ch(defs.CH_RX, 0, defs.DSP_BLK_SZ, defs.DSP_BLK_SZ, globals.Globals.smpl_rate, defs.SMPLS_48K, 0.0, 0.0, 0.0, 0.0);
    // and start the channel
    try wdsp.wdsp_set_ch_state(0, 1, 0);

    // Initialise net
    try net.init();
    defer net.deinit();

    // Open a broadcast socket
    sock = try udp.udp_open_bc_socket();
    // Run discover protocol
    hwAddr = try hw.Hardware.do_discover(&sock);
    std.debug.print("Device addr: {}\n", .{hwAddr});
    // Revert socket
    try udp.udp_revert_socket();

    // Create an iq ring buffer
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    var rb_iq = try std.RingBuffer.init(allocator, 262144);

    // Run pipeline thread
    pipelineThrd = try pipeline.pipeline_start(hwAddr, &rb_iq, &iq_mut, &iq_cond);

    // Run reader thread
    readerThrd = try reader.reader_start(&sock, hwAddr, &rb_iq, &iq_mut, &iq_cond);

    // Give the threads a chance to start
    std.time.sleep(1000000000);

    // Start processing
    pipeline.Pipeline.process(true);
    reader.Reader.listen(true);

    // Start streaming
    try hw.Hardware.do_start(&sock, false);

    // Run UI
    try ui.build();
    try ui.run();

    // Close everything
    try hw.Hardware.do_stop(&sock);
    try udp.udp_close_socket();
    reader.Reader.listen(false);
    reader.Reader.term();
    pipeline.Pipeline.term();
    readerThrd.join();
}
