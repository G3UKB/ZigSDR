// main.zig
// 
// Module - main
// Entry point fr application
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

const capy = @import("capy");
pub usingnamespace capy.cross_platform;

const wdsp = struct {
	usingnamespace @import("sdr/wdsp.zig");
};
const ui = struct {
	usingnamespace @import("ui/main_window.zig");
};

pub fn main() !void {

    // Initialise WSDP
    try wdsp.init();

    // Run UI
    const stdout = std.io.getStdOut().writer();
    try stdout.print("\nRun", .{});
    try ui.build();
    try stdout.print("\nClose", .{});
    //try ui.run();
}

pub fn run() !void {
    try wdsp.init();
}

test "ZigSDR" {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("\nRunning tests..", .{});
    try run();
}