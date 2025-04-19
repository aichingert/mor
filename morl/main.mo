coord :: struct {
    x: f32;
    y: f32 = 1.5;

    create :: () -> self {
        return { x = 0.5; };
    }

    jump :: (*self) {
        self.x += 20;
        self.y += 30;
    }
}

main :: () {
    p := coord.create();

    p.jump();
}
