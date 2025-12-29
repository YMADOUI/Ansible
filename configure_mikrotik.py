#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script Python - Configuration Mikrotik wAP 60G
Recupere les donnees depuis l'API TOPOS et genere la configuration
"""

import requests
import json
import getpass
from urllib3.exceptions import InsecureRequestWarning

# Desactiver les avertissements SSL
requests.packages.urllib3.disable_warnings(category=InsecureRequestWarning)

API_BASE = "https://www.dc-wifi.tech/interactions-equipements/webservice_passconfig"


def topos_api_call(method, parameters, token=None):
    """Appeler l'API TOPOS"""
    headers = {
        "Content-Type": "application/json",
        "Accept": "application/json, text/plain, */*"
    }
    
    if token:
        headers["Authorization"] = f"Bearer {token}"
    
    body = {
        "method": method,
        "parameters": parameters
    }
    
    response = requests.post(API_BASE, headers=headers, json=body, verify=False)
    response.raise_for_status()
    return response.json()


def generate_mikrotik_config(config_vars):
    """Generer la configuration Mikrotik depuis le template"""
    with open('templates/mikrotik_config.j2', 'r', encoding='utf-8') as f:
        template = f.read()
    
    # Remplacer les variables
    for key, value in config_vars.items():
        template = template.replace(f'{{{{ {key} }}}}', str(value))
    
    return template


def main():
    print("=" * 50)
    print("  Configuration Mikrotik wAP 60G")
    print("  Recuperation depuis API TOPOS")
    print("=" * 50)
    print()
    
    # Demander les informations
    username = input("Nom d'utilisateur TOPOS: ")
    password = getpass.getpass("Mot de passe TOPOS: ")
    client_id = input("Numero client: ")
    installation_id = input("ID Installation (numero du site): ")
    
    print()
    print("[1/5] Authentification TOPOS...")
    
    # Authentification
    auth_response = topos_api_call("login", {
        "username": username,
        "password": password
    })
    
    token = auth_response.get("response", {}).get("new_JWT")
    if not token:
        print("ERREUR: Impossible de recuperer le token")
        return
    
    print("OK - Authentification reussie")
    print()
    
    # Recuperer les infos du site
    print("[2/5] Recuperation des informations du site...")
    site_info = topos_api_call("installations_fiche", {"ID": installation_id}, token)
    
    site_data = site_info.get("response", {}).get("record", {})
    topos_snmp = site_data.get("SnmpCommunity")
    topos_rw = site_data.get("PasswordRW")
    num_installation = site_data.get("IDInstallation", installation_id)
    
    print(f"OK - Installation: {num_installation}")
    print(f"     SNMP Community: {topos_snmp}")
    print()
    
    # Recuperer la liste des equipements
    print("[3/5] Recuperation de la liste des equipements...")
    equipment_list_url = f"https://www.dc-wifi.tech/interactions-equipements/installations-immediate-interactions/{client_id}/{installation_id}"
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }
    
    response = requests.put(equipment_list_url, headers=headers, verify=False)
    equipments = response.json()
    
    if not isinstance(equipments, list):
        equipments = equipments.get("equipments", [])
    
    print(f"OK - {len(equipments)} equipements trouves")
    print()
    print("Equipements disponibles:")
    for idx, equip in enumerate(equipments):
        equip_id = equip.get("id")
        equip_name = equip.get("name")
        equip_category = equip.get("category", "N/A")
        equip_model = equip.get("modele", "N/A")
        print(f"  [{idx}] {equip_name} (ID: {equip_id}) [{equip_category}] - {equip_model}")
    
    print()
    equipment_index = int(input("Choisissez le numero de l'equipement: "))
    
    if equipment_index < 0 or equipment_index >= len(equipments):
        print("ERREUR: Numero d'equipement invalide")
        return
    
    selected_equipment = equipments[equipment_index]
    equipment_id = selected_equipment.get("id")
    equipment_name = selected_equipment.get("name")
    
    print(f"OK - Equipement selectionne: {equipment_name} (ID: {equipment_id})")
    print()
    
    # Recuperer les infos de l'equipement
    print("[4/5] Recuperation des informations de l'equipement...")
    equipment_info = topos_api_call("equipements_fiche", {"ID": equipment_id}, token)
    
    equipment_data = equipment_info.get("response", {}).get("record", {})
    topos_hostname = equipment_data.get("Hostname")
    topos_ip = equipment_data.get("AdminIP")
    
    print(f"OK - Equipement: {topos_hostname}")
    print(f"     IP Management: {topos_ip}")
    print()
    
    # Determiner le SSID
    print("[5/5] Generation du SSID...")
    ip_last_octet = int(topos_ip.split('.')[-1])
    
    if ip_last_octet in [1, 2]:
        ssid_prefix = "lien1"
    elif ip_last_octet in [3, 4]:
        ssid_prefix = "lien2"
    elif ip_last_octet in [5, 6]:
        ssid_prefix = "lien3"
    else:
        ssid_prefix = "lien1"
    
    new_ssid = f"{ssid_prefix}-{num_installation}"
    print(f"OK - SSID: {new_ssid}")
    print()
    
    # Generer la configuration
    print("[6/6] Generation de la configuration Mikrotik...")
    
    config_vars = {
        "NUMINSTALLATION": num_installation,
        "TOPOSSNMP": topos_snmp,
        "TOPOSRW": topos_rw,
        "TOPOSHOSTNAME": topos_hostname,
        "TOPOSIP": topos_ip,
        "NEWSSID": new_ssid,
        "MODE": "bridge",
        "MODE_TEXT": "bridge"
    }
    
    config = generate_mikrotik_config(config_vars)
    
    filename = f"mikrotik_{topos_hostname}.rsc"
    with open(filename, 'w', encoding='utf-8') as f:
        f.write(config)
    
    print(f"OK - Configuration generee: {filename}")
    print()
    
    # Afficher le recapitulatif
    print("=" * 50)
    print("  Configuration generee avec succes !")
    print("=" * 50)
    print()
    print("Recapitulatif:")
    print(f"  Site               : {num_installation}")
    print(f"  Equipement         : {topos_hostname}")
    print(f"  IP Management      : {topos_ip}")
    print(f"  SSID               : {new_ssid}")
    print(f"  Password           : {topos_rw}")
    print(f"  SNMP Community     : {topos_snmp}")
    print()
    print(f"Fichier genere: {filename}")
    print()
    print("Pour appliquer la configuration:")
    print("  1. Connectez-vous a https://192.168.88.2")
    print("  2. Allez dans Terminal ou New Terminal")
    print(f"  3. Copiez/collez le contenu du fichier {filename}")
    print()
    print("=" * 50)


if __name__ == "__main__":
    main()
