const std = @import("std");
const curl = @cImport(
    @cInclude("curl/curl.h"),
);

const Buffer = struct {
    data: []u8,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) Buffer {
        return Buffer{ .data = &[_]u8{}, .allocator = allocator };
    }

    pub fn append(self: *Buffer, new_data: []const u8) !void {
        const new_len = self.data.len + new_data.len;
        const new_buffer = try self.allocator.realloc(self.data, new_len);

        self.data = new_buffer[0..new_len];
        std.mem.copyForwards(u8, self.data[self.data.len - new_data.len ..], new_data);
    }
};

pub fn writeBuffer(ptr: ?*anyopaque, size: usize, nmemb: usize, userdata: *anyopaque) callconv(.C) usize {
    const total_size = size * nmemb;

    const buffer: *Buffer = @ptrCast(@alignCast(userdata));
    const data: [*]const u8 = @ptrCast(ptr);
    const slice = data[0..total_size];

    buffer.append(slice) catch @panic("Failed to write to buffer");

    return total_size;
}

pub fn readFromURL(allocator: std.mem.Allocator, url: []const u8) ![]const u8 {
    var curl_code: curl.CURLcode = 0;

    curl_code = curl.curl_global_init(curl.CURL_GLOBAL_DEFAULT);
    defer curl.curl_global_cleanup();

    if (curl_code != curl.CURLE_OK) {
        return error.FailedCurlGlobalInit;
    }

    const curl_data = curl.curl_easy_init() orelse return error.FailedInitCurl;
    defer curl.curl_easy_cleanup(curl_data);

    var buffer = Buffer.init(allocator);

    curl_code = curl.curl_easy_setopt(curl_data, curl.CURLOPT_URL, url.ptr);
    curl_code = curl.curl_easy_setopt(curl_data, curl.CURLOPT_WRITEFUNCTION, writeBuffer);
    curl_code = curl.curl_easy_setopt(curl_data, curl.CURLOPT_WRITEDATA, &buffer);

    if (curl_code != curl.CURLE_OK) {
        return error.FailedSetCurlOpt;
    }

    const res = curl.curl_easy_perform(curl_data);

    if (res != curl.CURLE_OK) {
        return error.FailedCurlPerform;
    }

    return buffer.data;
}
