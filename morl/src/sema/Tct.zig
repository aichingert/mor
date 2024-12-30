// Tct.zig: Type checked tree

const Self = @This();

// TODO: add in between step of ast and mir
// therefore giving more information to mir
// which enables it to use different sizes
// and makes it possible to figure out what
// types get passed to functions and able to
// implement structs
//
// TODO: what are types? and going from expected to actual with like
//
// n : u8 = 255
// a : u8[][] = {0}
// f : fn(i32) -> i32 = |a| a + 1
// s : structy = structy{ a := 10, b := 20 } // not sure about this syntax
//
// numbers -> u8, i8 - u64, i64 ? is there a difference between sizes or should it truncate/extend them
// strings -> pretty simple they are just an array of characters
// structs -> now things get weird (is this just a name or actually the different values in a struct like
//            it has the variable (b: i32, c: u8) -> or okay this is a struct so you can access variables
//            then again checking that a struct has that variable requires it to store the names of those
//            member variables but how are they represented in the type system
// arrays  -> should this store something else or what do types actually need just information that it is
//            an array so you can index it, but then again the size does matter because when you index an
//            array you get another type

pub const Type = struct {
    expt: Tag,
    node: u32,

    const Tag = struct {
        .array,
        .builtin,
        .function,
    };
};
