#include "debtv.h"
#include "tietv.h"

debXPVTC *debtv_global_cursor=0;
tieXPVTC *tietv_global_cursor=0;

MODULE = Tree::Fat		PACKAGE = Tree::Fat

PROTOTYPES: ENABLE


void
new(CLASS)
	char *CLASS;
	PREINIT:
	tieXPVTV *tv;
	PPCODE:
	tv = tieinit_tv((tieXPVTV*) safemalloc(sizeof(tieXPVTV)));
	XPUSHs(sv_setref_pv(sv_newmortal(), CLASS, tv));

void
tieXPVTV::DESTROY()
	CODE:
	tiefree_tv(THIS);

SV*
FETCH(THIS, key)
	SV *THIS
	char *key
	PREINIT:
	SV *ret;
	PPCODE:
	if (!tietv_fetch(THIS, key, &ret))
	  ret = &sv_undef;
	XPUSHs(ret);

void
STORE(THIS, key, val)
	SV *THIS
	char *key
	SV *val
	PREINIT:
	tieXPVTC *tc;
	CODE:
	tiedTVREMOTE(tc, THIS);
	if (tietc_seek(tc,key)) {
	  tietc_store(tc,&val);
	} else {
	  tietc_insert(tc,key,&val);
	}

void
DELETE(THIS, key)
	SV *THIS
	char *key
	CODE:
	tietv_delete(THIS, key);

void
tieXPVTV::CLEAR()
	CODE:
	tietv_clear(THIS);

int
EXISTS(THIS, key)
	SV *THIS
	char *key
	PREINIT:
	tieXPVTC *tc;
	CODE:
	tiedTVREMOTE(tc, THIS);
	RETVAL = tietc_seek(tc,key);
	OUTPUT:
	RETVAL

char *
FIRSTKEY(THIS)
	SV *THIS
	PREINIT:
	tieXPVTC *tc;
	SV *out;
	CODE:
	tiedTVREMOTE(tc, THIS);
	tietc_moveto(tc,-1);
	tietc_step(tc,1);
	RETVAL = tietc_fetch(tc, &out);
	OUTPUT:
	RETVAL

char *
NEXTKEY(THIS, lastkey)
	SV *THIS
	char *lastkey
	PREINIT:
	tieXPVTC *tc;
	SV *out;
	CODE:
	tiedTVREMOTE(tc, THIS);
	/*STUPID HACK:  Can perl help manage cursors?! */
	tietc_seek(tc,lastkey);
	tietc_step(tc,1);
	RETVAL = tietc_fetch(tc, &out);
	OUTPUT:
	RETVAL

void
tieXPVTV::DESTORY()
	CODE:
	tiefree_tv(THIS);

void
unshift(THIS, val)
	SV *THIS
	SV *val
	PREINIT:
	tieXPVTC *tc;
	CODE:
	tiedTVREMOTE(tc,THIS);
	tietc_moveto(tc,-1);
	tietc_insert(tc, SvPV(val,na), &val);

void
push(THIS, val)
	SV *THIS
	SV *val
	PREINIT:
	tieXPVTC *tc;
	CODE:
	tiedTVREMOTE(tc,THIS);
	tietc_moveto(tc, 1<<30);
	tietc_insert(tc, SvPV(val,na), &val);

void
stats(THIS)
	SV *THIS;
	PREINIT:
	tieXPVTV *tv = (tieXPVTV*) SvIV((SV*)SvRV(THIS));
	double depth, center;
	PPCODE:
	tietv_treestats(THIS, &depth, &center);
	XPUSHs(sv_2mortal(newSVpv("fill",0)));
	XPUSHs(sv_2mortal(newSViv(tieTvFILL(tv))));
	XPUSHs(sv_2mortal(newSVpv("max",0)));
	XPUSHs(sv_2mortal(newSViv(tieTvMAX(tv))));
	XPUSHs(sv_2mortal(newSVpv("depth",0)));
	XPUSHs(sv_2mortal(newSVnv(depth)));
	XPUSHs(sv_2mortal(newSVpv("center",0)));
	XPUSHs(sv_2mortal(newSVnv(center)));

