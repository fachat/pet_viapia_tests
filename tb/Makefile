
ROMS=tb_08_grp1.rom tb_08_grp6a.rom tb_08_grp11a.rom \
     	tb_04_grp3.rom

all: $(ROMS)

XAOPTS=-XMASM -XC

%.rom: %.a65
	xa $(XAOPTS) -P $(basename $@).lst -o $@ $<

