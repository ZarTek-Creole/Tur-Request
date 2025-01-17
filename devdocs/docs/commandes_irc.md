# 🤖 Commandes IRC Tur-Request

## 📋 1. Commandes de Base

### !request (Gestion des requêtes)

| Commande | Description | Exemple |
|----------|-------------|---------|
| `!request new <titre> [détails]` | Créer une nouvelle requête | `!request new "Matrix 2023" "AMZN WEB-DL 1080p"` |
| `!request info <id>` | Voir les détails d'une requête | `!request info 42` |
| `!request list [status]` | Liste des requêtes actives | `!request list pending` |
| `!request search <terme>` | Rechercher dans les requêtes | `!request search Matrix` |
| `!request cancel <id>` | Annuler une requête | `!request cancel 42` |
| `!request fill <id> <path>` | Remplir une requête | `!request fill 42 /site/incoming/release` |

#### Exemples d'utilisation :
```irc
<user> !request new "Top Gun Maverick" "1080p HDR"
<bot> Requête créée avec ID: 123
<bot> ⭐ Nouvelle Requête #123 - Top Gun Maverick - Par: user

<user> !request info 123
<bot> 📝 Requête #123:
<bot> Titre: Top Gun Maverick
<bot> Status: En attente
<bot> Créée par: user
<bot> Date: 2024-01-20 15:30
```

### !search (Recherche avancée)

| Commande | Description | Exemple |
|----------|-------------|---------|
| `!search <terme>` | Recherche simple | `!search Matrix` |
| `!search -u <user>` | Recherche par utilisateur | `!search -u johndoe` |
| `!search -s <status>` | Recherche par status | `!search -s filled` |
| `!search -d <date>` | Recherche par date | `!search -d 2024-01` |

#### Options de recherche :
- `-u, --user` : Filtrer par utilisateur
- `-s, --status` : Filtrer par status (new, pending, filled, cancelled)
- `-d, --date` : Filtrer par date (YYYY-MM-DD)
- `-t, --tag` : Filtrer par tag

## 🔧 2. Commandes Avancées

### !admin (Administration)

| Commande | Description | Exemple |
|----------|-------------|---------|
| `!admin adduser <user> <flags>` | Ajouter un utilisateur | `!admin adduser john +request` |
| `!admin deluser <user>` | Supprimer un utilisateur | `!admin deluser john` |
| `!admin setflags <user> <flags>` | Modifier les flags | `!admin setflags john +admin` |
| `!admin reload` | Recharger la configuration | `!admin reload` |
| `!admin cleanup` | Nettoyage système | `!admin cleanup` |

#### Flags disponibles :
- `+request` : Peut créer des requêtes
- `+fill` : Peut remplir des requêtes
- `+admin` : Accès administrateur
- `+mod` : Accès modérateur

### !stats (Statistiques)

| Commande | Description | Exemple |
|----------|-------------|---------|
| `!stats` | Statistiques globales | `!stats` |
| `!stats user <name>` | Stats utilisateur | `!stats user john` |
| `!stats top` | Top utilisateurs | `!stats top` |
| `!stats daily` | Stats journalières | `!stats daily` |

#### Exemple de sortie stats :
```irc
<user> !stats
<bot> 📊 Statistiques Tur-Request:
<bot> Requêtes totales: 1,234
<bot> Requêtes actives: 42
<bot> Taux de remplissage: 85%
<bot> Utilisateurs actifs: 123
```

## 🎨 3. Personnalisation

### !prefs (Préférences)

| Commande | Description | Exemple |
|----------|-------------|---------|
| `!prefs set <option> <value>` | Définir une préférence | `!prefs set notify on` |
| `!prefs get <option>` | Voir une préférence | `!prefs get notify` |
| `!prefs list` | Liste des préférences | `!prefs list` |
| `!prefs reset` | Réinitialiser | `!prefs reset` |

#### Options disponibles :
- `notify` : Notifications (on/off)
- `format` : Format d'affichage (compact/full)
- `lang` : Langue (fr/en)
- `timezone` : Fuseau horaire

## 🏷️ 4. Tags & Catégories

### !tag (Gestion des tags)

| Commande | Description | Exemple |
|----------|-------------|---------|
| `!tag add <id> <tags...>` | Ajouter des tags | `!tag add 123 movie 1080p` |
| `!tag remove <id> <tag>` | Retirer un tag | `!tag remove 123 1080p` |
| `!tag list <id>` | Liste des tags | `!tag list 123` |
| `!tag search <tag>` | Rechercher par tag | `!tag search movie` |

#### Tags populaires :
- `movie` : Films
- `tv` : Séries TV
- `music` : Musique
- `software` : Logiciels
- `1080p`, `2160p` : Qualité
- `x264`, `x265` : Codec

## 📊 5. Points & Crédits

### !points (Système de points)

| Commande | Description | Exemple |
|----------|-------------|---------|
| `!points` | Voir ses points | `!points` |
| `!points user <name>` | Points d'un utilisateur | `!points user john` |
| `!points top` | Classement | `!points top` |
| `!points history` | Historique | `!points history` |

#### Gain de points :
- Création requête : +1 point
- Remplissage requête : +5 points
- Requête populaire : +2 points
- Rapidité remplissage : +3 points

## 🚨 6. Alertes & Notifications

### !notify (Notifications)

| Commande | Description | Exemple |
|----------|-------------|---------|
| `!notify on` | Activer notifications | `!notify on` |
| `!notify off` | Désactiver notifications | `!notify off` |
| `!notify add <pattern>` | Ajouter alerte | `!notify add Matrix*` |
| `!notify list` | Liste des alertes | `!notify list` |
| `!notify remove <id>` | Supprimer alerte | `!notify remove 1` |

#### Types de notifications :
- Nouvelle requête correspondant au pattern
- Remplissage de vos requêtes
- Mentions dans les commentaires
- Alertes système

## 💡 7. Aide & Support

### !help (Aide)

| Commande | Description | Exemple |
|----------|-------------|---------|
| `!help` | Aide générale | `!help` |
| `!help <command>` | Aide spécifique | `!help request` |
| `!help advanced` | Commandes avancées | `!help advanced` |
| `!help admin` | Aide administration | `!help admin` |

#### Sections d'aide :
```irc
<user> !help
<bot> 📚 Aide Tur-Request:
<bot> !request : Gestion des requêtes
<bot> !search  : Recherche avancée
<bot> !stats   : Statistiques
<bot> !admin   : Administration
<bot> !help <commande> pour plus de détails
``` 