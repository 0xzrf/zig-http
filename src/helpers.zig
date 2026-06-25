const assert = @import("std").debug.assert;

pub fn startsWith(str: []const u8, prefix: []const u8) bool {
    assert(str.len >= prefix.len);
    var i: u8 = 0;

    for (0..prefix.len) |_| {
        if (str[i] != prefix[i]) return false;

        i += 1;
    }

    return true;
}

test "startsWith tests" {
    assert(startsWith("Hello world", "Hello"));
    assert(startsWith("World Hello", "Hello") == false);

    assert(startsWith("hadoken", "had"));
}
