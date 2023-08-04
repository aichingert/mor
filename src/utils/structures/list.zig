const std = @import("std");
pub fn List(comptime T: type) type {
    return struct {
        const Self = @This();

        pub const Node = struct {
            data: T,
            next: ?*Node = null,
            prev: ?*Node = null,

            pub const Data = T;
        };

        len: usize = 0,
        head: ?*Node = null,
        tail: ?*Node = null,

        pub fn pushFront(list: *Self, node: *Node) void {
            if (list.head) |head| {
                head.prev = node;
                node.next = head;
                list.head = node;
            } else {
                node.prev = null;
                list.head = node;
                list.tail = node;
            }

            list.len += 1;
        }

        pub fn pushBack(list: *Self, node: *Node) void {
            if (list.tail) |tail| {
                tail.next = node;
                node.prev = tail;
                list.tail = node;

                list.len += 1;
            } else {
                list.pushFront(node);
            }
        }
    };
}
