use strict;
package Tree::Fat;

use vars qw($VERSION @ISA @EXPORT);

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);
@EXPORT = qw();
$VERSION = '0.04';

bootstrap Tree::Fat $VERSION;

1;
__END__

=head1 NAME

Tree::Fat - Perl Extension to Implement Fat-Node Trees

=head1 SYNOPSIS

  use Tree::Fat

  my $t = new Tree::Fat();
  $t->STORE('key', 'value');

or

  1. C<tvgen.pl -p PREFIX>

  2. Edit C<PREFIXtv.tmpl>

  3. Compile and link into your own application!

=head1 DESCRIPTION

Implements object-oriented trees using algorithms adapted from b-trees
and AVL trees (without resorting to yucky C++).  Fat-node trees are
not the best for many niche applications, but they do have excellent
all-terrain performance.

 TYPE       Speed       Flexibility  Scales     Memory   Keeps-Order
 ---------- ----------- ------------ ---------- -------- ------------
 Arrays     fastest     so-so        not good   min      yes
 Hashes     fast        good         so-so      so-so    no
 Fat-Trees  medium      silly        big        varies   yes

And if you are interested in using I<persistent> trees in perl (and
even leaving SQL behind), then you might want to check out the
C<ObjStore> extension by the same author!

=head1 CURSOR BEHAVIOR

The only way to access a tree is via a cursor.  Cursors behavior is
derived from the principle of least-surprise (rather than efficiency).

Both cursors and trees store a version number.  If you modify the same
tree with more than one cursor, you can get mismatched versions.  If
there is a mismatch, an exception is thrown.

If you allow duplicate keys, seek always returns the first key that
matches.  For example, the cursor will match at the first instance of
'c': (a,b,*c,c,c,d,e).

Complete cursor behavior ridiculously complicated and cannot be
explained in one sentence.  The method C<tc_happy> in C<tv.code> gives
a full listing of valid states and constraints.

=head1 EMBEDDING API

  XPVTV *init_tv(XPVTV *tv);
  void free_tv(XPVTV *tv);
  void tv_clear(XPVTV *tv);
  void tv_insert(TcTV_T tv, TnKEY_T key, TnDATA_T *data);
  int tv_fetch(TcTV_T tv, TnKEY_T, TnDATA_T *out);
  void tv_delete(TcTV_T tv, TnKEY_T key);
  void tv_treestats(TcTV_T tv, double *depth, double *center);

  XPVTC *init_tc(XPVTC *tc, TcTV_T tv);
  void free_tc(XPVTC *tc);
  void tc_reset(XPVTC *tc);
  void tc_step(XPVTC *tc, I32 delta);
  TnKEY_T tc_fetch(XPVTC *tc, TnDATA_T *out);
  void tc_store(XPVTC *tc, TnDATA_T *data);
  int tc_seek(XPVTC *tc, TnKEY_T key);
  void tc_insert(XPVTC *tc, TnKEY_T key, TnDATA_T *data);
  void tc_delete(XPVTC *tc);
  void tc_moveto(XPVTC *tc, I32 xto);
  I32 tc_pos(XPVTC *tc);

=head1 PERFORMANCE

=over 4

=item * Average Fill

The number elements in the collection divided by the number of
available slots.  Higher is better.  (Perl built-in hashes max out
around 50-60%.  Hash tables generally max out at around 70%.)

=item * Average Depth

The average number of nodes to be inspected during a search.  Lower is
better.

=item * Average Centering

Each fat-node is essentially an array of elements.  This array is
allocated contiguously from the available slots.  The best arrangement
(for insertions & deletions) is if the block of filled slots is
centered.

=back

[Earlier releases were not measured or tuned for performance.]

=head1 REFERENCES

=over 4

=item * http://paris.lcs.mit.edu/~bvelez/std-colls/cacm/cacm-2455.html

Author: Foster, C. C. 

A generalization of AVL trees is proposed in which imbalances up to
(triangle shape) is a small integer. An experiment is performed to
compare these trees with standard AVL trees and with balanced trees on
the basis of mean retrieval time, of amount of restructuring expected,
and on the worst case of retrieval time. It is shown that, by
permitting imbalances of up to five units, the retrieval time is
increased a small amount while the amount of restructuring required is
decreased by a factor of ten. A few theoretical results are derived,
including the correction of an earlier paper, and are duly compared
with the experimental data. Reasonably good correspondence is found.

CACM August, 1973 

=item * http://www.imada.ou.dk/~kslarsen/Papers/AVL.html

  AVL Trees with Relaxed Balance 
  Kim S. Larsen 
  Proceedings of the 8th International Parallel Processing Symposium,
  pp. 888-893, IEEE Computer Society Press, 1994. 

AVL trees with relaxed balance were introduced with the aim of
improving runtime performance by allowing a greater degree of
concurrency. This is obtained by uncoupling updating from
rebalancing. An additional benefit is that rebalancing can be
controlled separately. In particular, it can be postponed completely
or partially until after peak working hours.

We define a new collection of rebalancing operations which allows for
a significantly greater degree of concurrency than the original
proposal. Additionally, in contrast to the original proposal, we prove
the complexity of our algorithm.  If N is the maximum size the tree
could ever have, we prove that each insertion gives rise to at most
floor(log_phi(N + 3/2) + log_phi(sqrt(5)) - 3) rebalancing operations
and that each deletion gives rise to at most floor(log_phi(N + 3/2) +
log_phi(sqrt(5)) - 4) rebalancing operations, where phi is the golden
ratio.

=back

=head1 PUBLIC SOURCE CODE

The source code is being released in a malleable form to encourage as
much testing as possible.  Bugs in fundemental collections are simply
UNACCEPTABLE and it is hard to trust a single vendor to debug their
code properly.  (And worse to have each vendor do their own
implementation!)

Get it at http://www.perl.com/CPAN/authors/id/JPRIT/!

=head1 AUTHOR

Copyright © 1997-1998 Joshua Nathaniel Pritikin.  All rights reserved.

This package is free software and is provided "as is" without express
or implied warranty.  It may be used, redistributed and/or modified
under the terms of the Perl Artistic License (see
http://www.perl.com/perl/misc/Artistic.html)

=cut
