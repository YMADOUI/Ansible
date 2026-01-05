# Configuration Automatique Mikrotik wAP 60G

Playbook Ansible pour configurer automatiquement des ponts radio Mikrotik wAP 60G à partir des données récupérées depuis l'API TOPOS.

## 📋 Prérequis

### Logiciels requis
- Ansible 2.9+
- Python 3.x
- `sshpass` (pour l'application SSH automatique)
  ```bash
  sudo apt-get install sshpass
  ```

### Fichiers nécessaires
- `credentials.yml` : Contient vos identifiants TOPOS
- `templates/mikrotik_config.j2` : Template de configuration Mikrotik

## 🔐 Configuration des credentials

Créez un fichier `credentials.yml` à la racine du projet :

```yaml
---
topos_username: "votre_username"
topos_password: "votre_password"
```

**⚠️ Important** : Ajoutez ce fichier dans `.gitignore` pour ne pas commiter vos credentials !

## 🚀 Utilisation

### Lancement du playbook

```bash
ansible-playbook configure_mikrotik_v2.yml
```

### Workflow interactif

Le playbook vous guide pas à pas :

1. **ID Installation** : Entrez le numéro du site
2. **Authentification** : Connexion automatique à l'API TOPOS avec vos credentials
3. **Sélection équipement** : Choisissez l'équipement dans la liste affichée
4. **Génération config** : Création automatique du fichier `.rsc`
5. **Application** (optionnel) : 
   - Choix Master (192.168.88.2) ou Slave (192.168.88.3)
   - Mot de passe admin du Mikrotik
   - Application via SSH

## 📊 Flux de données

```
credentials.yml → API TOPOS → Récupération données site
                              ↓
                    Liste des équipements
                              ↓
                    Sélection équipement
                              ↓
                    Génération SSID (lien1/lien2/lien3-<num_installation>)
                              ↓
                    Création fichier .rsc
                              ↓
                    Application SSH (optionnel)
```

## 🔧 Logique de nommage SSID

Le SSID est généré automatiquement selon le dernier octet de l'IP de management :

| IP (dernier octet) | Préfixe SSID | Exemple |
|--------------------|--------------|---------|
| 1 ou 2             | lien1        | lien1-12345 |
| 3 ou 4             | lien2        | lien2-12345 |
| 5 ou 6             | lien3        | lien3-12345 |
| Autre              | lien1        | lien1-12345 |

## 📁 Fichiers générés

Le playbook génère un fichier de configuration RouterOS :
```
mikrotik_<hostname>.rsc
```

Exemple : `mikrotik_WAP60G-SITE12345-M.rsc`

## 🔍 Données récupérées de TOPOS

- **SNMP Community** : Communauté SNMP du site
- **Password RW** : Mot de passe WiFi et admin
- **Hostname** : Nom de l'équipement
- **IP Management** : Adresse IP de gestion
- **ID Installation** : Numéro du site
- **Client ID** : Identifiant client

## 🛠️ Dépannage

### Erreur d'authentification TOPOS
```
Vérifiez vos credentials dans credentials.yml
```

### Erreur SSH vers Mikrotik
```
- Vérifiez que le Mikrotik est connecté et accessible
- Vérifiez le mot de passe admin
- Vérifiez que SSH est activé sur le Mikrotik
```

### Erreur d'accès à l'installation
```
Vérifiez que :
- L'ID installation est correct
- Vous avez les droits d'accès sur ce site dans TOPOS
```

## 📝 Structure du projet

```
Ansible/
├── configure_mikrotik_v2.yml    # Playbook principal
├── credentials.yml              # Identifiants TOPOS (non versionné)
├── templates/
│   └── mikrotik_config.j2      # Template de configuration
└── README.md                    # Ce fichier
```

## 🔒 Sécurité

- Les credentials sont chargés depuis un fichier externe non versionné
- Les mots de passe ne sont pas affichés dans les logs (no_log: true)
- Connexion SSH avec options de sécurité appropriées

## 🆘 Support

Pour toute question ou problème :
1. Vérifiez les logs Ansible
2. Testez la connectivité API TOPOS manuellement
3. Vérifiez la connectivité SSH vers le Mikrotik

## 📜 Changelog

### Version 2.0
- Suppression du système de cache JWT
- Utilisation directe des credentials depuis credentials.yml
- Simplification du flux d'authentification
- Conservation de toutes les fonctionnalités métier
