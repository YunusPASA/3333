AS      = as
LD      = ld
ASFLAGS = --64
LDFLAGS = -m elf_x86_64 -e _start

TARGET  = schedsim
SRCS    = schedsim.s
OBJS    = $(SRCS:.s=.o)

.PHONY: all clean

all: $(TARGET)

$(TARGET): $(OBJS)
	$(LD) $(LDFLAGS) -o $@ $^

%.o: %.s
	$(AS) $(ASFLAGS) -o $@ $<

clean:
	rm -f $(OBJS) $(TARGET)
