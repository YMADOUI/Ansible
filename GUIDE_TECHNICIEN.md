# 🚀 Guide Technicien - Configuration Mikrotik wAP 60G

## ⚡ Installation rapide (première fois uniquement)

### 1. Installer WSL Ubuntu
```powershell
wsl --install Ubuntu
```
⚠️ **Redémarrer le PC** après installation

### 2. Installer les outils
```powershell
wsl
sudo apt update
sudo apt install -y ansible sshpass python3-paramiko git
exit
```

### 3. Télécharger l'outil
```powershell
cd C:\Users\%USERNAME%
wsl git clone https://github.com/YMADOUI/Ansible.git Ansible
cd Ansible
```

### 4. Configurer vos identifiants TOPOS
```powershell
wsl cp credentials.yml.example credentials.yml
wsl nano credentials.yml
```

Remplir :
```yaml
topos_username: "votre_login"
topos_password: "votre_password"
```

Enregistrer : `Ctrl+X` → `Y` → `Entrée`

---

## 🔧 Utilisation quotidienne

### 1️⃣ Configurer votre PC
- **IP** : `192.168.88.100`
- **Masque** : `255.255.255.0`

### 2️⃣ Brancher le Mikrotik
- Câble Ethernet sur port PoE
- Attendre 30 secondes

### 3️⃣ Tester
```powershell
ping 192.168.88.2
```

### 4️⃣ Lancer l'outil
```powershell
cd C:\Users\%USERNAME%\Ansible
wsl ansible-playbook configure_mikrotik_v2.yml
```

### 5️⃣ Répondre aux questions
1. **ID Installation** : entrer le numéro du site (ex: `35914`)
2. **Choisir équipement** : taper le numéro (ex: `1`)
3. **Mot de passe Mikrotik** : entrer le password (vide si neuf)

✅ **C'est tout ! Configuration appliquée automatiquement.**

---

## 🔄 Mettre à jour l'outil

Avant chaque utilisation (recommandé) :
```powershell
cd C:\Users\%USERNAME%\Ansible
wsl git pull
```

---

## ⚠️ Problèmes courants

| Erreur | Solution |
|--------|----------|
| "Permission denied" | Mot de passe vide si Mikrotik neuf (juste Entrée) |
| "No route to host" | Vérifier câble + IP PC en 192.168.88.100 |
| "Access denied" | Vérifier l'ID Installation dans TOPOS |

---

## 📞 Support
**Yassine MADOUI** - yassin.madoui@passman.fr
