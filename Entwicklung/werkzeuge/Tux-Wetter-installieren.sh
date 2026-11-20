#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 R.Bruns
# SPDX-License-Identifier: GPL-3.0-or-later
#
# TuX-Wetter installieren oder aktualisieren – zum Doppelklicken in Dolphin („Ausführen“).
# Erledigt alles, was sonst im Terminal nötig wäre:
#   - installiert das Widget neu oder spielt eine neue Version ein (auch ohne „… existiert schon“),
#   - stellt Widgets mit einer älteren Kennung um (Einstellungen, Position und Grösse bleiben),
#   - lädt Plasma neu und legt das Widget auf Wunsch gleich auf den Desktop.
# Die Datei Tux-Wetter_v….plasmoid muss im selben Ordner liegen.

set -u
KENNUNG="ch.tuxwetter"
NAME="TuX-Wetter"
ORDNER="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APPLETSRC="${XDG_CONFIG_HOME:-$HOME/.config}/plasma-org.kde.plasma.desktop-appletsrc"
# Nur für Tests: TUX_TEST=1 lässt Plasma in Ruhe (kein Neuladen, kein Widget anlegen)
TEST="${TUX_TEST:-}"

# ── Meldungen: als KDE-Dialog, sonst im Terminal ──
GRAFISCH=""
if [ -z "$TEST" ] && command -v kdialog >/dev/null && { [ -n "${WAYLAND_DISPLAY:-}" ] || [ -n "${DISPLAY:-}" ]; }; then
    GRAFISCH=1
fi
info() {
    echo "$1"
    [ -n "$GRAFISCH" ] && kdialog --title "$NAME" --msgbox "$1" 2>/dev/null
    return 0
}
fehler() {
    echo "Fehler: $1" >&2
    [ -n "$GRAFISCH" ] && kdialog --title "$NAME" --error "$1" 2>/dev/null
    exit 1
}
frage() {  # Ja = 0, Nein = 1
    if [ -n "$GRAFISCH" ]; then
        kdialog --title "$NAME" --yesno "$1" 2>/dev/null
        return $?
    fi
    [ -n "$TEST" ] && { echo "$1 → ja (Test)"; return 0; }
    local antwort
    read -r -p "$1 [J/n] " antwort
    [ -z "$antwort" ] || [[ "$antwort" =~ ^[JjYy] ]]
}

# ── Voraussetzungen ──
command -v kpackagetool6 >/dev/null || fehler "$NAME braucht KDE Plasma 6. Das Programm kpackagetool6 fehlt; mit Plasma 5 läuft das Widget nicht."
PAKET="$(ls -1 "$ORDNER"/Tux-Wetter_v*.plasmoid 2>/dev/null | sort -V | tail -1)"
[ -n "$PAKET" ] || fehler "Die Datei Tux-Wetter_v….plasmoid wurde nicht gefunden. Sie muss im selben Ordner liegen wie dieses Programm."
VERSION="$(basename "$PAKET" .plasmoid)"; VERSION="${VERSION#Tux-Wetter_v}"

LISTE="$(kpackagetool6 -t Plasma/Applet -l 2>/dev/null)"
INSTALLIERT=""; grep -qx "$KENNUNG" <<< "$LISTE" && INSTALLIERT=1
# Ältere Kennungen (vor 1.5): ch.<name>.tuxwetter, ganz früher ch.<name>.glaswetter
ALTE="$(grep -xE 'ch\.[a-z]+\.(tuxwetter|glaswetter)' <<< "$LISTE" || true)"
ALTE_WIDGETS=0
[ -f "$APPLETSRC" ] && ALTE_WIDGETS="$(grep -cE '^plugin=ch\.[a-z]+\.(tuxwetter|glaswetter)$' "$APPLETSRC" || true)"

if [ -n "$INSTALLIERT" ]; then
    TEXT="$NAME ist schon installiert. Jetzt auf V$VERSION aktualisieren?"
elif [ -n "$ALTE" ] || [ "$ALTE_WIDGETS" -gt 0 ]; then
    TEXT="Eine ältere Fassung von $NAME ist installiert. Jetzt auf V$VERSION umsteigen? Widgets, Position und Einstellungen bleiben erhalten."
else
    TEXT="$NAME V$VERSION jetzt installieren?"
fi
frage "$TEXT

Der Desktop verschwindet dabei kurz und kommt gleich wieder; offene Programme bleiben offen." || exit 0

# ── Installieren oder aktualisieren ──
if [ -n "$INSTALLIERT" ]; then
    AUSGABE="$(kpackagetool6 -t Plasma/Applet -u "$PAKET" 2>&1)" || fehler "Aktualisieren hat nicht geklappt:
