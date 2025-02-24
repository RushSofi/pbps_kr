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
	install -m 0755 PICOFoxweb $(DESTDIR)/usr/local/sbin/
	install -m 0644 picofoxweb.service $(DESTDIR)/etc/systemd/system/
	mkdir -p $(DESTDIR)/var/www/foxweb
	cp -r webroot $(DESTDIR)/var/www/foxweb/
	chown -R www-data:www-data $(DESTDIR)/var/www/foxweb
	systemctl daemon-reload
	systemctl enable picofoxweb
	systemctl restart picofoxweb
	touch $(DESTDIR)/var/log/foxweb.log
	chown www-data:www-data  $(DESTDIR)/var/log/foxweb.log

uninstall:
	systemctl stop picofoxweb
	systemctl disable picofoxweb
	rm -f $(DESTDIR)/var/log/foxweb.log
	rm -rf $(DESTDIR)/var/www/foxweb
	rm -f $(DESTDIR)/usr/local/sbin/PICOFoxweb
	rm -f $(DESTDIR)/etc/systemd/system/picofoxweb.service
	systemctl daemon-reload
