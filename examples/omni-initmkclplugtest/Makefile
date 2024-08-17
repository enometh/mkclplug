.POSIX:
include config.mk

SRC = omni-mkclplugtest.c
OBJ = $(SRC:.c=.o)

all: a.out

a.out: $(OBJ)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $(OBJ) $(LIBS)

clean:
	rm -f $(OBJ) a.out

