# 🚀 Tur-Request v2.0.0

Un système de requêtes avancé pour glFTPd avec intégration Eggdrop et pzs-ng.

## 📋 Caractéristiques

- Interface IRC complète via Eggdrop
- Intégration avec pzs-ng pour l'auto-fill
- Système de points et crédits
- Base de données SQLite
- Support multi-sections
- Système de tags et recherche
- Gestion avancée des permissions
- Monitoring et statistiques

## 🔧 Prérequis

- Eggdrop 1.8+
- TCL 8.5+
- SQLite 3
- glFTPd 2.0+
- pzs-ng (optionnel pour auto-fill)

## 📥 Installation

1. **Copier les fichiers**
```bash
cd /path/to/eggdrop/scripts/
git clone https://github.com/your/tur-request.git
cd tur-request
```

2. **Configuration**
```bash
cp tur-request.conf.default tur-request.conf
vim tur-request.conf
```

3. **Charger le script**

Ajouter dans votre `eggdrop.conf`:
```tcl
source scripts/tur-request/tur-request.tcl
```

4. **Initialisation base de données**

La base de données sera créée automatiquement au premier démarrage.

## 🎯 Commandes IRC

### Commandes Utilisateurs

| Commande | Description | Exemple |
|----------|-------------|---------|
| `!request new <titre> [détails]` | Créer une requête | `!request new "Matrix 2023" "AMZN WEB-DL 1080p"` |
| `!request info <id>` | Voir les détails | `!request info 42` |
| `!request list [status]` | Liste des requêtes | `!request list pending` |
| `!request search <terme>` | Rechercher | `!request search Matrix` |
| `!request cancel <id>` | Annuler une requête | `!request cancel 42` |
| `!fill <id> <path>` | Remplir une requête | `!fill 42 /site/incoming/release` |

### Commandes Admin

| Commande | Description | Exemple |
|----------|-------------|---------|
| `!reqadmin clean` | Nettoyage ancien | `!reqadmin clean` |
| `!reqadmin del <id>` | Supprimer requête | `!reqadmin del 42` |
| `!reqadmin ban <user>` | Bannir utilisateur | `!reqadmin ban john` |
| `!reqstats` | Voir statistiques | `!reqstats` |

## ⚙️ Configuration

Le fichier `tur-request.conf` contient toutes les options configurables :

- Canaux IRC
- Limites requêtes
- Points & crédits
- Auto-fill
- Sections autorisées
- Format messages
- etc.

Voir `tur-request.conf.default` pour la liste complète des options.

## 🔌 Intégration pzs-ng

Pour activer l'auto-fill avec pzs-ng :

1. Activer dans la config :
```tcl
set ::turrequest::pzs::config(enabled) 1
set ::turrequest::pzs::config(auto_fill) 1
```

2. Configurer le score minimum de correspondance :
```tcl
set ::turrequest::pzs::config(match_score) 0.8
```

3. Exclure certains dossiers :
```tcl
set ::turrequest::pzs::config(exclude_dirs) {
    sample proof
}
```

## 📊 Système de Points

Les points sont gagnés/perdus selon les actions :

- Création requête : -5 points
- Remplissage requête : +10 points
- Upload : +1 point
- Download : -1 point

Les multiplicateurs par groupe :
- STAFF : x2.0
- VIP : x1.5
- DEFAULT : x1.0

## 🔒 Sécurité

- Validation des chemins
- Protection contre le flood
- Système de ban
- Permissions par groupe
- Quotas et limites
- Logging complet

## 📝 Logging

Les logs sont stockés dans `tur-request.log` avec rotation :

- Niveau configurable (DEBUG, INFO, WARN, ERROR)
- Taille maximum par fichier
- Nombre de fichiers de rotation

## 🤝 Contribution

Les contributions sont les bienvenues ! Voir `CONTRIBUTING.md` pour les détails.

## 📄 Licence

Ce projet est sous licence MIT. Voir `LICENSE` pour plus de détails.

## 🙏 Remerciements

- L'équipe glFTPd
- L'équipe pzs-ng
- La communauté Eggdrop
- Tous les contributeurs

## 📧 Contact

Pour les bugs et suggestions, merci d'ouvrir une issue sur GitHub. 