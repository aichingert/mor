coord :: struct {
    x: i32;
    y: i32 = 1 + 1;

    init :: () -> self {
        return { x = 0; };
    }

    jump :: (*self) {
        self.y += 30;
    }
}

coord.get_with_offset :: (*self, offset: i32) -> self {
    return { x = self.x + offset; y = self.y + offset; };
}

main :: () {
    p : coord = coord.create();
    o : coord = p.get_with_offset(30);

    p.jump();
    o.jump();
}
