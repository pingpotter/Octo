PROCESS=extcallversion

# Define your C objects list
OBJECTS=\
	version.o

${PROCESS}:
	gcc -o ${PROCESS} version.c extcall.sl

# DO NOT DELETE THIS LINE
