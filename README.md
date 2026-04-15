# 🛡️ LogGuardian - Système de Prévention d'Intrusion (IPS)

**LogGuardian** est un outil d'administration système modulaire écrit en Bash. Il permet de surveiller les tentatives d'intrusion SSH, d'analyser les comportements suspects et de bannir automatiquement les adresses IP malveillantes via `iptables`.

## 🚀 Fonctionnalités
- **Analyse Intelligente** : Extraction des échecs de connexion SSH depuis `journalctl` avec filtrage temporel (`--since`).
- **Seuil de Tolérance** : Détection des adresses IP dépassant un nombre paramétrable de tentatives.
- **Gestion de Liste Blanche** : Protection contre l'auto-bannissement via un fichier `whitelist.conf`.
- **Persistance** : Sauvegarde des adresses bannies dans une base de données locale (`.db`).
- **Remédiation Automatique** : Application de règles de pare-feu `iptables` avec vérification d'idempotence.
- **Mode Mocking** : Générateur de fausses attaques pour tester l'outil sans risque.

## 📁 Architecture du Projet
Le projet suit une structure modulaire inspirée des standards Linux :
```text
log-guardian/
├── Makefile                # Façade pour l'installation et les commandes rapides
├── install.sh              # Script d'installation (PATH, Symlinks, Dirs)
├── bin/                    # Exécutables
│   └── main.sh             # Point d'entrée (lié à ~/.local/bin/logguardian)
├── config/                 # Configuration statique
│   ├── guardian.conf       # Paramètres (seuil, noms de fichiers)
│   └── whitelist.conf      # IPs protégées (auto-rempli par install.sh)
├── lib/                    # Logique métier (Bibliothèques)
│   ├── core.lib.sh         # Analyse, extraction et filtrage des logs
│   ├── firewall.lib.sh     # Gestion iptables et persistance
│   ├── tests.lib.sh        # Fonctions de Mock/Simulation
│   └── utils.lib.sh        # Utilitaires (couleurs, checks, config, logs)
├── log/                    # Données volatiles (Historique)
│   └── firewall_activity.log
└── var/                    # Données d'état (Runtime)
    ├── banned_ips.db       # Liste des IPs bannies persistante
    └── reports/            # Rapports de sécurité générés
        └── security_report_YYYY-MM-DD.txt
```

## 🛠️ Installation & Usage

