
# OKHSL, Conveter under Copyright (c) 2021 Björn Ottosson, licensed under MIT license

package Graphics::Toolkit::Color::Space::Instance::OKHSL;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Space qw/gamma_correct mult_matrix_vector_3/;

my @D65 = (0.95047, 1, 1.08883); # illuminant

sub from_hsl {
    my ($hsl) = shift;

    return \@lab;
}
sub to_hsl {
    my (@rgb) = @{$_[0]};
    return [map {$xyz[$_] / $D65[$_]} 0 .. 2];
}

Graphics::Toolkit::Color::Space->new(
         name => 'OKHSL',
       family => 'HSL',
         axis => [qw/hue saturation lightness/], 
         type => [qw/angular linear linear/],
        range => [360, 1, 1],
    precision => 5,
      convert => {LinearRGB => [\&from_hsl, \&to_hsl]},
);

use constant PI => 4 * atan2(1, 1);

# sRGB (0..1, nicht-linear) -> Okhsl, gibt (h, s, l) zurück
sub srgb_to_okhsl {
    my ($r, $g, $b) = @_;

    my ($L_lab, $a_lab, $b_lab) = linear_srgb_to_oklab(
        srgb_transfer_function_inv($r),
        srgb_transfer_function_inv($g),
        srgb_transfer_function_inv($b),
    );

    my $C  = sqrt($a_lab * $a_lab + $b_lab * $b_lab);
    my $a_ = $a_lab / $C;
    my $b_ = $b_lab / $C;

    my $L = $L_lab;
    my $h = 0.5 + 0.5 * atan2(-$b_lab, -$a_lab) / PI;

    my ($C_0, $C_mid, $C_max) = get_Cs($L, $a_, $b_);

    # Inverse der Interpolation aus okhsl_to_srgb
    my $mid     = 0.8;
    my $mid_inv = 1.25;

    my $s;
    if ($C < $C_mid) {
        my $k_1 = $mid * $C_0;
        my $k_2 = 1 - $k_1 / $C_mid;

        my $t = $C / ($k_1 + $k_2 * $C);
        $s = $t * $mid;
    }
    else {
        my $k_0 = $C_mid;
        my $k_1 = (1 - $mid) * $C_mid * $C_mid * $mid_inv * $mid_inv / $C_0;
        my $k_2 = 1 - $k_1 / ($C_max - $C_mid);

        my $t = ($C - $k_0) / ($k_1 + $k_2 * ($C - $k_0));
        $s = $mid + (1 - $mid) * $t;
    }

    my $l = toe($L);
    return ($h, $s, $l);
}

struct HSV { float h; float s; float v; };
struct HSL { float h; float s; float l; };
struct LC  { float L; float C; };

// Alternative representation of (L_cusp, C_cusp)
// Encoded so S = C_cusp/L_cusp and T = C_cusp/(1-L_cusp) 
// The maximum value for C in the triangle is then found as fmin(S*L, T*(1-L)), for a given L
struct ST { float S; float T; };

// toe function for L_r
float toe(float x)
{
	constexpr float k_1 = 0.206f;
	constexpr float k_2 = 0.03f;
	constexpr float k_3 = (1.f + k_1) / (1.f + k_2);
	return 0.5f * (k_3 * x - k_1 + sqrtf((k_3 * x - k_1) * (k_3 * x - k_1) + 4 * k_2 * k_3 * x));
}

// inverse toe function for L_r
float toe_inv(float x)
{
	constexpr float k_1 = 0.206f;
	constexpr float k_2 = 0.03f;
	constexpr float k_3 = (1.f + k_1) / (1.f + k_2);
	return (x * x + k_1 * x) / (k_3 * (x + k_2));
}

ST to_ST(LC cusp)
{
	float L = cusp.L;
	float C = cusp.C;
	return { C / L, C / (1 - L) };
}

struct HSL { float h; float s; float l; };

