// cc_out.zig
// 
// Module - cc_out
// Module cc_out manages encoding the protocol command and control bytes to the hardware
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

const cc_out_def = struct {
    usingnamespace @import("../common/cc_out_defs.zig");
};

//========================================================================
// Container Constants
//
// Round robin sequence for sending CC bytes
// Note 0-6 for CCOBufferIdx 
const RR_CC:  u32 = 7;

//========================================================================
// Enumerations for bit fields in the CC structure
// CC buffer index
const CCOBufferIdx = enum {
	BGen,
	BRx1TxF,
	BRx1F,
	BRx2F,
	BRx3F,
	BMisc1,
	BMisc2
};

// CC byte index
const CCOByteIdx = enum {
	CC0,
	CC1,
	CC2,
	CC3,
	CC4
};

//========================================================================
// For each field in C2 - C4 we define the bits to set for the number of values for that setting.
// See the enum definitions in common/cc_out_defs for the index list of each field.
// Example: speed has 4 possible values so there are 4 byte values for the indexes 0-3. These are
// relative to the actual field starting bit and not bit 0. The second value is the mask that
// defines where those bits are placed in the byte. It does not define which byte C2 - C4 as that
// is defined by the calling function that sets the bits.

// Speed
const CCO_SPEED_B = [4]u8{ 0x00, 0x01, 0x02, 0x03 };
const CCO_SPEED_M: u8 = 0xfc;
// 10MHz ref
const CCO_10MHZ_REF_B = [3]u8{ 0x00,0x04,0x08 };
const CCO_10MHZ_REF_M: u8 = 0x3;
// 122MHs ref
const CCO_122MHZ_REF_B = [2]u8{ 0x00,0x10 };
const CCO_122MHZ_REF_M: u8 = 0xef;
// Board config
const CCO_BOARD_CONFIG_B = [4]u8{ 0x00,0x20,0x40,0x60 };
const CCO_BOARD_CONFIG_M: u8 = 0x9f;
// Mic src
const CCO_MIC_SRC_B = [2]u8{ 0x00,0x80 };
const CCO_MIC_SRC_M: u8 = 0x7f;
// Alex attenuator
const CCO_ALEX_ATTN_B = [4]u8{ 0x00,0x01,0x02,0x03 };
const CCO_ALEX_ATTN_M: u8 = 0xfc;
// Preamp
const CCO_PREAMP_B = [2]u8{ 0x00,0x04 };
const CCO_PREAMP_M: u8 = 0xfb;
// Alex RX ant
const CCO_RX_ANT_B = [4]u8{ 0x00,0x20,0x40,0x60 };
const CCO_RX_ANT_M: u8 = 0x9f;
// Alex RX out
const CCO_ALEX_RX_OUT_B = [2]u8{ 0x00,0x80 };
const CCO_ALEX_RX_OUT_M: u8 = 0x7f;
// Alex TX relay
const CCO_ALEX_TX_RLY_B = [3]u8{ 0x00,0x01,0x02 };
const CCO_ALEX_TX_RLY_M: u8 = 0xfc;
// Duplex
const CCO_DUPLEX_B = [2]u8{ 0x00,0x04 };
const CCO_DUPLEX_M: u8 = 0xfb;
// No.RX
const CCO_NUM_RX_B = [3]u8{ 0x00,0x08,0x10 };
const CCO_NUM_RX_M: u8 = 0xc7;
// Alex auto
const CCO_ALEX_AUTO_B = [u2]u8{ 0x00,0x40 };
const CCO_ALEX_AUTO_M: u8 = 0xbf;
// Alex HPF bypass
const CCO_ALEX_HPF_BYPASS_B = [2]u8{ 0x00,0x20 };
const CCO_ALEX_HPF_BYPASS_M: u8 = 0xdf;
// LPF Filter selects
const CCO_ALEX_LPF_30_20_B = [u2]u8{ 0x00,0x01 };
const CCO_ALEX_LPF_30_20_M: u8 = 0xfe;
const CCO_ALEX_LPF_60_40_B = [2]u8{ 0x00,0x02 };
const CCO_ALEX_LPF_60_40_M: u8 = 0xfd;
const CCO_ALEX_LPF_80_B = [2]u8{ 0x00,0x04 };
const CCO_ALEX_LPF_80_M: u8 = 0xfb;
const CCO_ALEX_LPF_160_B = [2]u8{ 0x00,0x08 };
const CCO_ALEX_LPF_160_M: u8 = 0xf7;
const CCO_ALEX_LPF_6_B = [2]u8{ 0x00,0x10 };
const CCO_ALEX_LPF_6_M: u8 = 0xef;
const CCO_ALEX_LPF_12_10_B = [u2]u8{ 0x00,0x20 };
const CCO_ALEX_LPF_12_10_M: u8 = 0xdf;
const CCO_ALEX_LPF_17_15_B = [u2]u8{ 0x00,0x40 };
const CCO_ALEX_LPF_17_15_M: u8 = 0xbf;
// HPF Filter selects
const CCO_ALEX_HPF_13_B = [2]u8{ 0x00,0x01 };
const CCO_ALEX_HPF_13_M: u8 = 0xfe;
const CCO_ALEX_HPF_20_B = [2]u8{ 0x00,0x02 };
const CCO_ALEX_HPF_20_M: u8 = 0xfd;
const CCO_ALEX_HPF_9_5_B = [u2]u8{ 0x00,0x04 };
const CCO_ALEX_HPF_9_5_M: u8 = 0xfb;
const CCO_ALEX_HPF_6_5_B = [2]u8{ 0x00,0x08 };
const CCO_ALEX_HPF_6_5_M: u8 = 0xf7;
const CCO_ALEX_HPF_1_5_B = [2]u8{ 0x00,0x10 };
const CCO_ALEX_HPF_1_5_M: u8 = 0xef;

