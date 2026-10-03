from pathlib import Path
import re

def set_label(text):
    def application(match):
        tag=match[0]
        if re.search(r'android:label\s*=',tag):
            return re.sub(r'android:label\s*=\s*([\x22\x27]).*?\1', 'android:label="Ondexa"',tag,count=1)
        return tag[:-1]+' android:label="Ondexa">'
    result,count=re.subn(r'<application\b[^>]*>',application,text,count=1,flags=re.S)
    if count!=1:raise RuntimeError('Application tag not found in AndroidManifest.xml')
    return result

if __name__=='__main__':
    manifest=Path('android/app/src/main/AndroidManifest.xml')
    manifest.write_text(set_label(manifest.read_text(encoding='utf-8')),encoding='utf-8')
    print('Android application label: Ondexa')
