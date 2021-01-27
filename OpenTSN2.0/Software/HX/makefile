#!/bin/bash



CC=gcc

LDHDPATH = -I ./include 
LDLIBS +=-lm -lpthread -lpcap -lnet

all: clean hx


hx:
	$(CC) -o buf.o -c ./lib_src/buf.c $(LDLIBS) $(LDHDPATH) 
	$(CC) -o quene.o -c ./lib_src/quene.c $(LDLIBS) $(LDHDPATH)
	$(CC) -o msg.o -c ./lib_src/msg.c $(LDLIBS) $(LDHDPATH)

	
	$(CC) -o data_rec_engine.o -c ./lib_src/np_data_rec_engine.c $(LDLIBS) $(LDHDPATH)
	$(CC) -o data_send_engine.o -c ./lib_src/np_data_send_engine.c $(LDLIBS) $(LDHDPATH)


	$(CC) -o basic.o -c ./lib_src/basic.c $(LDLIBS) $(LDHDPATH)
	$(CC) -o schedule.o -c ./lib_src/schedule.c $(LDLIBS) $(LDHDPATH)
	$(CC) -o tools.o -c ./lib_src/tools.c $(LDLIBS) $(LDHDPATH)
	$(CC) -o test.o -c ./app/test/test_main.c $(LDLIBS) $(LDHDPATH)    #test

	$(CC) -o hx main.c buf.o quene.o msg.o data_rec_engine.o data_send_engine.o basic.o schedule.o tools.o test.o $(LDLIBS) $(LDHDPATH)
	
clean:
	rm -rf hx *.o 






