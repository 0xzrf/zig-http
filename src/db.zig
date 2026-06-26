//! This is goint to handle all the crud operations for the contact db
//! the /get-contact?name=hunter will return data associated to hunter
//! /update-contact will take the key-value pair for the target contact and update it
//! /upload-contact will add a new row to the db
//! and lastly, /delete-contact will delete a specified contact

const std = @import("std");
const pg = @import("pg");
const builtin = @import("builtin");

pub const DB = struct {
    endpoint: []const u8,
    allocator: std.mem.Allocator,
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

        _ = try pool.exec(
            \\create table if not exists my_contacts (
            \\    contact text primary key,
            \\    phone text not null
            \\)
        , .{});

        return DB{ .endpoint = endpoint, .allocator = gpa, .pool = pool };
    }

    pub fn deinit(self: *DB) void {
        self.pool.deinit();
    }

    /// Returns an owned copy of the contact's phone number.
    /// The caller must free the returned slice with the allocator passed to `new`.
    pub fn fetchContact(self: *DB, contact: []const u8) ![]u8 {
        var row = (try self.pool.row(
            "select phone from my_contacts where contact = $1",
            .{contact},
        )) orelse return error.ContactNotFound;
        defer row.deinit() catch {};

        const phone = try row.get([]const u8, 0);
        return self.allocator.dupe(u8, phone);
    }

    pub fn updateContact(self: *DB, contact: []const u8, ph: []const u8) !void {
        const updated = (try self.pool.exec(
            "update my_contacts set phone = $1 where contact = $2",
            .{ ph, contact },
        )) orelse 0;

        if (updated == 0) return error.ContactNotFound;
    }

    pub fn uploadContact(self: *DB, contact: []const u8, ph: []const u8) !void {
        _ = try self.pool.exec(
            "insert into my_contacts (contact, phone) values ($1, $2)",
            .{ contact, ph },
        );
    }

    pub fn delContact(self: *DB, contact: []const u8) !void {
        const deleted = (try self.pool.exec(
            "delete from my_contacts where contact = $1",
            .{contact},
        )) orelse 0;

        if (deleted == 0) return error.ContactNotFound;
    }
};

fn initDb() !DB {
    if (comptime !builtin.is_test) {
        @compileError("can only call this during test");
    }

    const allocator = std.testing.allocator;

    // A test has no std.process.Init, so build an Io implementation ourselves.
    var threaded: std.Io.Threaded = .init(allocator, .{});
    defer threaded.deinit();
    const io = threaded.io();

    const endpoint = "postgresql://zerefdegnl@localhost:5432/myapp";

    return try DB.new(endpoint, allocator, io);
}

test "check db connectivity" {
    const endpoint = "postgresql://zerefdegnl@localhost:5432/myapp";
    var db = try initDb();
    defer db.deinit();

    std.testing.expectEqualStrings(endpoint, db.endpoint);
}

test "check create contact" {
    const contact = "Zeref";
    const ph = "+xx xxxxx xxxxx";

    var db = try initDb();
    defer db.delContact(contact);
    defer db.deinit();

    try db.uploadContact(contact, ph);
}
