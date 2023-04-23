// wdsp.zig
//
// Module - wdsp
// Binding to the WDSP lib
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

const c = @cImport({
    @cInclude("E:/Projects/ZigSDR/trunk/src/sdr/wdsp_lib/api.h");
});

/// Initialize wdsp_lib. Call before other wdsp_lib functions.
pub fn init() !void {
    var path = ".";
    c.WDSPwisdom(path);
}

// Open WDSP channel
pub fn wdsp_open_ch(ch_type: i32, ch_id: i32, iq_sz: i32, mic_sz: i32, in_rate: i32, out_rate: i32, tdelayup: f64, tslewup: f64, tdelaydown: f64, tslewdown: f64) !void {
    // Open a new DSP channel
    //
    // Arguments:
    // 	ch_type 	-- CH_RX | CH_TX
    //	channel		-- Channel to use
    // 	iq_size		-- 128, 256, 1024, 2048, 4096
    // 	mic_size	-- as iq_size for same sample rate
    // 	in_rate		-- input sample rate
    // 	out_rate	-- output sample rate
    // 	tdelayup	-- delay before up slew
    // 	tslewup		-- length of up slew
    //  tdelaydown	-- delay before down slew
    // 	tslewdown	-- length of down slew
    //
    // Note:
    // 	There are additional parameters to open_channel. These are handled as follows:
    // 		o in_size - the number of samples supplied to the channel.
    // 		o input_samplerate - taken from the set_speed() API call, default 48K.
    // 		o dsp_rate - same as input_samplerate.
    // 		o output_samplerate - fixed at 48K for RX TBD TX
    //
    // The channel is not automatically started. Call set_ch_state() to start the channel.
    //

    var input_sz: i32 = undefined;
    var dsp_rate: i32 = undefined;

    if (ch_type == defs.CH_RX) {
        // For RX we keep the input and dsp size the same.
        input_sz = iq_sz;
    } else {
        // For TX we arrange that the same number of samples arrive at the output as for RX
        // This depends on the input and output rates
        input_sz = mic_sz;
    }
    // Set the internal rate to the input samplerate
    dsp_rate = in_rate;

    // Open the channel
    // There is no return value so will probably crash if there is a problem
    c.OpenChannel(ch_id, input_sz, input_sz, in_rate, dsp_rate, out_rate, ch_type, defs.STATE_STOPPED, tdelayup, tslewup, tdelaydown, tslewdown);
}

// Set channel state
pub fn wdsp_set_ch_state(ch_id: i32, state: i32, dmode: i32) !void {
    c.SetChannelState(ch_id, state, dmode);
}
