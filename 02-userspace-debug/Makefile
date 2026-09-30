CFLAGS = -O0 -g -Wall -fno-omit-frame-pointer
all: target
target: target.c
	$(CC) $(CFLAGS) -o $@ $<
clean:
	rm -f target
.PHONY: all clean
