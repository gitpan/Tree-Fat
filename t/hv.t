# -*-perl-*- please

BEGIN { print "1..5\n"; }

use lib './t';
use test;
use strict;

package Tree::Fat;

sub TIEHASH {
    bless Tree::Fat->new(), shift;
}

sub new_hash {
    my %fake;
    tie %fake, shift;
    \%fake;
}

package main;

my $pkg = 'Tree::Fat';

my $h = $pkg->new_hash;
for (1..5) { $h->{$_} = 2*$_ }
ok($h->{1} == 2);
ok(exists $h->{4});
delete $h->{3};
ok(join('', keys %$h) eq '1245');
ok(join('', values %$h) eq '24810');
%$h = ();
ok(!exists $h->{1});
