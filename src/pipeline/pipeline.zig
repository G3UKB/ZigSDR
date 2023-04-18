// pipeline.zig
//
// Module - pipeline
// Coordinates the main sequence.
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

const globals = struct {
    usingnamespace @import("../common/globals.zig");
};

const defs = struct {
    usingnamespace @import("../common/common_defs.zig");
};

const seq = struct {
    usingnamespace @import("../protocol/seq_in.zig");
};

const net = struct {
    usingnamespace @import("../net/network.zig");
};

pub const Pipeline = struct {

    // Constants
    const sz: usize = defs.DSP_BLK_SZ * defs.BYTES_PER_SAMPLE;
    // Module variables
    var terminate = false;
    var iq_data = std.mem.zeroes([sz]u8);
    var rb: *std.RingBuffer = undefined;
    var mutex: *std.Thread.Mutex = undefined;
    var cond: *std.Thread.Condition = undefined;

    // Thread loop until terminate
    pub fn pipeline_run(hwAddr: net.EndPoint, rb_reader: *std.RingBuffer, iq_mutex: *std.Thread.Mutex, iq_cond: *std.Thread.Condition) !void {
        _ = hwAddr;
        rb = rb_reader;
        mutex = iq_mutex;
        cond = iq_cond;

        while (!terminate) {
            // Wait for data to be signalled
            if (try wait_data()) {
                // Data to process, already extracted from ring buffer to iq_data
                try run_sequence();
            }
        }
    }

    pub fn term() void {
        std.debug.print("Term pipeline\n", .{});
        terminate = true;
    }

    // Extract data from IQ ring buffer
    fn wait_data() !bool {
        // Wait for a signal
        mutex.lock();
        defer mutex.unlock();
        cond.timedWait(mutex, 10000000) catch |err| {
            if (err == error.Timeout) {
                return false;
            } else {
                // Extract data from the ring buffer to local storage
                var rb_slice: std.RingBuffer.Slice = try rb.sliceAt(rb.read_index, sz);
                var first = rb_slice.first;
                var second = rb_slice.second;
                iq_data = first + second;
                return true;
            }
        };
    }

    // Run the sequence to process IQ data
    fn run_sequence() !void {}
};

// Start pipeline loop
fn pipeline_thrd(hwAddr: net.EndPoint, rb: *std.RingBuffer, iq_mutex: *std.Thread.Mutex, iq_cond: *std.Thread.Condition) !void {
    std.debug.print("Reader thread\n", .{});
    try Pipeline.pipeline_run(hwAddr, rb, iq_mutex, iq_cond);
}

//==================================================================================
// Thread startup
pub fn pipeline_start(hwAddr: net.EndPoint, rb: *std.RingBuffer, iq_mutex: *std.Thread.Mutex, iq_cond: *std.Thread.Condition) std.Thread.SpawnError!std.Thread {
    return try std.Thread.spawn(.{}, pipeline_thrd, .{ hwAddr, rb, iq_mutex, iq_cond });
}
