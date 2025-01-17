#!/bin/bash

###############################################################################
# Script d'installation Tur-Request v2.0.0
###############################################################################

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Configuration par défaut
GLROOT="/glftpd"
EGGDROP_DIR="/home/eggdrop/eggdrop"
INSTALL_DIR="$EGGDROP_DIR/scripts/tur-request"

# Fonctions
check_dependencies() {
    echo -e "${YELLOW}Vérification des dépendances...${NC}"
    
    # Vérification TCL
    if ! command -v tclsh &> /dev/null; then
        echo -e "${RED}Erreur: TCL n'est pas installé${NC}"
        exit 1
    fi
    
    # Vérification SQLite
    if ! command -v sqlite3 &> /dev/null; then
        echo -e "${RED}Erreur: SQLite3 n'est pas installé${NC}"
        exit 1
    fi
    
    # Vérification glFTPd
    if [ ! -d "$GLROOT" ]; then
        echo -e "${RED}Erreur: glFTPd n'est pas installé dans $GLROOT${NC}"
        exit 1
    fi
    
    # Vérification Eggdrop
    if [ ! -d "$EGGDROP_DIR" ]; then
        echo -e "${RED}Erreur: Eggdrop n'est pas installé dans $EGGDROP_DIR${NC}"
        exit 1
    }
    
    echo -e "${GREEN}Toutes les dépendances sont satisfaites${NC}"
}

create_directories() {
    echo -e "${YELLOW}Création des répertoires...${NC}"
    
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$INSTALL_DIR/logs"
    mkdir -p "$INSTALL_DIR/db"
    
    echo -e "${GREEN}Répertoires créés${NC}"
}

copy_files() {
    echo -e "${YELLOW}Copie des fichiers...${NC}"
    
    # Copie fichiers principaux
    cp tur-request.tcl "$INSTALL_DIR/"
    cp tur-request.auth.tcl "$INSTALL_DIR/"
    cp tur-request.pzs.tcl "$INSTALL_DIR/"
    
    # Copie configuration
    if [ ! -f "$INSTALL_DIR/tur-request.conf" ]; then
        cp tur-request.conf.default "$INSTALL_DIR/tur-request.conf"
    else
        cp tur-request.conf.default "$INSTALL_DIR/tur-request.conf.new"
        echo -e "${YELLOW}Configuration existante détectée, nouvelle config sauvegardée dans tur-request.conf.new${NC}"
    fi
    
    # Copie documentation
    cp README.md "$INSTALL_DIR/"
    cp LICENSE "$INSTALL_DIR/"
    
    echo -e "${GREEN}Fichiers copiés${NC}"
}

set_permissions() {
    echo -e "${YELLOW}Configuration des permissions...${NC}"
    
    # Permissions répertoires
    chmod 755 "$INSTALL_DIR"
    chmod 755 "$INSTALL_DIR/logs"
    chmod 755 "$INSTALL_DIR/db"
    
    # Permissions fichiers
    chmod 644 "$INSTALL_DIR"/*.tcl
    chmod 644 "$INSTALL_DIR"/*.conf*
    chmod 644 "$INSTALL_DIR"/README.md
    chmod 644 "$INSTALL_DIR"/LICENSE
    
    echo -e "${GREEN}Permissions configurées${NC}"
}

configure_eggdrop() {
    echo -e "${YELLOW}Configuration Eggdrop...${NC}"
    
    # Vérification configuration existante
    if grep -q "source scripts/tur-request/tur-request.tcl" "$EGGDROP_DIR/eggdrop.conf"; then
        echo -e "${YELLOW}Configuration Eggdrop déjà présente${NC}"
        return
    fi
    
    # Ajout configuration
    echo "" >> "$EGGDROP_DIR/eggdrop.conf"
    echo "# Tur-Request v2.0.0" >> "$EGGDROP_DIR/eggdrop.conf"
    echo "source scripts/tur-request/tur-request.tcl" >> "$EGGDROP_DIR/eggdrop.conf"
    
    echo -e "${GREEN}Configuration Eggdrop mise à jour${NC}"
}

run_tests() {
    echo -e "${YELLOW}Exécution des tests...${NC}"
    
    cd "$INSTALL_DIR/tests"
    tclsh test_tur-request.tcl
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Tests réussis${NC}"
    else
        echo -e "${RED}Erreur: Certains tests ont échoué${NC}"
        exit 1
    fi
}

# Menu principal
echo "=== Installation Tur-Request v2.0.0 ==="
echo ""
echo "Cette installation va:"
echo "1. Vérifier les dépendances"
echo "2. Créer les répertoires nécessaires"
echo "3. Copier les fichiers"
echo "4. Configurer les permissions"
echo "5. Configurer Eggdrop"
echo "6. Exécuter les tests"
echo ""
echo -n "Continuer? (o/n) "
read -r response

if [ "$response" != "o" ]; then
    echo -e "${YELLOW}Installation annulée${NC}"
    exit 0
fi

# Exécution installation
check_dependencies
create_directories
copy_files
set_permissions
configure_eggdrop
run_tests

echo ""
echo -e "${GREEN}Installation terminée avec succès!${NC}"
echo ""
echo "Pour finaliser l'installation:"
echo "1. Éditer $INSTALL_DIR/tur-request.conf"
echo "2. Redémarrer Eggdrop"
echo ""
echo "Documentation disponible dans $INSTALL_DIR/README.md"
``` 