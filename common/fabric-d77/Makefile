PAM_DIR   ?= /etc/pam.d
PAM_FILE   = pam/fabric-d77

BIN_DIR    ?= /usr/bin
BIN_FILE    = bin/fabric-d77-signal

.PHONY: install uninstall

install:
	install -Dm644 $(PAM_FILE) $(PAM_DIR)/fabric-d77
	install -Dm755 $(BIN_FILE) $(BIN_DIR)/fabric-d77-signal

uninstall:
	rm -f $(PAM_DIR)/fabric-d77
	rm -f $(BIN_DIR)/fabric-d77-signal
