//! This is goint to handle all the crud operations for the contact db
//! the /get-contact?name=hunter will return data associated to hunter
//! /update-contact will take the key-value pair for the target contact and update it
//! /upload-contact will add a new row to the db
//! and lastly, /delete-contact will delete a specified contact
const std = @import("std");

pub const DB = struct {
    endpoint: []const u8,

    pub fn new(endpoint: []const u8) !DB {
        // Connect to the db endpoint

        // Make sure the connection is established for long time

        return DB{ .endpoint = endpoint };
    }

    pub fn fetchContact(contact: []const u8) !void {}
    pub fn updateContact(contact: []const u8, ph: []const u8) !void {}
    pub fn uploadContact(contact: []const u8, ph: []const u8) !void {}
    pub fn delContact(contact: []const u8) !void {}
};
