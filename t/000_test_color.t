#!/usr/bin/perl

use v5.12;
use warnings;
use lib 'lib', '../lib/', '.', './t';
use Test::More tests => 14;
use Test::Builder::Tester;
use Test::Color;

test_out("ok 1 - is_tuple runs");
is_tuple([1,1,1], [1,1,1], [qw/r g b/], 'is_tuple runs');
test_test("simplest is_tuple case runs");

test_out("not ok 1");
test_err("# 'is_tuple' got not enough arguments");
test_fail(+1);
is_tuple([1,1,1], [1,1,1], [qw/r g b/]);
test_test("is_tuple checks if it got enough arguments");

test_out("not ok 1 - C");
test_err("# failed test: C - got values that are not a tuple (ARRAY ref)");
test_fail(+1);
is_tuple(1, [1,1,1], [qw/r g b/], 'C');
test_test("is_tuple checks if got values in an ARRAY");

test_out("not ok 1 - D");
test_err("# failed test: D - expected values are not a tuple (ARRAY ref)");
test_fail(+1);
is_tuple([1,1,1], 1, [qw/r g b/], 'D');
test_test("is_tuple checks if expected values are in an ARRAY");

test_out("not ok 1 - E");
test_err("# failed test: E - axis names are not in a tuple (ARRAY ref)");
test_fail(+1);
is_tuple([1,1,1], [1,1,1], 'red', 'E');
test_test("is_tuple checks if axis names are in an ARRAY");

test_out("not ok 1 - F");
test_err("# failed test: F - got more values than axis names (3)");
test_fail(+1);
is_tuple([1,1,1,1], [1,1,1], [qw/r g b/], 'F');
test_test("is_tuple checks if result tuple has not too much of values");

test_out("not ok 1 - G");
test_err("# failed test: G - got less values than axis names (3)");
test_fail(+1);
is_tuple([1,1], [1,1,1], [qw/r g b/], 'G');
test_test("is_tuple checks if result tuple has not enough values");

test_out("not ok 1 - H");
test_err("# failed test: H - expected value tuple has more values than axis names (3)");
test_fail(+1);
is_tuple([1,1,1], [1,1,1,1], [qw/r g b/], 'H');
test_test("is_tuple checks if expected tuple has not too much of values");

test_out("not ok 1 - I");
test_err("# failed test: I - expected value tuple has less values than axis names (3)");
test_fail(+1);
is_tuple([1,1,1], [1,1], [qw/r g b/], 'I');
test_test("is_tuple checks if expected tuple has not enough values");

test_out("not ok 1 - J");
test_err("# failed test: J - expected r value of 1 but got 0.9");
test_fail(+1);
is_tuple([0.9,1,1], [1,1,1], [qw/r g b/], 'J');
test_test("is_tuple checks if one value is not as expected");

test_out("not ok 1 - K");
test_err("# failed test: K - red value I got is not a number");
test_fail(+1);
is_tuple(['-',1,1], [1,1,1], [qw/red g b/], 'K');
test_test("is_tuple checks if one value is not a number");

test_out("not ok 1 - L");
test_err("# failed test: L - red value I got is not a number, green value I got is not a number, blue value I got is not a number");
test_fail(+1);
is_tuple(['-','1.','2b'], [1,1,1], [qw/red green blue/], 'L');
test_test("is_tuple checks if all values are numbers");

test_out("not ok 1 - M");
test_err("# failed test: M - expected g value of 1 but got 0.1, expected b value of 1 but got 0.2");
test_fail(+1);
is_tuple([1,.1,.2], [1,1,1], [qw/r g b/], 'M');
test_test("is_tuple checks if two values are not as expected");

test_out("not ok 1 - N");
test_err("# failed test: N - expected r value of 1 but got 0, expected g value of 1 but got 0, expected b value of 1 but got 0");
test_fail(+1);
is_tuple([0,0,0], [1,1,1], [qw/r g b/], 'N');
test_test("is_tuple checks if all values are not as expected");

done_testing;

