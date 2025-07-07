@vertex
fn vs_main(@builtin(vertex_index) idx: u32) -> @builtin(position) vec4f {
    var pos = array<vec2f, 3>(
        vec2f(-0.5, -0.5),
        vec2f(0.5, -0.5),
        vec2f(0.0, 0.5)
    );
    return vec4f(pos[idx], 0.0, 1.0);
}

@fragment
fn fs_main() -> @location(0) vec4f {
    return vec4f(0.0, 0.4, 1.0, 1.0);   // blue-ish color
}
