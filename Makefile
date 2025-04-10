CHROOT_DIR=/var/www/foxweb-jail
BIN_DIR=/usr/local/sbin
SERVICE_DIR=/etc/systemd/system
WEB_USER=www-data
WEB_GROUP=www-data

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
	# Устанавливаем бинарник и сервис
	install -D -m 0755 PICOFoxweb $(DESTDIR)$(BIN_DIR)/PICOFoxweb
	install -D -m 0644 picofoxweb.service $(DESTDIR)$(SERVICE_DIR)/picofoxweb.service
	    
	# Создаём chroot-окружение 
	mkdir -p $(DESTDIR)$(CHROOT_DIR)/webroot
	mkdir -p $(DESTDIR)$(CHROOT_DIR)/etc
	mkdir -p $(DESTDIR)$(CHROOT_DIR)/var/log
	mkdir -p $(DESTDIR)$(CHROOT_DIR)/dev
	mkdir -p $(DESTDIR)$(CHROOT_DIR)/usr/local/sbin
	mkdir -p $(DESTDIR)$(CHROOT_DIR)/lib
	mkdir -p $(DESTDIR)$(CHROOT_DIR)/lib64

	# Копируем ВСЕ необходимые файлы для работы с пользователями
	mkdir -p $(CHROOT_DIR)/etc
	grep -E '^(root|www-data):' /etc/passwd > $(CHROOT_DIR)/etc/passwd
	grep -E '^(root|www-data):' /etc/group > $(CHROOT_DIR)/etc/group
	cp -f /etc/nsswitch.conf $(CHROOT_DIR)/etc/
	cp -f /etc/host.conf $(CHROOT_DIR)/etc/
	cp -f /etc/resolv.conf $(CHROOT_DIR)/etc/
	cp -f /etc/hosts $(CHROOT_DIR)/etc/

        # Проверяем существование пользователя
	if ! grep -q '^www-data:' $(CHROOT_DIR)/etc/passwd; then \
		echo "www-data:x:33:33:www-data:/nonexistent:/usr/sbin/nologin" >> $(CHROOT_DIR)/etc/passwd; \
		echo "www-data:x:33:" >> $(CHROOT_DIR)/etc/group; \
	fi
	   
	# Копируем минимальные системные файлы
	install -D -m 0644 /etc/passwd $(DESTDIR)$(CHROOT_DIR)/etc/passwd
	install -D -m 0644 /etc/group $(DESTDIR)$(CHROOT_DIR)/etc/group
	    
	# Копируем webroot
	cp -r webroot/* $(DESTDIR)$(CHROOT_DIR)/webroot/
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
	install -D -m 0755 $(DESTDIR)$(BIN_DIR)/PICOFoxweb $(DESTDIR)$(CHROOT_DIR)/usr/local/sbin/PICOFoxweb
	    
	# Узнаем зависимости бинарника
	sudo ldd /usr/local/sbin/PICOFoxweb

	# Копируем все необходимые библиотеки
	sudo mkdir -p /var/www/foxweb-jail/lib/x86_64-linux-gnu
	sudo mkdir -p /var/www/foxweb-jail/lib64
	sudo cp /lib/x86_64-linux-gnu/libc.so.6 /var/www/foxweb-jail/lib/x86_64-linux-gnu/
	sudo cp /lib64/ld-linux-x86-64.so.2 /var/www/foxweb-jail/lib64/
	sudo cp /lib/x86_64-linux-gnu/libpthread.so.0 /var/www/foxweb-jail/lib/x86_64-linux-gnu/

	    # Копируем необходимые библиотеки (исправленная версия)
	for lib in $(shell ldd /usr/local/sbin/PICOFoxweb | awk '/=>/ {print $$3}'); do \
		if [ -n "$$lib" ]; then \
		    install -D $$lib $(DESTDIR)$(CHROOT_DIR)$$lib || exit 1; \
		fi; \
	done
	install -D /lib64/ld-linux-x86-64.so.2 $(DESTDIR)$(CHROOT_DIR)/lib64/
	    
	    # Активируем сервис
	systemctl daemon-reload
	systemctl enable picofoxweb
	systemctl restart picofoxweb

run:
	sudo /usr/local/sbin/PICOFoxweb 8000

status:
	journalctl -u picofoxweb --no-pager

uninstall:
	systemctl stop picofoxweb
	systemctl disable picofoxweb
	rm -f $(DESTDIR)$(BIN_DIR)/PICOFoxweb
	rm -f $(DESTDIR)$(SERVICE_DIR)/picofoxweb.service
	rm -rf $(DESTDIR)$(CHROOT_DIR)
	systemctl daemon-reload
