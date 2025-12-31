# 🔧 Installation - Outil Configuration Mikrotik wAP 60G

Ce guide explique comment installer et utiliser l'outil d'automatisation pour configurer les ponts radio Mikrotik wAP 60G.

---

## 📋 Étape 1 : Installer WSL Ubuntu

Ouvrir **PowerShell en Administrateur** et exécuter :

```powershell
wsl --install Ubuntu
```

⚠️ **IMPORTANT** : **Redémarrer le PC** après l'installation.

Au premier lancement d'Ubuntu, créer :
- Un nom d'utilisateur (exemple : `technicien`)
- Un mot de passe

---

## 📦 Étape 2 : Installer Ansible et les outils

Dans PowerShell :

```powershell
wsl
sudo apt update
sudo apt install -y ansible sshpass python3-paramiko git
exit
```

**Vérifier que tout est installé :**
```powershell
wsl ansible --version
# Résultat attendu : ansible [core 2.16.x]

wsl sshpass -V
# Résultat attendu : sshpass 1.09
```

---

## 📥 Étape 3 : Télécharger l'outil depuis GitHub

```powershell
cd C:\Users\%USERNAME%
wsl git clone https://github.com/YMADOUI/Ansible.git Ansible
cd Ansible
```

---

## 🔑 Étape 4 : Configurer vos identifiants TOPOS

**Créer le fichier de credentials :**

```powershell
cd C:\Users\%USERNAME%\Ansible
wsl cp credentials.yml.example credentials.yml
wsl nano credentials.yml
```

**Remplir avec vos identifiants TOPOS :**

```yaml
topos_username: "votre_login_topos"
topos_password: "votre_mot_de_passe_topos"
```

**Enregistrer et quitter :**
- Appuyer sur `Ctrl + X`
- Appuyer sur `Y` (Yes)
- Appuyer sur `Entrée`

⚠️ **Ce fichier ne sera jamais partagé sur Git** (il est ignoré pour votre sécurité).

---

## 🚀 Étape 5 : Utiliser l'outil

### 1️⃣ Configurer votre carte réseau

Avant de brancher le Mikrotik :

- **Adresse IP** : `192.168.88.100`
- **Masque** : `255.255.255.0`
- **Passerelle** : `192.168.88.1`

### 2️⃣ Brancher le Mikrotik

1. Connecter le Mikrotik au PC via câble Ethernet (port PoE)
2. Alimenter le Mikrotik
3. Attendre **30 secondes** que le Mikrotik démarre

### 3️⃣ Tester la connexion

```powershell
ping 192.168.88.2
# OU
ping 192.168.88.3
```

✅ Si ça répond, c'est bon !

### 4️⃣ Lancer l'outil

```powershell
cd C:\Users\%USERNAME%\Ansible
wsl ansible-playbook configure_mikrotik_v2.yml
```

### 5️⃣ Suivre les instructions du playbook

Le playbook vous demandera :

**1. ID Installation** (numéro du site)
   - Exemple : `35914`

**2. Sélection de l'équipement**
   - Le playbook affiche la liste des équipements du site
   - Choisir le numéro (ex: `1` pour le Master, `2` pour le Slave)

**3. Mot de passe Mikrotik**
   - Entrer le mot de passe admin actuel (⚠️ vide par défaut sur Mikrotik neuf)

**4. Configuration appliquée automatiquement !** ✅

---

## 🔄 Mise à jour de l'outil

Pour récupérer les dernières modifications du playbook :

```powershell
cd C:\Users\%USERNAME%\Ansible
wsl git pull
```

---

## ⚠️ Dépannage

### ❌ Erreur "Permission denied" (SSH)

**Causes possibles :**
- Mot de passe incorrect
- Mikrotik sur une autre IP (essayez `.2` au lieu de `.3`)

**Solution :**
- Sur Mikrotik **neuf**, le mot de passe est **vide** (appuyez juste sur Entrée)
- Vérifiez l'IP : `ping 192.168.88.2` puis `ping 192.168.88.3`

---

### ❌ Erreur "No route to host"

**Causes possibles :**
- Mikrotik non connecté ou éteint
- PC pas en 192.168.88.x

**Solution :**
1. Vérifier le câble Ethernet (branché sur port PoE du Mikrotik)
2. Vérifier l'IP du PC : `ipconfig` (doit afficher 192.168.88.100)
3. Tester : `ping 192.168.88.2`

---

### ❌ Erreur "Access denied for this installation"

**Cause :**
Mauvais ID Installation ou vous n'avez pas accès à ce site.

**Solution :**
Vérifier l'ID Installation dans TOPOS (interface web).

---

### ❌ WSL ne démarre pas

**Solution :**
```powershell
wsl --shutdown
wsl
```

---

## 🎯 Récapitulatif rapide

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Brancher Mikrotik (câble Ethernet + alimentation)        │
│ 2. Vérifier connexion : ping 192.168.88.2                   │
│ 3. Lancer : wsl ansible-playbook configure_mikrotik_v2.yml  │
│ 4. Entrer : ID Installation                                  │
│ 5. Choisir l'équipement dans la liste                       │
│ 6. Entrer le mot de passe Mikrotik                          │
│ 7. ✅ Configuration appliquée automatiquement !              │
└─────────────────────────────────────────────────────────────┘
```

---

## 📞 Support

En cas de problème :
- **Yassine MADOUI** - yassin.madoui@passman.fr
- Équipe Infrastructure Réseau PASSMAN

---

**Version** : 1.0  
**Date** : 29 décembre 2025  
**Auteur** : Yassine MADOUI - PASSMAN
