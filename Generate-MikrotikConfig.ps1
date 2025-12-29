# ============================================
# Script PowerShell - Configuration Mikrotik wAP 60G
# Recupere les donnees depuis l'API TOPOS
# ============================================

# Desactiver la verification SSL
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$API_BASE = "https://www.dc-wifi.tech/interactions-equipements/webservice_passconfig"

# Fonction pour appliquer la configuration complete sur le Mikrotik via SSH
function Send-MikrotikConfig {
    param(
        [string]$IPAddress = "192.168.88.2",
        [string]$Username = "admin",
        [string]$Password = "",
        [string]$ConfigFile
    )
    
    Write-Host ""
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host "  Envoi de la configuration sur le Mikrotik" -ForegroundColor Cyan
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "IP Mikrotik: $IPAddress" -ForegroundColor Yellow
    Write-Host "Fichier: $ConfigFile" -ForegroundColor Yellow
    Write-Host ""
    
    # Verifier si le module Posh-SSH est installe
    if (-not (Get-Module -ListAvailable -Name Posh-SSH)) {
        Write-Host "Le module Posh-SSH n'est pas installe." -ForegroundColor Yellow
        Write-Host "Voulez-vous l'installer maintenant ? (O/n): " -ForegroundColor Yellow -NoNewline
        $installChoice = Read-Host
        
        if ($installChoice -eq "" -or $installChoice -eq "O" -or $installChoice -eq "o") {
            Write-Host "Installation du module Posh-SSH..." -ForegroundColor Yellow
            try {
                Install-Module -Name Posh-SSH -Force -Scope CurrentUser -AllowClobber -ErrorAction Stop
                Write-Host "OK - Module Posh-SSH installe" -ForegroundColor Green
            }
            catch {
                Write-Host "ERREUR - Impossible d'installer Posh-SSH: $_" -ForegroundColor Red
                Write-Host ""
                Write-Host "Installation manuelle requise:" -ForegroundColor Yellow
                Write-Host "  Install-Module -Name Posh-SSH -Force -Scope CurrentUser -AllowClobber" -ForegroundColor White
                Write-Host ""
                return $false
            }
        } else {
            Write-Host "Installation annulee. Configuration envoyee manuellement." -ForegroundColor Yellow
            return $false
        }
    }
    
    try {
        Import-Module Posh-SSH -ErrorAction Stop
    }
    catch {
        Write-Host "ERREUR - Impossible de charger le module Posh-SSH: $_" -ForegroundColor Red
        return $false
    }
    
    # Lire le fichier de configuration
    if (-not (Test-Path $ConfigFile)) {
        Write-Host "ERREUR - Fichier de configuration introuvable: $ConfigFile" -ForegroundColor Red
        return $false
    }
    
    $configContent = Get-Content $ConfigFile -Raw
    
    # Creer les credentials
    $securePassword = ConvertTo-SecureString $Password -AsPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential($Username, $securePassword)
    
    try {
        Write-Host "Connexion SSH au Mikrotik..." -ForegroundColor Yellow
        
        # Se connecter en SSH
        $session = New-SSHSession -ComputerName $IPAddress -Credential $credential -AcceptKey -ErrorAction Stop
        
        Write-Host "OK - Connecte" -ForegroundColor Green
        Write-Host ""
        Write-Host "Envoi de la configuration..." -ForegroundColor Yellow
        
        # Envoyer la configuration complete
        $result = Invoke-SSHCommand -SessionId $session.SessionId -Command $configContent -ErrorAction Stop
        
        Write-Host ""
        Write-Host "Sortie:" -ForegroundColor Cyan
        Write-Host $result.Output -ForegroundColor White
        
        if ($result.ExitStatus -eq 0) {
            Write-Host ""
            Write-Host "OK - Configuration appliquee avec succes" -ForegroundColor Green
            $success = $true
        } else {
            Write-Host ""
            Write-Host "ERREUR - Code de sortie: $($result.ExitStatus)" -ForegroundColor Red
            if ($result.Error) {
                Write-Host "Erreur: $($result.Error)" -ForegroundColor Red
            }
            $success = $false
        }
        
        # Fermer la session
        Remove-SSHSession -SessionId $session.SessionId | Out-Null
        
        return $success
    }
    catch {
        Write-Host "ERREUR - Connexion SSH echouee: $_" -ForegroundColor Red
        return $false
    }
}