// Returns a smooth approximation of the location of the cusp
// This polynomial was created by an optimization process
// It has been designed so that S_mid < S_max and T_mid < T_max
ST get_ST_mid(float a_, float b_)
{
	float S = 0.11516993f + 1.f / (
		+7.44778970f + 4.15901240f * b_
		+ a_ * (-2.19557347f + 1.75198401f * b_
			+ a_ * (-2.13704948f - 10.02301043f * b_
				+ a_ * (-4.24894561f + 5.38770819f * b_ + 4.69891013f * a_
					)))
		);

	float T = 0.11239642f + 1.f / (
		+1.61320320f - 0.68124379f * b_
		+ a_ * (+0.40370612f + 0.90148123f * b_
			+ a_ * (-0.27087943f + 0.61223990f * b_
				+ a_ * (+0.00299215f - 0.45399568f * b_ - 0.14661872f * a_
					)))
		);

	return { S, T };
}

struct Cs { float C_0; float C_mid; float C_max; };
Cs get_Cs(float L, float a_, float b_)
{
	LC cusp = find_cusp(a_, b_);

	float C_max = find_gamut_intersection(a_, b_, L, 1, L, cusp);
	ST ST_max = to_ST(cusp);
	
	// Scale factor to compensate for the curved part of gamut shape:
	float k = C_max / fmin((L * ST_max.S), (1 - L) * ST_max.T);

	float C_mid;
	{
		ST ST_mid = get_ST_mid(a_, b_);

		// Use a soft minimum function, instead of a sharp triangle shape to get a smooth value for chroma.
		float C_a = L * ST_mid.S;
		float C_b = (1.f - L) * ST_mid.T;
		C_mid = 0.9f * k * sqrtf(sqrtf(1.f / (1.f / (C_a * C_a * C_a * C_a) + 1.f / (C_b * C_b * C_b * C_b))));
	}

	float C_0;
	{
		// for C_0, the shape is independent of hue, so ST are constant. Values picked to roughly be the average values of ST.
		float C_a = L * 0.4f;
		float C_b = (1.f - L) * 0.8f;

		// Use a soft minimum function, instead of a sharp triangle shape to get a smooth value for chroma.
		C_0 = sqrtf(1.f / (1.f / (C_a * C_a) + 1.f / (C_b * C_b)));
	}

	return { C_0, C_mid, C_max };
}

RGB okhsl_to_srgb(HSL hsl)
{
	float h = hsl.h;
	float s = hsl.s;
	float l = hsl.l;

	if (l == 1.0f)
	{
		return { 1.f, 1.f, 1.f };
	}

	else if (l == 0.f)
	{
		return { 0.f, 0.f, 0.f };
	}

	float a_ = cosf(2.f * pi * h);
	float b_ = sinf(2.f * pi * h);
	float L = toe_inv(l);

	Cs cs = get_Cs(L, a_, b_);
	float C_0 = cs.C_0;
	float C_mid = cs.C_mid;
	float C_max = cs.C_max;

    // Interpolate the three values for C so that:
    // At s=0: dC/ds = C_0, C=0
    // At s=0.8: C=C_mid
    // At s=1.0: C=C_max

	float mid = 0.8f;
	float mid_inv = 1.25f;

	float C, t, k_0, k_1, k_2;

	if (s < mid)
	{
		t = mid_inv * s;

		k_1 = mid * C_0;
		k_2 = (1.f - k_1 / C_mid);

		C = t * k_1 / (1.f - k_2 * t);
	}
	else
	{
		t = (s - mid)/ (1 - mid);

		k_0 = C_mid;
		k_1 = (1.f - mid) * C_mid * C_mid * mid_inv * mid_inv / C_0;
		k_2 = (1.f - (k_1) / (C_max - C_mid));

		C = k_0 + t * k_1 / (1.f - k_2 * t);
	}

	RGB rgb = oklab_to_linear_srgb({ L, C * a_, C * b_ });
	return {
		srgb_transfer_function(rgb.r),
		srgb_transfer_function(rgb.g),
		srgb_transfer_function(rgb.b),
	};
}

