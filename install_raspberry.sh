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
# Installation des dépendances pour UFW et autres outils nécessaires
apt install -y python3-pip python3-venv ffmpeg git iptables ufw net-tools \
    build-essential pkg-config python3-dev \
    qt6-base-dev qt6-declarative-dev qt6-tools-dev qt6-tools-dev-tools \
    libgl1-mesa-dev

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
# Installation de PyQt6 en premier
sudo -u $USER venv/bin/pip install PyQt6
# Installation des autres dépendances
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