# Fonction pour faire des appels API
function Invoke-ToposAPI {
    param(
        [string]$Method,
        [hashtable]$Parameters,
        [string]$Token = $null
    )
    
    $headers = @{
        "Content-Type" = "application/json"
        "Accept" = "application/json, text/plain, */*"
        "User-Agent" = "PowerShell-Mikrotik-Automation/1.0"
    }
    
    if ($Token) {
        $headers["Authorization"] = "Bearer $Token"
    }
    
    $body = @{
        method = $Method
        parameters = $Parameters
    } | ConvertTo-Json -Depth 10
    
    try {
        Write-Host "DEBUG - URL: $API_BASE" -ForegroundColor DarkGray
        Write-Host "DEBUG - Body: $body" -ForegroundColor DarkGray
        $response = Invoke-RestMethod -Uri $API_BASE -Method Post -Headers $headers -Body $body -ErrorAction Stop
        return $response
    }
    catch {
        Write-Host "Erreur API: $_" -ForegroundColor Red
        Write-Host "Status: $($_.Exception.Response.StatusCode.value__)" -ForegroundColor DarkGray
        return $null
    }
}

# Fonction pour generer la configuration
function New-MikrotikConfig {
    param(
        [hashtable]$Config
    )
    
    $date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    $configContent = @"
# ================== Configuration Mikrotik wAP 60G ==================
# Site: $($Config.NUMINSTALLATION)
# Equipement: $($Config.TOPOSHOSTNAME)
# IP Management: $($Config.TOPOSIP)
# Genere le: $date

# ================== Configuration wlan60-1 ==================
/interface w60g set [find where name="wlan60-1"] ssid=$($Config.NEWSSID) password=$($Config.TOPOSRW) disabled=no

# Configuration Bridge (toujours actif car deja appaire)
/interface w60g set [find where name="wlan60-1"] put-stations-in-bridge=bridge isolate-stations=yes 

"@

    $configContent += @"
# ================== Ports du bridge ==================
/interface bridge port
:if ([:len [find where bridge="bridge" and interface="ether1"]] = 0) do={ add bridge=bridge interface=ether1 comment=defconf }
:if ([:len [find where bridge="bridge" and interface="wlan60-1"]] = 0) do={ add bridge=bridge interface=wlan60-1 comment=defconf }

# ================== Interface Lists ==================
/interface list
:if ([:len [find where name="WAN"]] = 0) do={ add name=WAN }
:if ([:len [find where name="LAN"]] = 0) do={ add name=LAN }
/interface list member
:if ([:len [find where list=LAN and interface=ether1]] = 0) do={ add list=LAN interface=ether1 }
:if ([:len [find where list=WAN and interface=wlan60-1]] = 0) do={ add list=WAN interface=wlan60-1 }

# ================== IP Management sur bridge ==================
/ip address
add address=$($Config.TOPOSIP)/20 comment="ip management" interface=bridge network=10.10.0.0

/ip route add dst-address=0.0.0.0/0 gateway=10.10.0.1 distance=1

# ================== SETTINGS ==================
/system leds
set 0 leds=led1,led2,led3,led4,led5

/system note
set show-at-login=no

/system ntp client
set enabled=yes

/system ntp client servers
add address=10.10.0.1

# ================== RADIUS (login) ==================
/radius
add accounting-port=1805 address=212.155.93.171 authentication-port=1804 service=login require-message-auth=no secret=Ke4TJh2d9Rsjtjkq4rSbls

/user aaa set use-radius=yes

/radius
add accounting-port=1805 address=212.155.93.172 authentication-port=1804 service=login require-message-auth=no secret=Ke4TJh2d9Rsjtjkq4rSbls

/user aaa set use-radius=yes

# ================== SNMP ==================
/snmp set enabled=yes trap-version=2
/snmp community add name=$($Config.TOPOSSNMP) addresses=0.0.0.0/0

# ================== System Identity ==================
/system identity set name=$($Config.TOPOSHOSTNAME)

# ================== Admin Password ==================
/user set admin password=$($Config.TOPOSRW)

# ================== CERTIFICATE ==================
# Creer CA + signature
/certificate add name="webfig-ca" common-name="webfig-ca" key-usage=key-cert-sign,crl-sign
/certificate sign [find where name="webfig-ca"]

# Cert serveur avec usage TLS
/certificate add name="webfig-cert" common-name="webfig" key-usage=digital-signature,key-encipherment,tls-server
/certificate sign [find where name="webfig-cert"] ca="webfig-ca"

# Activer HTTPS
/ip service set www-ssl certificate="webfig-cert" disabled=no

# Laisser HTTP active temporairement
/ip service set www disabled=no

# ================== Logs & Affichage ==================
:put "=== W60G MONITOR ==="
/interface w60g print detail
/interface w60g monitor wlan60-1 once

:put "=== IP ADDRESS ==="
/ip address print where interface=bridge

:put "=== Configuration appliquee avec succes ==="
"@

    return $configContent
}

