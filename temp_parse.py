import re
with open('/tmp/page_content.html','r',encoding='utf-8') as f:
    c=f.read()
s=re.findall(r'subtitle_url[^\"]+\"([^\"]+)\"',c)
print('sub',s[:2])
d=re.findall(r'"desc":"([^"]+)"',c)
print('desc',d[:2])
