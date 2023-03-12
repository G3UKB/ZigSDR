// cc_out_defs.zig
// module cc_out_defs
// 
// Command and Control definitions for cc_out (to hardware)
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

// Speed
pub const CCOSpeed = enum {
	S48kHz,
	S96kHz,
	S192kHz,
	S384kHz,
};

// Alex attenuator
pub const CCOAlexAttn = enum {
	Attn0db,
	Attn10db,
	Attn20db,
	Attn30db
};

// Preamp
pub const CCOPreamp = enum {
	PreAmpOff,
	PreAmpOn
};

// Alex RX ant
pub const CCORxAnt = enum {
	RxAntNone,
	RxAnt1,
	RxAnt2,
	RxAntXV
};

// Duplex
pub const CCODuplex = enum {
	DuplexOff,
	DuplexOn
};

// No.RX
pub const CCONumRx = enum {
	NumRx1,
	NumRx2,
	NumRx3
};

// Alex auto
pub const CCOAlexAuto = enum {
	AlexAuto,
	AlexManual
};

// Alex HPF bypass
pub const CCOAlexBypass = enum {
	AlexHpfDisable,
	AlexHpfEnable
};

// Alex LPF/HPF select
pub const CCOAlexHpfLpf = enum {
	AlexFiltDisable,
	AlexFiltEnable
};

// 10MHz ref
pub const CCO10MhzRef = enum {
	R10MHzAtlas,
	R10MHzPen,
	R10MHzMerc
};

// 122MHz ref
pub const CCO122MhzRef = enum {
	R122MHzPen,
	R122MHzMerc
};

// Board config
pub const CCOBoardConfig = enum {
	BoardNone,
	BoardPen,
	BoardMerc,
	BoardBoth
};

// Mic src
pub const CCOMicSrc = enum {
	MicJanus,
	MicPen
};

// Alex RX out
pub const CCOAlexRxOut = enum {
	RxOutOff,
	RxOutOn
};

// Alex TX relay
pub const CCOAlexTxRly = enum {
	TxRlyTx1,
	TxRlyTx2,
	TxRlyTx3
};