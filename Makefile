CHROOT_DIR=/var/www/foxweb-jail
BIN_DIR=/usr/local/sbin
SERVICE_DIR=/etc/systemd/system
WEB_USER=root
WEB_GROUP=root

all: PICOFoxweb

clean:
	@rm -rf *.o PICOFoxweb

PICOFoxweb: main.o httpd.o
	gcc -o PICOFoxweb $^

main.o: main.c httpd.h
	gcc -c -o main.o main.c

httpd.o: httpd.c httpd.h
	gcc -c -o httpd.o httpd.c

install: PICOFoxweb
	install -o root -g root -m 0755 PICOFoxweb $(DESTDIR)$(BIN_DIR)/
	install -o root -g root -m 0644 picofoxweb.service $(DESTDIR)$(SERVICE_DIR)/
	    
	mkdir -p $(DESTDIR)$(CHROOT_DIR)/webroot
	mkdir -p $(DESTDIR)$(CHROOT_DIR)/etc
	mkdir -p $(DESTDIR)$(CHROOT_DIR)/var/log
	mkdir -p $(DESTDIR)$(CHROOT_DIR)/dev
	mkdir -p $(DESTDIR)$(CHROOT_DIR)/usr/local/sbin
	mkdir -p $(DESTDIR)$(CHROOT_DIR)/lib
	mkdir -p $(DESTDIR)$(CHROOT_DIR)/lib64
	mkdir -p $(CHROOT_DIR)/etc
	grep -E '^(root|www-data):' /etc/passwd > $(CHROOT_DIR)/etc/passwd
	grep -E '^(root|www-data):' /etc/group > $(CHROOT_DIR)/etc/group
	cp -f /etc/nsswitch.conf $(CHROOT_DIR)/etc/
	cp -f /etc/host.conf $(CHROOT_DIR)/etc/
	cp -f /etc/resolv.conf $(CHROOT_DIR)/etc/
	cp -f /etc/hosts $(CHROOT_DIR)/etc/
	install -D -m 0644 /etc/passwd $(DESTDIR)$(CHROOT_DIR)/etc/passwd
	install -D -m 0644 /etc/group $(DESTDIR)$(CHROOT_DIR)/etc/group
	cp -r webroot $(DESTDIR)$(CHROOT_DIR)/
	chown -R $(WEB_USER):$(WEB_GROUP) $(DESTDIR)$(CHROOT_DIR)/webroot
	    
	    # Лог-файл
	touch $(DESTDIR)$(CHROOT_DIR)/var/log/foxweb.log
	chown $(WEB_USER):$(WEB_GROUP) $(DESTDIR)$(CHROOT_DIR)/var/log/foxweb.log
	   
	    # Специальные файлы устройств
	mknod -m 666 $(DESTDIR)$(CHROOT_DIR)/dev/null c 1 3
	mknod -m 666 $(DESTDIR)$(CHROOT_DIR)/dev/zero c 1 5
	mknod -m 666 $(DESTDIR)$(CHROOT_DIR)/dev/random c 1 8
	mknod -m 666 $(DESTDIR)$(CHROOT_DIR)/dev/urandom c 1 9
	    
	    # Копируем бинарник в chroot
	install -o root -g root -m 0755 $(DESTDIR)$(BIN_DIR)/PICOFoxweb $(DESTDIR)$(CHROOT_DIR)/usr/local/sbin/
	    
	systemctl daemon-reload
	systemctl start picofoxweb

uninstall:
	systemctl stop picofoxweb
	systemctl disable picofoxweb
	rm -f $(DESTDIR)$(BIN_DIR)/PICOFoxweb
	rm -f $(DESTDIR)$(SERVICE_DIR)/picofoxweb.service
	rm -rf $(DESTDIR)$(CHROOT_DIR)
	systemctl daemon-reload
