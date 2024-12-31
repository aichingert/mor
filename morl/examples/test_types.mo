main :: fn() {
    small : u8 = 10
    bigger : u16 = 20

    // Should complain
    plus : u16 = small + bigger // because small and bigger have different types
}
