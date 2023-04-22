// converters.zig
//
// Module - converters
// Various converters from byte stream BE to f32/f64 LE and visa versa.
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
    usingnamespace @import("globals.zig");
};

const defs = struct {
    usingnamespace @import("common_defs.zig");
};

//
// These are targetted rather than generic conversions. Grouped here for convienience and consistency.
//

// Convert input buffer in i8 BE to output buffer f64 LE
// Input side of DSP
pub fn i8be_to_f64le(in_data: *[defs.DSP_BLK_SZ * 6]u8, out_data: *[defs.DSP_BLK_SZ * 2]f64) void {
    // The in_data is a i8 1024 complex samples where each each interleaved I and Q are 24 bits in BE format.
    // Thus the length of the input data is 1024*6 representing the 1024 complex samples.
    // The output data is 1024 complex samples in f64 LE format suitable for the DSP exchange function.

    // Scale factors
    var scale: f64 = 1.0 / (std.math.pow(f64, 2, 23));

    // Size to iterate over
    var sz: u32 = (defs.DSP_BLK_SZ * defs.BYTES_PER_SAMPLE) - defs.BYTES_PER_SAMPLE / 2;

    var in_index: u32 = 0;
    var out_index: u32 = 0;
    var as_int: i32 = 0;

    // Here we would iterate over each receiver and use a 2d array but for now one receiver.
    // Pack the 3 x i8 BE bytes (24 bit sample) into an int in LE format.
    // We must retain the sign hence we shift up to MSB and then down to propogate the sign.
    while (in_index <= sz) {

        // Big endian stores the most significant byte in the lowest address
        // Little endian stores the most significant byte in the highest address
        as_int =
            ((@as(i32, (in_data[(in_index + 2)])) << 8) |
            (@as(i32, (in_data[(in_index + 1)])) << 16) |
            (@as(i32, (in_data[(in_index)])) << 24)) >> 8;

        // Scale and write to target array
        //out_data[out_index] = @as(f64, as_int) * scale;
        out_data[out_index] = @intToFloat(f64, as_int) * scale;

        // BYTES_PER_SAMPLE is complex sample but we are moving I and then Q so /2
        in_index += defs.BYTES_PER_SAMPLE / 2;
        out_index += 1;
    }
}

// Convert input buffer in f64 LE to output buffer i8 BE
// Output side of DSP to hardware
pub fn f64le_to_i8be(sample_sz: u32, in_data: [defs.DSP_BLK_SZ * 2]f64, out_data: [defs.DSP_BLK_SZ * 8]u8) !void {
    // This conversion is the opposite of the i8be_to_f64le() and is the output side of the DSP.
    // The converted data is suitable for insertion into the ring buffer to the UDP writer.

    //var base: i32 = 2;
    //var scale: f64 = @as(f64, std.math.pow(2, 15));
    var scale: f64 = std.math.pow(f64, 2, 15);

    var dest: usize = 0;
    var src: usize = 0;
    var l: i16 = 0;
    var r: i16 = 0;
    var i: i16 = 0;
    var q: i16 = 0;

    // We get 1024 f64 audio interleaved left/right
    // We 'will' get f64 samples interleaved IQ output data when TX is implemented
    // This means we have 1024*sizeof f64(8)*left/right(2) bytes of data to iterate on the input
    // However the output is 16 bit packed so we have 1024*2*2 to iterate on the output
    // Both in and out are interleaved

    // We iterate on the output side starting at the LSB
    while (dest <= (sample_sz - 8)) {
        l = @as(i16, in_data[src] * scale);
        r = @as(i16, in_data[src + 1] * scale);
        i = 0;
        q = 0;
        out_data[dest] = @as(u8, (l >> 8) & 0xff);
        out_data[dest + 1] = @as(u8, l & 0xff);
        out_data[dest + 2] = @as(u8, (r >> 8) & 0xff);
        out_data[dest + 3] = @as(u8, r & 0xff);

        out_data[dest + 4] = @as(u8, i);
        out_data[dest + 5] = @as(u8, i);
        out_data[dest + 6] = @as(u8, q);
        out_data[dest + 7] = @as(u8, q);

        dest += 8;
        src += 2;
    }
}

// Convert input buffer in f64 LE to output buffer i8 LE as f32 values
// Output side of DSP to local audio
pub fn f64le_to_i8le(sample_sz: u32, in_data: [defs.DSP_BLK_SZ * 2]f64, out_data: [defs.DSP_BLK_SZ * 4]u8) !void {

    // The output data is structured as follows:
    // <L0><L1><L2><L3><R0><R1><R2><R3>...
    //
    // The input is f64 for L and R thus the input size is sizeof f64*2
    // The L and R samples are in f32 format LE. Thus the output sz is sizeof f32*2

    // Copy and encode the samples
    var dest: usize = 0;
    var src: usize = 0;
    var l: i16 = 0;
    var r: i16 = 0;
    //var base: i32 = 2;
    //var scale: f64 = @as(f64, std.math.pow(2, 15));
    var scale: f64 = std.math.pow(f64, 2, 15);

    // We iterate on the output side starting at the MSB
    while (dest <= sample_sz - 4) {
        l = @as(i16, in_data[src] * scale);
        r = @as(i16, in_data[src + 1] * scale);

        out_data[dest] = @as(u8, l & 0xff);
        out_data[dest + 1] = @as(u8, (l >> 8) & 0xff);
        out_data[dest + 2] = @as(u8, r & 0xff);
        out_data[dest + 3] = @as(u8, (r >> 8) & 0xff);

        dest += 4;
        src += 2;
    }
}

// Convert input buffer in i8 LE to output buffer f32 LE
// Audio ring buffer to local audio
//pub fn i8le_to_f32le(in_data: &Vec<u8>, out_data: &mut Vec<f32>, sz: u32) {
//   // The U8 data in the ring buffer is ordered as LE i16 2 byte values
//
//    //let base: i32 = 2;
//    //let scale: f32 = 1.0 /(std.math.pow(2, 23)) as f32;
//    let scale: f32 = 1.0 /(std.math.pow(f32, 2, 23);
//    let mut src: u32 = 0;
//    let mut dest: u32 = 0;
//    let mut as_int_left: i16;
//    let mut as_int_right: i16;
//    // NOTE Do not remove parenthesis, they are required
//    while src <= sz -4 {
//        as_int_left = (
//            in_data[src as usize] as i16 |
//            ((in_data[(src+1) as usize] as i16) << 8));
//        as_int_right = (
//            in_data[(src+2) as usize] as i16 |
//            ((in_data[(src+3) as usize] as i16) << 8));
//
//        // Scale and write to target array
//        out_data[dest as usize] = (as_int_left as f32) * scale;
//        out_data[(dest+1) as usize] = (as_int_right as f32 * scale);
//
//        src += 4;
//        dest += 2;
//    }
//}
