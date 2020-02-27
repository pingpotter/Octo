#------------------------------------------------------------------------
# Define the flags to the compiler.  
#------------------------------------------------------------------------
#CFLAGS = -c -q64 ${DEBUG}

#
# The rule makes a shared library and puts it in ${SHARED_LIBRARY)
#
${SHARED_LIBRARY}:	${OBJECTS} 
			rm -f ${SHARED_LIBRARY}
			echo create ${SHARED_LIBRARY} 
			${LD} ${LIBNAME} ${SHARED_LIBRARY} $(OBJECTS) ${LFLAGS}

