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
    var blisten = false;
    var terminate = false;
    var udp_frame = std.mem.zeroes([1032]u8);
    var rb: *std.RingBuffer = undefined;

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
                    std.debug.print("Reader loop got short frame! Ignoring {any}\n", .{ resp.numberOfBytes });
                }
                std.debug.print("Reader loop got {any}, {any}\n", .{ resp.numberOfBytes, resp.sender });
                n += 1;
            }
            std.time.sleep(100000000);
        }
        std.debug.print("Reader loop exiting\n", .{});
    }

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
        
        const num_rx = globals.Globals.num_rx;
        const sel_rx = globals.Globals.sel_rx;
        
        // Check for frame type
        if (udp_frame[3] == defs.EP6){
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
            var ep6_seq = [4]u8{0,0,0,0};
            while (i <= 7) {
                ep6_seq[j] = (self.udp_frame[i]);
                j += 1; i += 1;
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
        let num_smpls = protocol::decoder::frame_decode(
            num_rx, sel_rx, globals::get_smpl_rate(), 
            &self.udp_frame, &mut self.iq, &mut self.mic);

        //================================================================================
        // At this point we have separated the IQ and Mic data into separate buffers
        // Truncate vec if necessary for RX samples for current number of receivers
        let mut success = false;
        let mut vec_iq = self.iq.to_vec();
        if num_rx > 1 {
            vec_iq.resize((num_smpls*common_defs::BYTES_PER_SAMPLE) as usize, 0);
        }
        // Copy the UDP frame into the rb_iq ring buffer
        let r = self.rb_iq.write().write(&vec_iq);
        match r {
            Err(e) => {
                println!("Write error on rb_iq, skipping block {:?}", e);
            }
            Ok(_sz) => {
                success = true;  
            }
        }
        // Signal the pipeline that data is available
        if success {
            let mut locked = self.iq_cond.0.lock().unwrap();
            *locked = true;
            self.iq_cond.1.notify_one();
        } 
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