void
opstats(...)
	PREINIT:
	tieXPVTC *tc = tietv_global_cursor;
	PPCODE:
	XPUSHs(sv_2mortal(newSVpv("rotate1",0)));
	XPUSHs(sv_2mortal(newSViv(tieTcSTAT(tc, tieTCS_ROTATE1))));
	XPUSHs(sv_2mortal(newSVpv("rotate2",0)));
	XPUSHs(sv_2mortal(newSViv(tieTcSTAT(tc, tieTCS_ROTATE2))));
	XPUSHs(sv_2mortal(newSVpv("copyslot",0)));
	XPUSHs(sv_2mortal(newSViv(tieTcSTAT(tc, tieTCS_COPYSLOT))));
	XPUSHs(sv_2mortal(newSVpv("stepnode",0)));
	XPUSHs(sv_2mortal(newSViv(tieTcSTAT(tc, tieTCS_STEPNODE))));
	XPUSHs(sv_2mortal(newSVpv("insert",0)));
	XPUSHs(sv_2mortal(newSViv(tieTcSTAT(tc, tieTCS_INSERT))));
	XPUSHs(sv_2mortal(newSVpv("delete",0)));
	XPUSHs(sv_2mortal(newSViv(tieTcSTAT(tc, tieTCS_DELETE))));
	XPUSHs(sv_2mortal(newSVpv("keycmp",0)));
	XPUSHs(sv_2mortal(newSViv(tieTcSTAT(tc, tieTCS_KEYCMP))));

void
sizeof(...)
	PPCODE:
	XPUSHs(sv_2mortal(newSViv(tieTnWIDTH)));
	XPUSHs(sv_2mortal(newSViv(sizeof(tieTN))));

void
tieXPVTV::dump()
	CODE:
	tietv_dump(THIS);


MODULE = Tree::Fat		PACKAGE = Tree::Fat::Test

void
case_report()
	CODE:
	debtv_c_CCOV_REPORT();

void
debug(mask)
	int mask
	CODE:
	debtv_set_debug(mask);

void
new(CLASS)
	char *CLASS
	PREINIT:
	debXPVTV *tv;
	PPCODE:
	tv = debinit_tv((debXPVTV*) safemalloc(sizeof(debXPVTV)));
	/*warn("new TV() = %p\n", tv);/**/
	XPUSHs(sv_setref_pv(sv_newmortal(), CLASS, tv));

void
debXPVTV::DESTROY()
	CODE:
	debfree_tv(THIS);
	/*warn("TV(%p)->DESTROY\n", THIS);/**/

void
insert(THIS, key, data)
	SV *THIS
	char *key
	SV *data
	CODE:
	debtv_insert(THIS, key, &data);

SV *
fetch(THIS, key)
	SV *THIS
	char *key
	CODE:
	if (!debtv_fetch(THIS, key, &RETVAL))
	  RETVAL = &sv_undef;
	OUTPUT:
	RETVAL

void
delete(THIS, key)
	SV *THIS
	char *key
	CODE:
	debtv_delete(THIS, key);

void
debXPVTV::clear()
	CODE:
	debtv_clear(THIS);

void
debXPVTV::stats()
	PPCODE:
	XPUSHs(sv_2mortal(newSViv(debTvFILL(THIS))));
	XPUSHs(sv_2mortal(newSViv(debTvMAX(THIS))));

void
new_cursor(THIS)
	SV *THIS
	PREINIT:
	char *CLASS = "Tree::Fat::Test::Remote";
	debXPVTC *tc;
	PPCODE:
	tc = debinit_tc((debXPVTC*) safemalloc(sizeof(debXPVTC)));
	SvREFCNT_inc(THIS);
	tc->xtc_tv = THIS;
	debtc_reset(tc);
	/*warn("new TC(%p) = %p\n", THIS, tc);/**/
	XPUSHs(sv_setref_pv(sv_newmortal(), CLASS, tc));

void
debXPVTV::dump()
	CODE:
	debtv_dump(THIS);


MODULE = Tree::Fat		PACKAGE = Tree::Fat::Test::Remote

void
debXPVTC::DESTROY()
	CODE:
	/*warn("TC(%p)->DESTROY\n", THIS);/**/
	if (THIS != debtv_global_cursor) debfree_tc(THIS);

