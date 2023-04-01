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
    const num_rx = globals.Globals.num_rx;
    const sel_rx = globals.Globals.sel_rx;

    var blisten = false;
    var terminate = false;
    var udp_frame = std.mem.zeroes([defs.FRAME_SZ]u8);
    var iq = std.mem.zeroes([defs.IQ_ARR_SZ_R1]u8);
    var mic = std.mem.zeroes([defs.MIC_ARR_SZ_R1]u8);
    var rb: *std.RingBuffer = undefined;

    // Thread loop until terminate
    fn loop(sock: *net.Socket, hwAddr: net.EndPoint, rb_reader: *std.RingBuffer) !void {
        _ = hwAddr;
        rb = rb_reader;
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
        _ = num_smpls;

        //================================================================================
        // At this point we have separated the IQ and Mic data into separate buffers
        // Truncate if necessary for RX samples for current number of receivers
        if (num_rx > 1) {
            //vec_iq.resize((num_smpls*common_defs::BYTES_PER_SAMPLE) as usize, 0);
            // Need to resize array
        }
        // Copy the UDP frame into the rb_iq ring buffer
        try rb.writeSlice(&iq);

        // Signal the pipeline that data is available
        //let mut locked = self.iq_cond.0.lock().unwrap();
        //*locked = true;
        //self.iq_cond.1.notify_one();
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

        // Tiny state machine states for IQ, Mic. Skip
        const IQ: i32 = 0;
        _ = IQ;
        const M: i32 = 1;
        _ = M;
        const SIQ1: i32 = 2;
        _ = SIQ1;
        const SIQ2: i32 = 3;
        _ = SIQ2;
        const SM1: i32 = 4;
        _ = SM1;
        const SM2: i32 = 5;
        _ = SM2;
        const SM3: i32 = 6;
        _ = SM3;

        // Index into IQ output data
        var idx_iq = undefined;
        _ = idx_iq;
        // Index into Mic output data
        var idx_mic = undefined;
        _ = idx_mic;
        // Number of samples of IQ and Mic for receiver(s) in one UDP frame
        var smpls = undefined;
        if (num_rx == 1) 
            {smpls = defs.NUM_SMPLS_1_RADIO / 2;}
            proc_one_rx(smpls); 
        else if (num_rx == 2) 
            {smpls = defs.NUM_SMPLS_2_RADIO / 2;}
            proc_two_rx(smpls); 
        else
            {smpls = defs.NUM_SMPLS_3_RADIO / 2;}
            proc_three_rx(smpls); 
        
    }

    // Decode for one receiver
    fn proc_one_rx(smpls: u32) void {
        // Take all I/Q and Mic data for one receiver
		var idx_iq = 0;
		var idx_mic = 0;
        var frame = 1;
        var smpl = 0;
        var byte = 0;
		while (frame <= 2) {
			var state = IQ;
			var index = defs.START_FRAME_1;
			if (frame == 2) {index = defs.START_FRAME_2;}
			while (smpl < smpls*2) {
				if (state == IQ) {
					// Take IQ bytes
                    while (index < index+defs.BYTES_PER_SAMPLE) {
						iq[idx_iq] = udp_frame[index];
						idx_iq += 1;
                        index += 1;
					}
					state = M;
				} else if (state == M) {
					// Take Mic bytes
                    while (index < index+defs.MIC_BYTES_PER_SAMPLE) {
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
        return smpls*2;
    }

    fn take_iq_bytes() void {

    }
};

fn reader_thrd(sock: *net.Socket, hwAddr: net.EndPoint, rb: *std.RingBuffer) !void {
    std.debug.print("Reader thread\n", .{});
    try Reader.loop(sock, hwAddr, rb);
}

//==================================================================================
// Thread startup
pub fn reader_start(sock: *net.Socket, hwAddr: net.EndPoint, rb: *std.RingBuffer) std.Thread.SpawnError!std.Thread {
    return try std.Thread.spawn(.{}, reader_thrd, .{ sock, hwAddr, rb });
}
