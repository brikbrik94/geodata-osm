import json
import os
import re
import shutil
import sys
import time
from datetime import datetime

# Corporate Identity einbinden
sys.path.append(os.path.join(os.path.dirname(__file__), "ci"))
from utils import log_success, C_BOLD, C_GREEN, C_RESET

# --- KONFIGURATION ---
log_file_path = sys.argv[1]
docker_pid = int(sys.argv[2])

# Prüfen ob wir in einem echten Terminal sind
IS_TTY = sys.stdout.isatty()

cols = shutil.get_terminal_size().columns if IS_TTY else 80
bar_width = 30

# ANSI Farben
ESC = chr(27)
RED = f"{ESC}[91m"
GREEN = f"{ESC}[92m"
YELLOW = f"{ESC}[93m"
BLUE = f"{ESC}[94m"
MAGENTA = f"{ESC}[95m"
CYAN = f"{ESC}[96m"
WHITE = f"{ESC}[97m"
BOLD = f"{ESC}[1m"
RESET = f"{ESC}[0m"

ansi_escape = re.compile(r"\x1B(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~])")

def clean_line(line):
    return ansi_escape.sub("", line)

def is_process_running(pid):
    try:
        os.kill(pid, 0)
        return True
    except OSError:
        return False

class Dashboard:
    def __init__(self):
        self.current_phase = "INITIALIZING"
        self.percent = 0
        self.speed = ""
        self.cpu = "0.0"
        self.heap = ""
        self.last_errors = []
        self.start_time = time.time()
        self.stats = {}
        self.last_draw_time = 0

    def update(self, line_no_color):
        # Phase und Fortschritt extrahieren
        phase_match = re.search(r"INF \[(.*?)\] - (.*)", line_no_color)
        if phase_match:
            self.current_phase = phase_match.group(1).upper()
            details = phase_match.group(2)
            
            perc_match = re.search(r"(\d+)%", details)
            if perc_match:
                self.percent = int(perc_match.group(1))
            
            speed_match = re.search(r"(\d+\.?\d*[MkG]?/s)", details)
            if speed_match:
                self.speed = speed_match.group(1)

        # System-Ressourcen
        res_match = re.search(r"cpus: ([\d\.]+) .*? heap: (.*?/.*? )", line_no_color)
        if res_match:
            self.cpu = res_match.group(1)
            self.heap = res_match.group(2).strip()

        # Fehler sammeln
        if "ERR" in line_no_color or "WAR" in line_no_color or "Exception" in line_no_color:
            clean_err = line_no_color.split("- ", 1)[-1] if "-" in line_no_color else line_no_color
            if clean_err not in self.last_errors:
                self.last_errors.append(clean_err[:cols-10])
                self.last_errors = self.last_errors[-3:]

        # Finale Stats
        if "Max tile:" in line_no_color:
            self.stats['max_tile'] = re.search(r"Max tile: (.*)", line_no_color).group(1)
        if "Avg tile:" in line_no_color:
            self.stats['avg_tile'] = re.search(r"Avg tile: (.*)", line_no_color).group(1)
        if "overall" in line_no_color and "cpu:" in line_no_color:
            self.stats['duration'] = re.search(r"overall\s+(.*?)\s", line_no_color).group(1)

    def draw(self):
        # Nur alle 1 Sekunde zeichnen um SSH-Load zu senken
        now = time.time()
        if now - self.last_draw_time < 1.0:
            return
        self.last_draw_time = now

        if IS_TTY:
            # Dashboard Mode (Overwrite)
            sys.stdout.write(f"{ESC}[H") 
            header = f" {BOLD}{WHITE}PLANETILER BUILD DASHBOARD{RESET} "
            sys.stdout.write(f"{BLUE}{header:=^{cols}}{RESET}\n")
            filled = int(bar_width * self.percent / 100)
            bar = f"{GREEN}{'█' * filled}{RESET}{'░' * (bar_width - filled)}"
            sys.stdout.write(f"\n {BOLD}PHASE:{RESET} {CYAN}{self.current_phase:<15}{RESET} [{bar}] {YELLOW}{self.percent:>3}%{RESET} \n")
            sys.stdout.write(f" {BOLD}SPEED:{RESET} {MAGENTA}{self.speed:<12}{RESET} | {BOLD}CPU:{RESET} {self.cpu:>4} | {BOLD}RAM:{RESET} {self.heap:<15} \n")
            sys.stdout.write(f"\n {BOLD}{RED}LOG / RECENT ISSUES:{RESET} \n")
            if not self.last_errors:
                sys.stdout.write(f" {GREEN}No issues reported so far.{RESET} \n\n")
            else:
                for err in self.last_errors:
                    color = RED if "ERR" in err or "Exception" in err else YELLOW
                    sys.stdout.write(f" {color}» {err[:cols-5]:<{cols-5}}{RESET} \n")
                for _ in range(3 - len(self.last_errors)): sys.stdout.write(" " * cols + "\n")
            elapsed = int(time.time() - self.start_time)
            footer = f" Elapsed: {elapsed//60}m {elapsed%60}s | PID: {docker_pid} "
            sys.stdout.write(f"\n{BLUE}{footer:=^{cols}}{RESET}\n")
        else:
            # Simple Mode (Line by Line für Log-Dateien / SSH-Piping)
            elapsed = int(time.time() - self.start_time)
            msg = f"[{elapsed//60}m {elapsed%60}s] PHASE: {self.current_phase} | {self.percent}% | Speed: {self.speed} | CPU: {self.cpu}"
            sys.stdout.write(msg + "\n")
        
        sys.stdout.flush()

# --- MAIN LOOP ---
dash = Dashboard()
if IS_TTY:
    print(f"{ESC}[2J") # Screen clear

if not os.path.exists(log_file_path):
    while not os.path.exists(log_file_path):
        time.sleep(0.2)

try:
    with open(log_file_path, "r", encoding="utf-8", errors="ignore") as f:
        while True:
            line = f.readline()
            if not line:
                if not is_process_running(docker_pid):
                    break
                time.sleep(0.2)
                continue
            
            line_no_color = clean_line(line.strip())
            if line_no_color:
                dash.update(line_no_color)
                dash.draw()

except KeyboardInterrupt:
    pass

# Abschluss-Report
log_success("BUILD COMPLETED!")
if dash.stats:
    print(f" {C_BOLD}Duration:{C_RESET}  {dash.stats.get('duration', 'N/A')}")
    print(f" {C_BOLD}Tile Size:{C_RESET} Max {dash.stats.get('max_tile', 'N/A')} | Avg {dash.stats.get('avg_tile', 'N/A')}")
