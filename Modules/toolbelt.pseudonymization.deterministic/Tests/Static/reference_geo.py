"""Unabhängige synthetische Geo-Orakel; keine SQL-/UDT-Qualifikation."""
from hashlib import sha256
import math
from reference_vectors import frame, select_candidate, MIN, MAX

R = 6416001.0
Q = 1 << 53
DOMAIN = b"TBXDGEO1"
GOLDEN = (
    ("5442584447454f3100000000000000000000000100000000000000000000000000000000001fffffffffffff00000007436f6e746f736f00000000",
     "fe3d6c956dd52968f09016e8b68d7b67137fca1ab69f7ab3f1b570404ada4343", 8282163373222248),
    ("5442584447454f3100000000000000010000000100000000000000000000000000000000001fffffffffffff00000007436f6e746f736f00000000",
     "6bb88e54b091d7ec1b075a143db60d871cae70583667beec21181cd1023d639f", 6911893831800812),
)


def uniform(key, version, seed, context):
    # Framing und Rejection ausschließlich aus der vorhandenen V1-Referenz.
    encoded = frame(key, version, seed, 0, Q - 1, 0, DOMAIN, context)
    digest = sha256(encoded).digest()
    value, attempt = select_candidate([int.from_bytes(digest[:8], "big")], 0, Q - 1)
    assert attempt == 0
    return value / Q


def destination(lat, lon, radius, u, v):
    # Lokale Meridian-/Ostprojektion statt globaler n/N/E-Vektorkopie.
    phi = math.radians(lat)
    lam = math.radians(0 if abs(lat) == 90 else lon)
    delta = 2 * math.asin(math.sqrt(u) * math.sin(radius / R / 2))
    bearing = 2 * math.pi * v
    vertical = math.sin(phi) * math.cos(delta) + math.cos(phi) * math.sin(delta) * math.cos(bearing)
    meridian = math.cos(phi) * math.cos(delta) - math.sin(phi) * math.sin(delta) * math.cos(bearing)
    east = math.sin(delta) * math.sin(bearing)
    result_lat = math.degrees(math.atan2(vertical, math.hypot(meridian, east)))
    result_lon = math.degrees(lam + math.atan2(east, meridian))
    result_lon = (result_lon + 180) % 360 - 180
    return result_lat, result_lon


def mapped(lat, lon, radius, key=b"Contoso", version=1, seed=0):
    return destination(lat, lon, radius, uniform(key, version, seed, 0), uniform(key, version, seed, 1))


# Feste synthetische Eingaben; SQL-Erwartungen werden separat als Literale eingefroren.
INPUTS = ((0, 0, 100, b"Contoso", 1, 0),
          (45, 179.999999, 10000, b"Contoso", 1, 0),
          (-45, -179.999999, 10000, b"Contoso", 1, 0),
          (90, 180, 1, b"Contoso", 1, 0),
          (-90, -180, 10000, b"Contoso", 1, 0),
          (89.999999, -179.999999, 100, b"\x00", 2147483647, MIN),
          (-89.999999, 179.999999, 1, b"\xff", 42, MAX),
          (0, 0, 10000, b"x" * 8000, 1, -1),
          (0, 0, 1, b"Contoso", 1, 0),
          (0, 0, 100, b"Contoso", 1, 1))
COORDINATES = ((0.00009329559721656489, -0.0008512208572426516),
               (45.0092663146956, 179.87959867546851),
               (-44.99060722285967, 179.87963987893778),
               (89.99999143681708, -96.25477230654049),
               (-89.91436817155254, -83.7452276701227),
               (89.99971816569024, -28.790814209926396),
               (-89.99999686455504, -33.20626371892752),
               (0.01116404359559117, 0.02938514279188098),
               (0.0000009329559722007257, -0.000008512208580668812),
               (0.0006761847921125811, -0.00013784759525492518))


def spherical_angle(lat1, lon1, lat2, lon2):
    def unit(lat, lon):
        phi, lam = math.radians(lat), math.radians(lon)
        return math.cos(phi) * math.cos(lam), math.cos(phi) * math.sin(lam), math.sin(phi)
    a, b = unit(lat1, lon1), unit(lat2, lon2)
    cross = (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0])
    return math.atan2(math.sqrt(sum(x * x for x in cross)), sum(x * y for x, y in zip(a, b)))


def run():
    count = 0
    def check(condition):
        nonlocal count
        assert condition
        count += 1
    for context, (expected_frame, expected_digest, expected_integer) in enumerate(GOLDEN):
        encoded = frame(b"Contoso", 1, 0, 0, Q - 1, 0, DOMAIN, context)
        check(encoded.hex() == expected_frame)
        check(sha256(encoded).hexdigest() == expected_digest)
        check(uniform(b"Contoso", 1, 0, context) == expected_integer / Q)
    f = 1 / 298.257223563
    max_curvature = 6378137 / math.sqrt(1 - f * (2 - f))
    check(max_curvature < 6400000 and max_curvature * 1.0025 < R)
    for version in (1, 2147483647):
        for seed in (MIN, -1, 0, MAX):
            for key in (b"\x00", b"Contoso", b"x" * 8000):
                for context in (0, 1):
                    check(0 <= uniform(key, version, seed, context) < 1)
    for lat in (-90, -89.999999, -45, 0, 45, 89.999999, 90):
        for lon in (-180, 0, 180):
            for radius in (1, 100, 10000):
                for u in (0, 1 / Q, .25, .5, (Q - 1) / Q):
                    for v in (0, .25, .5, .75, (Q - 1) / Q):
                        a, b = destination(lat, lon, radius, u, v)
                        check(math.isfinite(a) and math.isfinite(b) and -90 <= a <= 90 and -180 <= b < 180)
                        d = 2 * math.asin(math.sqrt(u) * math.sin(radius / R / 2))
                        check(d * max_curvature * 1.0025 <= radius)
                        measured = spherical_angle(lat, 0 if abs(lat) == 90 else lon, a, b)
                        check(abs(measured - d) * R < 1e-6)
                        check(abs((math.sin(d / 2) / math.sin(radius / R / 2)) ** 2 - u) < 2e-15)
    for args, expected in zip(INPUTS, COORDINATES):
        result = mapped(*args)
        check(all(abs(x - y) < 1e-12 for x, y in zip(result, expected)))
    for pole in (-90, 90):
        check(mapped(pole, -180, 100) == mapped(pole, 180, 100))
    return count


if __name__ == "__main__":
    print(f"PASS: Geo-Modell-/Hashreferenz {run()} Assertions; SQL not executed")