# ============================================
# SCRIPT PRINCIPAL
# ============================================

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Configuration Mikrotik wAP 60G" -ForegroundColor Cyan
Write-Host "  Recuperation depuis API TOPOS" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Fichier cache pour le token
$tokenCacheFile = ".topos_token_cache.json"
$token = $null
$username = $null

# Verifier si un token en cache existe et est valide
if (Test-Path $tokenCacheFile) {
    try {
        $cache = Get-Content $tokenCacheFile | ConvertFrom-Json
        $tokenAge = (Get-Date) - [DateTime]$cache.timestamp
        
        # Token valide pour 23 heures (expire apres 24h normalement)
        if ($tokenAge.TotalHours -lt 23) {
            Write-Host "Token en cache trouve (valide pour $([int](23 - $tokenAge.TotalHours))h)" -ForegroundColor Green
            $useCache = Read-Host "Utiliser le token en cache ? (O/n)"
            
            if ($useCache -ne 'n' -and $useCache -ne 'N') {
                $token = $cache.token
                $username = $cache.username
                Write-Host "Token reutilise pour $username" -ForegroundColor Green
                Write-Host ""
            }
        } else {
            Write-Host "Token en cache expire" -ForegroundColor Yellow
            Remove-Item $tokenCacheFile -Force
        }
    }
    catch {
        Write-Host "Erreur lecture cache, connexion necessaire" -ForegroundColor Yellow
        Remove-Item $tokenCacheFile -Force -ErrorAction SilentlyContinue
    }
}

# Si pas de token en cache, demander authentification
if (-not $token) {
    # Etape 1: Demander les credentials
    Write-Host "[1/6] Authentification TOPOS" -ForegroundColor Yellow
    $username = Read-Host "Nom d'utilisateur TOPOS"
    $securePassword = Read-Host "Mot de passe TOPOS" -AsSecureString
    $password = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword))

    Write-Host "Connexion en cours..." -ForegroundColor Gray

    # Login API
    $loginResult = Invoke-ToposAPI -Method "login" -Parameters @{
        username = $username
        password = $password
        application = "wifipass"
    }

    if (-not $loginResult) {
        Write-Host "Echec de la connexion !" -ForegroundColor Red
        exit 1
    }

    # Extraire le token
    if ($loginResult.token) {
        $token = $loginResult.token
    }
    elseif ($loginResult.data.token) {
        $token = $loginResult.data.token
    }
    elseif ($loginResult.response.new_JWT) {
        $token = $loginResult.response.new_JWT
    }
    elseif ($loginResult.new_JWT) {
        $token = $loginResult.new_JWT
    }

    if (-not $token) {
        Write-Host "Token non trouve dans la reponse !" -ForegroundColor Red
        Write-Host "Reponse: $($loginResult | ConvertTo-Json -Depth 5)" -ForegroundColor Gray
        exit 1
    }

    # Sauvegarder le token en cache
    $cacheData = @{
        token = $token
        username = $username
        timestamp = (Get-Date).ToString("o")
    }
    $cacheData | ConvertTo-Json | Out-File -FilePath $tokenCacheFile -Encoding UTF8
    
    Write-Host "OK - Connexion reussie ! (Token sauvegarde)" -ForegroundColor Green
    Write-Host ""
} else {
    Write-Host "[1/6] Authentification TOPOS - Token en cache utilise" -ForegroundColor Yellow
    Write-Host ""
}

