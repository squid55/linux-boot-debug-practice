/* userspace 디버깅 실습용 대상 프로그램
 * 일부러 여러 종류의 동작을 섞어두었다:
 *   파일 열기/쓰기(syscall), 메모리 할당, 계산 함수, 짧은 대기
 * 빌드: make      실행: ./target 5
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

long compute(int n)              /* uprobe 로 잡아볼 함수 */
{
    long sum = 0;
    for (int i = 1; i <= n; i++)
        sum += (long)i * i;
    return sum;
}

static void write_result(const char *path, long value)
{
    FILE *fp = fopen(path, "a");
    if (!fp) { perror("fopen"); return; }
    fprintf(fp, "result=%ld\n", value);
    fclose(fp);
}

int main(int argc, char **argv)
{
    int rounds = (argc > 1) ? atoi(argv[1]) : 3;
    char *buf = malloc(4096);
    memset(buf, 0, 4096);

    for (int r = 0; r < rounds; r++) {
        long v = compute(1000 * (r + 1));
        printf("[%d] compute -> %ld\n", r, v);
        write_result("/tmp/target-out.txt", v);
        usleep(200 * 1000);
    }
    free(buf);
    return 0;
}
