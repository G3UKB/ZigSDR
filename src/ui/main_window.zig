// main_window.zig
// 
// Module - main_window
// Main application window
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
const Allocator = std.mem.Allocator;
var allocator: Allocator = undefined;

const wdsp = struct {
	usingnamespace @import("../sdr/wdsp.zig");
};

pub fn clicked(_: *anyopaque) !void {
    //const stdout = std.io.getStdOut().writer();
    //try stdout.print("Clicked {s}\n", .{"me"});
    std.log.info("Clicked", .{});
}

pub fn build() !void {
    try capy.backend.init();
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (comptime !@import("builtin").target.isWasm()) {
        _ = gpa.deinit();
    };

    if (comptime !@import("builtin").target.isWasm()) {
        allocator = gpa.allocator();
    } else {
        allocator = std.heap.page_allocator;
    }

    try capy.init();
    defer capy.deinit();
    
    var window = try capy.Window.init();
    try window.set(
        capy.Button(.{ .label = "A Button", .onclick = clicked })
    );

    window.resize(300, 200);
    window.show();
    defer window.deinit();
    capy.runEventLoop();
    
}

pub fn run() !void {
    capy.runEventLoop();
}
