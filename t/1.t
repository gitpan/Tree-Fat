# -*-perl-*- please

#    Tree::Fat::Test::debug(0xff);

BEGIN { print "1..35\n"; }
END { print "not ok 1\n" if !$test; }

use IO::Handle;
use lib './t';
use test;
use strict;

my $global;
my %stats;
sub sum_stats {
    my $c = shift;
    my %st = $c->stats();
    for my $k (keys %st) {
	$stats{$k} ||= 0;
	$stats{$k} += $st{$k};
    }
}

print "ok 1\n"; ++$test;

#--------------------------------------

sub null_test {
    my $o = shift->new;

    ok(!defined $o->fetch('bogus'));
    $o->delete('bogus');

    my $c = $o->new_cursor;

    eval { $c->step(0); };
    ok($@ =~ m'step by zero');
    undef $@;
    eval { $c->store('oops') };
    ok($@ =~ m'unset cursor');
    undef $@;

    ok(!$c->seek('bogus'));
    ok($c->pos eq -1);
    ok(!defined $c->each(1));
    ok($c->pos eq -1);

    $o->insert(2,2);
    $c->moveto('start');
#    $c->dump;
    $c->insert(1,1);
    ok(($c->fetch)[1] == 1);
    $c->moveto('end');
    ok($c->pos() == 2);
    $c->insert(3,3);
#    $o->dump;
    ok(($c->fetch)[1] == 3);
    $c->moveto(-1);
    ok($c->pos()==-1);
    $c->seek(1.5);
    eval { $c->pos() };
    ok($@ =~ m'unpositioned') or warn $@;
    undef $@;

    ok(!defined $o->fetch('bogus'));
    $o->delete('bogus');
    sum_stats($c);
}

#--------------------------------------

sub easy_test {
    my $o = shift->new;
    $o->insert('chorze', 'fwaz');
    $o->insert('fwap', 'fwap');
    $o->insert('snorf', 'snorf');

    my $c = $o->new_cursor;
    ok($c->seek('snorf'));
    my @r = $c->fetch();
    ok($r[0] eq 'snorf') or warn $r[0];
    ok($r[1] eq 'snorf') or warn $r[1];

    $c->store('borph');
    @r = $c->fetch();
    ok($r[0] eq 'snorf' and $r[1] eq 'borph') or warn @r;
    
    $c->step(1);
    ok(!defined $c->fetch());
    $c->step(-1);
    @r = $c->fetch();
    ok($r[0] eq 'snorf' and $r[1] eq 'borph') or warn @r;

    for (qw(a chorze fwap snorf)) { $o->delete($_); }
    ok(($o->stats)[0]==0 and ($o->stats)[1]==0) or warn $o->stats;

    eval { $c->fetch() };
    ok($@ =~ m'out of sync') or warn $@;
    undef $@;
    sum_stats($c);
}

#--------------------------------------

sub insert_test {
    my $o = shift->new;
    my $c = $o->new_cursor;
    my $p = permutation([qw(a b c e f g)]);
    while (my @vector = &$p) {
	for my $q ('b','d','f') { $o->insert($q,$q); }
	for my $kv (@vector) {
	    $o->insert($kv, $kv);
	}
	$c->moveto('start');
#	$c->dump;
	my @done;
	while (my ($k,$v) = $c->each(1)) {
#	    $c->dump;
#	    warn "$k\n";
	    push(@done, $k);
	}
	die @done if join('',@done) ne 'abbcdeffg';
	$o->clear;
    }
    ok(1);
    sum_stats($c);
}

sub insert2_test {
    my $o = shift->new;
    my $c = $o->new_cursor;

    # insert at start & end
    $o->insert(1,1);
    $c->moveto('end');
    $c->insert(2,2);
    $c->moveto('start');
    $c->insert(0,0);
    ok(join('', $o->values) eq '210');

    # keep position & direction across splits?
    $o->clear;
    $c->moveto(-1);
    for (1..4) { $c->insert($_,$_); }
    $c->moveto(3);
    $c->step(-1);
    $c->insert(5,5);
    $c->step(-1);
    ok($c->pos() == 1);

    $o->clear;
    $c->moveto(-1);
    for (1..4) { $c->insert($_,$_); }
    $c->moveto(2);
    $c->insert(5,5);
    $c->step(1);
    ok($c->pos() == 3);

    # is treecache updated if top node splits?
    $c->step(-1);
    for (6..9) { $c->insert($_,$_); }
    ok(1);
    sum_stats($c);
}

