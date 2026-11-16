import re
b=open('/tmp/wasm/bundle.js').read()
n=len(re.findall(r'</script', b, re.I)); b=re.sub(r'</(script)', r'<\\/\1', b, flags=re.I)
t=open('/tmp/wasm/app/template.html').read()
out=t.replace('/*__BUNDLE__*/', b)
open('/workspace/hueforge/frame/share/HueForge_Frame_Maker.html','w').write(out)
print('escaped', n, 'size MB', round(len(out)/1e6,2))