//========================================================================
// Container variables

// Current index into array
var cc_idx: u32 = 0;
// Default MOX state
var cc_mox_state: bool = false;
// Default array contains the C0 values that define how C1-C4 are defined
var cc_array = [5][8]u8 {
	[_]u8{0x00, 0x00, 0x00, 0x00, 0x00},
	[_]u8{0x02, 0x00, 0x00, 0x00, 0x00},
	[_]u8{0x04, 0x00, 0x00, 0x00, 0x00},
	[_]u8{0x06, 0x00, 0x00, 0x00, 0x00},
	[_]u8{0x08, 0x00, 0x00, 0x00, 0x00},
	[_]u8{0x0a, 0x00, 0x00, 0x00, 0x00},
	[_]u8{0x0c, 0x00, 0x00, 0x00, 0x00},
	[_]u8{0x0e, 0x00, 0x00, 0x00, 0x00}
};
// Single row of the array is returned as next in sequence
var cc_el = [5]u8{0x00, 0x00, 0x00, 0x00, 0x00};

// ==========================================================================
// Public interface

// Return the next CC data in sequence
pub fn cc_out_next_seq() [5]u8 {
	cc_el = cc_array[cc_idx];
	
	// Check for MOX
	if (cc_idx == 0) {
		if (cc_mox_state) {
			// Need to set the MOX bit
			cc_array[0][0]= cc_array[0][0] | 0x01;
		}
		else {
			// Need to reset the MOX bit
			cc_array[0][0] = cc_array[0][0] & 0xfe;
		}
	}

	// Bump the index
	cc_idx = cc_idx + 1;
	if (cc_idx > RR_CC) {
		cc_idx = 0;
	}

	// Return a copy of the current index array
	return cc_el.clone();
}

// ==========================================================================
// Private interface

//==============================================================
// Functions to manipulate fields in the cc_array

// Get the given byte at the given index in cc_array
fn cc_get_byte(array_idx: u32, byte_idx: u32) u8 {
	return cc_array[array_idx][byte_idx];
}

// Overwrite the given byte at the given index in cc_array 
fn cc_put_byte(array_idx: u32, byte_idx: u32, b: u8) noreturn {
	cc_array[array_idx][byte_idx] = b;
}

// Given a target bit setting and the current bit field and mask return the modified field
fn cc_set_bits(bit_setting: u8, bit_field: u8, bit_mask: u8) u8 {
	return (bit_field & bit_mask) | bit_setting;
}