#--------------------------------------

sub cursor_test {
    my $o = shift->new;
    my @e = qw(a b c d e f g h i j k l m n o p q r s t u v w x y z);
    my $max = $#e;
    for (@e) { $o->insert($_, $_); }

    # forward
    my $c = $o->new_cursor;
    $c->moveto('start');
    for (my $r=0; $r <= @e+2; $r++) {
	my @r=();
#	warn $r;
	for (my $s=0; $s <= $r; $s++) {
	    push(@r, ($c->each(1))[0]);
#	    $c->dump;
	}
	for (my $s=0; $s <= $r; $s++) { 
	    push(@r, ($c->each(-1))[0]);
#	    $c->dump;
	}
	my $mess1 = join('',@r);
	my @tmp = (@e[0..$r], reverse(@e[0..($r-1)]));
	my $mess2 = join('', map {defined $_? $_ : '' } @tmp);
	if ($mess1 ne $mess2) {
	    die "Expecting '$mess2', got '$mess1'";
	}
#	warn "$mess1\n";
    }
    ok(1);

    # backward
    $c->moveto('end');
    for (my $r=0; $r <= @e+2; $r++) {
	my @r=();
#	warn $r;
	for (my $s=0; $s <= $r; $s++) {
	    push(@r, ($c->each(-1))[0]);
#	    warn "each-1\n"; $c->dump;
	}
	for (my $s=0; $s <= $r; $s++) { 
	    push(@r, ($c->each(1))[0]);
#	    warn "each1\n"; $c->dump;
	}
	my $mess1 = join('',@r);
	my $ex = $max-$r;
	my $mess2 = join('', reverse(@e[($ex<0?0:$ex)..$max]),
			 @e[($ex+1<0?0:$ex+1)..$max]);
	if ($mess1 ne $mess2) {
	    die "Expecting '$mess2', got '$mess1'";
	}
#	warn "$mess1\n";
    }
    ok(1);
    sum_stats($c);
}

#--------------------------------------

sub seek_test {
    my $o = shift->new;
    my @l1 = qw/b c d e f g h i j k/;
    my @l2 = qw/l m n o p q r s t u v/;
    for my $e (reverse @l1) { $o->insert($e,$e); }
    for my $e (@l2) { $o->insert($e,$e); }
    my $c = $o->new_cursor;

    my @all = ('a',@l1,@l2);
    for (my $t=0; $t < @all; $t++) {
	$c->seek("$all[$t]+");
#	$o->dump;
#	warn "seek $all[$t]+";
#	$c->dump;
	$c->step(-1);
#	warn "step -1";
#	$c->dump;
	if ($t == 0) {
	    die $t if $c->fetch() || $c->pos() != -1;
	} else {
	    die $t if ($c->fetch())[1] ne $all[$t];
	}
    }
    for (my $t=0; $t < @all; $t++) {
	$c->seek("$all[$t]+");
#	$o->dump;
#	warn "seek $all[$t]+";
#	$c->dump;
	$c->step(1);
#	warn "step 1"; $c->dump;
	if ($t == @all-1) {
	    die $t if $c->fetch() || $c->pos() != ($o->stats())[0];
	} else {
	    die $t if ($c->fetch())[1] ne $all[$t+1];
	}
    }
    sum_stats($c);
}

sub seek2_test {
    my $o = shift->new;
    $o->clear;
    my $c = $o->new_cursor;
    for (qw/b b c/) { $o->insert($_,$_) }
    $c->seek('b');
    $c->step(-1);
    ok($c->pos() == -1);

    $o->insert('a','a');
    $c->seek('b');
    $c->step(-1);
    ok(($c->fetch())[1] eq 'a');
    sum_stats($c);
}

#--------------------------------------

