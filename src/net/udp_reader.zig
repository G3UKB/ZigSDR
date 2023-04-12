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

const globals = struct {
    usingnamespace @import("common/globals.zig");
};

const defs = struct {
    usingnamespace @import("common/common_defs.zig");
};

const seq = struct {
    usingnamespace @import("protocol/seq_in.zig");
};

const net = struct {
    usingnamespace @import("network.zig");
};

pub const Reader = struct {

    // Global constants for convienience
    const num_rx = globals.Globals.num_rx;
    const sel_rx = globals.Globals.sel_rx;
    const smpl_rate = globals.Globals.smpl_rate;

    // Tiny state machine states for IQ, Mic. Skip
    const IQ: i32 = 0;
    const M: i32 = 1;
    const SIQ1: i32 = 2;
    const SIQ2: i32 = 3;
    const SM1: i32 = 4;
    const SM2: i32 = 5;
    const SM3: i32 = 6;

    // Module variables
    var blisten = false;
    var terminate = false;
    var udp_frame = std.mem.zeroes([defs.FRAME_SZ]u8);
    var iq = std.mem.zeroes([defs.IQ_ARR_SZ_R1]u8);
    var mic = std.mem.zeroes([defs.MIC_ARR_SZ_R1]u8);
    var rb: *std.RingBuffer = undefined;
    var mutex: std.Thread.Mutex = undefined;
    var cond: std.Thread.Condition = undefined;

    // Thread loop until terminate
    fn loop(sock: *net.Socket, hwAddr: net.EndPoint, rb_reader: *std.RingBuffer, iq_mutex: std.Thread.Mutex, iq_cond: std.Thread.Condition) !void {
        _ = hwAddr;
        rb = rb_reader;
        mutex = iq_mutex;
        cond = iq_cond;
        var n: u32 = 0;
        while (!terminate) {
            if (listen) {
                var resp: net.Socket.ReceiveFrom = undefined;
                resp = try sock.receiveFrom(&udp_frame);
                if (resp.numberOfBytes == 1032) {
                    //try rb.writeSlice(&data);
                    try split_frame();
                } else {
                    std.debug.print("Reader loop got short frame! Ignoring {any}\n", .{resp.numberOfBytes});
                }
                std.debug.print("Reader loop got {any}, {any}\n", .{ resp.numberOfBytes, resp.sender });
                n += 1;
            }
            std.time.sleep(100000000);
        }
        std.debug.print("Reader loop exiting\n", .{});
    }

    // State settings
    pub fn listen(state: bool) void {
        if (state) {
            blisten = true;
        } else {
            blisten = false;
        }
        std.debug.print("Listen {}\n", .{blisten});
    }

    pub fn term() void {
        std.debug.print("Term\n", .{});
        terminate = true;
    }

    // Split frame into protocol fields and data content and decode
    fn split_frame() !void {
        // Check for frame type
        if (udp_frame[3] == defs.EP6) {
            // We have a frame of IQ data
            // First 8 bytes are the header, then 2x512 bytes of data
            // The sync and cc bytes are the start of each data frame
            //
            // Extract and check the sequence number
            //  2    1   1   4
            // Sync Cmd End Seq
            // if the sequence number check fails it means we have missed some frames
            // Nothing we can do so it just gets reported.

            // Move sequence data into temp array
            var j: u32 = 0;
            var i: u32 = 4;
            var ep6_seq = [4]u8{ 0, 0, 0, 0 };
            while (i <= 7) {
                ep6_seq[j] = (udp_frame[i]);
                j += 1;
                i += 1;
            }
            if (seq.SeqIn.check_ep6_seq(ep6_seq)) {
                //Boolean return incase we need to do anything
                // Sequence errors are reported in cc-in
            }
        } else if (udp_frame[3] == defs.EP4) {
            // We have wideband data
            // TBD
            return;
        }

        // Decode into contiguous IQ and Mic frames
        const num_smpls = decode_frame();

        //================================================================================
        // At this point we have separated the IQ and Mic data into separate buffers
        // Truncate if necessary for RX samples for current number of receivers
        var slice = undefined;
        if (num_rx > 1) {
            // Need to resize array to actual number of samples
            slice = iq[0 .. num_smpls * defs.BYTES_PER_SAMPLE];
        }
        // Copy the IQ data into the ring buffer
        try rb.writeSlice(&slice);

        // Signal the pipeline that data is available
        mutex.lock();
        defer mutex.unlock();
        cond.signal();
    }

    // Split inti IQ and Mic frames
    fn decode_frame() !u32 {
        // Extract the data from the UDP frame into the IQ and Mic frames
        // Select the correct RX data at this point
        // One RX   - I2(1)I1(1)10(1)Q2(1)Q1(1)Q0(1)MM etc
        // Two RX   - I2(1)I1(1)I0(1)Q2(1)Q1(1)Q0(1)I2(2)I1(2)I0(2)Q2(2)Q1(2)Q0(2)MM etc
        // Three RX - I2(1)I1(1)I0(1)Q2(1)Q1(1)Q0(1)I2(2)I1(2)I0(2)Q2(2)Q1(2)Q0(2)I2(3)I1(3)I0(3)Q2(3)Q1(3)Q0(3)MM etc
        //
        // So for one RX we take all the IQ data always.
        // This is 63 samples of I/Q and 63 samples of Mic as 504/8 = 63.
        //
        // For 2 RX we take either just the RX1 or RX2 data depending on the selected receiver.
        // This is 36 samples of RX1, RX2 and Mic as 504/14 = 36
        //
        // For 3 RX we take RX1, RX2 or RX3 data depending on the selected receiver.
        // This is 25 samples of RX1, RX2, RX3 and Mic but 504/25 is 20 rm 4 so there are 4 nulls at the end.
        //
        // For 48KHz sample rate we take all Mic samples
        // For 96KHz sample rate we take every second sample
        // For 192KHz sample rate we take every fourth sample

        // Index into IQ output data
        var idx_iq = undefined;
        _ = idx_iq;
        // Index into Mic output data
        var idx_mic = undefined;
        _ = idx_mic;
        // Number of samples of IQ and Mic for receiver(s) in one UDP frame
        var smpls = undefined;
        if (num_rx == 1) {
            smpls = defs.NUM_SMPLS_1_RADIO / 2;
            proc_one_rx(smpls);
        } else if (num_rx == 2) {
            smpls = defs.NUM_SMPLS_2_RADIO / 2;
            proc_two_rx(smpls);
        } else {
            smpls = defs.NUM_SMPLS_3_RADIO / 2;
            proc_three_rx(smpls);
        }
    }

    // Decode for one receiver
    fn proc_one_rx(smpls: u32) void {
        // Take all I/Q and Mic data for one receiver
        var idx_iq = 0;
        var idx_mic = 0;
        var frame = 1;
        var smpl = 0;
        while (frame <= 2) {
            var state = IQ;
            var index = defs.START_FRAME_1;
            if (frame == 2) {
                index = defs.START_FRAME_2;
            }
            while (smpl < smpls * 2) {
                if (state == IQ) {
                    // Take IQ bytes
                    while (index < index + defs.BYTES_PER_SAMPLE) {
                        iq[idx_iq] = udp_frame[index];
                        idx_iq += 1;
                        index += 1;
                    }
                    state = M;
                } else if (state == M) {
                    // Take Mic bytes
                    while (index < index + defs.MIC_BYTES_PER_SAMPLE) {
                        mic[idx_mic] = udp_frame[index];
                        idx_mic += 1;
                        index += 1;
                    }
                    state = IQ;
                }
                smpl += 1;
            }
            frame = 2;
        }
        return smpls * 2;
    }

    // Decode for two receivers
    fn proc_two_rx(smpls: u32) void {
        // Skip either RX 1 or RX 2 data
        var idx_iq = 0;
        var idx_mic = 0;
        var frame = 1;
        var smpl = 0;
        var byte = 0;
        _ = byte;
        while (frame <= 2) {
            // Main state depends on selected RX
            var state = IQ;
            if (sel_rx == 2) {
                state = SIQ1;
            }
            // Sub-state depend on sample rate as we may skip mic samples
            var sub_state = undefined;
            if (smpl_rate == defs.SMPLS_48K) {
                sub_state = M;
            } else {
                sub_state = SM1;
            }
            // Set start point depending on frame
            var index = defs.START_FRAME_1;
            if (frame == 2) {
                index = defs.START_FRAME_2;
            }
            while (smpl < smpls * 3) {
                if (state == IQ) {
                    // Take IQ bytes
                    while (index < index + defs.BYTES_PER_SAMPLE) {
                        iq[idx_iq] = udp_frame[index];
                        idx_iq += 1;
                        index += 1;
                    }
                    // Next state and sub-state
                    if (sel_rx == 1) {
                        state = SIQ1;
                    } else {
                        state = M;
                    }
                    if (smpl_rate == defs.SMPLS_48K) {
                        sub_state = M;
                    } else {
                        sub_state = SM1;
                    }
                } else if (state == SIQ1) {
                    // Skip IQ bytes, not selected RX
                    index += defs.BYTES_PER_SAMPLE;
                    // Set next state
                    if (sel_rx == 1) {
                        state = M;
                    } else {
                        state = IQ;
                    }
                    if (smpl_rate == defs.SMPLS_48K) {
                        sub_state = M;
                    } else {
                        sub_state = SM1;
                    }
                } else if (state == M) {
                    // Skip 1,2 or 3 samples if > 48KHz
                    if (sub_state == SM1) {
                        index += defs.MIC_BYTES_PER_SAMPLE;
                        if (smpl_rate == defs.SMPLS_192K) {
                            sub_state = SM2;
                        } else {
                            sub_state = M;
                        }
                    } else if (sub_state == SM2) {
                        index += defs.MIC_BYTES_PER_SAMPLE;
                        if (smpl_rate == defs.SMPLS_192K) {
                            sub_state = SM3;
                        } else {
                            sub_state = M;
                        }
                    } else if (sub_state == SM3) {
                        index += defs.MIC_BYTES_PER_SAMPLE;
                        sub_state = M;
                    } else {
                        // Take Mic bytes
                        while (index < index + defs.MIC_BYTES_PER_SAMPLE) {
                            mic[idx_mic] = udp_frame[index];
                            idx_mic += 1;
                            index += 1;
                        }
                    }
                    // Set next state
                    if (sel_rx == 1) {
                        state = IQ;
                    } else {
                        state = SIQ1;
                    }
                }
                smpl += 1;
            }
            frame = 2;
        }
        return smpls * 2;
    }

    // Decode for three receivers
    fn proc_three_rx(smpls: u32) void {
        // Skip either RX 1 RX 2 or RX 3 data
        var idx_iq = 0;
        var idx_mic = 0;
        var frame = 1;
        var smpl = 0;
        while (frame <= 2) {
            // Main state depends on selected RX
            var state = IQ;
            if (sel_rx == 2 or sel_rx == 3) {
                state = SIQ1;
            }
            // Sub-state depend on sample rate as we may skip mic samples
            var sub_state = undefined;
            if (smpl_rate == defs.SMPLS_48K) {
                sub_state = M;
            } else {
                sub_state = SM1;
            }
            // Set start point depending on frame
            var index = defs.START_FRAME_1;
            if (frame == 2) {
                index = defs.START_FRAME_2;
            }
            while (smpl < smpls * 4) {
                if (state == IQ) {
                    // Take IQ bytes
                    while (index < index + defs.BYTES_PER_SAMPLE) {
                        iq[idx_iq] = udp_frame[index];
                        idx_iq += 1;
                        index += 1;
                    }
                    // Next state and sub-state
                    if (sel_rx == 1) {
                        state = SIQ1;
                    } else if (sel_rx == 2) {
                        state = SIQ2;
                    } else {
                        state = M;
                    }
                    if (smpl_rate == defs.SMPLS_48K) {
                        sub_state = M;
                    } else {
                        sub_state = SM1;
                    }
                } else if (state == SIQ1) {
                    // Skip IQ bytes, not selected RX
                    index += defs.BYTES_PER_SAMPLE;
                    // Set next state
                    if (sel_rx == 1) {
                        state = SIQ2;
                    } else if (sel_rx == 2) {
                        state = IQ;
                    } else {
                        state = SIQ2;
                    }
                    if (smpl_rate == defs.SMPLS_48K) {
                        sub_state = M;
                    } else {
                        sub_state = SM1;
                    }
                } else if (state == M) {
                    // Skip 1,2 or 3 samples if > 48KHz
                    if (sub_state == SM1) {
                        index += defs.MIC_BYTES_PER_SAMPLE;
                        if (smpl_rate == defs.SMPLS_192K) {
                            sub_state = SM2;
                        } else {
                            sub_state = M;
                        }
                    } else if (sub_state == SM2) {
                        index += defs.MIC_BYTES_PER_SAMPLE;
                        if (smpl_rate == defs.SMPLS_192K) {
                            sub_state = SM3;
                        } else {
                            sub_state = M;
                        }
                    } else if (sub_state == SM3) {
                        index += defs.MIC_BYTES_PER_SAMPLE;
                        sub_state = M;
                    } else {
                        // Take Mic bytes
                        while (index < index + defs.MIC_BYTES_PER_SAMPLE) {
                            mic[idx_mic] = udp_frame[index];
                            idx_mic += 1;
                            index += 1;
                        }
                    }
                    // Set next state
                    if (sel_rx == 1) {
                        state = IQ;
                    } else {
                        state = SIQ1;
                    }
                }
                smpl += 1;
            }
            frame = 2;
        }
        return smpls * 2;
    }
};

// Start reader loop
fn reader_thrd(sock: *net.Socket, hwAddr: net.EndPoint, rb: *std.RingBuffer, iq_mutex: std.Thread.Mutex, iq_cond: std.Thread.Condition) !void {
    std.debug.print("Reader thread\n", .{});
    try Reader.loop(sock, hwAddr, rb, iq_mutex, iq_cond);
}

//==================================================================================
// Thread startup
pub fn reader_start(sock: *net.Socket, hwAddr: net.EndPoint, rb: *std.RingBuffer, iq_mutex: std.Thread.Mutex, iq_cond: std.Thread.Condition) std.Thread.SpawnError!std.Thread {
    return try std.Thread.spawn(.{}, reader_thrd, .{ sock, hwAddr, rb, iq_mutex, iq_cond });
}