# Etape 2: Demander l'ID installation
Write-Host "[2/5] Informations du site" -ForegroundColor Yellow
$clientId = Read-Host "Numero client"
$siteId = Read-Host "ID Installation (numero du site)"

Write-Host "Recuperation des infos du site..." -ForegroundColor Gray

$siteInfo = Invoke-ToposAPI -Method "installations_fiche" -Parameters @{
    ID = $siteId
} -Token $token

if (-not $siteInfo) {
    Write-Host "Impossible de recuperer les infos du site !" -ForegroundColor Red
    Write-Host "Verifiez que l'ID installation est correct" -ForegroundColor Yellow
    exit 1
}

# Extraire les donnees du site
$siteData = $siteInfo.response.record
if (-not $siteData) {
    $siteData = $siteInfo.record
}
if (-not $siteData) {
    $siteData = $siteInfo
}

# Recuperer TOPOSSNMP et TOPOSRW depuis les infos site
$TOPOSSNMP = if ($siteData.SnmpCommunity) { $siteData.SnmpCommunity } else { "public" }
$TOPOSRW = if ($siteData.PasswordRW) { $siteData.PasswordRW } elseif ($siteData.PasswordRO) { $siteData.PasswordRO } else { "admin" }
$NUMINSTALLATION = if ($siteData.IDinstallation) { $siteData.IDinstallation } else { $siteId }

Write-Host "OK - Informations site recuperees" -ForegroundColor Green
Write-Host "  Installation: $NUMINSTALLATION" -ForegroundColor Gray
Write-Host "  SNMP Community: $TOPOSSNMP" -ForegroundColor Gray
Write-Host ""

# Etape 3: Liste des equipements via API REST
Write-Host "[3/5] Liste des equipements" -ForegroundColor Yellow
Write-Host "Recuperation de la liste..." -ForegroundColor Gray

$equipmentsUrl = "https://www.dc-wifi.tech/interactions-equipements/installations-immediate-interactions/$clientId/$siteId"
$headers = @{
    "Authorization" = "Bearer $token"
    "Accept" = "application/json, text/plain, */*"
    "Content-Type" = "application/json"
}

try {
    $equipmentsList = Invoke-RestMethod -Uri $equipmentsUrl -Method Put -Headers $headers -ErrorAction Stop
    
    # DEBUG: Afficher la structure
    Write-Host "DEBUG - Type retourne: $($equipmentsList.GetType().Name)" -ForegroundColor DarkGray
    Write-Host "DEBUG - Nombre d'elements: $($equipmentsList.Count)" -ForegroundColor DarkGray
    Write-Host "DEBUG - Premier equipement (raw):" -ForegroundColor DarkGray
    if ($equipmentsList -is [array] -and $equipmentsList.Count -gt 0) {
        $firstEquip = $equipmentsList[0]
        Write-Host "  Type: $($firstEquip.GetType().Name)" -ForegroundColor DarkGray
        Write-Host "  Properties: $($firstEquip.PSObject.Properties.Name -join ', ')" -ForegroundColor DarkGray
        Write-Host ($equipmentsList[0] | ConvertTo-Json -Depth 2) -ForegroundColor DarkGray
    } else {
        Write-Host ($equipmentsList | ConvertTo-Json -Depth 3) -ForegroundColor DarkGray
    }
}
catch {
    Write-Host "Erreur lors de la recuperation des equipements: $_" -ForegroundColor Red
    Write-Host "URL: $equipmentsUrl" -ForegroundColor DarkGray
    exit 1
}

