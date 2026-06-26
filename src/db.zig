//! This is goint to handle all the crud operations for the contact db
//! the /get-contact?name=hunter will return data associated to hunter
//! /update-contact will take the key-value pair for the target contact and update it
//! /upload-contact will add a new row to the db
//! and lastly, /delete-contact will delete a specified contact

const std = @import("std");
const pg = @import("pg");

pub const DB = struct {
    endpoint: []const u8,
    pool: *pg.Pool,

    /// Opens a connection pool to `endpoint` and verifies it works.
    /// `endpoint` must be a PostgreSQL URI, e.g.
    /// "postgresql://user:password@localhost:5432/contacts".
    pub fn new(endpoint: []const u8, gpa: std.mem.Allocator, io: std.Io) !DB {
        const uri = try std.Uri.parse(endpoint);

        const pool = try pg.Pool.initUri(io, gpa, uri, .{
            .size = 5,
            .timeout = 10_000,
        });
        errdefer pool.deinit();

        // initUri eagerly opens the connections, but issue a real round-trip
        // query so a bad host/credentials surfaces here as an error.
        _ = try pool.exec("select 1", .{});

        return DB{ .endpoint = endpoint, .pool = pool };
    }

    pub fn deinit(self: *DB) void {
        self.pool.deinit();
    }

    // pub fn fetchContact(contact: []const u8) ![]const u8 {}
    // pub fn updateContact(contact: []const u8, ph: []const u8) !void {}
    // pub fn uploadContact(contact: []const u8, ph: []const u8) !void {}
    // pub fn delContact(contact: []const u8) !void {}
};

test "check db connectivity" {
    const allocator = std.testing.allocator;

    // A test has no std.process.Init, so build an Io implementation ourselves.
    var threaded: std.Io.Threaded = .init(allocator, .{});
    defer threaded.deinit();
    const io = threaded.io();

    const endpoint = "postgresql://zerefdegnl@localhost:5432/myapp";

    var db = try DB.new(endpoint, allocator, io);
    defer db.deinit();

    try std.testing.expectEqualStrings(endpoint, db.endpoint);
    std.debug.print("Hello", .{});
}
