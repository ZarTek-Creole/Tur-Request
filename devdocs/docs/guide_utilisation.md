# 📖 Guide d'Utilisation Tur-Request

## 🚀 1. Commandes de Base

### 1.1 Commandes SITE
```bash
# Commandes glFTPd
SITE REQUEST <nom>      # Créer une requête via FTP
SITE REQFILL <id>      # Remplir une requête
SITE REQWIPE <id>      # Supprimer une requête
SITE REQLIST           # Liste des requêtes
SITE REQINFO <id>      # Info détaillée

# Options Avancées
SITE REQUEST -p <prio> <nom>    # Avec priorité
SITE REQUEST -t <tag> <nom>     # Avec tag
SITE REQUEST -n <note> <nom>    # Avec note
```

### 1.2 Permissions Requises
```yaml
Flags Utilisateur:
  1FLAG:
    - Création requêtes
    - Consultation status
    - Liste requêtes
    - Annulation propres requêtes

  2FLAG:
    - Remplissage requêtes
    - Modification status
    - Stats basiques
    - Recherche avancée

  3FLAG:
    - Administration complète
    - Gestion priorités
    - Suppression requêtes
    - Stats avancées
```

### 1.3 Sécurité
```yaml
Restrictions:
  Requêtes:
    - Max actives: 5 par user
    - Taille max: 256 chars
    - Cooldown: 5 minutes
    - Blacklist mots

  Remplissage:
    - Vérification droits
    - Log des actions
    - Confirmation requise
    - Notification admin
```

### 1.2 Gestion
```bash
# Admin Commandes
!approve <id>     # Approuver requête
!deny <id>        # Refuser requête
!edit <id>        # Modifier requête
!move <id>        # Déplacer requête

# Stats & Info
!stats            # Statistiques requêtes
!top              # Top requesters
!info <id>        # Info détaillée
```

## 📊 2. Fonctionnalités Avancées

### 2.1 Priorités & Tags
```yaml
Priorités:
  1: Urgent
  2: Haute
  3: Normale
  4: Basse
  5: Très basse

Tags:
  - NEW: Nouvelle release
  - OLD: Ancien contenu
  - COMPLETE: Collection complète
  - SPECIFIC: Version spécifique
```

### 2.2 Notifications
```yaml
Types:
  - Création requête
  - Status update
  - Complétion
  - Expiration

Canaux:
  - IRC privé
  - Channel public
  - Channel staff
```

## 🔧 3. Configuration Utilisateur

### 3.1 Préférences
```yaml
Settings:
  Notifications:
    - PM: on/off
    - Channel: on/off
    - Type: all/important
    
  Display:
    - Format: court/long
    - Couleurs: on/off
    - Timestamps: on/off
```

### 3.2 Filtres & Recherche
```yaml
Filtres:
  - Status
  - Priorité
  - Date
  - Tag
  
Search:
  !search <terme>     # Recherche simple
  !search -t <tag>    # Recherche par tag
  !search -d <date>   # Recherche par date
```

## 📝 4. Règles & Limites

### 4.1 Règles Requêtes
```yaml
Limites:
  - Max requêtes actives: 5
  - Temps expiration: 7 jours
  - Min chars description: 10
  - Max requêtes/jour: 10

Restrictions:
  - Pas de doublons
  - Pas de spam
  - Format correct
  - Description claire
```

### 4.2 Points & Crédits
```yaml
Système Points:
  Gain:
    - Requête complétée: +10
    - Bonus rapidité: +5
    - Bonus qualité: +3
    
  Perte:
    - Requête expirée: -5
    - Annulation: -2
    - Mauvais format: -1
```

## 🔍 5. Troubleshooting

### 5.1 Problèmes Courants
```yaml
Erreurs:
  - Format invalide
  - Limite atteinte
  - Doublon détecté
  - Permission denied

Solutions:
  - Vérifier syntaxe
  - Attendre expiration
  - Chercher existant
  - Contacter staff
```

### 5.2 Support
```yaml
Aide:
  - !help              # Aide générale
  - !help request      # Aide requêtes
  - !help admin        # Aide admin
  - !help search       # Aide recherche

Contact:
  - Channel: #request-help
  - Staff: !staff
  - FAQ: !faq
```

## 🤖 3. Interface IRC

### 3.1 Commandes Utilisateur
```bash
# Gestion Requêtes
!request <nom>           # Créer une requête
!status [id]            # Status d'une/toutes les requêtes
!list [pattern]         # Liste des requêtes (avec filtre optionnel)
!search <terme>         # Recherche dans les requêtes
!cancel <id>            # Annuler sa requête

# Options Avancées
!request -p <1-5> <nom>      # Définir priorité (1=urgent)
!request -t <tag> <nom>      # Ajouter tag
!request -n "note" <nom>     # Ajouter note
!request -w <semaines> <nom> # Définir durée validité
```

### 3.2 Commandes Admin
```bash
# Administration
!approve <id> [note]    # Approuver requête
!deny <id> [raison]     # Refuser requête
!edit <id> <champ> <valeur>  # Modifier requête
!move <id> <section>    # Déplacer requête
!wipe <id> [raison]     # Supprimer requête

# Gestion
!ban <user> [durée]     # Bannir utilisateur
!unban <user>          # Débannir utilisateur
!clean [jours]         # Nettoyer anciennes requêtes
!reload                # Recharger configuration
```

### 3.3 Système Notifications
```yaml
Types Message:
  Requête:
    - Création: Format standard
    - Update: Changement status
    - Complétion: Détails fill
    - Expiration: Avertissement

  Admin:
    - Approbation: Confirmation
    - Refus: Avec raison
    - Modification: Détails changement
    - Système: Alerts & Warnings

Format:
  Standard: [REQ-#ID] User » Action | Details
  Alert: [!] Message important
  Error: [X] Message d'erreur
  Success: [✓] Confirmation action
```

### 3.4 Personnalisation
```yaml
Préférences:
  Notifications:
    - Mode: NOTICE/PRIVMSG
    - Cible: Chan/Query
    - Format: Court/Long
    - Couleurs: On/Off

  Affichage:
    - Timestamps: On/Off
    - Couleurs: ANSI/mIRC
    - Langue: FR/EN
    - Verbosité: 1-3

  Alertes:
    - Expiration: 24h/12h/6h
    - Updates: On/Off
    - Mentions: On/Off
    - Sons: On/Off
```

##  2. Intégration pzs-ng

### 2.1 Système de Race
```yaml
Comportement Race:
  Détection:
    - Vérification requêtes actives
    - Match pattern release
    - Validation format
    - Check doublons

  Complétion:
    - Update status requête
    - Notification utilisateur
    - Mise à jour stats
    - Log événement

  Post-Processing:
    - Cleanup automatique
    - Archive requête
    - Update historique
    - Génération rapport
```

### 2.2 Stats & Métriques
```yaml
Statistiques:
  Requêtes:
    - Total complétées
    - Temps moyen remplissage
    - Ratio succès/échec
    - Distribution par section

  Performance:
    - Temps traitement
    - Utilisation ressources
    - Queue status
    - Cache hits/misses

  Utilisateurs:
    - Top requesters
    - Top fillers
    - Ratio activité
    - Points accumulation
```

### 2.3 Hooks & Events
```yaml
Events System:
  Pre-Request:
    - Validation format
    - Check permissions
    - Vérification quota
    - Anti-spam check

  During-Race:
    - Match patterns
    - Update progress
    - Notify status
    - Track completion

  Post-Complete:
    - Update database
    - Generate stats
    - Send notifications
    - Cleanup resources
``` 