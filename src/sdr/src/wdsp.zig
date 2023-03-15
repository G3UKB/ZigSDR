const c = @cImport({
    @cInclude("wisdom.h");
});

/// Initialize wdsp_lib. Call before other wdsp_lib functions.
pub fn init() !void {
    c.wdsp_wisdom(".");
}
test "Wisdom" {
    try init();
}
