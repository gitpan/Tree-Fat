#!/nw/dev/usr/bin/perl -w

use Getopt::Std;

sub usage {
    print "usage: ccovscan.pl file.c > file.cov\n";
    exit;
}

#my %opts;
#getopts('s', \%opts);

&usage if @ARGV != 1;

package Chunk;

sub new {
    my ($class, $str, $line, $live) = @_;
    bless {str=>$str, line=>$line, live=>$live}, $class
}

sub str {
    my ($o, $new) = @_;
    $o->{str} = $new if @_==2;
    $o->{str};
}
sub line { shift->{line} }
sub live { shift->{live} }

package main;

use IO::File;
use Text::Balanced qw/extract_bracketed/;
use vars qw/$CASE $err/;

$CASE=0;
$err=0;

my @flowset = qw/ if for do while return break continue goto exit /;
my $sp = '[ \t]*';
my $caseRE = $sp.'CASE\([\d ]+\)'.$sp.'\;'.$sp;
my $flowRE;
#warn $caseRE;

sub set_flow {
    $flowRE = '\n('.$sp.")(".join('|',@flowset).") (?!\w)";
#    warn $flowRE;
}
&set_flow;

sub stmts {
    my ($stmts, $level) = @_;
    for (my $s=0; $s < @$stmts; $s++) {
	if (ref $stmts->[$s] ne 'Chunk') {
	    stmts($stmts->[$s], $level+1);
	    next;
	}
	next if $level == 0;
	my $line = $stmts->[$s]->line;
	my $text = $stmts->[$s]->str;
	next if $text =~ m/^[{}]$/;
	my $last = $line + ($text =~ tr/\n/\n/);
	my $where = "$line-$last:";
	
	if ($text =~ m/ \s switch /sx) {
	    warn "$where switch is not yet supported:\n$text\n";
	    ++$err;
	}
	if ($text =~ m/ \s (if | else | SCOPE) (.*?) \; /sx) {
	    warn "$where '$1' statement missing block:\n$text\n";
	    ++$err;
	}
	if ($text =~ m/ \s if \s* ( \( .* ) $/sx) {
	    my @m = extract_bracketed($1, "\(");
	    if ($m[0] =~ m{ \|\| }sx and $m[0] !~ m{ /\*OK\*/ }sx) {
		warn "$where remove confusing || from 'if' test:\n$text\n";
		++$err;
	    }
	}
	if ($text =~ m/ \s for \s* ( \( .* ) $/sx) {
	    my @m = extract_bracketed($1, "\(");
	    if ($m[1] =~ m/;/s) {
		warn "$where 'for' statement missing block:\n$text\n";
		++$err;
	    }
	}
	if ($text =~ m/ \s while \s* ( \( .* ) $/sx) {
	    my @m = extract_bracketed($1, "\(");
	    if ($m[1] =~ m/\w+ \s* ;/sx) {
		warn "$where 'while' statement missing block:\n$text\n";
		++$err;
	    }
	}
    }
    return if $level == 0;

    for (my $s=0; $s < @$stmts; $s++) {
	next if ref $stmts->[$s] ne 'Chunk';
	my $text = $stmts->[$s]->str;
	next if $text =~ m/^[{}]$/;
	
	my @rest = @$stmts[$s+1..$s+4]; # '{' $nested '}' $next
	pop @rest while (@rest and !defined $rest[$#rest]);

	next if ($text =~ m/^ \s* (else | SCOPE) \s* $/sx or
		 $text =~ m{^ \s* else \s+ if }sx or
		 $text =~ m/^ \s* $/sx);

#	$text =~ s/\n $caseRE \n/\n/sxg;

	eval {
	    if (@rest==4 and
		$text =~ m/ \W if \W /sx and $rest[3]->str !~ m/ \W else \W /sx) {
		$rest[2]->str("\} else { CASE($CASE); }");
		++$CASE;
	    }
	};
	if ($@) {
	    die $@.join(' ', map {defined $_ ? $_:'undef'} @rest);
	}
	
	if ($text =~ m/^ \s* while \( /) {
	} elsif ($text =~ s/$flowRE/\n$1CASE($CASE); $2/sx) {
	    ++$CASE;
	} elsif ($text =~ s/\n ($sp) ([^\n]*) \n ($sp) $/\n$1$2 CASE($CASE);\n$3/sx) {
	    ++$CASE;
	}
	
	$stmts->[$s]->str($text);
    }
}

sub block_tree {
    my ($text, $st, $level) = @_;
    ++ $level;
    my @ready;
    my $save = sub {
	my ($s, $yes) = @_;
	my $c = new Chunk($s, $st->{line}, $yes);
	push(@ready, $c);
	$st->{line} += $s =~ tr/\n/\n/;
	$c;
    };
    while (1) {
#	$text =~ s/^ ([\s\}]*) / $save->($1) /sex;
	if ($text =~ s/^ (.*?) \{ /\{/sx ) {
	    if (length $1) {
		$save->($1, $level > 1);
	    }
	    my @match = extract_bracketed($text, "\{");
	    if ($match[0]) {
		my $block = $match[0];
		$block =~ s/^ \{ (.*) \} $/$1/sx;
		$save->('{', 0);
		push(@ready, block_tree($block, $st, $level));
		$save->('}', 0);
		$text = $match[1];
	    }
	} else {
	    my $c = $save->($text, $level > 1);
	    last;
	}
    }    
    \@ready;
}

sub print_tree {
    my ($t) = @_;
    for my $b (@$t) {
	if (ref $b eq 'Chunk') { print $b->str; }
	else { print_tree($b); }
    }
}

sub go {
    # no support for multiple files yet
    for my $name (@ARGV) {
	print "static void CASE(int dd);";
	my $fh = new IO::File;
	$fh->open($name) or die "open $name: $!";
	my $st = { name => $name, text=>'', line=>0, on=>0 };
	my $line=0;
	while (defined(my $l = <$fh>)) {
	    ++$line;

	    if ($l =~ m, \/\*+ \s* COVERAGE\: \s* (.*?) \*+\/ ,x) {

		my ($cmd, @args) = split(/\s+/, $1);
		if ($cmd =~ m/^off$/) {
		    die "Matching 'on' directive not found at $line in $name" 
			if !$st->{on};
		    my $tree = block_tree($st->{text}, $st, 0);
		    die "errors" if $err;
		    stmts($tree, 0);
		    print_tree($tree);
		    $st->{on} = 0;
		    $st->{text} = '';
		    
		} elsif ($cmd =~ m/^on$/) {
		    $st->{on} = 1;
		    $st->{line} = $line+1;

		} elsif ($cmd =~ m/^jump$/) {
		    push(@flowset, @args);
		    &set_flow;
		    
		} else {
		    warn "Unknown COVERAGE command $cmd\n";
		}
		print $l;
		next;
	    }

	    if ($st->{on}) {
#		$l =~ s| \} $sp else $sp \{ $caseRE \} |\}|sx;
		$st->{text} .= $l;
	    } else {
		print $l;
	    }
	}
	print recorder($name, $CASE) if !$err;
    }
}

# assumes existance of 32bit (or better) unsigned long */
sub recorder {
    my ($file, $max) = @_;
    $file =~ tr/./_/;
    qq{
/***************************************** CCOV FLIGHT RECORDER */
#include <stdio.h>
#define CCOV_MAXCASE $max
#define CCOV_MASKLEN (1+CCOV_MAXCASE/32)
static unsigned long ccov_mask[CCOV_MASKLEN];
static int ccov_init=0;

static void
CASE(int dd)
{
  if (!ccov_init) {
    int mx;
    for (mx=0; mx < CCOV_MASKLEN; mx++) ccov_mask[mx]=0;
    ccov_init=1;
  }
  if (dd > CCOV_MAXCASE) {
    fprintf(stderr, "CCov: coverage test %d out of range(0..%d)\\n",
	    dd, CCOV_MAXCASE);
    abort();
  }
  *(ccov_mask+(dd>>5)) |= 1 << (dd & 0x1f);
}

void $ {file}_CCOV_REPORT()
{
  int mx;
  int missed=CCOV_MAXCASE;
  for (mx=0; mx < CCOV_MAXCASE; mx++) {
    if ((*(ccov_mask+(mx>>5)) & (1 << (mx & 0x1f))) ) {
	--missed;
    }
  }
  if (missed) {
      fprintf(stderr, "CCov: coverage for %s missed (%d/%d):\\n",
	     __FILE__, missed, CCOV_MAXCASE);
      for (mx=0; mx < CCOV_MAXCASE; mx++) {
	  if (! (*(ccov_mask+(mx>>5)) & (1 << (mx & 0x1f))) ) {
              fprintf(stderr, "%d ", mx);
          }
      }
      fprintf(stderr, "\\n");
  } else {
      fprintf(stderr, "CCov: perfect coverage for %s (%d/%d).\\n",
	     __FILE__, CCOV_MAXCASE, CCOV_MAXCASE);
  }
}
/*********************************** CCOV FLIGHT RECORDER (END) */
};
}

go();

__END__;

=head1 SYNOPSIS

  ccovscan.pl code.c > covcode.c

=head1 DESCRIPTION

Scans the C/C++ source (before cpp) and inserts a call in each block
to record execution.  Designed to be as simple as possible.

Detects error prone constructs and forces you to rewrite them in a
simpler form.  Many of these ideas came from study of the highly
regarded perl5 source code.  (And as a side-effort makes C/C++ easy
for a simple parser to grok.)

This approach to coverage analysis is not close to fullproof!  Just
because you exercise every code path does not mean that you have
exercised all possible states.  For example,

  char
  fetch_char(int xx)
  {
    static char *string = "Dr. Zorph Trokien";
    if (xx < 0) {
      return 0;
    } else {
      return string[xx];
    }
  }

You still have to be smart about writing your code (and test scripts).

=head1 CCOV Source Code Directives

=over 4

=item * /* COVERAGE: on */

Turns on coverage instrumentation.

=item * /* COVERAGE: off */

Turns off coverage instrumentation.

=item * /* COVERAGE: jump myexit croak panic */

Adds to the list of functions that cause a change in execution flow.

=item * ||

If you use || in an C<if> test, you can avoid the warning by adding an
/*OK*/ comment inside the C<if> expression.

=item * ?:

The ?: operator is not checked.

=back

=head1 API

=over 4

=item * file_c_CCOV_REPORT()

=back

=head1 TODO

Split into a separate distribution.

Persist results between runs.  MD5/SHA checksum on code to determine
when to reset results cache.

=head1 AUTHOR

Copyright © 1997-1998 Joshua Nathaniel Pritikin.  All rights reserved.

This package is free software and is provided "as is" without express
or implied warranty.  It may be used, redistributed and/or modified
under the terms of the Perl Artistic License (see
http://www.perl.com/perl/misc/Artistic.html)

=cut
