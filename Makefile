CC   = gcc
CXX  = g++
RASM = rasm
ECHO = echo

CCFLAGS = -W -Wall
RASMFLAGS =

ALL = bin2m12 cge2bin convert gfx \
      up-xmas2019.bin up-xmas2019.m12 \
      up-xmas2019_emu.bin up-xmas2019_emu.m12

all: $(ALL)

bin2m12: tools/bin2m12.c
	@$(ECHO) "CC	$@"
	@$(CC) $(CCFLAGS) -o $@ $^

cge2bin: tools/cge2bin.c
	@$(ECHO) "CC	$@"
	@$(CC) $(CCFLAGS) -o $@ $^ -lm

convert: tools/convert.c
	@$(ECHO) "CC	$@"
	@$(CC) $(CCFLAGS) -o $@ $^ -lm

gfx: cge2bin convert
	@$(ECHO) "GEN	GFX"
	@./convert ./data/santa.png ./data/gfx00
	@./cge2bin -x 0 -y 0 -w 8 -h 25 ./data/0000.txt ./data/border03.bin
	@./cge2bin -x 8 -y 0 -w 8 -h 25 ./data/0000.txt ./data/border04.bin
	@./cge2bin -x 16 -y 0 -w 8 -h 25 ./data/0000.txt ./data/border05.bin
	@./cge2bin -x 24 -y 0 -w 8 -h 25 ./data/0000.txt ./data/border00.bin
	@./cge2bin -x 32 -y 0 -w 8 -h 25 ./data/0000.txt ./data/border01.bin
	@./cge2bin -x 32 -y 0 -w 8 -h 25 ./data/0001.txt ./data/border02.bin
	@./cge2bin -x 32 -y 0 -w 8 -h 25 ./data/0002.txt ./data/border06.bin
	@./cge2bin -x 32 -y 0 -w 8 -h 25 ./data/0003.txt ./data/border07.bin
	@./cge2bin -x 0 -y 0 -w 16 -h 16 ./data/0001.txt ./data/star.bin
	@./cge2bin -x 16 -y 0 -w 16 -h 16 ./data/0001.txt ./data/santa.bin
	@./cge2bin -x 0 -y 0 -w 16 -h 16 ./data/0002.txt ./data/frost.bin
	@./cge2bin -x 16 -y 0 -w 16 -h 16 ./data/0002.txt ./data/socks.bin
	@./cge2bin -x 0 -y 0 -w 16 -h 16 ./data/0003.txt ./data/gifts.bin
	@./cge2bin -x 16 -y 0 -w 16 -h 16 ./data/0003.txt ./data/homealone.bin
	@./cge2bin -x 0 -y 0 -w 16 -h 16 ./data/0004.txt ./data/grinch.bin
	@./cge2bin -x 16 -y 0 -w 16 -h 16 ./data/0004.txt ./data/bozo.bin

up-xmas2019.bin:  gfx
	@$(ECHO) "RASM	$@"
	@$(RASM) $(RASMFLAGS) up-xmas2019.asm -o $(basename $@)

%.m12: %.bin bin2m12
	@$(ECHO) "M12	$@"
	@./bin2m12 $< $@ UP-XMAS2019

up-xmas2019_emu.bin: up-xmas2019.bin
	@$(ECHO) "RASM	$@"
	@$(RASM) -DEMU=1 $(RASMFLAGS) up-xmas2019.asm -o $(basename $@)

clean:
	@$(ECHO) "CLEANING UP..."
	@rm -f bin2m12 cge2bin convert up-xmas2019.bin up-xmas2019_emu.bin up-xmas2019.m12 up-xmas2019_emu.m12
	@find $(BUILD_DIR) -name "*.o" -exec rm -f {} \;
