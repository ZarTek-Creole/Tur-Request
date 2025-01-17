# 🤝 Contribuer à Tur-Request

Merci de votre intérêt pour contribuer à Tur-Request ! Ce document fournit les lignes directrices pour contribuer au projet.

## 📋 Table des matières

- [Code de conduite](#code-de-conduite)
- [Comment contribuer](#comment-contribuer)
  - [Signaler des bugs](#signaler-des-bugs)
  - [Suggérer des améliorations](#suggérer-des-améliorations)
  - [Pull Requests](#pull-requests)
- [Style de code](#style-de-code)
- [Tests](#tests)
- [Documentation](#documentation)

## 📜 Code de conduite

Ce projet et tous ses participants sont régis par notre [Code de Conduite](CODE_OF_CONDUCT.md). En participant, vous acceptez de respecter ce code.

## 🛠️ Comment contribuer

### Signaler des bugs

Les bugs sont tracés via les issues GitHub. Avant de créer une issue :

1. Vérifiez que le bug n'a pas déjà été signalé
2. Assurez-vous d'utiliser la dernière version
3. Créez une issue en utilisant le template Bug Report

Incluez autant d'informations que possible :
- Version de Tur-Request
- Versions des dépendances (Eggdrop, TCL, glFTPd, etc.)
- Étapes pour reproduire
- Comportement attendu vs observé
- Logs pertinents
- Configuration utilisée

### Suggérer des améliorations

Les suggestions sont également gérées via les issues GitHub :

1. Vérifiez que la suggestion n'existe pas déjà
2. Créez une issue en utilisant le template Feature Request
3. Décrivez clairement la fonctionnalité
4. Expliquez pourquoi elle serait utile
5. Proposez une implémentation si possible

### Pull Requests

1. Fork le projet
2. Créez une branche pour votre fonctionnalité (`git checkout -b feature/AmazingFeature`)
3. Committez vos changements (`git commit -m 'Add some AmazingFeature'`)
4. Push sur la branche (`git push origin feature/AmazingFeature`)
5. Ouvrez une Pull Request

Assurez-vous que votre PR :
- A un titre clair et descriptif
- Décrit les changements en détail
- Met à jour la documentation si nécessaire
- Ajoute ou met à jour les tests
- Respecte le style de code
- Est basée sur la dernière version de la branche main

## 🎨 Style de code

### TCL

```tcl
# Nommage
set variable_name "value"              # Variables en snake_case
proc my_procedure {arg1 arg2} { ... }  # Procédures en snake_case
namespace eval ::my_namespace { ... }   # Namespaces en snake_case

# Indentation
if {$condition} {
    # 4 espaces d'indentation
    set var "value"
}

# Commentaires
# Commentaire sur une ligne

###############################################################################
# Section majeure
###############################################################################

# Documentation proc
proc my_proc {arg1 arg2} {
    # Description: Ce que fait la procédure
    # Args:
    #   arg1: Description de arg1
    #   arg2: Description de arg2
    # Returns:
    #   Description de la valeur retournée
    
    # Code...
}
```

### Shell

```bash
# Nommage
local variable_name="value"  # Variables en snake_case
my_function() { ... }       # Fonctions en snake_case

# Indentation
if [ "$condition" ]; then
    # 4 espaces d'indentation
    echo "True"
fi

# Commentaires comme ci-dessus
```

## 🧪 Tests

- Les tests sont écrits avec tcltest
- Chaque fonctionnalité doit avoir des tests
- Les tests doivent être dans `tests/`
- Exécutez `tclsh tests/test_tur-request.tcl` avant de soumettre

### Structure des tests

```tcl
test nom-1 "Description du test" {
    # Setup
    set result [proc_to_test "arg"]
    
    # Test
    expr {$result eq "expected"}
} 1
```

## 📚 Documentation

- Mettez à jour README.md si nécessaire
- Documentez les nouvelles fonctionnalités
- Mettez à jour les commentaires dans le code
- Suivez le format de documentation existant

### Format documentation

```tcl
###############################################################################
# Nom du module
# Description du module
###############################################################################

# Description namespace
namespace eval ::my_namespace {
    # Description variable
    variable my_var
    
    # Description procédure
    proc my_proc {arg1 arg2} {
        # Documentation...
    }
}
```

## 🙏 Merci !

Encore une fois, merci de contribuer à Tur-Request ! 