/*
    Lignicide
    Copyright (c) 2025-2025 Clevermeld™ LLC

    TODO: Document.
*/

#import bevy_sprite::mesh2d_vertex_output::VertexOutput

// Simplex noise functions
// Based on work by Ian McEwan, Stefan Gustavson, Munrocket, and Johan Helsing
// MIT License

struct TileMaterial {
    seed: f32,
}

@group(2) @binding(0) var<uniform> material: TileMaterial;

fn permute_4_(x: vec4<f32>) -> vec4<f32> {
    return ((x * 34.0 + 1.0) * x) % vec4<f32>(289.0);
}

fn taylor_inv_sqrt_4_(r: vec4<f32>) -> vec4<f32> {
    return 1.79284291400159 - 0.85373472095314 * r;
}

fn simplex_noise_3d_seeded(v: vec3<f32>, seed: vec3<f32>) -> f32 {
    let C: vec2<f32> = vec2(1.0 / 6.0, 1.0 / 3.0);
    let D: vec4<f32> = vec4(0.0, 0.5, 1.0, 2.0);

    // First corner
    var i: vec3<f32> = floor(v + dot(v, C.yyy));
    let x0: vec3<f32> = v - i + dot(i, C.xxx);

    // Other corners
    let g: vec3<f32> = step(x0.yzx, x0.xyz);
    let l: vec3<f32> = 1.0 - g;
    let i1: vec3<f32> = min(g.xyz, l.zxy);
    let i2: vec3<f32> = max(g.xyz, l.zxy);

    let x1: vec3<f32> = x0 - i1 + 1.0 * C.xxx;
    let x2: vec3<f32> = x0 - i2 + 2.0 * C.xxx;
    let x3: vec3<f32> = x0 - 1.0 + 3.0 * C.xxx;

    // Permutations with seed
    i = i % vec3(289.0);
    let s: vec3<f32> = floor(seed + vec3(0.5));
    let p: vec4<f32> = permute_4_(permute_4_(permute_4_(
        i.z + vec4(0.0, i1.z, i2.z, 1.0) + s.z) +
        i.y + vec4(0.0, i1.y, i2.y, 1.0) + s.y) +
        i.x + vec4(0.0, i1.x, i2.x, 1.0) + s.x
    );

    let n_: f32 = 1.0 / 7.0;
    let ns: vec3<f32> = n_ * D.wyz - D.xzx;
    let j: vec4<f32> = p - 49.0 * floor(p * ns.z * ns.z);
    let x_: vec4<f32> = floor(j * ns.z);
    let y_: vec4<f32> = floor(j - 7.0 * x_);
    let x: vec4<f32> = x_ * ns.x + ns.yyyy;
    let y: vec4<f32> = y_ * ns.x + ns.yyyy;
    let h: vec4<f32> = 1.0 - abs(x) - abs(y);

    let b0: vec4<f32> = vec4(x.xy, y.xy);
    let b1: vec4<f32> = vec4(x.zw, y.zw);
    let s0: vec4<f32> = floor(b0) * 2.0 + 1.0;
    let s1: vec4<f32> = floor(b1) * 2.0 + 1.0;
    let sh: vec4<f32> = -step(h, vec4(0.0));

    let a0: vec4<f32> = b0.xzyw + s0.xzyw * sh.xxyy;
    let a1: vec4<f32> = b1.xzyw + s1.xzyw * sh.zzww;

    var p0: vec3<f32> = vec3(a0.xy, h.x);
    var p1: vec3<f32> = vec3(a0.zw, h.y);
    var p2: vec3<f32> = vec3(a1.xy, h.z);
    var p3: vec3<f32> = vec3(a1.zw, h.w);

    let norm: vec4<f32> = taylor_inv_sqrt_4_(vec4(dot(p0, p0), dot(p1, p1), dot(p2, p2), dot(p3, p3)));
    p0 = p0 * norm.x;
    p1 = p1 * norm.y;
    p2 = p2 * norm.z;
    p3 = p3 * norm.w;

    var m: vec4<f32> = 0.5 - vec4(dot(x0, x0), dot(x1, x1), dot(x2, x2), dot(x3, x3));
    m = max(m, vec4(0.0));
    m = m * m;
    return 105.0 * dot(m * m, vec4(dot(p0, x0), dot(p1, x1), dot(p2, x2), dot(p3, x3)));
}

@fragment
fn fragment(mesh: VertexOutput) -> @location(0) vec4<f32> {
    // 256x256 tiles
    let grid_size: f32 = 256.0;

    // Calculate which tile this pixel belongs to based on UV coordinates
    let tile_coord: vec2<f32> = floor(mesh.uv * grid_size);

    // Generate noise value for this tile using seed
    let noise: f32 = simplex_noise_3d_seeded(vec3<f32>(tile_coord * 0.1, 0.0), vec3<f32>(material.seed, 0.0, 0.0));

    // Remap noise from [-1, 1] to [0, 1]
    let noise_normalized: f32 = (noise + 1.0) * 0.5;

    // Define terrain colors
    let ocean_color: vec3<f32> = vec3<f32>(0.1, 0.3, 0.6);      // Deep blue
    let coastal_color: vec3<f32> = vec3<f32>(0.8, 0.7, 0.5);    // Sandy beige
    let land_color: vec3<f32> = vec3<f32>(0.2, 0.6, 0.2);       // Green
    let mountain_color: vec3<f32> = vec3<f32>(0.5, 0.5, 0.5);   // Gray

    // Apply thresholds to determine terrain type
    var color: vec3<f32> = ocean_color;
    if (noise_normalized > 0.4) {
        color = coastal_color;
    }
    if (noise_normalized > 0.5) {
        color = land_color;
    }
    if (noise_normalized > 0.7) {
        color = mountain_color;
    }

    return vec4<f32>(color, 1.0);
}

