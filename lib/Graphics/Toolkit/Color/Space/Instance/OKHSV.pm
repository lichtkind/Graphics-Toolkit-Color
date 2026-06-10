
# OKHSV color space by Björn Ottosson

package Graphics::Toolkit::Color::Space::Instance::OKHSV;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Space qw/gamma_correct mult_matrix_vector_3/;

my @D65 = (0.95047, 1, 1.08883); # illuminant

sub from_hsv {
    my ($xyz) = shift;
    my @xyz = map {$xyz->[$_] * $D65[$_]} 0 .. 2;
    my @lms = mult_matrix_vector_3([[ 0.8189330101, 0.3618667424,-0.1288597137],
                                    [ 0.0329845436, 0.9293118715, 0.0361456387],
                                    [ 0.0482003018, 0.2643662691, 0.6338517070]], @xyz);

    @lms = map {gamma_correct($_, 1/3)} @lms;

    my @lab = mult_matrix_vector_3([[ 0.2104542553,  0.7936177850, -0.0040720468],
                                    [ 1.9779984951, -2.4285922050,  0.4505937099],
                                    [ 0.0259040371,  0.7827717662, -0.8086757660]], @lms);
    $lab[1] += .5;
    $lab[2] += .5;
    return \@lab;
}
sub to_hsv {
    my (@lab) = @{$_[0]};
    $lab[1] -= .5;
    $lab[2] -= .5;
    my @lms = mult_matrix_vector_3([[ 1,  0.396338 ,  0.215804  ],
                                    [ 1, -0.105561 , -0.0638542 ],
                                    [ 1, -0.0894842, -1.29149   ]], @lab);

    @lms = map {gamma_correct($_, 3)} @lms;

    my @xyz = mult_matrix_vector_3([[ 1.22701  , -0.5578  , 0.281256 ],
                                    [-0.0405802,  1.11226 ,-0.0716767],
                                    [-0.0763813, -0.421482, 1.58616  ]], @lms);
    return [map {$xyz[$_] / $D65[$_]} 0 .. 2];
}

Graphics::Toolkit::Color::Space->new(
         name => 'OKHSV',
       family => 'HSV',
         axis => [qw/hue saturation value/], 
         type => [qw/angular linear linear/],
        range => [360, 1, 1],
    precision => 5,
      convert => {LinearRGB => [\&from_hsv, \&to_hsv]},
);



def okhsv_to_oklab(hsv):
    """Convert from Okhsv to Oklab."""

    h, s, v = hsv
    s /= 100
    v /= 100
    h = util.no_nan(h) / 360.0

    l = toe_inv(v)
    a = b = 0

    if l != 0 and s != 0:
        a_ = math.cos(2.0 * math.pi * h)
        b_ = math.sin(2.0 * math.pi * h)

        cusp = find_cusp(a_, b_)
        s_max, t_max = to_st(cusp)
        s_0 = 0.5
        k = 1 - s_0 / s_max

        # first we compute L and V as if the gamut is a perfect triangle:

        # L, C when v==1:
        l_v = 1 - s * s_0 / (s_0 + t_max - t_max * k * s)
        c_v = s * t_max * s_0 / (s_0 + t_max - t_max * k * s)

        l = v * l_v
        c = v * c_v

        # then we compensate for both toe and the curved top part of the triangle:
        l_vt = toe_inv(l_v)
        c_vt = c_v * l_vt / l_v

        l_new = toe_inv(l)
        c = c * l_new / l
        l = l_new

        # RGB scale
        rs, gs, bs = oklab_to_linear_srgb([l_vt, a_ * c_vt, b_ * c_vt])
        scale_l = util.nth_root(1.0 / max(max(rs, gs), max(bs, 0.0)), 3)

        l = l * scale_l
        c = c * scale_l

        a = c * a_
        b = c * b_

    return [l, a, b]


def oklab_to_okhsv(lab):
    """Oklab to Okhsv."""

    c = math.sqrt(lab[1] ** 2 + lab[2] ** 2)
    l = lab[0]

    h = util.NaN
    s = 0
    v = toe(l)

    if c != 0 and l != 0 and l != 1:
        a_ = lab[1] / c
        b_ = lab[2] / c

        h = 0.5 + 0.5 * math.atan2(-lab[2], -lab[1]) / math.pi

        cusp = find_cusp(a_, b_)
        s_max, t_max = to_st(cusp)
        s_0 = 0.5
        k = 1 - s_0 / s_max

        # first we find L_v, C_v, L_vt and C_vt
        t = t_max / (c + l * t_max)
        l_v = t * l
        c_v = t * c

        l_vt = toe_inv(l_v)
        c_vt = c_v * l_vt / l_v

        # we can then use these to invert the step that compensates for the toe and the curved top part of the triangle:
        rs, gs, bs = oklab_to_linear_srgb([l_vt, a_ * c_vt, b_ * c_vt])
        scale_l = util.nth_root(1.0 / max(max(rs, gs), max(bs, 0.0)), 3)

        l = l / scale_l
        c = c / scale_l

        c = c * toe(l) / l
        l = toe(l)

        # we can now compute v and s:
        v = l / l_v
        s = (s_0 + t_max) * c_v / ((t_max * s_0) + t_max * k * c_v)

    if s == 0:
        h = util.NaN

    return [util.constrain_hue(h * 360), s * 100, v * 100]
