import requests
import re
from collections import defaultdict

def parse_domains(url):
    response = requests.get(url)
    content = response.content.decode('utf-8')
    domains = defaultdict(list)
    for line in content.splitlines():
        if 'site=' not in line:
            continue
        site_name = re.search(r'site=([^,]*)', line).group(1)
        if 'boost' in line:
            domains['higher'].append(site_name)
        elif 'downrank' in line:
            domains['lower'].append(site_name)
        else:
            domains['remove'].append(site_name)
    for key in domains:
        domains[key] = list(set(domains[key]))
    return dict(domains)

urls = [
    'https://raw.githubusercontent.com/kynoptic/wikipedia-reliable-sources/refs/heads/main/wikipedia-reliable-sources.goggle',
    'https://raw.githubusercontent.com/gayolGate/gayolGate/8f26b202202e76896bce59d865c5e7d4c35d5855/goggle.txt'
    
    ]

all_domains = defaultdict(list)
for key in ['neutral', 'lower', 'higher', 'remove']:
    with open(f'{key}', 'r') as file:
        all_domains[key] = [line.strip() for line in file.readlines()]


for url in urls:
    domains = parse_domains(url)
    for key in domains:
        all_domains[key].extend(domains[key])


all_domains['remove'] = [domain for domain in all_domains['remove'] if domain not in all_domains['higher'] and domain not in all_domains['lower'] and domain not in all_domains['neutral']]

keys = ['higher', 'lower', 'remove']
for key in keys:
    with open(f'{key}_domains.txt', 'w') as file:
        for domain in all_domains[key]:
            file.write(f"{domain}\n")
