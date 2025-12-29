# 🚀 Configuration Automatique Mikrotik wAP 60G depuis TOPOS

Automatisation de la configuration des ponts radio Mikrotik wAP 60G en récupérant les données depuis l'API TOPOS.

> 📖 **Guide d'installation complet** : Voir [INSTALLATION.md](INSTALLATION.md)

---

## ⚙️ Configuration initiale (OBLIGATOIRE)

**Avant la première utilisation**, créez le fichier `credentials.yml` avec vos identifiants TOPOS :

```bash
# Copier le fichier exemple
cp credentials.yml.example credentials.yml

# Éditer avec vos vrais identifiants
nano credentials.yml
```

**Contenu du fichier `credentials.yml` :**
```yaml
topos_username: "votre_login_topos"
topos_password: "votre_password_topos"
installation_id: "20514"
```

⚠️ **Important** : Ce fichier est ignoré par Git pour protéger vos identifiants.

---

## 📋 Fonctionnalités

✅ **Authentification TOPOS** avec cache du token JWT (23h)  
✅ **Liste interactive** des équipements depuis l'API  
✅ **Génération automatique du SSID** basé sur l'IP de gestion  
✅ **Configuration complète** : WiFi, Bridge, SNMP, RADIUS, Certificats  
✅ **Application SSH automatique** sur le Mikrotik  
✅ **Support multi-équipements** : configure 6 ponts d'affilée sans reconnexion  

---

## 🔄 Mise à jour

Pour récupérer les dernières modifications :

```powershell
cd C:\Users\%USERNAME%\Ansible
wsl git pull
```

---

## 🚀 Utilisation rapide

```powershell
cd C:\Users\%USERNAME%\Ansible
wsl ansible-playbook configure_mikrotik_v2.yml
```

**Le playbook vous guidera étape par étape !**

---

## 🎯 Architecture

### Configuration SSID Automatique
- **IP .1 ou .2** → `lien1-{installation_id}`
- **IP .3 ou .4** → `lien2-{installation_id}`
- **IP .5 ou .6** → `lien3-{installation_id}`

### Données récupérées depuis TOPOS
| Source | Données |
|--------|---------|
| **installations_fiche** | SNMP Community, Password RW, Installation ID |
| **equipements_fiche** | Hostname, AdminIP, VpnPrivateIP |
| **Liste équipements** | 38 équipements disponibles avec ID/Nom/Catégorie |

---

## 🛠️ Installation

### Option 1 : Ansible avec WSL (Recommandé)

```powershell
# 1. Installer WSL Ubuntu (si pas déjà fait)
wsl --install Ubuntu

# 2. Installer Ansible dans WSL
wsl sudo apt update
wsl sudo apt install -y ansible sshpass

# 3. Vérifier l'installation
wsl ansible --version
```

### Option 2 : PowerShell (Natif Windows)

Aucune installation nécessaire - PowerShell 5.1+ inclus avec Windows.

### Option 3 : Python

```powershell
# Installer Python 3.12
winget install Python.Python.3.12

# Installer les dépendances
python -m pip install requests jinja2
```

---

## 🚀 Utilisation

### ✨ **Ansible (WSL) - Méthode recommandée**

```powershell
wsl ansible-playbook configure_mikrotik_v2.yml
```

**Workflow interactif :**
1. Saisir les identifiants TOPOS
2. Saisir Client ID et Installation ID
3. Choisir l'équipement dans la liste
4. Confirmer l'application sur le Mikrotik
5. Choisir Master (192.168.88.2) ou Slave (192.168.88.3)
6. Saisir le mot de passe admin du Mikrotik

**Avantages :**
- ✅ Token en cache (pas de reconnexion pendant 23h)
- ✅ Application SSH automatique
- ✅ Gestion des erreurs avec retry
- ✅ Mot de passe affiché en clair pour debug

### 🔧 **PowerShell**

```powershell
.\Generate-MikrotikConfig.ps1
```

**Fonctionnalités :**
- Token en cache (23h)
- Liste interactive des 38 équipements
- Génération du fichier .rsc
- Option SSH avec Posh-SSH (installation automatique)

### 🐍 **Python**

```powershell
python configure_mikrotik.py
```

**Fonctionnalités :**
- API REST avec requests
- Template Jinja2
- Génération du fichier .rsc

---

## 📁 Structure des Fichiers

```
Ansible/
├── configure_mikrotik_v2.yml       # Playbook Ansible (recommandé)
├── configure_mikrotik.py           # Script Python alternatif
├── Generate-MikrotikConfig.ps1     # Script PowerShell alternatif
├── ansible.cfg                     # Configuration Ansible
├── README.md                       # Ce fichier
│
├── templates/
│   └── mikrotik_config.j2          # Template Jinja2 de configuration
│
├── inventory/
│   └── hosts                       # Inventaire Ansible (localhost)
│
└── mikrotik_*.rsc                  # Fichiers générés (un par équipement)
```

