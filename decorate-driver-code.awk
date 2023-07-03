#!/usr/bin/awk -f

# This script decorates C-code formatted as kernel coding standard
#  by entry/return logging (by using logfun variable).
# It aims to be simple.
# It adds 4 defines at begining of the file.

BEGIN {
	logfun = "pr_info"
	if (!logtag) {
		logtag = "deco: "
		print "setting logtag to", logtag, "use wrapper shell script to pass C filename as a tag" > "/dev/stderr"
	}
}

/LOG_(ENTRY|RET(_COMPLEX)?|VOID)/ { print; next }

function print_defines() {
	print "#define LOG_ENTRY() int __attribute__((unused)) _dummy_ ## __LINE__ = ({ "logfun"(\""logtag"->%s()\\n\", __FUNCTION__); 0; })"
	print "#define LOG_RET(x) ({ __auto_type _x = (x); "logfun"(\""logtag"<-%s():L%d returns %s, retval as longint=%ld\\n\", __FUNCTION__, __LINE__, #x, (long int) _x ); _x; })"
	print "#define LOG_RET_COMPLEX(x) ({ "logfun"(\""logtag"<-%s():L%d returns %s\\n\", __FUNCTION__, __LINE__, #x ); (x); })"
	print "#define LOG_VOID(_) do { "logfun"(\""logtag"<-%s():L%d returns void\\n\", __FUNCTION__, __LINE__); return; } while (0)"
}

NR == 1 {
	print_defines()
}

{
	if (prv_line ~ /^[^ ].*[(]/) {
		line = $0
	} else {
		# function declaration/definition begining - line break after retun type case
		line = prv_line " " $0
	}
}

!/^[ \t#]/ {
	# function declaration/definition begining
	if (match(line, "[a-zA-Z0-9_]+[(]")) {
		fnamebeg = substr(line, RSTART, RLENGTH-1)
		decl_line = line
	}
}

# function declaration body
/^{$/ {
	maybevoid = match(decl_line, "void[ \t][a-zA-Z0-9_]+[(]") ? "void " : ""
	maybevoidstar = match(decl_line, "void[ \t][*][a-zA-Z0-9_]+[(]") ? "void *" : ""
	fnameend = fnamebeg

	# special case: IRQ handlers should do not log anything, assume some common type/name convtions below
	# special case: inline functions should also do not log anything
	# special cases to decrease log spamming - HW related funcs
	if (		decl_line ~ /static inline|irqreturn_t .*irq_handler\(/ ||
			fnameend ~ /ice_get_hw_addr/ ||
			fnameend ~ /ice_(get|clear)_vsi_ctx/ ||
			fnameend ~ /ice_hw_to_dev/)
	{
		fnameend = 0
		print "{"
		next
	}

	# special case to decrease log spamming: ov5647_write_reg or ov5645_write_reg
	if (decl_line ~ /^static s32 ov564[57]_write_reg\(u16 reg, u8 val\)$/) {
		fnameend = 0
		print "{ int __attribute__((unused)) dummy = "logfun"(\"%s %04x:=%02x\\n\", __FUNCTION__, reg, val); /*LOG_RET*/"
		next
	}

	# special case to decrease log spamming: ov5647_read_reg or ov5645_read_reg
	if (decl_line ~ /^static s32 ov564[57]_read_reg\(u16 reg, u8 \*val\)$/) {
		print "{"
		next
	}

	print "{\tLOG_ENTRY();"
	next
}

# any non-documentation return
/^[^*]+return.*;/ && fnameend {
	match($0, /[^ \t]/)
	padding = substr($0, 1, RSTART-1)
	retmacro = ""

	# TODO: handle "return x; /* commments */"

	# 'void *' case
	if (maybevoidstar && match($0, /return [^;]+;$/)) {
		retstr = substr($0, RSTART+7, RLENGTH-8)
		retmacro = "return LOG_RET_COMPLEX"
	}
	# heurestic!: better formatting for return 'error or something' cases, (non function call, adress-of operators, etc)
	else if (!maybevoid && match($0, /return -?[a-zA-Z0-9_]+;$/)) {
		retstr = substr($0, RSTART+7, RLENGTH-8)
		retmacro = "return " (retstr != "NULL" ? "LOG_RET" : "LOG_RET_COMPLEX")
	}
	# other non-void cases
	else if (!maybevoid && match($0, /return [^;]+;$/)) {
		retstr = substr($0, RSTART+7, RLENGTH-8)
		retmacro = "return LOG_RET_COMPLEX"
	}
	# void erly-return cases
	else if (maybevoid && match($0, /return;$/)) {
		retmacro = "LOG_VOID"
		retstr = "return"
	}

	if (retmacro) {
		print padding retmacro "("retstr");"
		next
	}
}

# end of void function
/^}$/ && maybevoid && fnameend {
	print "LOG_VOID(_); }"
	next
}

{
	prv_line = $0
	print
}