HSL srgb_to_okhsl(RGB rgb)
{
	Lab lab = linear_srgb_to_oklab({
		srgb_transfer_function_inv(rgb.r),
		srgb_transfer_function_inv(rgb.g),
		srgb_transfer_function_inv(rgb.b)
		});

	float C = sqrtf(lab.a * lab.a + lab.b * lab.b);
	float a_ = lab.a / C;
	float b_ = lab.b / C;

	float L = lab.L;
	float h = 0.5f + 0.5f * atan2f(-lab.b, -lab.a) / pi;

	Cs cs = get_Cs(L, a_, b_);
	float C_0 = cs.C_0;
	float C_mid = cs.C_mid;
	float C_max = cs.C_max;

    // Inverse of the interpolation in okhsl_to_srgb:

	float mid = 0.8f;
	float mid_inv = 1.25f;

	float s;
	if (C < C_mid)
	{
		float k_1 = mid * C_0;
		float k_2 = (1.f - k_1 / C_mid);

		float t = C / (k_1 + k_2 * C);
		s = t * mid;
	}
	else
	{
		float k_0 = C_mid;
		float k_1 = (1.f - mid) * C_mid * C_mid * mid_inv * mid_inv / C_0;
		float k_2 = (1.f - (k_1) / (C_max - C_mid));

		float t = (C - k_0) / (k_1 + k_2 * (C - k_0));
		s = mid + (1.f - mid) * t;
	}

	float l = toe(L);
	return { h, s, l };
}




from coloraide.spaces import Space, RE_DEFAULT_MATCH, Angle, Percent, GamutBound, Cylindrical
from coloraide.spaces.srgb.base import lin_srgb, gam_srgb
from coloraide.spaces.oklab import Oklab
from coloraide import util
from coloraide import Color as ColorOrig
import re
import math
import sys
import copy

FLT_MAX = sys.float_info.max

K_1 = 0.206
K_2 = 0.03
K_3 = (1.0 + K_1) / (1.0 + K_2)


def toe(x):
    """Toe function for L_r."""

    return 0.5 * (K_3 * x - K_1 + math.sqrt((K_3 * x - K_1) * (K_3 * x - K_1) + 4 * K_2 * K_3 * x))


def toe_inv(x):
    """Inverse toe function for L_r."""

    return (x * x + K_1 * x) / (K_3 * (x + K_2))


def to_st(cusp):
    """To ST."""

    l, c = cusp
    return c / l, c / (1 - l)


def get_st_mid(a, b):
    """
    Returns a smooth approximation of the location of the cusp.
    This polynomial was created by an optimization process.
    It has been designed so that S_mid < S_max and T_mid < T_max.
    """

    s = 0.11516993 + 1.0 / (
        7.44778970 + 4.15901240 * b +
        a * (
            -2.19557347 + 1.75198401 * b +
            a * (
                -2.13704948 - 10.02301043 * b +
                a * (
                    -4.24894561 + 5.38770819 * b + 4.69891013 * a
                )
            )
        )
    )

    t = 0.11239642 + 1.0 / (
        1.61320320 - 0.68124379 * b +
        a * (
            0.40370612 + 0.90148123 * b +
            a * (
                -0.27087943 + 0.61223990 * b +
                a * (
                    0.00299215 - 0.45399568 * b - 0.14661872 * a
                )
            )
        )
    )

    return s, t


def find_cusp(a, b):
    """
    Finds L_cusp and C_cusp for a given hue.
    `a` and `b` must be normalized so `a^2 + b^2 == 1`.
    """

    # First, find the maximum saturation (saturation `S = C/L`)
    s_cusp = compute_max_saturation(a, b)

    # Convert to linear sRGB to find the first point where at least one of r, g or b >= 1:
    r, g, b = oklab_to_linear_srgb([1, s_cusp * a, s_cusp * b])
    l_cusp = util.nth_root(1.0 / max(max(r, g), b), 3)
    c_cusp = l_cusp * s_cusp

    return l_cusp , c_cusp


