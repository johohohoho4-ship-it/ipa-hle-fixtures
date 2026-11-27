#import "ViewController.h"
#include <arpa/inet.h>
#include <netdb.h>
#include <netinet/in.h>
#include <stddef.h>
#include <stdio.h>
#include <string.h>
#include <sys/socket.h>

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor systemBackgroundColor];

    int passed = [self runNetdbChecks];

    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(20, 80, 350, 32)];
    title.text = @"Netdb Getaddrinfo";
    title.font = [UIFont boldSystemFontOfSize:22];
    title.accessibilityIdentifier = @"gai.title";
    [self.view addSubview:title];

    UILabel *status = [[UILabel alloc] initWithFrame:CGRectMake(20, 124, 350, 28)];
    status.text = [NSString stringWithFormat:@"Netdb OK (%d checks)", passed];
    status.font = [UIFont systemFontOfSize:16];
    status.accessibilityIdentifier = @"gai.status";
    [self.view addSubview:status];
}

- (int)runNetdbChecks {
    int passed = 0;

    printf("GAI_ABI sizeof_ai=%zu off_canon=%zu off_addr=%zu off_next=%zu af6=%d eai_noname=%d ai_numserv=%d\n",
           sizeof(struct addrinfo),
           offsetof(struct addrinfo, ai_canonname),
           offsetof(struct addrinfo, ai_addr),
           offsetof(struct addrinfo, ai_next),
           AF_INET6,
           EAI_NONAME,
           AI_NUMERICSERV);
    passed++;

    // 1. Numeric IPv4 with AI_NUMERICHOST | AI_CANONNAME
    struct addrinfo hints;
    struct addrinfo *res = NULL;
    memset(&hints, 0, sizeof(hints));
    hints.ai_family = AF_INET;
    hints.ai_socktype = SOCK_STREAM;
    hints.ai_flags = AI_NUMERICHOST | AI_CANONNAME;
    int rc = getaddrinfo("127.0.0.1", "8080", &hints, &res);
    if (rc == 0 && res != NULL && res->ai_addr != NULL) {
        struct sockaddr_in *sin = (struct sockaddr_in *)res->ai_addr;
        char ip[INET_ADDRSTRLEN] = {0};
        inet_ntop(AF_INET, &sin->sin_addr, ip, sizeof(ip));
        printf("GAI_IPV4 rc=%d fam=%d sock=%d proto=%d len=%u sin_len=%u port=%u ip=%s canon=%s\n",
               rc, res->ai_family, res->ai_socktype, res->ai_protocol,
               (unsigned)res->ai_addrlen, (unsigned)sin->sin_len,
               (unsigned)ntohs(sin->sin_port), ip,
               res->ai_canonname ? res->ai_canonname : "(null)");
        freeaddrinfo(res);
        passed++;
    } else {
        printf("GAI_IPV4 rc=%d\n", rc);
    }

    // 2. Numeric IPv6
    res = NULL;
    memset(&hints, 0, sizeof(hints));
    hints.ai_family = AF_INET6;
    hints.ai_socktype = SOCK_STREAM;
    hints.ai_flags = AI_NUMERICHOST;
    rc = getaddrinfo("::1", "443", &hints, &res);
    if (rc == 0 && res != NULL && res->ai_addr != NULL) {
        struct sockaddr_in6 *sin6 = (struct sockaddr_in6 *)res->ai_addr;
        char ip6[INET6_ADDRSTRLEN] = {0};
        inet_ntop(AF_INET6, &sin6->sin6_addr, ip6, sizeof(ip6));
        printf("GAI_IPV6 rc=%d fam=%d sock=%d proto=%d len=%u sin6_len=%u port=%u ip=%s\n",
               rc, res->ai_family, res->ai_socktype, res->ai_protocol,
               (unsigned)res->ai_addrlen, (unsigned)sin6->sin6_len,
               (unsigned)ntohs(sin6->sin6_port), ip6);
        freeaddrinfo(res);
        passed++;
    } else {
        printf("GAI_IPV6 rc=%d\n", rc);
    }

    // 3. localhost + named service "http"
    res = NULL;
    memset(&hints, 0, sizeof(hints));
    hints.ai_family = AF_INET;
    hints.ai_socktype = SOCK_STREAM;
    rc = getaddrinfo("localhost", "http", &hints, &res);
    if (rc == 0 && res != NULL && res->ai_addr != NULL) {
        struct sockaddr_in *sin = (struct sockaddr_in *)res->ai_addr;
        char ip[INET_ADDRSTRLEN] = {0};
        inet_ntop(AF_INET, &sin->sin_addr, ip, sizeof(ip));
        printf("GAI_LOCALHOST rc=%d fam=%d port=%u ip=%s\n",
               rc, res->ai_family, (unsigned)ntohs(sin->sin_port), ip);
        freeaddrinfo(res);
        passed++;
    } else {
        printf("GAI_LOCALHOST rc=%d\n", rc);
    }

    // 4. NULL node with AI_PASSIVE
    res = NULL;
    memset(&hints, 0, sizeof(hints));
    hints.ai_family = AF_INET;
    hints.ai_socktype = SOCK_STREAM;
    hints.ai_flags = AI_PASSIVE;
    rc = getaddrinfo(NULL, "9000", &hints, &res);
    if (rc == 0 && res != NULL && res->ai_addr != NULL) {
        struct sockaddr_in *sin = (struct sockaddr_in *)res->ai_addr;
        char ip[INET_ADDRSTRLEN] = {0};
        inet_ntop(AF_INET, &sin->sin_addr, ip, sizeof(ip));
        printf("GAI_PASSIVE rc=%d fam=%d port=%u ip=%s\n",
               rc, res->ai_family, (unsigned)ntohs(sin->sin_port), ip);
        freeaddrinfo(res);
        passed++;
    } else {
        printf("GAI_PASSIVE rc=%d\n", rc);
    }

    // 5-7. getnameinfo: numeric, named service, buffer overflow
    struct sockaddr_in sa;
    memset(&sa, 0, sizeof(sa));
    sa.sin_len = sizeof(sa);
    sa.sin_family = AF_INET;
    sa.sin_port = htons(80);
    inet_pton(AF_INET, "127.0.0.1", &sa.sin_addr);

    char hbuf[NI_MAXHOST] = {0};
    char sbuf[NI_MAXSERV] = {0};
    int gni_num = getnameinfo((struct sockaddr *)&sa, sizeof(sa),
                              hbuf, sizeof(hbuf), sbuf, sizeof(sbuf),
                              NI_NUMERICHOST | NI_NUMERICSERV);
    printf("GAI_GNI_NUM rc=%d host=%s serv=%s\n", gni_num, hbuf, sbuf);
    if (gni_num == 0) passed++;

    memset(hbuf, 0, sizeof(hbuf));
    memset(sbuf, 0, sizeof(sbuf));
    int gni_svc = getnameinfo((struct sockaddr *)&sa, sizeof(sa),
                              hbuf, sizeof(hbuf), sbuf, sizeof(sbuf),
                              NI_NUMERICHOST);
    printf("GAI_GNI_SVC rc=%d host=%s serv=%s\n", gni_svc, hbuf, sbuf);
    if (gni_svc == 0) passed++;

    char tiny[4] = {0};
    int gni_ovf = getnameinfo((struct sockaddr *)&sa, sizeof(sa),
                              tiny, sizeof(tiny), NULL, 0,
                              NI_NUMERICHOST);
    printf("GAI_GNI_OVF rc=%d\n", gni_ovf);
    if (gni_ovf == EAI_OVERFLOW) passed++;

    // 8. Error codes + gai_strerror
    struct addrinfo *err_res = NULL;
    int err_null = getaddrinfo(NULL, NULL, NULL, &err_res);

    memset(&hints, 0, sizeof(hints));
    hints.ai_flags = AI_NUMERICHOST;
    int err_numhost = getaddrinfo("localhost", "80", &hints, &err_res);

    memset(&hints, 0, sizeof(hints));
    hints.ai_flags = AI_NUMERICSERV;
    int err_numserv = getaddrinfo("127.0.0.1", "http", &hints, &err_res);

    memset(&hints, 0, sizeof(hints));
    hints.ai_family = 99;
    int err_fam = getaddrinfo("127.0.0.1", "80", &hints, &err_res);

    memset(&hints, 0, sizeof(hints));
    hints.ai_socktype = 99;
    int err_sock = getaddrinfo("127.0.0.1", "80", &hints, &err_res);

    const char *err_str = gai_strerror(EAI_NONAME);
    int str_ok = (err_str != NULL && strlen(err_str) > 0) ? 1 : 0;
    printf("GAI_ERRORS null=%d numhost=%d numserv=%d fam=%d sock=%d str_ok=%d\n",
           err_null, err_numhost, err_numserv, err_fam, err_sock, str_ok);
    if (err_null == EAI_NONAME && err_numhost == EAI_NONAME && err_numserv == EAI_NONAME &&
        err_fam == EAI_FAMILY && err_sock == EAI_SOCKTYPE && str_ok == 1) {
        passed++;
    }

    // 9. inet_pton / inet_ntop / inet_aton / inet_addr / inet_ntoa
    struct in_addr a4;
    struct in6_addr a6;
    char out4[INET_ADDRSTRLEN] = {0};
    char out6[INET6_ADDRSTRLEN] = {0};
    int pton4 = inet_pton(AF_INET, "192.0.2.42", &a4);
    inet_ntop(AF_INET, &a4, out4, sizeof(out4));
    int pton6 = inet_pton(AF_INET6, "2001:db8::1", &a6);
    inet_ntop(AF_INET6, &a6, out6, sizeof(out6));
    int pton_bad = inet_pton(AF_INET, "not-an-ip", &a4);
    struct in_addr a_aton;
    int aton_ok = inet_aton("10.20.30.40", &a_aton);
    struct in_addr a_addr;
    a_addr.s_addr = inet_addr("10.20.30.40");
    const char *ntoa_str = inet_ntoa(a_addr);
    printf("GAI_INET pton4=%d ntop4=%s pton6=%d ntop6=%s bad=%d aton=%d ntoa=%s\n",
           pton4, out4, pton6, out6, pton_bad, aton_ok, ntoa_str ? ntoa_str : "(null)");
    if (pton4 == 1 && pton6 == 1 && pton_bad == 0 && aton_ok == 1) passed++;

    printf("GAI_DONE checks=%d\n", passed);
    return passed;
}

@end
