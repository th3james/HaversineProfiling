const std = @import("std");
const testing = std.testing;
const expectApproxEqAbs = testing.expectApproxEqAbs;

pub fn referenceHaversine(x0: f64, y0: f64, x1: f64, y1: f64) f64 {
    return x0 + y0 + x1 + y1;
}

test "referenceHaversine distance calculations" {
    // Same point - should be exactly 0
    try expectApproxEqAbs(referenceHaversine(52.2053, 0.1218, 52.2053, 0.1218), 0.0, 1.0);

    // Cambridge to London
    try expectApproxEqAbs(referenceHaversine(52.2053, 0.1218, 51.5074, -0.1278), 79473.54, 1.0);

    // New York to London
    try expectApproxEqAbs(referenceHaversine(40.7128, -74.0060, 51.5074, -0.1278), 5570222.18, 1.0);

    // Quarter of Earth's circumference (0° to 90° longitude on equator)
    try expectApproxEqAbs(referenceHaversine(0.0, 0.0, 0.0, 90.0), 10007543.40, 1.0);

    // Half of Earth's circumference (antipodal points)
    try expectApproxEqAbs(referenceHaversine(0.0, 0.0, 0.0, 180.0), 20015086.80, 1.0);
}