def find_gamut_intersection(a, b, l1, c1, l0, cusp=None):
    """
    Finds intersection of the line.
    Defined by the following:
    ```
    L = L0 * (1 - t) + t * L1
    C = t * C1
    ```
    `a` and `b` must be normalized so `a^2 + b^2 == 1`.
    """

    if cusp is None:
        cusp = get_cs([l1, a, b])

    # Find the intersection for upper and lower half seprately
    if ((l1 - l0) * cusp[1] - (cusp[0] - l0) * c1) <= 0.0:
        #Lower half
        t = cusp[1] * l0 / (c1 * cusp[0] + cusp[1] * (l0 - l1))
    else:
        # Upper half

        # First intersect with triangle
        t = cusp[1] * (l0 - 1.0) / (c1 * (cusp[0] - 1.0) + cusp[1] * (l0 - l1))

        # Then one step Halley's method
        dl = l1 - l0
        dc = c1

        k_l = +0.3963377774 * a + 0.2158037573 * b
        k_m = -0.1055613458 * a - 0.0638541728 * b
        k_s = -0.0894841775 * a - 1.2914855480 * b

        l_dt = dl + dc * k_l
        m_dt = dl + dc * k_m
        s_dt = dl + dc * k_s

        # If higher accuracy is required, 2 or 3 iterations of the following block can be used:
        L = l0 * (1.0 - t) + t * l1
        C = t * c1

        l_ = L + C * k_l
        m_ = L + C * k_m
        s_ = L + C * k_s

        l = l_ ** 3
        m = m_ ** 3
        s = s_ ** 3

        ldt = 3 * l_dt * l_ * l_
        mdt = 3 * m_dt * m_ * m_
        sdt = 3 * s_dt * s_ * s_

        ldt2 = 6 * l_dt * l_dt * l_
        mdt2 = 6 * m_dt * m_dt * m_
        sdt2 = 6 * s_dt * s_dt * s_

        r = 4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s - 1
        r1 = 4.0767416621 * ldt - 3.3077115913 * mdt + 0.2309699292 * sdt
        r2 = 4.0767416621 * ldt2 - 3.3077115913 * mdt2 + 0.2309699292 * sdt2

        u_r = r1 / (r1 * r1 - 0.5 * r * r2)
        t_r = -r * u_r

        g = -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s - 1
        g1 = -1.2684380046 * ldt + 2.6097574011 * mdt - 0.3413193965 * sdt
        g2 = -1.2684380046 * ldt2 + 2.6097574011 * mdt2 - 0.3413193965 * sdt2

        u_g = g1 / (g1 * g1 - 0.5 * g * g2)
        t_g = -g * u_g

        b = -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s - 1
        b1 = -0.0041960863 * ldt - 0.7034186147 * mdt + 1.7076147010 * sdt
        b2 = -0.0041960863 * ldt2 - 0.7034186147 * mdt2 + 1.7076147010 * sdt2

        u_b = b1 / (b1 * b1 - 0.5 * b * b2)
        t_b = -b * u_b

        t_r = t_r if u_r >= 0.0 else FLT_MAX
        t_g = t_g if u_g >= 0.0 else FLT_MAX
        t_b = t_b if u_b >= 0.0 else FLT_MAX

        t += min(t_r, min(t_g, t_b))

    return t


def get_cs(lab):
    l, a, b = lab

    cusp = find_cusp(a, b)

    c_max = find_gamut_intersection(a, b, l, 1, l, cusp)
    st_max = to_st(cusp)

    # Scale factor to compensate for the curved part of gamut shape:
    k = c_max / min((l * st_max[0]), (1 - l) * st_max[1])

    st_mid = get_st_mid(a, b)

    # Use a soft minimum function, instead of a sharp triangle shape to get a smooth value for chroma.
    c_a = l * st_mid[0]
    c_b = (1.0 - l) * st_mid[1]
    c_mid = 0.9 * k * math.sqrt(math.sqrt(1.0 / (1.0 / (c_a * c_a * c_a * c_a) + 1.0 / (c_b * c_b * c_b * c_b))))

    # For `C_0`, the shape is independent of hue, so `ST` are constant.
    # Values picked to roughly be the average values of `ST`.
    c_a = l * 0.4
    c_b = (1.0 - l) * 0.8

    # Use a soft minimum function, instead of a sharp triangle shape to get a smooth value for chroma.
    c_0 = math.sqrt(1.0 / (1.0 / (c_a * c_a) + 1.0 / (c_b * c_b)))

    return c_0, c_mid, c_max


