coord :: struct {
    x: i32;
    y: i32 = 1 + 1;

    init :: () -> self {
        return .{ x = 0 };
    }

    jump :: (*self) {
        self.y += 30;
    }

    get_with_offset :: (*self, offset: i32) -> self {
        return .{ x = self.x + offset, y = self.y + offset };
    }
}

ret_code :: () -> i32 {
    return 10;
}

main :: () -> i32 {
    p : coord = coord.create();
    o : coord = p.get_with_offset(30);

    p.jump();
    o.jump();
    return ret_code();
}
