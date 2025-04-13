all: PICOFoxweb

clean:
	@rm -rf *.o
	@rm -rf PICOFoxweb

PICOFoxweb: main.o httpd.o
	gcc -o PICOFoxweb $^

main.o: main.c httpd.h
	gcc -c -o main.o main.c

httpd.o: httpd.c httpd.h
	gcc -c -o httpd.o httpd.c

install: PICOFoxweb
	mkdir -p /var/www/foxweb/webroot
	mkdir -p /var/www/foxweb/logs
	mkdir -p /var/www/foxweb/dev
	mkdir -p /var/www/foxweb/etc
	mkdir -p /var/www/foxweb/lib
	mkdir -p /var/www/foxweb/lib64
	mkdir -p /var/www/foxweb/usr/lib
	mkdir -p /var/www/foxweb/usr/local/sbin
	mknod -m 666 /var/www/foxweb/dev/null c 1 3
	cp /etc/resolv.conf /var/www/foxweb/etc/
	install -o root -g root -m 0755 PICOFoxweb /var/www/foxweb/usr/local/sbin/                       
	ln -sf /var/www/foxweb/usr/local/sbin/PICOFoxweb /usr/local/sbin/PICOFoxweb
	install -o root -g root -m 0644 picofoxweb.service /etc/systemd/system/
	mkdir -p /var/www/foxweb/lib/x86_64-linux-gnu
	cp /lib/x86_64-linux-gnu/libc.so.6 /var/www/foxweb/lib/x86_64-linux-gnu/
	cp /lib64/ld-linux-x86-64.so.2 /var/www/foxweb/lib64/
	cp /lib/x86_64-linux-gnu/libnss_* /var/www/foxweb/lib/x86_64-linux-gnu/
	cp -r webroot -t /var/www/foxweb/
	chmod -R 0755 /var/www/foxweb/webroot
	chown -R root:root /var/www/foxweb
	touch /var/www/foxweb/logs/foxweb.log
	chown root:root /var/www/foxweb/logs/foxweb.log
	chmod 666 /var/www/foxweb/logs/foxweb.log
	systemctl daemon-reload
	systemctl restart picofoxweb.service

uninstall:
	rm -rf /var/www/foxweb
	rm -f /usr/local/sbin/PICOFoxweb
	rm -f /etc/systemd/system/picofoxweb.service
	systemctl daemon-reload
