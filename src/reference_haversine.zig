const std = @import("std");
const sin = std.math.sin;
const asin = std.math.asin;
const cos = std.math.cos;
const sqrt = std.math.sqrt;
const testing = std.testing;
const expectApproxEqAbs = testing.expectApproxEqAbs;

const earthRadius = 6372.8;

fn square(a: f64) f64 {
    return a * a;
}

fn radiansFromDegrees(degrees: f64) f64 {
    return 0.01745329251994329577 * degrees;
}

pub fn referenceHaversine(x0: f64, y0: f64, x1: f64, y1: f64) f64 {
    var lat1 = y0;
    var lat2 = y1;
    const lon1 = x0;
    const lon2 = x1;

    const dLat = radiansFromDegrees(lat2 - lat1);
    const dLon = radiansFromDegrees(lon2 - lon1);
    lat1 = radiansFromDegrees(lat1);
    lat2 = radiansFromDegrees(lat2);

    const a = square(sin(dLat / 2.0)) + cos(lat1) * cos(lat2) * square(sin(dLon / 2));
    const c = 2.0 * asin(sqrt(a));

    return earthRadius * c;
}

test "referenceHaversine distance calculations" {
    // Same point - should be exactly 0
    try expectApproxEqAbs(referenceHaversine(0.1218, 52.2053, 0.1218, 52.2053), 0.0, 1.0);

    // Cambridge to London
    try expectApproxEqAbs(referenceHaversine(0.1218, 52.2053, -0.1278, 51.5074), 79.47354, 1.0);

    // New York to London
    try expectApproxEqAbs(referenceHaversine(-74.0060, 40.7128, -0.1278, 51.5074), 5570.22218, 2.0);

    // Quarter of Earth's circumference (0° to 90° longitude on equator)
    try expectApproxEqAbs(referenceHaversine(0.0, 0.0, 90.0, 0.0), 10007.54340, 3.0);

    // Half of Earth's circumference (antipodal points)
    try expectApproxEqAbs(referenceHaversine(0.0, 0.0, 180.0, 0.0), 20015.08680, 6.0);
}
