# Variables
INSTALL_SCRIPT = ./install.sh
MAIN_SCRIPT = bin/main.sh

.PHONY: install mock clean help

help:
	@echo "LogGuardian Makefile"
	@echo "  make install   - Lance l'installateur"
	@echo "  make mock      - Simule des attaques SSH (Mock)"
	@echo "  make stats     - Affiche les stats actuelles"
	@echo "  make clean     - Nettoie les logs et la base de données"

install:
	@chmod 700 $(INSTALL_SCRIPT)
	@$(INSTALL_SCRIPT)

mock:
	@./$(MAIN_SCRIPT) --mock

stats:
	@./$(MAIN_SCRIPT) --stats

clean:
	@echo "Nettoyage des fichiers temporaires..."
	rm -rf var/*.db log/*.log var/reports/*.txt
	@echo "Terminé."