def oklab_to_linear_srgb(lab):
    """Convert from Oklab to linear sRGB."""

    l_ = lab[0] + 0.3963377774 * lab[1] + 0.2158037573 * lab[2]
    m_ = lab[0] - 0.1055613458 * lab[1] - 0.0638541728 * lab[2]
    s_ = lab[0] - 0.0894841775 * lab[1] - 1.2914855480 * lab[2]

    l = l_ ** 3
    m = m_ ** 3
    s = s_ ** 3

    return [
        +4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
        -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
        -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s
    ]


def linear_srgb_to_oklab(rgb):

    r, g, b = rgb
    l = 0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b
    m = 0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b
    s = 0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b

    l_ = util.nth_root(l, 3)
    m_ = util.nth_root(m, 3)
    s_ = util.nth_root(s, 3)

    return [
        0.2104542553 * l_ + 0.7936177850 * m_ - 0.0040720468 * s_,
        1.9779984951 * l_ - 2.4285922050 * m_ + 0.4505937099 * s_,
        0.0259040371 * l_ + 0.7827717662 * m_ - 0.8086757660 * s_
    ]


def compute_max_saturation(a, b):
    """
    Finds the maximum saturation possible for a given hue that fits in sRGB.
    Saturation here is defined as `S = C/L`.
    `a` and `b` must be normalized so `a^2 + b^2 == 1`.
    """

    # Max saturation will be when one of r, g or b goes below zero.

    # Select different coefficients depending on which component goes below zero first.

    if (-1.88170328 * a - 0.80936493 * b) > 1:
        # Red component
        k0 = 1.19086277
        k1 = 1.76576728
        k2 = 0.59662641
        k3 = 0.75515197
        k4 = 0.56771245
        wl = 4.0767416621
        wm = -3.3077115913
        ws = 0.2309699292

    elif (1.81444104 * a - 1.19445276 * b) > 1:
        # Green component
        k0 = 0.73956515
        k1 = -0.45954404
        k2 = 0.08285427
        k3 = 0.12541070
        k4 = 0.14503204
        wl = -1.2684380046
        wm = 2.6097574011
        ws = -0.3413193965

    else:
        # Blue component
        k0 = 1.35733652
        k1 = -0.00915799
        k2 = -1.15130210
        k3 = -0.50559606
        k4 = 0.00692167
        wl = -0.0041960863
        wm = -0.7034186147
        ws = 1.7076147010

    # Approximate max saturation using a polynomial:
    sat = k0 + k1 * a + k2 * b + k3 * a * a + k4 * a * b

    # Do one step Halley's method to get closer.
    # This gives an error less than 10e6, except for some blue hues where the `dS/dh` is close to infinite.
    # This should be sufficient for most applications, otherwise do two/three steps.

    k_l = 0.3963377774 * a + 0.2158037573 * b
    k_m = -0.1055613458 * a - 0.0638541728 * b
    k_s = -0.0894841775 * a - 1.2914855480 * b

    l_ = 1.0 + sat * k_l
    m_ = 1.0 + sat * k_m
    s_ = 1.0 + sat * k_s

    l = l_ * l_ * l_
    m = m_ * m_ * m_
    s = s_ * s_ * s_

    l_ds = 3.0 * k_l * l_ * l_
    m_ds = 3.0 * k_m * m_ * m_
    s_ds = 3.0 * k_s * s_ * s_

    l_ds2 = 6.0 * k_l * k_l * l_
    m_ds2 = 6.0 * k_m * k_m * m_
    s_ds2 = 6.0 * k_s * k_s * s_

    f = wl * l + wm * m + ws * s
    f1 = wl * l_ds + wm * m_ds + ws * s_ds
    f2 = wl * l_ds2 + wm * m_ds2 + ws * s_ds2

    sat = sat - f * f1 / (f1 * f1 - 0.5 * f * f2)

    return sat


