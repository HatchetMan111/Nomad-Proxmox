# Nomad LXC Installer for Proxmox VE

Ein eigenständiger Proxmox VE Community-Scripts-Installer für
[Project N.O.M.A.D.](https://www.projectnomad.us) – einen offline-first
Wissens-Server (Kiwix, Kolibri, Ollama, ProtoMaps, Flatnotes u.a.) als
Docker-Compose-Stack in einem LXC-Container.

Dieses Repo folgt exakt dem Format der offiziellen
[Proxmox VE Community Scripts](https://github.com/community-scripts/ProxmoxVE)
(`ct/`-Erstellungsskript + `install/`-Installationsskript) und nutzt deren
Framework (`build.func` / `install.func`) live vom offiziellen Repo – genauso,
wie es die Community-Scripts-Dokumentation für eigene/geforkte Skripte
vorsieht.

## Installation (Proxmox VE Host-Shell)

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/HatchetMan111/Nomad-Proxmox/main/ct/nomad.sh)"
```

Optional mit angepassten Defaults, z. B.:

```bash
var_cpu=4 var_ram=8192 var_disk=64 \
bash -c "$(curl -fsSL https://raw.githubusercontent.com/HatchetMan111/Nomad-Proxmox/main/ct/nomad.sh)"
```

## Update

Im Proxmox-Host-Shell den Container betreten (`pct enter <ID>`) und dort
das Update-Kommando des Frameworks ausführen, oder das `ct/nomad.sh`
Skript erneut gegen die bestehende Container-ID laufen lassen (Community-
Scripts-Standardverhalten, ruft intern `update_script()` auf).

## Anforderungen

- **Disk**: 16 GB minimum, 250 GB+ empfohlen bei großen Wikipedia-Dumps / KI-Modellen
- **RAM**: 4 GB minimum, 32 GB+ empfohlen für lokale LLMs
- **GPU**: NVIDIA GPU empfohlen für KI-Beschleunigung (Passthrough wird automatisch eingerichtet)
- **Architektur**: nur x86_64 (arm64 wird von Project N.O.M.A.D. nicht unterstützt)

## Hinweise

- Keine eingebaute Authentifizierung – Zugriff über Netzwerk-Ebene absichern.
- Der KI-Assistent (Ollama) ist optional.
- Alle Daten liegen persistent unter `/opt/project-nomad/`.
- Generierte Zugangsdaten (App-Key, DB-Passwörter) werden nach
  `~/nomad.creds` im Container geschrieben.
- Standardport ist 80 (über `var_port`/Compose-Datei anpassbar).

## Lizenz & Attribution

Dieses Repository steht unter der **MIT-Lizenz** (siehe [LICENSE](./LICENSE)).

- Basiert auf dem **community-scripts/ProxmoxVE** Framework (`build.func`,
  `install.func`), MIT-lizenziert, Copyright (c) 2021–2026 tteck /
  community-scripts ORG. Framework wird zur Laufzeit direkt vom offiziellen
  Repo geladen, nicht kopiert.
- Die App-spezifische Installationslogik orientiert sich an
  [scripts-underground/proxmox](https://github.com/scripts-underground/proxmox)
  (MIT-lizenziert, Copyright (c) 2026 scripts-underground), das Project
  N.O.M.A.D. zuerst als Proxmox-Community-Script gepackt hat. Danke dafür! 🙏
- **Project N.O.M.A.D.** selbst ist ein separates Projekt von
  [Crosstalk-Solutions](https://github.com/Crosstalk-Solutions/project-nomad),
  lizenziert unter **Apache License 2.0**. Der Quellcode der App wird nicht
  in diesem Repo gehostet, sondern bei der Installation direkt von den
  offiziellen GitHub-Releases geladen.

Dieses Repo enthält also **keinen fremden Code 1:1 kopiert** ohne
Lizenzhinweis – die Installationslogik ist eigenständig für das offizielle
Community-Scripts-Framework geschrieben, mit vollständiger Attribution aller
Quellen gemäß deren jeweiliger Lizenzbedingungen.

## Links

- Website: <https://www.projectnomad.us>
- Installationsanleitung (Upstream): <https://www.projectnomad.us/install>
- Hardware-Guide: <https://www.projectnomad.us/hardware>
- FAQ: <https://github.com/Crosstalk-Solutions/project-nomad/blob/main/FAQ.md>