sub delete_test {
    # delete just one element
    my $o = shift->new;
    my $c = $o->new_cursor;
    for my $targ (-10 .. 10) {
	$o->clear;
	for (my $n=1; $n < 10; $n += 2) {
	    $o->insert("$n", $n); 
	    $o->insert("-$n", -$n);
	}
	for (my $n=2; $n <= 10; $n += 2) {
	    $o->insert("$n", $n); 
	    $o->insert("-$n", -$n);
	}
	$o->insert(0,0);
	$c->seek($targ);
#	$o->dump;
#	$c->dump;
	my $pos = $c->pos();
	$c->delete();
	# 9 is the last element due to strcmp
	if ($c->pos() != $pos) {
	    $o->dump;
	    $c->dump;
	    die "deleted $targ at $pos: moved to ".$c->pos();
	}
	for my $n (-10 .. 10) {
	    $c->seek($n);
	    my $got = ($c->fetch())[1];
#	    my $got = $o->fetch($n);
	    if ($n != $targ) {
		if ($got != $n) {
		    $o->dump;
		    $c->dump;
		    die "$targ: got $got, expected $n";
		}
	    } else {
		if ($got) {
		    die "$targ: got $got, expected () at $n";
		}
	    }
	}
    }
    ok(1);
    sum_stats($c);
}

sub delete_test2 {
    # delete all elements 1-by-1
    my $o = shift->new;
    my $c = $o->new_cursor;
    my @mirror;
    $o->clear;
    srand(1);
    for my $n (1..600) {
	my $z = int(rand(600));
	$o->insert($z,$z);
	push(@mirror, $z);
    }
    if (join(' ',sort(@mirror)) ne join(' ', sort($o->keys()))) {
	die "mismatch keys";
    }
    if (join(' ',sort(@mirror)) ne join(' ', sort($o->values()))) {
	die "mismatch values";
    }
    while (@mirror) {
#	$o->dump;
#	warn scalar(@mirror);
	for (1..20) {
	    $o->delete(pop @mirror);
	}
	die "delete mismatch" if ($o->stats)[0] != @mirror;
	for (my $x=0; $x < @mirror; $x++) {
	    die "delete mismatch" if !$c->seek($mirror[$x]);
	}
    }
    sum_stats($c);
    ok(1);
}

#--------------------------------------

sub moveto_test {
    my $o = shift->new;
    for my $n (45..90) { $o->insert("$n", $n); }
    for my $n (10..44) { $o->insert("$n", $n); }
#    $o->dump;
    my $c = $o->new_cursor;
    for my $n (10..90) {
	$c->moveto($n-10);
	if (($c->fetch)[0] != $n) {
	    $o->dump;
	    $c->dump;
	    die $n;
	}
    }
    ok(1);
    sum_stats($c);
}

sub step_test {
    my $o = shift->new;
    my $max = 100;
    for my $n (1..$max) { $o->insert($n,$n); }
    my $c = $o->new_cursor;
    for my $ss (1..20) {
	my $pos=-1;
	$c->moveto('start');
	while (1) {
	    $c->step($ss);
	    $pos += $ss;
	    last if $c->pos == $max;
	    if ($pos != $c->pos) {
		$c->dump;
		die $c->pos;
	    }
	}
	$pos = 100;
	$c->moveto('end');
	while (1) {
	    $c->step(-$ss);
	    $pos -= $ss;
	    last if $c->pos == -1;
	    if ($pos != $c->pos) {
		$c->dump;
		die $pos;
	    }
	}
    }
    ok(1);
    sum_stats($c);
}

#--------------------------------------

# Should split to multiple files once the coverage analysis is
# restartable.

my $tv = 'Tree::Fat::Test';

$tv->new->new_cursor;

null_test($tv);
easy_test($tv);
$global = "$ {tv}::Remote"->global();
cursor_test($tv);
warn ":seek\n";
seek_test($tv);
seek2_test($tv);
warn ":moveto\n";
moveto_test($tv);
step_test($tv);
warn ":insert\n";
insert_test($tv);
insert2_test($tv);
#    Tree::Fat::Test::debug(4);
warn ":delete\n";
delete_test($tv);
delete_test2($tv);

STDERR->print("Cursor Stats:\n");
sum_stats($global);
for my $k (sort keys %stats) {
    STDERR->printf("  %-12s %7d\n", $k, $stats{$k});
}

Tree::Fat::Test::case_report();

__END__;

Cursor Stats:
  copyslot       12949
  delete           524
  insert          6956
  rotate1           50
  rotate2           13
  stepnode        5280
