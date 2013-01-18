CC		=	valac
SOURCES		+=	src/*.vala
PACKAGES	+=	--pkg gio-2.0
CFLAGS		+=	$(PACKAGES)

BINARYDIR	+=	build/
BINARY		+=	fsdump




all: CFLAGS += -X -O3
all: $(BINARYDIR)$(BINARY)

debug: CFLAGS += --debug
debug: $(BINARYDIR)$(BINARY)




install:
	cp $(BINARYDIR)$(BINARY) /usr/bin/$(BINARY)

uninstall:
	rm /usr/bin/$(BINARY)

clean:
	rm $(BINARYDIR)$(BINARY)




$(BINARYDIR)$(BINARY): $(SOURCES)
	$(CC) $(CFLAGS) $(SOURCES) -o $(BINARYDIR)$(BINARY) 
