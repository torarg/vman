install:
	install -m 0755 -g bin -o root vman /usr/local/bin/vman

uninstall:
	rm /usr/local/bin/vman