if (-not $equipmentsList) {
    Write-Host "Impossible de recuperer la liste des equipements !" -ForegroundColor Red
    exit 1
}

# Extraire la liste - utiliser directement sans transformation
$equipments = $equipmentsList

# Verifier qu'on a des equipements
if (-not $equipments -or $equipments.Count -eq 0) {
    Write-Host "Aucun equipement trouve pour ce site !" -ForegroundColor Red
    exit 1
}

Write-Host "OK - $($equipments.Count) equipements trouves" -ForegroundColor Green

Write-Host ""
Write-Host "Equipements disponibles:" -ForegroundColor Cyan
for ($i = 0; $i -lt $equipments.Count; $i++) {
    # Acceder directement depuis le tableau
    $equipId = $equipments[$i].id
    $equipName = $equipments[$i].name
    $equipCategory = $equipments[$i].category
    $equipModel = $equipments[$i].modele
    
    $displayName = if ($equipName) { $equipName } else { "Equipement sans nom" }
    $displayInfo = ""
    if ($equipCategory) { $displayInfo += " [$equipCategory]" }
    if ($equipModel) { $displayInfo += " - $equipModel" }
    
    Write-Host "  [$i] $displayName (ID: $equipId)$displayInfo" -ForegroundColor White
}
Write-Host ""

$equipChoice = Read-Host "Choisissez le numero de l'equipement"
$selectedEquipment = $equipments[[int]$equipChoice]

# Recuperer l'ID de l'equipement
$selectedEquipId = $selectedEquipment.id
$selectedEquipName = $selectedEquipment.name

Write-Host "OK - Equipement selectionne: $selectedEquipName (ID: $selectedEquipId)" -ForegroundColor Green
Write-Host ""

# Etape 4: Informations de l'equipement
Write-Host "[4/5] Informations de l'equipement" -ForegroundColor Yellow
Write-Host "Recuperation des details..." -ForegroundColor Gray

$equipmentInfo = Invoke-ToposAPI -Method "equipements_fiche" -Parameters @{
    ID = $selectedEquipId
} -Token $token

if (-not $equipmentInfo) {
    Write-Host "Impossible de recuperer les infos de l'equipement !" -ForegroundColor Red
    exit 1
}

$equipData = $null
if ($equipmentInfo.response.record) {
    $equipData = $equipmentInfo.response.record
} elseif ($equipmentInfo.record) {
    $equipData = $equipmentInfo.record
} elseif ($equipmentInfo.data) {
    $equipData = $equipmentInfo.data
} else {
    $equipData = $equipmentInfo
}

# DEBUG: Afficher toutes les donnees de l'equipement
Write-Host "DEBUG - Donnees equipement:" -ForegroundColor Magenta
Write-Host ($equipData | ConvertTo-Json -Depth 3) -ForegroundColor DarkGray
Write-Host ""

Write-Host "OK - Informations recuperees" -ForegroundColor Green
Write-Host ""

# Etape 5: Choix du mode (désactivé car déjà appairé)
# Write-Host "[5/5] Type de configuration" -ForegroundColor Yellow
# $deviceMode = Read-Host "Type (MASTER ou SLAVE)"
# $mode = if ($deviceMode.ToUpper() -eq "MASTER") { "bridge" } else { "station-bridge" }

# Pas besoin de mode car déjà appairé
$mode = "bridge" # Mode par défaut
$deviceMode = "AUTO"
Write-Host ""

# Determiner le SSID en fonction de l'IP
$ipLastOctet = 1 # Valeur par defaut
if ($equipData.AdminIP -match '\.(\d+)$') {
    $ipLastOctet = [int]$matches[1]
}

$ssidPrefix = ""
if ($ipLastOctet -in @(1, 2)) {
    $ssidPrefix = "lien1"
} elseif ($ipLastOctet -in @(3, 4)) {
    $ssidPrefix = "lien2"
} elseif ($ipLastOctet -in @(5, 6)) {
    $ssidPrefix = "lien3"
} else {
    $ssidPrefix = "lien1" # Par defaut
}

