#!/bin/bash

# Import des fonctions d'animation
source "$(dirname "$0")/matrix.sh"

# Fonction de nettoyage
cleanup() {
    stop_matrix_background
    echo -e "\n${RED}Installation interrompue${NC}"
    exit 1
}

# Capture des signaux d'interruption
trap cleanup SIGINT SIGTERM

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Démarrer l'effet matrix en arrière-plan
start_matrix_background

# ASCII Art stylé
ASCII_ART="
 ██████╗ ██╗  ██╗██╗   ██╗███████╗██████╗ ████████╗ ██████╗ ██╗  ██╗███████╗▄▄███▄▄╗
██▄████╗╚██╗██▄╝██╗   ██╗██▄▄▄▄█╗██▄▄▄▄█╗   ██╗   ██▄▄▄▄█╗██╗ ██▄╝██▄▄▄▄█╗██▄▄▄▄▄╝
██╗██▄██╗ ╚███▄╝ ██╗   ██╗█████▄╝ █████▄╝    ██╗   ██████▄╝█████▄╝ █████╗ ██████╗
████▄╝██╗ ██▄██╗ ╚██╗ ██▄╝██▄▄▄▄█╗██▄▄▄▄█╗   ██╗   ██▄▄▄▄█╗██▄▄▄▄█╗██▄▄▄╝ ╚▄▄▄▄██╗
╚█████▄╝██▄╝ ██╗ ╚████▄╝ ██╗  ██╗██╗  ██╗   ██╗   ██╗  ██╗██╗  ██╗██╗  ██╗███████╗
 ╚▄▄▄▄╝ ╚▄╝  ╚▄╝  ╚▄▄▄╝  ╚▄╝  ╚▄╝╚▄╝  ╚▄╝   ╚▄╝   ╚▄╝  ╚▄╝╚▄╝  ╚▄╝╚▄╝  ╚▄╝╚▄▄▄▄▄▄╝
"

show_ascii_art "$ASCII_ART"

echo -e "${BLUE}=== Installation de OnTheSpot sur Raspberry Pi ===${NC}"

# Vérifier si on est sur un Raspberry Pi
if ! grep -q "Raspberry Pi" /proc/cpuinfo; then
    echo -e "${RED}Ce script doit être exécuté sur un Raspberry Pi${NC}"
    exit 1
fi

# Vérifier les privilèges root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Ce script doit être exécuté en tant que root (sudo)${NC}"
    exit 1
fi

# Définir le dossier d'installation
INSTALL_DIR="/home/trn/onthespot"
SERVICE_NAME="onthespot"
USER="trn"

# Effet matrix déjà en cours
echo -e "\n${CYAN}[INITIALIZING SYSTEM UPGRADE SEQUENCE]${NC}"
cyber_loading "Scanning system components" 3
echo -e "${BLUE}1. Mise à jour du système...${NC}"
progress_bar "System Update" 3
apt update && apt upgrade -y

echo -e "\n${CYAN}[INSTALLING CORE DEPENDENCIES]${NC}"
cyber_loading "Analyzing required packages" 2
echo -e "${BLUE}2. Installation des dépendances système...${NC}"
# Mise à jour des dépôts et outils de base
apt install -y software-properties-common apt-transport-https ca-certificates curl gnupg
apt update

# Outils de développement essentiels
echo -e "${BLUE}2.1 Installation des outils de développement...${NC}"
apt install -y build-essential pkg-config cmake ninja-build git

# Dépendances multimédia
echo -e "${BLUE}2.2 Installation des dépendances multimédia...${NC}"
apt install -y ffmpeg libavcodec-dev libavformat-dev libswscale-dev

# Outils réseau et sécurité
echo -e "${BLUE}2.3 Installation des outils réseau...${NC}"
apt install -y iptables ufw net-tools

# Dépendances Python de base
echo -e "${BLUE}2.4 Installation des dépendances Python...${NC}"
apt install -y python3-pip python3-venv python3-dev \
    python3-wheel python3-setuptools

echo -e "${BLUE}2.5 Configuration du firewall...${NC}"
# Vérification du statut de UFW
if ! systemctl is-active --quiet ufw; then
    echo -e "${YELLOW}Activation du service UFW...${NC}"
    systemctl enable ufw
    systemctl start ufw
fi

# Configuration du firewall
echo -e "${YELLOW}Configuration des règles du firewall...${NC}"
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 5000/tcp comment 'OnTheSpot Web Interface'
ufw --force enable

