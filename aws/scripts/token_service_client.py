
# ArcGIS Online token service client

import argparse
import os
import json
import ssl
import urllib.parse
import urllib.request


class TokenServiceClient:

    def __init__(self, token_service_url='https://www.arcgis.com/sharing/rest/generateToken'):
        self.token_service_url = token_service_url

    # Generates token for the specified username and password.
    def generate_token(self, username: str, password: str, referer='referer', expiration=600):
        if username is None:
            raise ValueError('ArcGIS Online user name is not specified.')

        if password is None:
            raise ValueError('ArcGIS Online user password is not specified.')

        request = urllib.request.Request(self.token_service_url)
        request.method = 'POST'

        data = {
            'username': username,
            'password': password,
            'client': 'referer',
            'referer': referer,
            'expiration': str(expiration),
            'f': 'json'
        }

        request.data = urllib.parse.urlencode(data).encode('utf-8')

        response = urllib.request.urlopen(
            request, context=ssl._create_unverified_context())
        json_response = json.loads(response.read().decode())

        if response.code > 200:
            raise Exception(json_response['message'])
        if 'error' in json_response and 'message' in json_response['error']:
            raise Exception(json_response['error']['message'])

        return json_response['token']

if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        prog='token_service_client.py',
        description='Generates ArcGIS Online token for the specified user credentials.')

    parser.add_argument('-u', dest='username', required=False,
                        help='ArcGIS Online user name')
    parser.add_argument('-p', dest='password', required=False,
                        help='ArcGIS Online user password')

    args = parser.parse_args()

    if args.username:
        username = args.username
    elif 'ARCGIS_ONLINE_USERNAME' in os.environ:
        username = os.environ['ARCGIS_ONLINE_USERNAME']
    else:
        raise ValueError('ArcGIS Online user name is not specified.')

    if args.password:
        password = args.password
    elif 'ARCGIS_ONLINE_PASSWORD' in os.environ:
        password = os.environ['ARCGIS_ONLINE_PASSWORD']
    else:
        raise ValueError('ArcGIS Online user password is not specified.')

    token_service = TokenServiceClient()

    try:
        token = token_service.generate_token(username, password)
        print('token=' + token)    
    except Exception as e:
        print(e)
        exit(1)
    