### Prérequis
- Système Linux (Debian/Ubuntu recommandé).
- Droits `sudo` (uniquement pour l'application des règles de pare-feu).

### Installation
```bash
git clone https://github.com/elabs-ops/log-guardian.git
cd log-guardian
chmod +x main.sh
./main.sh --repair ou ./install.sh  # Initialise l'arborescence
```
### Installation rapide
```bash
make install
```

### Les commandes
```bash
# Générer des logs de test (Mocking)
./main.sh --mock

# Néttoyer le journal de logs
./main.sh --flush-logs

# Afficher toutes les tentatives du jour (DATE + IP)
./main.sh --parsed-raw

# Afficher les statistiques des tentatives du jour
./main.sh --stats

# Afficher les tentatives ayant dépassé le seuil de tolérance
./main.sh --malicious

# Identifier les menaces et mettre à jour la base locale
./main.sh --update

# Initialiser/réparer l'arborescence 
./main.sh --repair

# Générer un rapport de sécurité complet
./main.sh --report

# Appliquer réellement les bannissements (Root requis)
sudo ./main.sh --apply-bans

# Réinitialiser les règles (Root requis)
sudo ./main.sh --firewall-flush

# Lister les règles INPUT (Root requis)
sudo ./main.sh --firewall-list

# Affihcer le nombre de règle INPUT (Root requis)
sudo ./main.sh --firewall-status
```

## ⚙️ Configuration
Le fichier `config/guardian.conf` permet de personnaliser le comportement de l'outil :
- `BAN_THRESHOLD` : Nombre d'échecs avant bannissement (Défaut : 5).
- `WHITELIST` : Nom du fichier contenant les IPs à ne jamais bloquer.

## 🧠 Concepts DevOps Appliqués
Ce projet a été conçu pour démontrer la maîtrise des concepts suivants :
- **Modularité (SOLID)** : Séparation stricte des responsabilités entre les scripts.
- **Idempotence** : Le script peut être lancé plusieurs fois sans créer de règles `iptables` redondantes.
- **Gestion du Cycle de Vie** : Rotation des journaux et nettoyage des données de test.
- **Sécurité** : Application du principe de moindre privilège (gestion des fichiers en mode non-root).

## 🧠 Mémo Bash (rappels utiles)

### 🧭 Initialisation de l’environnement

- `$0` : chemin utilisé pour lancer le script (souvent relatif)  
- `readlink -f` : convertit en chemin absolu et résout les liens symboliques  
- `dirname` : extrait le dossier contenant le script  
- Pattern recommandé :

```bash
BASE_DIR=$(dirname "$(readlink -f "$0")")
cd "$BASE_DIR"
```

Permet d’exécuter le script depuis son propre dossier, même lancé depuis ailleurs.

---

### 📥 Lecture de fichiers (`read`)

- `read -r` : lit la ligne telle quelle (ne pas interpréter `\`)  
- `read -p "txt"` : prompt interactif  
- `read -s` : mode silencieux (mot de passe)  
- `read -t 5` : timeout  
- `read -a array` : lecture dans un tableau  
- Boucle standard :

```bash
while read -r line; do
    ...
done < fichier
```

---

### 🔍 Tests de fichiers

- `-e` : existe (fichier, dossier, lien…)  
- `-f` : fichier régulier  
- `-d` : dossier  
- `-s` : fichier non vide  
- `-r / -w / -x` : lisible / modifiable / exécutable  

---

### 🔁 Groupes de commandes

- `( … )` : sous‑shell (variables non persistantes)  
- `{ …; }` : même shell (variables persistantes)  

---

### 🔧 Redirections

- `>` : stdout  
- `>>` : append  
- `2>` : stderr  
- `&>` : stdout + stderr  
- `>&2` : envoyer vers stderr  

---

### 🛡️ iptables — commandes essentielles

- `iptables -L INPUT -n -v --line-numbers` : afficher proprement les règles  
- `-A` : ajouter une règle  
- `-I` : insérer à une position  
- `-D` : supprimer  
- `-C` : vérifier si une règle existe  
- `-j TARGET` : cible (DROP, ACCEPT, LOG, REJECT…)  

---

### 🧰 Exemple : boucle de traitement d’IP

```bash
while read -r ip; do
    if ! iptables -C INPUT -s "$ip" -j DROP &>/dev/null; then
        iptables -A INPUT -s "$ip" -j DROP
        display_success "IP $ip ajoutée au pare-feu."
        log_event "BANNED: $ip"
    fi
done < "$BANNED_IPS_DB"
```


Parfait, je t’intègre **la section RANDOM** directement dans ton **README précédent**, au bon endroit, sous forme d’un sous‑titre `##`, avec la même mise en forme professionnelle que le reste.

Voici la **version fusionnée**, prête à coller dans ton `README.md`.

---

## 🎲 Mémo RANDOM (tests & génération aléatoire)

### 🔢 `$RANDOM`

- Génère un entier pseudo‑aléatoire entre **0 et 32767**.  
- Chaque appel produit une nouvelle valeur.  
- Idéal pour sélectionner un élément au hasard ou simuler des ports éphémères.

---

### 📌 Taille d’un tableau

- `${#ips[@]}` → nombre d’éléments dans le tableau `ips`.

---

### ➗ Modulo (`%`)

- Permet de ramener un nombre dans une plage donnée.  
- Exemple :  
  ```bash
  index=$(( RANDOM % ${#ips[@]} ))
  ```
  → index garanti entre `0` et `n-1`.

---

### 🔥 Générer un port aléatoire réaliste (40000–59999)

- `$RANDOM % 20000` → génère un nombre entre **0 et 19999**  
- `+ 40000` → décale la plage vers **40000..59999**

Exemple :

```bash
port=$(( (RANDOM % 20000) + 40000 ))
echo "Port aléatoire : $port"
```

---

### 🔢 Compter les occurrences et trier les IP par activité

Cette commande permet d’analyser un fichier de logs ou une liste d’IP, puis de classer les adresses de la plus active à la moins active.

```bash
sort fichier.log | uniq -c | sort -rn
```

### 🧩 Décomposition

- **1 — `sort`**  
  Trie les lignes (ici les IP) pour regrouper les occurrences identiques.

- **2 — `uniq -c`**  
  Compte le nombre d’occurrences consécutives et les affiche sur une seule ligne.  
  Exemple :  
  ```
  12  192.168.0.1
  ```

- **3 — `sort -rn`**  
  Trie les résultats :
  - `-r` → ordre décroissant (reverse)
  - `-n` → tri numérique (sur le nombre d’occurrences)

### 🎯 Résultat

Tu obtiens une liste du type :

```
120  203.0.113.45
87   198.51.100.22
14   192.0.2.10
```

→ Très utile pour identifier les IP les plus actives ou suspectes.

---