---

## 🔐 Pré-requis Mikrotik

### 1. SSH activé
```routeros
/ip service
set ssh disabled=no port=22
```

### 2. Compte admin configuré
```routeros
/user
set admin password="votre_mot_de_passe"
```

### 3. Connectivité réseau
- **IP par défaut** : 192.168.88.2 (Master) ou 192.168.88.3 (Slave)
- **Accès SSH** : Port 22 ouvert
- **Réseau local** : Mikrotik sur le même réseau que votre PC

---

## 📝 Exemple de Configuration Générée

```routeros
# Configuration Mikrotik wAP 60G
# Equipement: 325284-rwb04-8412
# Site: 20514
# SSID: lien2-20514
# Date: 2025-12-29

/interface wireless
set [ find default-name=wlan60-1 ] \
    disabled=no \
    ssid="lien2-20514" \
    mode=bridge \
    frequency=60480 \
    channel-width=2160mhz \
    wireless-protocol=nstreme \
    wds-mode=static \
    wds-default-bridge=bridge1

/interface bridge
add name=bridge1

/interface bridge port
add bridge=bridge1 interface=ether1
add bridge=bridge1 interface=wlan60-1

/snmp
set enabled=yes contact="IT Support" \
    location="Site 20514"

/snmp community
set [ find default=yes ] name="4fX8gKej"

/system identity
set name="325284-rwb04-8412"

/user
set admin password="VPrwhDtT"
```

---

## 🔄 Cache du Token

Le token JWT TOPOS est mis en cache pour **23 heures** :

**Ansible (WSL)** :
```bash
/tmp/.topos_token_cache.json
```

**PowerShell** :
```powershell
.topos_token_cache.json
```

**Avantage** : Configurez plusieurs ponts sans vous reconnecter à TOPOS à chaque fois !

---

## 🐛 Dépannage

### Erreur : "Permission denied" (SSH)

**Causes possibles :**
1. Mot de passe incorrect
2. Compte admin non configuré
3. SSH désactivé

**Solution :**
```routeros
/user set admin password="nouveau_mdp"
/ip service set ssh disabled=no
```

### Erreur : "No route to host"

**Causes possibles :**
1. Mikrotik débranché
2. IP incorrecte
3. Pas sur le même réseau

**Solution :**
- Vérifier la connexion physique
- Configurer votre PC en 192.168.88.x
- Essayer un ping : `wsl ping 192.168.88.2`

### Erreur : "Connection timeout"

**Solution :**
- Augmenter le délai : `timeout 300` dans le playbook
- Vérifier le firewall Windows

---

## 📊 API TOPOS

### Endpoints utilisés

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| POST | `/webservice_passconfig` | Authentification (login) |
| POST | `/webservice_passconfig` | Informations du site (installations_fiche) |
| PUT | `/installations-immediate-interactions/{client}/{installation}` | Liste des équipements |
| POST | `/webservice_passconfig` | Détails de l'équipement (equipements_fiche) |

### Authentification

```json
{
  "method": "login",
  "parameters": {
    "username": "votre_username",
    "password": "votre_password"
  }
}
```

**Réponse :**
```json
{
  "response": {
    "new_JWT": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

---

## 🎓 Variables du Template

| Variable | Source | Exemple |
|----------|--------|---------|
| `NUMINSTALLATION` | installations_fiche → IDInstallation | 20514 |
| `TOPOSSNMP` | installations_fiche → SnmpCommunity | 4fX8gKej |
| `TOPOSRW` | installations_fiche → PasswordRW | VPrwhDtT |
| `TOPOSHOSTNAME` | equipements_fiche → Hostname | 325284-rwb04-8412 |
| `TOPOSIP` | equipements_fiche → AdminIP | 10.10.11.4 |
| `NEWSSID` | Généré (lien1/2/3-{installation}) | lien2-20514 |
| `MODE` | Fixe | bridge |

---

## 📜 Licence

Projet interne PASSMAN - Usage restreint

---

## 👤 Auteur

**Yassine MADOUI** - Configuration automatisée Mikrotik wAP 60G  
📧 ymadoui@passman.fr  
🏢 PASSMAN - Infrastructure Réseau

---

## 🔗 Liens Utiles

- [Documentation Mikrotik wAP 60G](https://mikrotik.com/product/wap_60g)
- [API TOPOS](https://www.dc-wifi.tech/interactions-equipements/webservice_passconfig)
- [Ansible Documentation](https://docs.ansible.com/)
- [RouterOS Scripting](https://wiki.mikrotik.com/wiki/Manual:Scripting)

---

**Version** : 2.0  
**Dernière mise à jour** : 29 décembre 2025
