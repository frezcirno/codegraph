import os

for f in os.listdir('.'):
    if f.endswith('.bc'):
        base, ext = f.rsplit('.', 1)
        p, r = base.split('-', 1)
        os.makedirs(f"output/{p}/bitcode", exist_ok=True)
        os.rename(f, f"output/{p}/bitcode/{r}.{ext}")