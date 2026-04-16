import os
import json
from datetime import datetime
import shutil

# --- KONFIGURATION ---
PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
DIST_DIR = os.path.join(PROJECT_ROOT, "dist")
PMTILES_DIR = os.path.join(DIST_DIR, "pmtiles")
STYLES_DIR = os.path.join(DIST_DIR, "styles")
TEMPLATE_STYLE = os.path.join(PROJECT_ROOT, "styles", "osm-style.json")
MANIFEST_FILE = os.path.join(DIST_DIR, "manifest.json")

def format_size(size_bytes):
    if size_bytes == 0: return "0 B"
    size_name = ("B", "KB", "MB", "GB", "TB")
    import math
    i = int(math.floor(math.log(size_bytes, 1024)))
    p = math.pow(1024, i)
    s = round(size_bytes / p, 2)
    return f"{s} {size_name[i]}"

def generate_manifest():
    print(f"📦 Generating Manifest according to Plugin-Standard...")
    
    if not os.path.exists(PMTILES_DIR):
        os.makedirs(PMTILES_DIR, exist_ok=True)
    if not os.path.exists(STYLES_DIR):
        os.makedirs(STYLES_DIR, exist_ok=True)

    datasets = []
    files = [f for f in os.listdir(PMTILES_DIR) if f.endswith(".pmtiles")]
    
    for filename in sorted(files):
        map_id = filename.replace(".pmtiles", "")
        pmtiles_rel_path = f"pmtiles/{filename}"
        style_filename = f"{map_id}.json"
        style_rel_path = f"styles/{style_filename}"
        
        # 1. Style-Datei vorbereiten
        target_style_path = os.path.join(STYLES_DIR, style_filename)
        if os.path.exists(TEMPLATE_STYLE):
            # Template kopieren (oder hier Platzhalter ersetzen falls nötig)
            shutil.copy2(TEMPLATE_STYLE, target_style_path)
            print(f"  [STYLE] Created {style_rel_path}")
        else:
            print(f"  [WARN] Template style not found at {TEMPLATE_STYLE}")

        # 2. Datensatz-Eintrag gemäß EXTERNAL_PLUGINS.md
        dataset = {
            "id": map_id,
            "type": "basemap",
            "source": "osm",
            "name": f"OSM {map_id.replace('-', ' ').title()}",
            "style_path": style_rel_path,
            "pmtiles_path": pmtiles_rel_path
        }
        datasets.append(dataset)
        
        file_path = os.path.join(PMTILES_DIR, filename)
        size = format_size(os.stat(file_path).st_size)
        print(f"  [DATA]  Linked {filename} ({size})")

    manifest = {
        "version": "1.0",
        "project": "geodata-osm",
        "generated_at": datetime.now().isoformat() + "Z",
        "datasets": datasets,
        "resources": {
            "sprites": [],
            "fonts": []
        }
    }

    with open(MANIFEST_FILE, "w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2, ensure_ascii=False)
    
    print(f"\n✅ Manifest saved to: {MANIFEST_FILE}")

if __name__ == "__main__":
    generate_manifest()
