# Projekt-Abhängigkeiten (geodata-osm)

Um dieses Repository vollumfänglich nutzen zu können, müssen folgende Tools auf dem Host-System installiert sein:

## System-Tools
| Tool | Zweck | Installations-Befehl (Ubuntu/Debian) |
| :--- | :--- | :--- |
| `bash` | Ausführung der Haupt-Skripte | *Vorinstalliert* |
| `curl` | URL-Checks und Fallback-Downloads | `sudo apt install curl` |
| `aria2c` | Schnelle, parallele Downloads | `sudo apt install aria2` |
| `osmium` | Mergen und Validieren von PBF-Dateien | `sudo apt install osmium-tool` |
| `docker` | Ausführung von Planetiler (Isolation) | [Docker Install Guide](https://docs.docker.com/engine/install/) |
| `python3` | Manifest-Erstellung und Monitoring | `sudo apt install python3` |

## Docker Images
Folgende Images werden automatisch geladen:
- `ghcr.io/onthegomap/planetiler:latest` (Wird in `convert.sh` genutzt)

## Python Module
Die Python-Skripte nutzen ausschließlich die Standard-Bibliothek (keine `pip install` notwendig).
