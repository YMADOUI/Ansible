#!/usr/bin/python
# -*- coding: utf-8 -*-

from ansible.module_utils.basic import AnsibleModule
import requests
import json

DOCUMENTATION = '''
---
module: topos_api
short_description: Module pour interagir avec l'API TOPOS
description:
    - Permet de récupérer les données de configuration depuis l'API TOPOS
    - Gère l'authentification et les requêtes API
options:
    action:
        description: Action à effectuer (login, get_site_info, list_equipments, get_equipment_info)
        required: true
    username:
        description: Nom d'utilisateur TOPOS
        required: false
    password:
        description: Mot de passe TOPOS
        required: false
    token:
        description: Token d'authentification
        required: false
    site_id:
        description: Numéro d'installation
        required: false
    equipment_id:
        description: ID de l'équipement
        required: false
'''

EXAMPLES = '''
- name: Se connecter à l'API TOPOS
  topos_api:
    action: login
    username: "mon_user"
    password: "mon_password"

- name: Récupérer les infos du site
  topos_api:
    action: get_site_info
    token: "{{ topos_token }}"
    site_id: "12345"
'''

class ToposAPI:
    def __init__(self, base_url="https://www.dc-wifi.tech"):
        self.base_url = base_url
        self.token = None
        self.headers = {
            'Content-Type': 'application/json',
            'Accept': 'application/json, text/plain, */*',
            'User-Agent': 'Ansible-Mikrotik-Automation/1.0'
        }

    def login(self, username, password):
        """Authentification et récupération du token"""
        url = f"{self.base_url}/interactions-equipements/webservice_passconfig"
        
        payload = {
            "method": "login",
            "parameters": {
                "username": username,
                "password": password,
                "application": "wifipass"
            }
        }
        
        try:
            response = requests.post(url, json=payload, headers=self.headers, verify=False)
            response.raise_for_status()
            data = response.json()
            
            if 'token' in data or 'data' in data:
                self.token = data.get('token') or data.get('data', {}).get('token')
                return {'success': True, 'token': self.token, 'data': data}
            else:
                return {'success': False, 'error': 'Token non trouvé dans la réponse'}
                
        except Exception as e:
            return {'success': False, 'error': str(e)}

    def get_site_info(self, token, site_id):
        """Récupérer les informations du site"""
        url = f"{self.base_url}/interactions-equipements/webservice_passconfig"
        
        headers = self.headers.copy()
        headers['Authorization'] = f'Bearer {token}'
        
        payload = {
            "method": "getSiteInfo",
            "parameters": {
                "site_id": str(site_id)
            }
        }
        
        try:
            response = requests.post(url, json=payload, headers=headers, verify=False)
            response.raise_for_status()
            data = response.json()
            
            return {'success': True, 'data': data}
                
        except Exception as e:
            return {'success': False, 'error': str(e)}

    def list_equipments(self, token, site_id):
        """Lister les équipements du site"""
        url = f"{self.base_url}/interactions-equipements/webservice_passconfig"
        
        headers = self.headers.copy()
        headers['Authorization'] = f'Bearer {token}'
        
        payload = {
            "method": "listEquipments",
            "parameters": {
                "site_id": str(site_id)
            }
        }
        
        try:
            response = requests.post(url, json=payload, headers=headers, verify=False)
            response.raise_for_status()
            data = response.json()
            
            return {'success': True, 'data': data}
                
        except Exception as e:
            return {'success': False, 'error': str(e)}

    def get_equipment_info(self, token, equipment_id):
        """Récupérer les informations de l'équipement"""
        url = f"{self.base_url}/interactions-equipements/webservice_passconfig"
        
        headers = self.headers.copy()
        headers['Authorization'] = f'Bearer {token}'
        
        payload = {
            "method": "getEquipmentInfo",
            "parameters": {
                "equipment_id": str(equipment_id)
            }
        }
        
        try:
            response = requests.post(url, json=payload, headers=headers, verify=False)
            response.raise_for_status()
            data = response.json()
            
            return {'success': True, 'data': data}
                
        except Exception as e:
            return {'success': False, 'error': str(e)}


def main():
    module = AnsibleModule(
        argument_spec=dict(
            action=dict(required=True, type='str', 
                       choices=['login', 'get_site_info', 'list_equipments', 'get_equipment_info']),
            username=dict(required=False, type='str', no_log=True),
            password=dict(required=False, type='str', no_log=True),
            token=dict(required=False, type='str', no_log=True),
            site_id=dict(required=False, type='str'),
            equipment_id=dict(required=False, type='str'),
        ),
        supports_check_mode=True
    )

    action = module.params['action']
    api = ToposAPI()

    if action == 'login':
        username = module.params.get('username')
        password = module.params.get('password')
        
        if not username or not password:
            module.fail_json(msg="username et password requis pour l'action login")
        
        result = api.login(username, password)
        
        if result['success']:
            module.exit_json(changed=False, token=result['token'], response=result['data'])
        else:
            module.fail_json(msg=f"Échec de l'authentification: {result['error']}")

    elif action == 'get_site_info':
        token = module.params.get('token')
        site_id = module.params.get('site_id')
        
        if not token or not site_id:
            module.fail_json(msg="token et site_id requis pour l'action get_site_info")
        
        result = api.get_site_info(token, site_id)
        
        if result['success']:
            module.exit_json(changed=False, site_info=result['data'])
        else:
            module.fail_json(msg=f"Échec de la récupération: {result['error']}")

    elif action == 'list_equipments':
        token = module.params.get('token')
        site_id = module.params.get('site_id')
        
        if not token or not site_id:
            module.fail_json(msg="token et site_id requis pour l'action list_equipments")
        
        result = api.list_equipments(token, site_id)
        
        if result['success']:
            module.exit_json(changed=False, equipments=result['data'])
        else:
            module.fail_json(msg=f"Échec de la récupération: {result['error']}")

    elif action == 'get_equipment_info':
        token = module.params.get('token')
        equipment_id = module.params.get('equipment_id')
        
        if not token or not equipment_id:
            module.fail_json(msg="token et equipment_id requis pour l'action get_equipment_info")
        
        result = api.get_equipment_info(token, equipment_id)
        
        if result['success']:
            module.exit_json(changed=False, equipment_info=result['data'])
        else:
            module.fail_json(msg=f"Échec de la récupération: {result['error']}")


if __name__ == '__main__':
    main()