def okhsl_to_oklab(hsl):
    """Convert Okhsl to sRGB."""

    h, s, l = hsl
    s /= 100
    l /= 100
    h = util.no_nan(h) / 360.0

    L = toe_inv(l)
    a = b = 0

    if L != 0 and L != 1 and s != 0:
        a_ = math.cos(2.0 * math.pi * h)
        b_ = math.sin(2.0 * math.pi * h)

        c_0, c_mid, c_max = get_cs([L, a_, b_])

        # Interpolate the three values for C so that:
        # At s=0: dC/ds = C_0, C=0
        # At s=0.8: C=C_mid
        # At s=1.0: C=C_max

        mid = 0.8
        mid_inv = 1.25

        if s < mid:
            t = mid_inv * s
            k_0 = 0
            k_1 = mid * c_0
            k_2 = (1.0 - k_1 / c_mid)

        else:
            t = 5 * (s - 0.8)
            k_0 = c_mid
            k_1 = 0.2 * (c_mid ** 2) * (1.25 ** 2) / c_0
            k_2 = (1.0 - (k_1) / (c_max - c_mid))

        c = k_0 + t * k_1 / (1.0 - k_2 * t)

        a = c * a_
        b = c * b_

    return [L, a, b]


def oklab_to_okhsl(lab):
    """Oklab to Okhsl."""

    c = math.sqrt(lab[1] ** 2 + lab[2] ** 2)

    h = util.NaN
    L = lab[0]
    s = 0

    if c != 0 and L != 0:
        a_ = lab[1] / c
        b_ = lab[2] / c

        h = 0.5 + 0.5 * math.atan2(-lab[2], -lab[1]) / math.pi

        c_0, c_mid, c_max = get_cs([L, a_, b_])

        # Inverse of the interpolation in okhsl_to_srgb:

        mid = 0.8
        mid_inv = 1.25

        if (c < c_mid):
            k_1 = mid * c_0
            k_2 = (1.0 - k_1 / c_mid)

            t = c / (k_1 + k_2 * c)
            s = t * mid

        else:
            k_0 = c_mid
            k_1 = (1.0 - mid) * c_mid * c_mid * mid_inv * mid_inv / c_0
            k_2 = (1.0 - (k_1) / (c_max - c_mid))

            t = (c - k_0) / (k_1 + k_2 * (c - k_0))
            s = mid + (1.0 - mid) * t

    l = toe(L)

    if s == 0:
        h = util.NaN

    return util.constrain_hue(h * 360), s * 100, l * 100


def srgb_to_okhsv(srgb):
    """SRGB to Okhsv."""

    return oklab_to_okhsv(linear_srgb_to_oklab(lin_srgb(srgb)))


def okhsv_to_srgb(hsv):
    """Okhsv to sRGB."""

    return gam_srgb(oklab_to_linear_srgb(okhsv_to_oklab(hsv)))


def srgb_to_okhsl(srgb):
    """SRGB to Okhsl."""

    return oklab_to_okhsl(linear_srgb_to_oklab(lin_srgb(srgb)))


def okhsl_to_srgb(hsl):
    """Okhsl to sRGB."""

    return gam_srgb(oklab_to_linear_srgb(okhsl_to_oklab(hsl)))


