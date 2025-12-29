# 🔧 Installation - Outil Configuration Mikrotik wAP 60G

## 📋 Prérequis Windows

### 1️⃣ Installer WSL Ubuntu

Ouvrir **PowerShell en Administrateur** :

```powershell
wsl --install Ubuntu
```

⚠️ **IMPORTANT** : Redémarrer le PC après l'installation.

Au premier lancement d'Ubuntu, vous devrez :
1. Créer un nom d'utilisateur
2. Définir un mot de passe

---

### 2️⃣ Installer Ansible et les dépendances

```powershell
wsl
sudo apt update
sudo apt install -y ansible sshpass python3-paramiko git
exit
```

**Vérifier l'installation :**
```powershell
wsl ansible --version
# Doit afficher : ansible [core 2.16.x]

wsl sshpass -V
# Doit afficher : sshpass 1.09
```

---

### 3️⃣ Cloner le dépôt Git

```powershell
cd C:\Users\%USERNAME%
wsl git clone https://github.com/YMADOUI/Ansible.git Ansible
cd Ansible
```

**OU** si vous avez déjà le dossier, l'initialiser avec Git :

```powershell
cd C:\Users\%USERNAME%\Ansible
wsl git init
wsl git remote add origin https://github.com/PASSMAN/ansible-mikrotik.git
wsl git pull origin main
```

---

## 🔄 Mise à jour de l'outil

Pour récupérer les dernières modifications :

```powershell
cd C:\Users\%USERNAME%\Ansible
wsl git pull
```

C'est tout ! Vous avez maintenant la dernière version.

---

## 🚀 Première utilisation

### 1. Configuration réseau du PC

Avant de brancher le Mikrotik, configurez votre carte réseau :

**Paramètres réseau :**
- Adresse IP : `192.168.88.100` (ou n'importe quelle IP en .88.x sauf .2 et .3)
- Masque : `255.255.255.0`
- Passerelle : `192.168.88.1`

### 2. Brancher le Mikrotik

1. Connecter le Mikrotik au PC via câble Ethernet
2. Alimenter le Mikrotik
3. Attendre 30 secondes que le Mikrotik démarre

### 3. Tester la connexion

```powershell
ping 192.168.88.2
# OU
ping 192.168.88.3
```

Si ça répond, c'est bon ! ✅

### 4. Lancer l'outil

```powershell
cd C:\Users\%USERNAME%\Ansible
wsl ansible-playbook configure_mikrotik_v2.yml
```

### 5. Suivre les instructions

Le playbook vous demandera automatiquement :

1. **Identifiants TOPOS** (une seule fois, token valide 23h)
   - Username
   - Password

2. **Informations du site**
   - Numéro client (ex: 8412)
   - ID Installation (ex: 20514)

3. **Sélection de l'équipement**
   - Choisir le numéro dans la liste affichée

4. **Application de la configuration**
   - Confirmer l'application : `oui`
   - Type : `1` (Master) ou `2` (Slave)
   - Mot de passe admin actuel du Mikrotik

---

## ⚠️ Dépannage

### Erreur "Permission denied" (SSH)

**Causes :**
- Mot de passe incorrect
- SSH désactivé sur le Mikrotik

**Solution :**
Si c'est un Mikrotik neuf, le mot de passe est **vide** (appuyer juste sur Entrée).

---

### Erreur "No route to host"

**Causes :**
- Mikrotik non connecté ou éteint
- Mauvaise configuration réseau du PC

**Solution :**
1. Vérifier le câble Ethernet
2. Vérifier que votre PC est en 192.168.88.x
3. Ping le Mikrotik : `ping 192.168.88.2`

---

### Erreur "Token expired"

**Causes :**
Le token TOPOS expire après 23 heures.

**Solution :**
C'est normal, le playbook va vous redemander vos identifiants TOPOS.

---

### WSL ne démarre pas

**Solution :**
```powershell
# Redémarrer WSL
wsl --shutdown
wsl
```

---

## 📞 Support

En cas de problème, contacter :
- **Yassine MADOUI** - ymadoui@passman.fr
- Équipe Infrastructure Réseau PASSMAN

---

## 🎯 Workflow complet

```
1. Brancher Mikrotik → 2. Ping 192.168.88.x → 3. Lancer playbook
           ↓                      ↓                      ↓
    PC en .88.x            Vérifier réseau      Se connecter TOPOS
                                                         ↓
                                                 Choisir équipement
                                                         ↓
                                                 Appliquer config
                                                         ↓
                                                    ✅ SUCCÈS !
```

---

**Version** : 1.0  
**Date** : 29 décembre 2025  
**Auteur** : Yassine MADOUI - PASSMAN