debXPVTC*
global(...)
	PREINIT:
	char *CLASS = "Tree::Fat::Test::Remote";
	PPCODE:
	assert(debtv_global_cursor);
	XPUSHs(sv_setref_pv(sv_newmortal(), CLASS, debtv_global_cursor));

void
debXPVTC::stats()
	PPCODE:
	XPUSHs(sv_2mortal(newSVpv("rotate1",0)));
	XPUSHs(sv_2mortal(newSViv(debTcSTAT(THIS, debTCS_ROTATE1))));
	XPUSHs(sv_2mortal(newSVpv("rotate2",0)));
	XPUSHs(sv_2mortal(newSViv(debTcSTAT(THIS, debTCS_ROTATE2))));
	XPUSHs(sv_2mortal(newSVpv("copyslot",0)));
	XPUSHs(sv_2mortal(newSViv(debTcSTAT(THIS, debTCS_COPYSLOT))));
	XPUSHs(sv_2mortal(newSVpv("stepnode",0)));
	XPUSHs(sv_2mortal(newSViv(debTcSTAT(THIS, debTCS_STEPNODE))));
	XPUSHs(sv_2mortal(newSVpv("insert",0)));
	XPUSHs(sv_2mortal(newSViv(debTcSTAT(THIS, debTCS_INSERT))));
	XPUSHs(sv_2mortal(newSVpv("delete",0)));
	XPUSHs(sv_2mortal(newSViv(debTcSTAT(THIS, debTCS_DELETE))));
	XPUSHs(sv_2mortal(newSVpv("keycmp",0)));
	XPUSHs(sv_2mortal(newSViv(debTcSTAT(THIS, debTCS_KEYCMP))));

debXPVTV *
debXPVTC::focus()
	PREINIT:
	char *CLASS = "Tree::Fat::Test";
	CODE:
	debTcTV(THIS, RETVAL);
	OUTPUT:
	RETVAL

void
debXPVTC::delete()
	CODE:
	debtc_delete(THIS);

void
debXPVTC::insert(key, data)
	char *key
	SV *data
	CODE:
	debtc_insert(THIS, key, &data);

void
debXPVTC::moveto(...)
	PROTOTYPE: $;$
	PREINIT:
	SV *where;
	I32 xto=-2;
	CODE:
	if (items == 1) {
	  xto=-1;
	} else {
	  where = ST(1);
	  if (SvNIOK(where)) { xto = SvIV(where); }
	  else if (SvPOK(where)) {
	    char *wh = SvPV(where, na);
	    if (strEQ(wh, "start")) xto=-1;
	    else if (strEQ(wh, "end")) {
	      debXPVTV *tv;
	      debTcTV(THIS, tv);
	      xto=debTvFILL(tv);
	    }
	  } else {
	    croak("TC(%p)->moveto(): unknown location", THIS);
	  }
	}
	debtc_moveto(THIS, xto);

SV *
debXPVTC::pos()
	PREINIT:
	I32 where;
	PPCODE:
	XPUSHs(sv_2mortal(newSViv(debtc_pos(THIS))));

int
debXPVTC::seek(key)
	char *key
	CODE:
	RETVAL = debtc_seek(THIS, key);
	OUTPUT:
	RETVAL

void
debXPVTC::step(delta)
	int delta
	CODE:
	debtc_step(THIS, delta);

void
debXPVTC::each(delta)
	int delta;
	PREINIT:
	char *key;
	SV *out;
	PPCODE:
	debtc_step(THIS, delta);
	key = debtc_fetch(THIS, &out);
	if (key) {
	  XPUSHs(sv_2mortal(newSVpv(key,0)));
	  XPUSHs(sv_2mortal(newSVsv(out)));
	}

void
debXPVTC::fetch()
	PREINIT:
	char *key;
	SV *out;
	PPCODE:
	key = debtc_fetch(THIS, &out);
	if (key) {
	  XPUSHs(sv_2mortal(newSVpv(key,0)));
	  XPUSHs(sv_2mortal(newSVsv(out)));
	}

void
debXPVTC::store(data)
	SV *data
	CODE:
	debtc_store(THIS, &data);

void
debXPVTC::dump()
	CODE:
	debtc_dump(THIS);