// Given the array and byte index get the corrent byte value 'b'.
// Get the new byte with the field updated.
// Update the given field in cc_array
fn cc_update(array_idx: usize, byte_idx: usize, bit_setting: u8, bit_mask: u8) noreturn {
	var b: u8 = self.cc_get_byte(array_idx, byte_idx);
	var new_b: u8 = cc_set_bits(bit_setting, b, bit_mask);
	cc_put_byte(array_idx, byte_idx, new_b);
}

//==============================================================
// Setting functions for every bit field in cc_array

// Set/clear the MOX bit
pub fn cc_mox(&mut self, mox: bool) {
	if mox {
		self.cc_mox_state = true;
	} else {
		self.cc_mox_state = false;
	}
}

//========================================
// Configuration settings

// Set the bandwidth
pub fn cc_speed(&mut self, speed: CCOSpeed) {
	let setting = CCO_SPEED_B[speed as usize];
	self.cc_update(CCOBufferIdx::BGen as usize, CCOByteIdx::CC1 as usize, setting, CCO_SPEED_M);
}

// Set the 10MHz ref source
pub fn cc_10_ref(&mut self, reference: CCO10MhzRef) {
	let setting = CCO_10MHZ_REF_B[reference as usize];
	self.cc_update(CCOBufferIdx::BGen as usize, CCOByteIdx::CC1 as usize, setting, CCO_10MHZ_REF_M);
}

// Set the 122.88MHz ref source
pub fn cc_122_ref(&mut self, reference: CCO122MhzRef) {
	let setting = CCO_122MHZ_REF_B[reference as usize];
	self.cc_update(CCOBufferIdx::BGen as usize, CCOByteIdx::CC1 as usize, setting, CCO_122MHZ_REF_M);
}

// Set the board config
pub fn cc_board_config(&mut self, config: CCOBoardConfig) {
	let setting = CCO_BOARD_CONFIG_B[config as usize];
	self.cc_update(CCOBufferIdx::BGen as usize, CCOByteIdx::CC1 as usize, setting, CCO_BOARD_CONFIG_M);
}

// Set the mic src
pub fn cc_mic_src(&mut self, src: CCOMicSrc) {
	let setting = CCO_MIC_SRC_B[src as usize];
	self.cc_update(CCOBufferIdx::BGen as usize, CCOByteIdx::CC1 as usize, setting, CCO_MIC_SRC_M);
}

// Set the alex attenuator
pub fn cc_alex_attn(&mut self, attn: CCOAlexAttn) {
	let setting = CCO_ALEX_ATTN_B[attn as usize];
	self.cc_update(CCOBufferIdx::BGen as usize, CCOByteIdx::CC3 as usize, setting, CCO_ALEX_ATTN_M);
}

// Set the preamp
pub fn cc_preamp(&mut self, preamp: CCOPreamp) {
	let setting = CCO_PREAMP_B[preamp as usize];
	self.cc_update(CCOBufferIdx::BGen as usize, CCOByteIdx::CC3 as usize, setting, CCO_PREAMP_M);
}

// Set the alex rx antenna
pub fn cc_alex_rx_ant(&mut self, ant: CCORxAnt) {
	let setting = CCO_RX_ANT_B[ant as usize];
	self.cc_update(CCOBufferIdx::BGen as usize, CCOByteIdx::CC3 as usize, setting, CCO_RX_ANT_M);
}

// Set the alex rx output
pub fn cc_alex_rx_out(&mut self, out: CCOAlexRxOut) {
	let setting = CCO_ALEX_RX_OUT_B[out as usize];
	self.cc_update(CCOBufferIdx::BGen as usize, CCOByteIdx::CC3 as usize, setting, CCO_ALEX_RX_OUT_M);
}

// Set the alex tx relay
pub fn cc_alex_tx_rly(&mut self, rly: CCOAlexTxRly) {
	let setting = CCO_ALEX_TX_RLY_B[rly as usize];
	self.cc_update(CCOBufferIdx::BGen as usize, CCOByteIdx::CC4 as usize, setting, CCO_ALEX_TX_RLY_M);
}

// Set duplex
pub fn cc_duplex(&mut self, duplex: CCODuplex) {
	let setting = CCO_DUPLEX_B[duplex as usize];
	self.cc_update(CCOBufferIdx::BGen as usize, CCOByteIdx::CC4 as usize, setting, CCO_DUPLEX_M);
}

