CC		=	go
SOURCES		+=	src/*.go
PACKAGES	+=	
CFLAGS		+=	$(PACKAGES)

BINARYDIR	+=	build/
BINARY		+=	fsdump



all: $(BINARYDIR)$(BINARY)


install:
	cp $(BINARYDIR)$(BINARY) /usr/bin/$(BINARY)

uninstall:
	rm /usr/bin/$(BINARY)

clean:
	rm $(BINARYDIR)$(BINARY)


$(BINARYDIR)$(BINARY): $(SOURCES)
	$(CC) build -o $(BINARYDIR)$(BINARY) $(CFLAGS) $(SOURCES)
