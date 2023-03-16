const std = @import("std");

const c = @cImport({
    @cInclude("E:/Projects/ZigSDR/trunk/src/sdr/wdsp_lib/src/wisdom.h");
});

/// Initialize wdsp_lib. Call before other wdsp_lib functions.
pub fn init() !void {
    var path = ".";
    //const c_string: @ptrCast([*c]const u8,  ".");
    //const as_slice: [:0]const u8 = std.mem.span(c_string);
    //const path = c".";
    c.WDSPwisdom(path);
}
test "Wisdom" {
    try init();
}