$NEWSSID = "$ssidPrefix-$NUMINSTALLATION"

# Preparer toutes les variables
$config = @{
    NUMINSTALLATION = $NUMINSTALLATION
    TOPOSSNMP = $TOPOSSNMP
    TOPOSRW = $TOPOSRW
    TOPOSHOSTNAME = if ($equipData.hostname) { $equipData.hostname } elseif ($equipData.name) { $equipData.name } else { "mikrotik-wap60g" }
    IPADDR = if ($equipData.ip_address) { $equipData.ip_address } elseif ($equipData.ip) { $equipData.ip } else { "192.168.88.2" }
    TOPOSIP = if ($equipData.AdminIP) { $equipData.AdminIP } elseif ($equipData.management_ip) { $equipData.management_ip } elseif ($equipData.ip_address) { $equipData.ip_address } else { "10.10.1.1" }
    NEWSSID = $NEWSSID
    MODE = $mode
    MODE_TEXT = $deviceMode
}

# Generation
Write-Host "Generation de la configuration..." -ForegroundColor Yellow

$configContent = New-MikrotikConfig -Config $config
$filename = "mikrotik_$($config.TOPOSHOSTNAME).rsc"

$configContent | Out-File -FilePath $filename -Encoding UTF8

Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "  Configuration generee avec succes !" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "Recapitulatif:" -ForegroundColor Cyan
Write-Host "  Site               : $($config.NUMINSTALLATION)" -ForegroundColor White
Write-Host "  Equipement         : $($config.TOPOSHOSTNAME)" -ForegroundColor White
Write-Host "  IP Management      : $($config.TOPOSIP)" -ForegroundColor White
Write-Host "  SSID               : $($config.NEWSSID)" -ForegroundColor White
Write-Host "  Password           : $($config.TOPOSRW)" -ForegroundColor White
Write-Host "  SNMP Community     : $($config.TOPOSSNMP)" -ForegroundColor White
Write-Host ""
Write-Host "Fichier genere: $filename" -ForegroundColor Yellow
Write-Host ""

# Demander si on veut appliquer directement la configuration
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Voulez-vous appliquer la configuration directement sur le Mikrotik ? (O/n): " -ForegroundColor Yellow -NoNewline
$applyConfig = Read-Host

if ($applyConfig -eq "" -or $applyConfig -eq "O" -or $applyConfig -eq "o") {
    Write-Host ""
    Write-Host "Type d'equipement:" -ForegroundColor Cyan
    Write-Host "  [1] Master (192.168.88.2)" -ForegroundColor White
    Write-Host "  [2] Slave (192.168.88.3)" -ForegroundColor White
    Write-Host "Choisissez (1 ou 2): " -ForegroundColor Yellow -NoNewline
    $deviceType = Read-Host
    
    $mikrotikIP = if ($deviceType -eq "2") { "192.168.88.3" } else { "192.168.88.2" }
    
    Write-Host ""
    Write-Host "Mot de passe admin du Mikrotik (laisser vide si pas de mot de passe): " -ForegroundColor Yellow -NoNewline
    $mikrotikPassword = Read-Host -AsSecureString
    $mikrotikPasswordPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($mikrotikPassword))
    
    # Appliquer la configuration
    $result = Send-MikrotikConfig -IPAddress $mikrotikIP -Username "admin" -Password $mikrotikPasswordPlain -ConfigFile $filename
    
    if ($result) {
        Write-Host "Configuration appliquee avec succes !" -ForegroundColor Green
    } else {
        Write-Host "Des erreurs se sont produites lors de l'application." -ForegroundColor Red
    }
} else {
    Write-Host ""
    Write-Host "Pour appliquer la configuration manuellement:" -ForegroundColor Cyan
    Write-Host "  1. Connectez-vous a https://192.168.88.2" -ForegroundColor White
    Write-Host "  2. Allez dans Terminal ou New Terminal" -ForegroundColor White
    Write-Host "  3. Copiez/collez le contenu du fichier $filename" -ForegroundColor White
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
