# log-guardian
Bash based security tool for monitoring SSH authentication failures and automated reporting

## Struture
.
├── log_guardian.sh      # Point d'entrée
├── common.lib.sh        # Votre bibliothèque de fonctions (le moteur)
├── whitelist.conf       # Les IPs à ne JAMAIS bannir
├── README.md            # La documentation
└── .gitignore           # Pour ne pas commit les fichiers temporaires (.txt)
