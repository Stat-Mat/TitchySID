HEADERS = resource.h titchysid.h
OBJS =	obj/sidsample.o obj/sidsample_rc.o 

WARNS = -Wall

CC = gcc
LDFLAGS = -s -lcomdlg32 -lgdi32 -ltitchysid_extras -lwinmm -L../lib -Wl,--subsystem,windows
RC = windres

CFLAGS = -O3 ${WARNS}

all: Release/sidsample_mingw.exe

Release/sidsample_mingw.exe: ${OBJS}
	mkdir -p Release
	${CC} -o "$@" ${OBJS} ${LDFLAGS}

clean:
	del obj\*.o "Release\sidsample_mingw.exe"

obj:
	mkdir -p obj
    
obj/%.o: %.c ${HEADERS} obj
	${CC} ${CFLAGS} -c $< -o $@

obj/sidsample_rc.o: sidsample.rc resource.h
	${RC} -i $< -o $@
