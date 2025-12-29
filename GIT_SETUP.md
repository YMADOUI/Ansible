# 📦 Publier sur Git (GitHub/GitLab)

## Option 1 : GitHub

### 1. Créer le dépôt sur GitHub
1. Aller sur https://github.com/new
2. Nom du dépôt : `ansible-mikrotik-wap60g`
3. **Important** : Cocher "Private" (dépôt privé)
4. Ne pas initialiser avec README (on a déjà les fichiers)
5. Cliquer "Create repository"

### 2. Pousser le code
```powershell
cd C:\Users\ymadoui.PASSMAN\Ansible

# Remplacer VOTRE-USERNAME par votre nom d'utilisateur GitHub
git remote add origin https://github.com/VOTRE-USERNAME/ansible-mikrotik-wap60g.git
git branch -M main
git push -u origin main
```

---

## Option 2 : GitLab

### 1. Créer le dépôt sur GitLab
1. Aller sur https://gitlab.com/projects/new
2. Nom du projet : `ansible-mikrotik-wap60g`
3. Visibility : **Private**
4. Décocher "Initialize repository with a README"
5. Cliquer "Create project"

### 2. Pousser le code
```powershell
cd C:\Users\ymadoui.PASSMAN\Ansible

# Remplacer VOTRE-USERNAME par votre nom d'utilisateur GitLab
git remote add origin https://gitlab.com/VOTRE-USERNAME/ansible-mikrotik-wap60g.git
git branch -M main
git push -u origin main
```

---

## Mise à jour après modifications

### Vous faites des modifications
```powershell
cd C:\Users\ymadoui.PASSMAN\Ansible

# Voir les fichiers modifiés
git status

# Ajouter tous les fichiers modifiés
git add .

# Créer un commit avec un message
git commit -m "Fix: correction du template SSID"

# Pousser vers Git
git push
```

### Le technicien récupère les modifications
```powershell
cd C:\Users\%USERNAME%\Ansible
wsl git pull
```

---

## 🔐 Gestion des accès

### Ajouter un collaborateur (GitHub)
1. Aller dans Settings → Collaborators
2. Inviter le technicien avec son email/username GitHub

### Ajouter un collaborateur (GitLab)
1. Aller dans Settings → Members
2. Inviter le technicien avec son email/username GitLab
3. Role : **Developer** (peut pull/push)

---

## 📝 Commandes Git utiles

```powershell
# Voir l'historique des commits
git log --oneline

# Voir les différences avant de commit
git diff

# Annuler les modifications locales
git checkout .

# Voir l'URL du dépôt distant
git remote -v

# Changer l'URL du dépôt distant
git remote set-url origin https://nouvelle-url.git
```

---

## ⚠️ Important

**Fichiers automatiquement ignorés** (dans .gitignore) :
- `mikrotik_*.rsc` - Fichiers de configuration générés
- `.topos_token_cache.json` - Token TOPOS (sécurité)
- Logs et fichiers temporaires

Ces fichiers ne seront JAMAIS envoyés sur Git.
