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

const converters = struct {
    usingnamespace @import("../common/converters.zig");
};

const seq = struct {
    usingnamespace @import("../protocol/seq_in.zig");
};

const net = struct {
    usingnamespace @import("../net/network.zig");
};
const wdsp = struct {
    usingnamespace @import("../sdr/wdsp.zig");
};

pub const Pipeline = struct {

    // Constants
    const dsp_blk_sz: usize = defs.DSP_BLK_SZ * defs.BYTES_PER_SAMPLE;
    // Module variables
    var terminate = false;
    var bprocess = false;
    var iq_data = std.mem.zeroes([dsp_blk_sz]u8);
    var iq_dsp_data: [defs.DSP_BLK_SZ * 2]f64 = undefined;
    var iq_proc_data: [defs.DSP_BLK_SZ * 2]f64 = undefined;
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
            if (bprocess) {
                // Wait for data to be signalled
                if (wait_data()) {
                    // Extract data from the ring buffer to local storage
                    //var rb_slice: std.RingBuffer.Slice = rb.sliceAt(rb.read_index, sz);
                    //var rb_slice: std.RingBuffer.Slice = rb.sliceLast(sz);
                    //std.debug.print("RB len {}, read ptr {}\n", .{ rb.len(), rb.read_index });
                    //std.debug.print("Read ptr {}\n", .{rb.read_index});
                    //iq_data = *rb_slice.first; // + *rb_slice.second;
                    //std.debug.print("Data {}, {}\n", .{ rb_slice.first.len, rb_slice.second.len });
                    // Data to process, already extracted from ring buffer to iq_data
                    if (rb.len() > dsp_blk_sz) {
                        var index: u32 = 0;
                        while (index < dsp_blk_sz) {
                            iq_data[index] = rb.readAssumeLength();
                            index += 1;
                        }
                    }
                    try run_sequence();
                }
            } else {
                // Waste 10ms while not listening
                std.time.sleep(10000000);
            }
        }
        std.debug.print("Pipeline thread exiting...\n", .{});
    }

    // State settings
    pub fn process(state: bool) void {
        if (state) {
            bprocess = true;
        } else {
            bprocess = false;
        }
        std.debug.print("Process {}\n", .{bprocess});
    }

    pub fn term() void {
        std.debug.print("Term pipeline\n", .{});
        terminate = true;
    }

    // At each signal more data has been added to the ring buffer
    fn wait_data() bool {
        var success: bool = false;

        // Wait for a signal
        mutex.lock();
        defer mutex.unlock();
        while (true) {
            cond.timedWait(mutex, 10000000) catch |err| {
                if (err == error.Timeout) {
                    //std.debug.print("Timeout\n", .{});
                    if (terminate) {
                        break;
                    } else {
                        continue;
                    }
                }
            };
            success = true;
            break;
        }
        //std.debug.print("Wait {}\n", .{success});
        return success;
    }

    // Run the sequence to process IQ data
    fn run_sequence() !void {
        // Convert the byte stream in BE 24 bit IQ samples -
        // to LE 64 bit double samples for the DSP process
        converters.i8be_to_f64le(&iq_data, &iq_dsp_data);

        // Exchange data with DSP engine
        var e: i32 = wdsp.wdsp_exchange(&iq_dsp_data, &iq_proc_data);
        if (e == 0) {
            // Successful exchange
            // Process data for audio output
        }
    }
};

// Start pipeline loop
fn pipeline_thrd(hwAddr: net.EndPoint, rb: *std.RingBuffer, iq_mutex: *std.Thread.Mutex, iq_cond: *std.Thread.Condition) !void {
    std.debug.print("Pipeline thread starting...\n", .{});
    try Pipeline.pipeline_run(hwAddr, rb, iq_mutex, iq_cond);
}

//==================================================================================
// Thread startup
pub fn pipeline_start(hwAddr: net.EndPoint, rb: *std.RingBuffer, iq_mutex: *std.Thread.Mutex, iq_cond: *std.Thread.Condition) std.Thread.SpawnError!std.Thread {
    return try std.Thread.spawn(.{}, pipeline_thrd, .{ hwAddr, rb, iq_mutex, iq_cond });
}
