#import "ViewController.h"
#include <langinfo.h>
#include <limits.h>
#include <locale.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <xlocale.h>

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor systemBackgroundColor];

    int passed = [self runLocaleChecks];

    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(20, 80, 350, 32)];
    title.text = @"Locale C";
    title.font = [UIFont boldSystemFontOfSize:22];
    title.accessibilityIdentifier = @"loc.title";
    [self.view addSubview:title];

    UILabel *status = [[UILabel alloc] initWithFrame:CGRectMake(20, 124, 350, 28)];
    status.text = [NSString stringWithFormat:@"Locale OK (%d checks)", passed];
    status.font = [UIFont systemFontOfSize:16];
    status.accessibilityIdentifier = @"loc.status";
    [self.view addSubview:status];
}

- (int)runLocaleChecks {
    int passed = 0;

    // 1. Darwin ARM64 ABI constants and struct lconv layout
    printf("LOC_ABI sizeof_lconv=%zu off_dp=%zu off_ifd=%zu off_ipcs=%zu off_incs=%zu off_ipsp=%zu off_insp=%zu "
           "cats=%d,%d,%d,%d,%d,%d,%d masks=%d,%d,%d nl=%d,%d,%d,%d cmax=%d\n",
           sizeof(struct lconv),
           offsetof(struct lconv, decimal_point),
           offsetof(struct lconv, int_frac_digits),
           offsetof(struct lconv, int_p_cs_precedes),
           offsetof(struct lconv, int_n_cs_precedes),
           offsetof(struct lconv, int_p_sep_by_space),
           offsetof(struct lconv, int_n_sign_posn),
           LC_ALL, LC_COLLATE, LC_CTYPE, LC_MONETARY, LC_NUMERIC, LC_TIME, LC_MESSAGES,
           LC_MESSAGES_MASK, LC_NUMERIC_MASK, LC_ALL_MASK,
           CODESET, RADIXCHAR, THOUSEP, CRNCYSTR, CHAR_MAX);
    passed++;

    // 2. Initial C locale, POSIX normalization, CODESET
    const char *init_all = setlocale(LC_ALL, NULL);
    const char *posix_all = setlocale(LC_ALL, "POSIX");
    const char *init_cs = nl_langinfo(CODESET);
    printf("LOC_INIT all=%s posix=%s cs=%s\n",
           init_all ? init_all : "(null)",
           posix_all ? posix_all : "(null)",
           init_cs ? init_cs : "(null)");
    if (init_all && strcmp(init_all, "C") == 0 &&
        posix_all && strcmp(posix_all, "C") == 0 &&
        init_cs && strcmp(init_cs, "US-ASCII") == 0) {
        passed++;
    }

    // 3. LC_CTYPE="UTF-8", composite LC_ALL string, restore to C and composite
    const char *u_ct = setlocale(LC_CTYPE, "UTF-8");
    const char *u_all = setlocale(LC_ALL, NULL);
    const char *u_cs = nl_langinfo(CODESET);
    const char *r_c = setlocale(LC_ALL, "C");
    const char *r_comp = setlocale(LC_ALL, "C/UTF-8/C/C/C/C");
    printf("LOC_UTF8 ct=%s all=%s cs=%s rc=%s comp=%s\n",
           u_ct ? u_ct : "(null)",
           u_all ? u_all : "(null)",
           u_cs ? u_cs : "(null)",
           r_c ? r_c : "(null)",
           r_comp ? r_comp : "(null)");
    if (u_ct && strcmp(u_ct, "UTF-8") == 0 &&
        u_all && strcmp(u_all, "C/UTF-8/C/C/C/C") == 0 &&
        u_cs && strcmp(u_cs, "UTF-8") == 0 &&
        r_c && strcmp(r_c, "C") == 0 &&
        r_comp && strcmp(r_comp, "C/UTF-8/C/C/C/C") == 0) {
        passed++;
    }

    // 4. Invalid locale / category rejected without altering current locale
    const char *bad_all_utf8 = setlocale(LC_ALL, "UTF-8");
    const char *bad_name = setlocale(LC_ALL, "no_SUCH_LOCALE_XYZ");
    const char *bad_cat = setlocale(99, "C");
    const char *after_bad = setlocale(LC_ALL, NULL);
    printf("LOC_INVALID utf8=%d name=%d cat=%d after=%s\n",
           bad_all_utf8 == NULL ? 0 : 1,
           bad_name == NULL ? 0 : 1,
           bad_cat == NULL ? 0 : 1,
           after_bad ? after_bad : "(null)");
    if (bad_all_utf8 == NULL && bad_name == NULL && bad_cat == NULL &&
        after_bad && strcmp(after_bad, "C/UTF-8/C/C/C/C") == 0) {
        passed++;
    }

    // 5. setlocale(LC_ALL, "") with deterministic environment variables
    setlocale(LC_ALL, "C");
    unsetenv("LC_ALL");
    unsetenv("LC_COLLATE");
    unsetenv("LC_CTYPE");
    unsetenv("LC_MONETARY");
    unsetenv("LC_NUMERIC");
    unsetenv("LC_TIME");
    unsetenv("LC_MESSAGES");
    unsetenv("LANG");
    const char *env_empty = setlocale(LC_ALL, "");
    setenv("LC_CTYPE", "UTF-8", 1);
    const char *env_utf8 = setlocale(LC_ALL, "");
    unsetenv("LC_CTYPE");
    const char *env_reset = setlocale(LC_ALL, "");
    printf("LOC_ENV empty=%s utf8=%s reset=%s\n",
           env_empty ? env_empty : "(null)",
           env_utf8 ? env_utf8 : "(null)",
           env_reset ? env_reset : "(null)");
    if (env_empty && strcmp(env_empty, "C") == 0 &&
        env_utf8 && strcmp(env_utf8, "C/UTF-8/C/C/C/C") == 0 &&
        env_reset && strcmp(env_reset, "C") == 0) {
        passed++;
    }

    // 6. localeconv() in C locale
    struct lconv *lc = localeconv();
    int empty_strs_ok = 0;
    int chars_ok = 0;
    if (lc != NULL) {
        empty_strs_ok = (strcmp(lc->thousands_sep, "") == 0 &&
                         strcmp(lc->grouping, "") == 0 &&
                         strcmp(lc->int_curr_symbol, "") == 0 &&
                         strcmp(lc->currency_symbol, "") == 0 &&
                         strcmp(lc->mon_decimal_point, "") == 0 &&
                         strcmp(lc->mon_thousands_sep, "") == 0 &&
                         strcmp(lc->mon_grouping, "") == 0 &&
                         strcmp(lc->positive_sign, "") == 0 &&
                         strcmp(lc->negative_sign, "") == 0) ? 1 : 0;
        chars_ok = (lc->int_frac_digits == CHAR_MAX &&
                    lc->frac_digits == CHAR_MAX &&
                    lc->p_cs_precedes == CHAR_MAX &&
                    lc->p_sep_by_space == CHAR_MAX &&
                    lc->n_cs_precedes == CHAR_MAX &&
                    lc->n_sep_by_space == CHAR_MAX &&
                    lc->p_sign_posn == CHAR_MAX &&
                    lc->n_sign_posn == CHAR_MAX &&
                    lc->int_p_cs_precedes == CHAR_MAX &&
                    lc->int_n_cs_precedes == CHAR_MAX &&
                    lc->int_p_sep_by_space == CHAR_MAX &&
                    lc->int_n_sep_by_space == CHAR_MAX &&
                    lc->int_p_sign_posn == CHAR_MAX &&
                    lc->int_n_sign_posn == CHAR_MAX) ? 1 : 0;
    }
    printf("LOC_LCONV dp=%s empty=%d chars=%d\n",
           (lc && lc->decimal_point) ? lc->decimal_point : "(null)",
           empty_strs_ok, chars_ok);
    if (lc && strcmp(lc->decimal_point, ".") == 0 && empty_strs_ok == 1 && chars_ok == 1) {
        passed++;
    }

    // 7. nl_langinfo items in C locale
    const char *radix = nl_langinfo(RADIXCHAR);
    const char *thou = nl_langinfo(THOUSEP);
    const char *dfmt = nl_langinfo(D_FMT);
    const char *tfmt = nl_langinfo(T_FMT);
    const char *day1 = nl_langinfo(DAY_1);
    const char *mon1 = nl_langinfo(MON_1);
    const char *yesx = nl_langinfo(YESEXPR);
    const char *nox = nl_langinfo(NOEXPR);
    const char *unk = nl_langinfo(999);
    printf("LOC_LANGINFO radix=%s thou=%s dfmt=%s tfmt=%s day1=%s mon1=%s yes=%s no=%s unk_empty=%d\n",
           radix, thou, dfmt, tfmt, day1, mon1, yesx, nox,
           (unk != NULL && unk[0] == '\0') ? 1 : 0);
    if (strcmp(radix, ".") == 0 && strcmp(thou, "") == 0 &&
        strcmp(dfmt, "%m/%d/%y") == 0 && strcmp(tfmt, "%H:%M:%S") == 0 &&
        strcmp(day1, "Sunday") == 0 && strcmp(mon1, "January") == 0 &&
        strcmp(yesx, "^[yY]") == 0 && strcmp(nox, "^[nN]") == 0 &&
        unk != NULL && unk[0] == '\0') {
        passed++;
    }

    // 8. xlocale: newlocale, querylocale, duplocale, uselocale, localeconv_l, freelocale
    locale_t cur0 = uselocale(NULL);
    locale_t loc = newlocale(LC_CTYPE_MASK, "UTF-8", NULL);
    const char *q_ct = loc ? querylocale(LC_CTYPE_MASK, loc) : NULL;
    const char *q_num = loc ? querylocale(LC_NUMERIC_MASK, loc) : NULL;
    locale_t dup = loc ? duplocale(loc) : NULL;
    locale_t prev = loc ? uselocale(loc) : NULL;
    const char *t_cs = nl_langinfo(CODESET);
    locale_t restored = uselocale(LC_GLOBAL_LOCALE);
    const char *g_cs = nl_langinfo(CODESET);
    struct lconv *lcl = loc ? localeconv_l(loc) : NULL;
    int f1 = loc ? freelocale(loc) : -1;
    int f2 = dup ? freelocale(dup) : -1;
    printf("LOC_XLOCALE cur_global=%d q_ct=%s q_num=%s prev_global=%d t_cs=%s rest_eq=%d g_cs=%s dp=%s f=%d,%d\n",
           cur0 == LC_GLOBAL_LOCALE ? 1 : 0,
           q_ct ? q_ct : "(null)",
           q_num ? q_num : "(null)",
           prev == LC_GLOBAL_LOCALE ? 1 : 0,
           t_cs ? t_cs : "(null)",
           restored == loc ? 1 : 0,
           g_cs ? g_cs : "(null)",
           (lcl && lcl->decimal_point) ? lcl->decimal_point : "(null)",
           f1, f2);
    if (cur0 == LC_GLOBAL_LOCALE && loc != NULL && dup != NULL &&
        q_ct && strcmp(q_ct, "UTF-8") == 0 &&
        q_num && strcmp(q_num, "C") == 0 &&
        prev == LC_GLOBAL_LOCALE &&
        t_cs && strcmp(t_cs, "UTF-8") == 0 &&
        restored == loc &&
        g_cs && strcmp(g_cs, "US-ASCII") == 0 &&
        lcl && strcmp(lcl->decimal_point, ".") == 0 &&
        f1 == 0 && f2 == 0) {
        passed++;
    }

    printf("LOC_DONE checks=%d\n", passed);
    return passed;
}

@end