$AUSGABE"
else
    AUSGABE="$(kpackagetool6 -t Plasma/Applet -i "$PAKET" 2>&1)" || fehler "Installieren hat nicht geklappt:
$AUSGABE"
fi
echo "$AUSGABE"

# ── Plasma beenden und starten ──
DIENST=""
[ -z "$TEST" ] && systemctl --user is-active --quiet plasma-plasmashell 2>/dev/null && DIENST=1
plasma_stopp() {
    [ -n "$TEST" ] && return
    if [ -n "$DIENST" ]; then systemctl --user stop plasma-plasmashell; else kquitapp6 plasmashell 2>/dev/null; fi
    # warten, bis Plasma wirklich beendet ist (höchstens 20 Sekunden)
    for _ in $(seq 1 40); do pgrep -u "$(id -u)" -x plasmashell >/dev/null || break; sleep 0.5; done
}
plasma_start() {
    [ -n "$TEST" ] && return
    if [ -n "$DIENST" ]; then systemctl --user start plasma-plasmashell
    else (setsid kstart plasmashell >/dev/null 2>&1 &) ; fi
}

# ── Umstieg von einer älteren Kennung: Widgets in der Plasma-Konfiguration umschreiben ──
if [ "$ALTE_WIDGETS" -gt 0 ]; then
    SICHERUNG="$APPLETSRC.vor-$KENNUNG-$(date +%Y%m%d-%H%M%S)"
    cp -p "$APPLETSRC" "$SICHERUNG" || fehler "Die Plasma-Einstellungen konnten nicht gesichert werden; es wurde nichts umgestellt."
    plasma_stopp
    sed -i -E "s/^plugin=ch\.[a-z]+\.(tuxwetter|glaswetter)\$/plugin=$KENNUNG/" "$APPLETSRC"
    plasma_start
    echo "Umgestellt: $ALTE_WIDGETS Widget(s); Sicherung: $SICHERUNG"
else
    plasma_stopp
    plasma_start
fi
# Alte Fassung(en) entfernen
for alt in $ALTE; do
    kpackagetool6 -t Plasma/Applet -r "$alt" >/dev/null 2>&1 && echo "Alte Fassung $alt entfernt"
done

# ── Widget auf den Desktop legen, falls noch keines da ist ──
VORHANDEN=0
[ -f "$APPLETSRC" ] && VORHANDEN="$(grep -cx "plugin=$KENNUNG" "$APPLETSRC" || true)"
QDBUS="$(command -v qdbus-qt6 || command -v qdbus6 || command -v qdbus || true)"
HINWEIS="Den Ort wählen: Rechtsklick auf das Widget → „$NAME einrichten …“ → bei „Ort suchen“ den Ort eingeben."
if [ -n "$TEST" ]; then
    echo "Test: Widgets vorhanden: $VORHANDEN"
elif [ "$VORHANDEN" -eq 0 ] && frage "$NAME ist installiert. Soll es gleich auf den Desktop gelegt werden?"; then
    ANGELEGT=""
    if [ -n "$QDBUS" ]; then
        # warten, bis Plasma wieder bereit ist (höchstens 30 Sekunden)
        for _ in $(seq 1 60); do "$QDBUS" org.kde.plasmashell /PlasmaShell >/dev/null 2>&1 && break; sleep 0.5; done
        sleep 2
        ERGEBNIS="$("$QDBUS" org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "
            var d = desktopsForActivity(currentActivity())[0] || desktops()[0];
            var r = screenGeometry(d.screen);
            var w = d.addWidget('$KENNUNG', Math.max(0, r.width - 620), 60, 560, 436);
            print(w ? 'ok' : 'nein');" 2>&1)"
        [[ "$ERGEBNIS" == *ok* ]] && ANGELEGT=1
    fi
    if [ -n "$ANGELEGT" ]; then
        info "Fertig! $NAME V$VERSION liegt oben rechts auf dem Desktop.

$HINWEIS"
    else
        info "$NAME V$VERSION ist installiert. Bitte von Hand auf den Desktop legen: Rechtsklick auf den Desktop → „Miniprogramme hinzufügen …“ → „$NAME“ auf den Desktop ziehen.

$HINWEIS"
    fi
    exit 0
fi
info "Fertig! $NAME ist jetzt V$VERSION.$( [ "$ALTE_WIDGETS" -gt 0 ] && printf '\n\nDie Widgets wurden umgestellt; Einstellungen, Position und Grösse sind geblieben.' )"
