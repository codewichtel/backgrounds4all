# Microsoft Teams Backgrounds per Gruppenrichtlinie (GPO)

Dieses Paket verteilt unternehmensweite benutzerdefinierte Hintergründe für **New Microsoft Teams** per Active-Directory-Gruppenrichtlinie.

Die technische Idee basiert auf dem Ansatz aus FlorianSLZ/scloud für die Intune-Verteilung von Teams-Hintergründen.

Für den GPO-Einsatz wurde das Verfahren angepasst:

- Ausführung im Benutzerkontext
- stabile GUIDs
- SHA-256-Änderungserkennung
- idempotente Ausführung bei jedem Logon
- automatische Bereinigung entfernter Hintergründe
- keine Löschung persönlicher Teams-Hintergründe

## Verzeichnisstruktur

```text
Teams-Backgrounds-GPO\
├── Deploy-TeamsBackgrounds.ps1
├── Deploy-TeamsBackgrounds.cmd
├── README.md
└── bg\
    ├── Company-01.jpg
    └── Company-02.png
```

Die gewünschten Hintergrundbilder werden in `bg` abgelegt.

Unterstützt werden:

```text
.jpg
.jpeg
.png
.bmp
```

## Zielpfad in New Teams

Das Skript schreibt pro angemeldetem Benutzer nach:

```text
%LOCALAPPDATA%\Packages\MSTeams_8wekyb3d8bbwe\LocalCache\Microsoft\MSTeams\Backgrounds\Uploads
```

Für jedes Hintergrundbild werden zwei Dateien erzeugt:

```text
<GUID>.jpg
<GUID>_thumb.jpg
```

Die GUID wird deterministisch aus dem Quelldateinamen erzeugt.

Dadurch wird bei jedem Logon dieselbe GUID verwendet und der Teams-Ordner wächst nicht durch immer neue Dateien an.

# GPO Deployment

## 1. Dateien nach SYSVOL kopieren

Beispiel:

```text
\\contoso.local\SYSVOL\contoso.local\scripts\Teams-Backgrounds\
```

Dort liegen anschließend:

```text
Deploy-TeamsBackgrounds.ps1
Deploy-TeamsBackgrounds.cmd
bg\
```

Domänenbenutzer benötigen lediglich Leserechte.

## 2. GPO erstellen

Beispiel:

```text
USR - Microsoft Teams Corporate Backgrounds
```

Die GPO wird auf die OU mit den entsprechenden Benutzerkonten verknüpft.

## 3. Logonskript konfigurieren

Pfad:

```text
Benutzerkonfiguration
  -> Windows-Einstellungen
    -> Skripts (Anmelden/Abmelden)
      -> Anmelden
```

Als Logonskript kann verwendet werden:

```text
Deploy-TeamsBackgrounds.cmd
```

Der darin konfigurierte SYSVOL-Pfad muss vorher an die eigene Umgebung angepasst werden.

# Warum Benutzer-GPO?

Der Teams-Hintergrundordner befindet sich unter:

```text
%LOCALAPPDATA%
```

Ein Computer-Startup-Skript läuft normalerweise als `SYSTEM`.

Dadurch würde in das falsche Benutzerprofil geschrieben.

Das Deployment muss deshalb im Benutzerkontext ausgeführt werden.

# Idempotenz

Bei jedem Lauf:

1. Bilder aus dem zentralen `bg`-Ordner einlesen
2. stabile GUID aus dem Dateinamen erzeugen
3. SHA-256-Hash berechnen
4. unveränderte Bilder überspringen
5. geänderte Bilder aktualisieren
6. zentral entfernte verwaltete Bilder lokal entfernen

Persönliche Teams-Hintergründe werden nicht gelöscht.

# State

Der Verwaltungsstatus liegt unter:

```text
%LOCALAPPDATA%\Teams-Backgrounds-GPO\managed-backgrounds.json
```

Damit weiß das Skript exakt, welche Dateien von der GPO verwaltet werden.

# Logging

Logdatei:

```text
%LOCALAPPDATA%\Teams-Backgrounds-GPO\Logs\Deploy-TeamsBackgrounds.log
```

# Manueller Test

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass `
    -File .\Deploy-TeamsBackgrounds.ps1 `
    -SourcePath .\bg `
    -Verbose
```

Danach prüfen:

```powershell
Get-ChildItem "$env:LOCALAPPDATA\Packages\MSTeams_8wekyb3d8bbwe\LocalCache\Microsoft\MSTeams\Backgrounds\Uploads"
```

Log:

```powershell
Get-Content "$env:LOCALAPPDATA\Teams-Backgrounds-GPO\Logs\Deploy-TeamsBackgrounds.log"
```

# Aktualisieren eines Hintergrundes

Ein Bild kann im zentralen `bg`-Verzeichnis einfach ersetzt werden.

Bleibt der Dateiname gleich, bleibt auch die GUID gleich.

Der geänderte SHA-256-Hash sorgt dafür, dass das Bild beim nächsten Logon aktualisiert wird.

# Entfernen eines Hintergrundes

Wird ein Bild aus dem zentralen `bg`-Verzeichnis gelöscht, entfernt das Skript beim nächsten Logon die zugehörigen verwalteten Dateien aus Teams.

Andere, vom Benutzer selbst hinzugefügte Hintergründe bleiben erhalten.

# Rollback / Deinstallation

Alle durch dieses Skript verwalteten Hintergründe können mit folgendem Aufruf entfernt werden:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass `
    -File .\Deploy-TeamsBackgrounds.ps1 `
    -RemoveManagedBackgrounds
```

Für einen zentralen Rollback kann temporär eine separate User-GPO mit diesem Aufruf verteilt werden.

# Hinweise

- vorgesehen für New Microsoft Teams / MSTeams MSIX
- keine lokalen Administratorrechte erforderlich
- Ausführung im Benutzerkontext
- SYSVOL muss beim Login erreichbar sein
- Teams muss beim Kopieren nicht beendet werden
- neue Hintergründe können gegebenenfalls erst nach erneutem Öffnen der Hintergrundauswahl oder Teams-Neustart sichtbar werden

# Quelle / Inspiration

Ausgangspunkt:

FlorianSLZ/scloud  
`Teams/Teams-Backgrounds`

Die ursprüngliche Variante ist auf Intune ausgelegt. Diese Implementierung adaptiert das Verfahren für wiederkehrende Active-Directory-GPO-Logons.