// Set num rx
pub fn cc_num_rx(&mut self, num: CCONumRx) {
	let setting = CCO_NUM_RX_B[num as usize];
	self.cc_update(CCOBufferIdx::BGen as usize, CCOByteIdx::CC4 as usize, setting, CCO_NUM_RX_M);
}

//========================================
// Alex filters

// Set the alex auto mode
pub fn cc_alex_auto(&mut self, alex_auto: CCOAlexAuto) {
	let setting = CCO_ALEX_AUTO_B[alex_auto as usize];
	self.cc_update(CCOBufferIdx::BMisc1 as usize, CCOByteIdx::CC2 as usize, setting, CCO_ALEX_AUTO_M);
}

// Bypass alex HPF
pub fn cc_alex_hpf_bypass(&mut self, bypass: CCOAlexBypass) {
	let setting = CCO_ALEX_HPF_BYPASS_B[bypass as usize];
	self.cc_update(CCOBufferIdx::BMisc1 as usize, CCOByteIdx::CC2 as usize, setting, CCO_ALEX_HPF_BYPASS_M);
}

// LPF FIlter select
// 30/20
pub fn cc_lpf_30_20(&mut self, setting: CCOAlexHpfLpf) {
	let setting = CCO_ALEX_LPF_30_20_B[setting as usize];
	self.cc_update(CCOBufferIdx::BMisc1 as usize, CCOByteIdx::CC4 as usize, setting, CCO_ALEX_LPF_30_20_M);
}
// 60/40
pub fn cc_lpf_60_40(&mut self, setting: CCOAlexHpfLpf) {
	let setting = CCO_ALEX_LPF_60_40_B[setting as usize];
	self.cc_update(CCOBufferIdx::BMisc1 as usize, CCOByteIdx::CC4 as usize, setting, CCO_ALEX_LPF_60_40_M);
}
// 80
pub fn cc_lpf_80(&mut self, setting: CCOAlexHpfLpf) {
	let setting = CCO_ALEX_LPF_80_B[setting as usize];
	self.cc_update(CCOBufferIdx::BMisc1 as usize, CCOByteIdx::CC4 as usize, setting, CCO_ALEX_LPF_80_M);
}
// 160
pub fn cc_lpf_160(&mut self, setting: CCOAlexHpfLpf) {
	let setting = CCO_ALEX_LPF_160_B[setting as usize];
	self.cc_update(CCOBufferIdx::BMisc1 as usize, CCOByteIdx::CC4 as usize, setting, CCO_ALEX_LPF_160_M);
}
// 6
pub fn cc_lpf_6(&mut self, setting: CCOAlexHpfLpf) {
	let setting = CCO_ALEX_LPF_6_B[setting as usize];
	self.cc_update(CCOBufferIdx::BMisc1 as usize, CCOByteIdx::CC4 as usize, setting, CCO_ALEX_LPF_6_M);
}
// 12/10
pub fn cc_lpf_12_10(&mut self, setting: CCOAlexHpfLpf) {
	let setting = CCO_ALEX_LPF_12_10_B[setting as usize];
	self.cc_update(CCOBufferIdx::BMisc1 as usize, CCOByteIdx::CC4 as usize, setting, CCO_ALEX_LPF_12_10_M);
}
// 17/15
pub fn cc_lpf_17_15(&mut self, setting: CCOAlexHpfLpf) {
	let setting = CCO_ALEX_LPF_17_15_B[setting as usize];
	self.cc_update(CCOBufferIdx::BMisc1 as usize, CCOByteIdx::CC4 as usize, setting, CCO_ALEX_LPF_17_15_M);
}

