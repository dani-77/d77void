PAM_DIR   ?= /etc/pam.d
PAM_FILE   = pam/fabric-d77

.PHONY: install uninstall

install:
	install -Dm644 $(PAM_FILE) $(PAM_DIR)/fabric-d77

uninstall:
	rm -f $(PAM_DIR)/fabric-d77