# Afficher le statut du firewall
echo -e "${GREEN}Statut du firewall :${NC}"
ufw status verbose

echo -e "${BLUE}3. Création du dossier d'installation...${NC}"
mkdir -p $INSTALL_DIR
chown $USER:$USER $INSTALL_DIR

echo -e "${BLUE}4. Clonage du projet...${NC}"
cd $INSTALL_DIR
sudo -u $USER git clone https://github.com/0xverTake/onthespot.git .

echo -e "\n${CYAN}[CONFIGURING PYTHON MATRIX]${NC}"
cyber_loading "Initializing virtual environment" 2
echo -e "${BLUE}5. Configuration de l'environnement Python...${NC}"

# Création et activation de l'environnement virtuel
echo -e "${BLUE}5.1 Création de l'environnement virtuel...${NC}"
sudo -u $USER python3 -m venv venv

# Mise à jour des outils de base Python
echo -e "${BLUE}5.2 Mise à jour pip...${NC}"
sudo -u $USER venv/bin/pip install --upgrade pip setuptools wheel

# Installation des dépendances
echo -e "${BLUE}5.3 Installation des dépendances du projet...${NC}"
# Installation des dépendances depuis requirements.txt
sudo -u $USER venv/bin/pip install -r requirements.txt

# Installation des dépendances Flask et ses composants essentiels
echo -e "${BLUE}5.4 Installation des dépendances Flask...${NC}"
sudo -u $USER venv/bin/pip install flask werkzeug jinja2 click itsdangerous
sudo -u $USER venv/bin/pip install flask-cors python-dotenv requests urllib3

# Vérification de l'installation de Flask
echo -e "${BLUE}5.5 Vérification de l'installation...${NC}"
if ! sudo -u $USER venv/bin/python -c "import flask, werkzeug" 2>/dev/null; then
    echo -e "${RED}Erreur: Flask ou ses dépendances ne sont pas correctement installées${NC}"
    exit 1
fi

# Création du service systemd
echo -e "${BLUE}7. Création du service systemd...${NC}"
cat > /etc/systemd/system/$SERVICE_NAME.service << EOL
[Unit]
Description=OnTheSpot Music Server
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$INSTALL_DIR/src
ExecStart=/home/trn/onthespot/venv/bin/python /home/trn/onthespot/src/web_app.py
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOL

# Configuration des permissions
echo -e "${BLUE}8. Configuration des permissions...${NC}"
chown -R $USER:$USER $INSTALL_DIR
chmod 755 $INSTALL_DIR

# Activation et démarrage du service
echo -e "${BLUE}9. Activation du service...${NC}"
systemctl daemon-reload
systemctl enable $SERVICE_NAME
systemctl start $SERVICE_NAME

# Création du dossier de téléchargement avec les bonnes permissions
echo -e "${BLUE}10. Création du dossier de téléchargement...${NC}"
mkdir -p $INSTALL_DIR/downloads
chown -R $USER:$USER $INSTALL_DIR/downloads
chmod 755 $INSTALL_DIR/downloads

# Vérification du service
echo -e "${BLUE}11. Vérification du statut du service...${NC}"
systemctl status $SERVICE_NAME

# Vérifier les logs pour les erreurs
echo -e "${BLUE}12. Vérification des logs...${NC}"
journalctl -u $SERVICE_NAME --no-pager -n 50

# Obtenir l'adresse IP
IP_ADDRESS=$(hostname -I | cut -d' ' -f1)

# Effet matrix déjà en cours
echo -e "\n${GREEN}╔════════════════════════════════════╗${NC}"
echo -e "${GREEN}║     Installation terminée !        ║${NC}"
echo -e "${GREEN}║  Système prêt pour exécution     ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════╝${NC}"
echo -e "${GREEN}OnTheSpot est maintenant installé et configuré sur votre Raspberry Pi${NC}"
echo -e "${GREEN}Vous pouvez y accéder à l'adresse : http://$IP_ADDRESS:5000${NC}"
echo -e "\nCommandes utiles :"
echo -e "${BLUE}- Voir les logs :${NC} sudo journalctl -u $SERVICE_NAME -f"
echo -e "${BLUE}- Redémarrer le service :${NC} sudo systemctl restart $SERVICE_NAME"
echo -e "${BLUE}- Arrêter le service :${NC} sudo systemctl stop $SERVICE_NAME"
echo -e "${BLUE}- Voir le statut :${NC} sudo systemctl status $SERVICE_NAME"

# Arrêt propre de l'effet matrix
sleep 2  # Pause pour voir le message final
stop_matrix_background