// HPF filter select
// 13
pub fn cc_hpf_13(&mut self, setting: CCOAlexHpfLpf) {
	let setting = CCO_ALEX_HPF_13_B[setting as usize];
	self.cc_update(CCOBufferIdx::BMisc1 as usize, CCOByteIdx::CC3 as usize, setting, CCO_ALEX_HPF_13_M);
}
// 20
pub fn cc_hpf_20(&mut self, setting: CCOAlexHpfLpf) {
	let setting = CCO_ALEX_HPF_20_B[setting as usize];
	self.cc_update(CCOBufferIdx::BMisc1 as usize, CCOByteIdx::CC3 as usize, setting, CCO_ALEX_HPF_20_M);
}
// 9.5
pub fn cc_hpf_9_5(&mut self, setting: CCOAlexHpfLpf) {
	let setting = CCO_ALEX_HPF_9_5_B[setting as usize];
	self.cc_update(CCOBufferIdx::BMisc1 as usize, CCOByteIdx::CC3 as usize, setting, CCO_ALEX_HPF_9_5_M);
}
// 6.5
pub fn cc_hpf_6_5(&mut self, setting: CCOAlexHpfLpf) {
	let setting = CCO_ALEX_HPF_6_5_B[setting as usize];
	self.cc_update(CCOBufferIdx::BMisc1 as usize, CCOByteIdx::CC3 as usize, setting, CCO_ALEX_HPF_6_5_M);
}
// 1.5
pub fn cc_hpf_1_5(&mut self, setting: CCOAlexHpfLpf) {
	let setting = CCO_ALEX_HPF_1_5_B[setting as usize];
	self.cc_update(CCOBufferIdx::BMisc1 as usize, CCOByteIdx::CC3 as usize, setting, CCO_ALEX_HPF_1_5_M);
}

//========================================
// Frequency setting

// Slightly different from the single fields as frequency is a 4 byte field
// The common setting function
fn cc_common_set_freq(&mut self, buffer_idx: CCOBufferIdx, freq_in_hz: u32) {
	let idx = buffer_idx as usize;
	self.cc_array[idx][1] = ((freq_in_hz >> 24) & 0xff) as u8;
	self.cc_array[idx][2] = ((freq_in_hz >> 16) & 0xff) as u8;
	self.cc_array[idx][3] = ((freq_in_hz >> 8) & 0xff) as u8;
	self.cc_array[idx][4] = (freq_in_hz & 0xff) as u8;
}

//There are several frequencies for RX 1/TX and RX 2,3,4
// RX 1/TX freq
pub fn cc_set_rx_tx_freq(&mut self, freq_in_hz: u32) {
	self.cc_common_set_freq(CCOBufferIdx::BRx1TxF, freq_in_hz);
	self.cc_common_set_freq(CCOBufferIdx::BRx1F, freq_in_hz);
}
// RX 2 freq
pub fn cc_set_rx2_freq(&mut self, freq_in_hz: u32) {
	self.cc_common_set_freq(CCOBufferIdx::BRx2F, freq_in_hz);
}
// RX 3 freq
pub fn cc_set_rx3_freq(&mut self, freq_in_hz: u32) {
	self.cc_common_set_freq(CCOBufferIdx::BRx3F, freq_in_hz);
}
// TX freq
pub fn cc_set_tx_freq(&mut self, freq_in_hz: u32) {
	self.cc_common_set_freq(CCOBufferIdx::BRx1TxF, freq_in_hz);
}

//========================================
// Set sensible initialisation values
pub fn cc_init(&mut self) {
	self.cc_mox(false);
	self.cc_speed(CCOSpeed::S48kHz);
	self.cc_10_ref(CCO10MhzRef::R10MHzMerc);
	self.cc_122_ref(CCO122MhzRef::R122MHzMerc);
	self.cc_board_config(CCOBoardConfig::BoardBoth);
	self.cc_mic_src(CCOMicSrc::MicPen);
	self.cc_alex_attn(CCOAlexAttn::Attn0db);
	self.cc_preamp(CCOPreamp::PreAmpOff);
	self.cc_alex_rx_ant(CCORxAnt::RxAntNone);
	self.cc_alex_rx_out(CCOAlexRxOut::RxOutOff );
	self.cc_alex_tx_rly(CCOAlexTxRly::TxRlyTx1);
	self.cc_duplex(CCODuplex::DuplexOff);
	self.cc_num_rx(CCONumRx::NumRx1);
	self.cc_alex_auto(CCOAlexAuto::AlexAuto);
	self.cc_set_rx_tx_freq(7150000);
	self.cc_set_tx_freq(7150000);
}