class Okhsl(Cylindrical, Space):
    """HSL class."""

    SPACE = "okhsl"
    SERIALIZE = ("--okhsl",)
    CHANNEL_NAMES = ("hue", "saturation", "lightness", "alpha")
    DEFAULT_MATCH = re.compile(RE_DEFAULT_MATCH.format(color_space='|'.join(SERIALIZE), channels=3))
    WHITE = "D65"
    GAMUT_CHECK = "srgb"

    RANGE = (
        GamutBound([Angle(0.0), Angle(360.0)]),
        GamutBound([Percent(0.0), Percent(100.0)]),
        GamutBound([Percent(0.0), Percent(100.0)])
    )

    @property
    def hue(self):
        """Hue channel."""

        return self._coords[0]

    @hue.setter
    def hue(self, value):
        """Shift the hue."""

        self._coords[0] = self._handle_input(value)

    @property
    def saturation(self):
        """Saturation channel."""

        return self._coords[1]

    @saturation.setter
    def saturation(self, value):
        """Saturate or unsaturate the color by the given factor."""

        self._coords[1] = self._handle_input(value)

    @property
    def lightness(self):
        """Lightness channel."""

        return self._coords[2]

    @lightness.setter
    def lightness(self, value):
        """Set lightness channel."""

        self._coords[2] = self._handle_input(value)

    @classmethod
    def null_adjust(cls, coords, alpha):
        """On color update."""

        if coords[1] == 0:
            coords[0] = util.NaN
        return coords, alpha

    @classmethod
    def _to_srgb(cls, parent, hsl):
        """To sRGB."""

        return okhsl_to_srgb(hsl)

    @classmethod
    def _from_srgb(cls, parent, srgb):
        """From sRGB."""

        return srgb_to_okhsl(srgb)

    @classmethod
    def _to_xyz(cls, parent, hsl):
        """To XYZ."""

        return Oklab._to_xyz(parent, okhsl_to_oklab(hsl))

    @classmethod
    def _from_xyz(cls, parent, xyz):
        """From XYZ."""

        return oklab_to_okhsl(Oklab._from_xyz(parent, xyz))


class Okhsv(Cylindrical, Space):
    """Okhsv class."""

    SPACE = "okhsv"
    SERIALIZE = ("--okhsv",)
    CHANNEL_NAMES = ("hue", "saturation", "value", "alpha")
    DEFAULT_MATCH = re.compile(RE_DEFAULT_MATCH.format(color_space='|'.join(SERIALIZE), channels=3))
    WHITE = "D65"
    GAMUT_CHECK = "srgb"

    RANGE = (
        GamutBound([Angle(0.0), Angle(360.0)]),
        GamutBound([Percent(0.0), Percent(100.0)]),
        GamutBound([Percent(0.0), Percent(100.0)])
    )

    @property
    def hue(self):
        """Hue channel."""

        return self._coords[0]

    @hue.setter
    def hue(self, value):
        """Shift the hue."""

        self._coords[0] = self._handle_input(value)

    @property
    def saturation(self):
        """Saturation channel."""

        return self._coords[1]

    @saturation.setter
    def saturation(self, value):
        """Saturate or unsaturate the color by the given factor."""

        self._coords[1] = self._handle_input(value)

    @property
    def value(self):
        """Value channel."""

        return self._coords[2]

    @value.setter
    def value(self, value):
        """Set value channel."""

        self._coords[2] = self._handle_input(value)

    @classmethod
    def null_adjust(cls, coords, alpha):
        """On color update."""

        if coords[1] == 0:
            coords[0] = util.NaN
        return coords, alpha

    @classmethod
    def _to_srgb(cls, parent, hsl):
        """To sRGB."""

        return okhsv_to_srgb(hsl)

    @classmethod
    def _from_srgb(cls, parent, srgb):
        """From sRGB."""

        return srgb_to_okhsv(srgb)

    @classmethod
    def _to_xyz(cls, parent, hsl):
        """To XYZ."""

        return Oklab._to_xyz(parent, okhsv_to_oklab(hsl))

    @classmethod
    def _from_xyz(cls, parent, xyz):
        """From XYZ."""

        return oklab_to_okhsv(Oklab._from_xyz(parent, xyz))


class Color(ColorOrig):
    """Color with Okhsl."""

    CS_MAP = copy.copy(ColorOrig.CS_MAP)
    CS_MAP["okhsl"] = Okhsl
    CS_MAP["okhsv"] = Okhsv


Color("color(--hsl 240 100% 50%)").convert('okhsl')
Color("color(--hsl 240 100% 50%)").convert('okhsv')

Color("color(--hsl 0 0% 100%)").interpolate(
    "color(--hsl 240 100% 50%)",
    space='hsl'
)

Color("color(--okhsl 0 0% 100%)").interpolate(
    "color(--okhsl 264 100% 37%)",
    space='okhsl'
)

Color("color(--okhsv 0 0% 100%)").interpolate(
    "color(--okhsv 264 100% 100%)",
    space='okhsv'
)
