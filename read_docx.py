# -*- coding: utf-8 -*-
from docx import Document
import sys
import io

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

doc = Document(r'C:\Users\xumou\Desktop\statistics for data\grp-prj\stat group.docx')
for p in doc.paragraphs:
    if p.text.strip():
        print(p.text)
