#!/bin/bash

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# ASCII Art stylé avec des caractères UTF-8
# Couleur vert acide (bright green)
echo -e "\033[38;5;82m"
cat << "EOF"


 ██████╗ ██╗  ██╗██╗   ██╗███████╗██████╗ ████████╗ █████╗ ██╗  ██╗███████╗▄▄███▄▄·
██╔═████╗╚██╗██╔╝██║   ██║██╔════╝██╔══██╗╚══██╔══╝██╔══██╗██║ ██╔╝██╔════╝██╔════╝
██║██╔██║ ╚███╔╝ ██║   ██║█████╗  ██████╔╝   ██║   ███████║█████╔╝ █████╗  ███████╗
████╔╝██║ ██╔██╗ ╚██╗ ██╔╝██╔══╝  ██╔══██╗   ██║   ██╔══██║██╔═██╗ ██╔══╝  ╚════██║
╚██████╔╝██╔╝ ██╗ ╚████╔╝ ███████╗██║  ██║   ██║   ██║  ██║██║  ██╗███████╗███████║
 ╚═════╝ ╚═╝  ╚═╝  ╚═══╝  ╚══════╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═▀▀▀══╝
                                                                                   

EOF

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
INSTALL_DIR="/opt/onthespot"
SERVICE_NAME="onthespot"
USER="trn"

echo -e "${BLUE}1. Mise à jour du système...${NC}"
apt update && apt upgrade -y

echo -e "${BLUE}2. Installation des dépendances système...${NC}"
# Mise à jour des dépôts et outils de base
apt install -y software-properties-common apt-transport-https ca-certificates curl gnupg
apt update

# Outils de développement essentiels
echo -e "${BLUE}2.1 Installation des outils de développement...${NC}"
apt install -y build-essential pkg-config cmake ninja-build git

# Dépendances Python
echo -e "${BLUE}2.2 Installation des dépendances Python...${NC}"
apt install -y python3-pip python3-venv python3-dev python3-wheel

# Dépendances Qt et GUI
echo -e "${BLUE}2.3 Installation des dépendances Qt...${NC}"
apt install -y qt6-base-dev qt6-base-private-dev \
    qt6-declarative-dev qt6-declarative-private-dev \
    qt6-tools-dev qt6-tools-dev-tools \
    qt6-l10n-tools qt6-translations-l10n \
    qmake6 \
    libgl1-mesa-dev libglib2.0-dev

# Dépendances multimédia
echo -e "${BLUE}2.4 Installation des dépendances multimédia...${NC}"
apt install -y ffmpeg libavcodec-dev libavformat-dev libswscale-dev

# Outils réseau et sécurité
echo -e "${BLUE}2.5 Installation des outils réseau...${NC}"
apt install -y iptables ufw net-tools

echo -e "${BLUE}2.1 Configuration du firewall...${NC}"
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

echo -e "${BLUE}5. Création de l'environnement virtuel...${NC}"
sudo -u $USER python3 -m venv venv
source venv/bin/activate

echo -e "${BLUE}6. Installation des dépendances Python...${NC}"
# Mise à jour des outils de base Python
echo -e "${BLUE}6.1 Mise à jour pip, setuptools, wheel...${NC}"
sudo -u $USER venv/bin/pip install --upgrade pip setuptools wheel

# Configuration de l'environnement Qt6
echo -e "${BLUE}6.2 Configuration de Qt6...${NC}"
export QT_SELECT=qt6
export QMAKE=/usr/lib/qt6/bin/qmake

# Installation des composants PyQt6 dans le bon ordre
echo -e "${BLUE}6.3 Installation de PyQt6 et ses dépendances...${NC}"
sudo -u $USER venv/bin/pip install sip PyQt6-sip
sudo -u $USER venv/bin/pip install PyQt6-Qt6
sudo -u $USER venv/bin/pip install --no-deps PyQt6

# Installation des dépendances du projet
echo -e "${BLUE}6.4 Installation des dépendances du projet...${NC}"
sudo -u $USER venv/bin/pip install -r requirements.txt

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
Environment=PATH=$INSTALL_DIR/venv/bin:$PATH
ExecStart=$INSTALL_DIR/venv/bin/python web_app.py
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

# Obtenir l'adresse IP
IP_ADDRESS=$(hostname -I | cut -d' ' -f1)

echo -e "\n${GREEN}=== Installation terminée ! ===${NC}"
echo -e "${GREEN}OnTheSpot est maintenant installé et configuré sur votre Raspberry Pi${NC}"
echo -e "${GREEN}Vous pouvez y accéder à l'adresse : http://$IP_ADDRESS:5000${NC}"
echo -e "\nCommandes utiles :"
echo -e "${BLUE}- Voir les logs :${NC} sudo journalctl -u $SERVICE_NAME -f"
echo -e "${BLUE}- Redémarrer le service :${NC} sudo systemctl restart $SERVICE_NAME"
echo -e "${BLUE}- Arrêter le service :${NC} sudo systemctl stop $SERVICE_NAME"
echo -e "${BLUE}- Voir le statut :${NC} sudo systemctl status $SERVICE_NAME"
