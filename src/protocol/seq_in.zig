// seq_in.rs
//
// Module - seq_in
// Manages the EP6 sequence number check
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

const std = @import("std");
const expect = std.testing.expect;

// Container local variables
// Maximum sequence number
const seq_max: u32 = std.math.maxInt(u32);
// EP6 sequence number to check
var ep6_seq_check: u32 = 0;
// True when seq initialised
var ep6_init: bool = false;

// ==========================================================================
// Public interface
pub fn check_ep6_seq(seq: [4]u8) !bool {
    var r: bool = false;
    var new_seq = big_to_little_endian(seq);
    if (!ep6_init) {
        ep6_seq_check = new_seq;
        ep6_init = true;
        r = true;
    } else if (new_seq == 0) { 
        ep6_seq_check = 0;
    } else if (ep6_seq_check + 1 != new_seq) {
        const stdout = std.io.getStdOut().writer();
        try stdout.print("EP6 sequence error - Ex:{d}, Got:{d}\n", .{ep6_seq_check, new_seq});
        ep6_seq_check = new_seq;
    } else {
        ep6_seq_check = next_seq(ep6_seq_check);
        r = true;
    }
    return r;
}

// ==========================================================================
// Private interface
fn next_seq(seq: u32) u32 {
    var new_seq = seq + 1;
    if (new_seq > seq_max) {
        new_seq = 0;
    }
    return new_seq;
}

fn big_to_little_endian(big_endian: [4]u8) u32 {
    var little_endian: u32 = undefined;
    little_endian = big_endian[0];
    little_endian = (little_endian << 8) | (big_endian[1]);
    little_endian = (little_endian << 8) | (big_endian[2]);
    little_endian = (little_endian << 8) | (big_endian[3]);
    return little_endian;
}

// ==========================================================================
// Module test
test "EP6 Sequence Check" {
    const stdout = std.io.getStdOut().writer();
    var r: bool = try check_ep6_seq([_]u8{0,0,0,0});
    try stdout.print("\nEP6 check result {}\n", .{r});
    try expect(r==true);

    r = try check_ep6_seq([_]u8{0,0,0,1});
    try stdout.print("\nEP6 check result {}\n", .{r});
    try expect(r==true);
}


