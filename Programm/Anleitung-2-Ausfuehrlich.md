# Tux-Wetter V1.6 – Ausführliche Anleitung

Erstellt 2026 von R.Bruns · Lizenz GPL-3.0-or-later

Tux-Wetter ist ein Wetter-Widget für den KDE-Plasma-Desktop. Es zeigt das aktuelle Wetter, die
nächsten Stunden und fünf Tage Vorschau auf einer Karte im Glas-Look – mit Warnungen, gemessener
Temperatur und vielen Zusatzinfos. Es spricht Deutsch und Englisch.

> **Schnell starten:** Installieren ([Kapitel 3](#k3)), Ort suchen ([Kapitel 4](#k4)) – fertig.
> Alles Weitere kann man später nachlesen.

---

<a id="neu"></a>

## Neu in Version 1.6

**Neu**

- **Hinweis auf neue Versionen:** Einmal am Tag fragt das Widget bei GitHub nach, ob es eine neuere
  Version gibt. Wenn ja, erscheint auf der Karte ein Hinweis mit zwei Knöpfen:
  **Download-Seite öffnen** und **Diese Version überspringen**. Nach dem Öffnen der Download-Seite
  erinnert das Widget nach drei Tagen erneut, falls die neue Version dann noch nicht installiert ist.
  Heruntergeladen oder installiert wird dabei nichts – das bleibt in der eigenen Hand
  ([Kapitel 14](#k14)). In der Leiste zeigt ein grüner Kreis mit Pfeil am Symbol die neue Version an
  ([Kapitel 9](#k9)). Abschalten lässt sich der Hinweis in den Einstellungen unter
  **Neue Versionen** ([Kapitel 10](#k10)).

### Bereits in Version 1.5

**Neu**

- **Einstellungen gehen nicht mehr verloren:** Entfernt man das Widget vom Desktop, löscht Plasma seine
  Einstellungen. Tux-Wetter sichert sie darum zusätzlich selbst. Ein neu hinzugefügtes Widget findet die
  Sicherung und fragt: **Frühere Einstellungen gefunden – übernehmen?** ([Kapitel 14](#k14)).
- **In Datei sichern und aus Datei laden:** In den Einstellungen unter **Sicherung**, z. B. für einen
  anderen Rechner. API-Schlüssel kommen nur auf Wunsch mit.
- **Quellenangabe auf der Karte:** Unten rechts steht klein, woher die Daten kommen; beim Darüberfahren
  alle Quellen mit Lizenz. Die Wetterdienste verlangen diese Angabe ([Kapitel 5](#k5)).
- **Warnungen von MeteoSchweiz wieder standardmässig an:** Sie kommen jetzt über MeteoAlarm, das
  Warnportal der europäischen Wetterdienste, und sind dort frei weiterverwendbar. Titel und Text
  erscheinen im Wortlaut von MeteoSchweiz ([Kapitel 7](#k7)).
- **Deutscher Wetterdienst als Wetteranbieter:** die Stationsvorhersage MOSMIX des DWD, kostenlos und
  ohne Schlüssel, mit Böen und Regenwahrscheinlichkeit ([Kapitel 11](#k11)).

**Verbessert**

- **Installationsprogramm zum Doppelklicken** (`Tux-Wetter-installieren.sh`): installiert, aktualisiert
  und steigt von älteren Versionen um, ganz ohne Terminal ([Kapitel 3](#k3)).
- **Neuer Name „Tux-Wetter“** und neue Kennung `ch.tuxwetter` ohne Personennamen; einmaliger Umstieg
  siehe unten.
- Die Anleitung erklärt genauer, wie man eine **neue Version einspielt**. Über **Miniprogramm aus lokaler
  Datei installieren …** geht das nicht: Plasma meldet dann „… existiert schon“
  ([Kapitel 14](#k14)).

**Behoben**

- Beim Wechsel der Sprache in den Einstellungen sprangen Farbschema, Wettermodell und Warnstufe der
  Benachrichtigung in der Anzeige auf den ersten Eintrag zurück.
- Die Auswahl der Wettermodelle nannte zu viele Tage: MeteoSchweiz ICON-CH2 reicht 4–5 Tage und nur für den
  Alpenraum, Météo-France 3–4 Tage.
- Deckt ein Wettermodell den Ort nicht ab, steht jetzt eine verständliche Meldung auf der Karte statt
  „Fehler 400“.

> **Umstieg von 1.4 oder älter:** Das Widget hat seit 1.5 eine neue Kennung (`ch.tuxwetter`). Darum
> klappt das übliche Aktualisieren diesmal nicht. Ein einmaliger Umstieg übernimmt die Widgets samt
> Position und Einstellungen ([Kapitel 14](#k14), „Umstieg von Version 1.4 oder älter“). Das Widget dafür
> **nicht** vom Desktop löschen.

### Bereits in Version 1.4

**Verbessert**

- **Grösse bleibt erhalten:** Das Widget merkt sich seine Grösse auf dem Desktop. Stellt Plasma es nach
  einem Neustart neu auf (z. B. unter Wayland mit Skalierung), erscheint es nicht mehr in der
  Grundgrösse. Die Position legt weiterhin Plasma fest.
- **Tagesdetails bei MET Norway** jetzt auch für die letzten Tage der Vorschau (dort mit Werten alle
  6 Stunden).
- **Datenquellen und Lizenz** stehen jetzt vollständig in den Einstellungen; der Lizenztext liegt dem
  Widget bei.

**Geändert**

- **Warnungen von MeteoSchweiz waren in 1.4 standardmässig aus.** Seit 1.5 sind sie über MeteoAlarm
  wieder an (siehe oben).

**Behoben**

- Das Wettersymbol blieb beim Wechsel auf Nebel kurz leer.
- Beim Öffnen der Einstellungen erschienen Warnungen im Systemprotokoll.
- Ungültige eigene Farben in der Einstellungsdatei ergaben eine unlesbare Karte; jetzt gilt dann das
  Standard-Farbschema.

---

## Inhalt

[Neu in Version 1.6](#neu)

**Teil 1 · Loslegen**

1. [Das kann Tux-Wetter](#k1)
2. [Voraussetzungen](#k2)
3. [Installieren](#k3)
4. [In zwei Minuten eingerichtet](#k4)

**Teil 2 · Benutzen**

5. [Die Karte](#k5)
6. [Bedienen](#k6)
7. [Wetterwarnungen](#k7)
8. [Mehrere Orte und Standort](#k8)
9. [Tux-Wetter in der Leiste](#k9)

**Teil 3 · Einstellen**

10. [Die Einstellungen](#k10)
11. [Den Wetteranbieter wählen](#k11)

**Teil 4 · Hintergrund**

12. [Woher die Daten kommen](#k12)
13. [Datenschutz](#k13)
14. [Sichern, aktualisieren, entfernen](#k14)

**Teil 5 · Hilfe**

15. [Meldungen auf der Karte](#k15)
16. [Häufige Fragen](#k16)
17. [Begriffe](#k17)

---

# Teil 1 · Loslegen

<a id="k1"></a>

## 1. Das kann Tux-Wetter

**Wetter**
- aktuelles Wetter mit Temperatur, Wetterlage, Höchst- und Tiefstwert, gefühlter Temperatur
- Wind mit Richtungspfeil, Regenwahrscheinlichkeit, Luftfeuchtigkeit
- die nächsten 6 Stunden und 5 Tage Vorschau, je Tag mit Regen bzw. Neuschnee
- Klick auf einen Tag: Temperaturkurve über 24 Stunden
- in der Schweiz, in Österreich und in Deutschland die **gemessene** Temperatur der nächsten Wetterstation

**Infozeile**
- Sonnenauf- und -untergang, Mondphase, UV-Index, Luftqualität, Pollen
- Regen der nächsten 2 Stunden, z. B. „Regen: ab 14:15“

**Warnungen**
- vor Wind, Gewitter, Starkregen, Schnee, Glätte und Frost sowie Hitze
- amtlich von MeteoSchweiz, GeoSphere Austria und dem Deutschen Wetterdienst
- auf Wunsch als Desktop-Benachrichtigung, auch für weitere gespeicherte Orte

**Bedienung und Aussehen**
- mehrere Orte in einem Widget, Standort auf Wunsch automatisch
- 5 Wetteranbieter, 3 davon ohne Anmeldung
- Glas-Look, helle oder deckende Karte, 8 Farbschemen oder eigene Farben
- animierte Wettersymbole, Deutsch und Englisch
- läuft auch in einer Leiste am Bildschirmrand

---

<a id="k2"></a>

## 2. Voraussetzungen

> **Kurz gesagt:** KDE Plasma 6 und eine Internetverbindung. Administratorrechte sind nicht nötig.

| Was | Mindestens |
|---|---|
| KDE Plasma | Version 6 |
| Qt | Version 6.8 (kommt mit Plasma) |
| Internet | ja, die Wetterdaten kommen live |
| Konto | nicht nötig (für zwei der fünf Anbieter ein kostenloser Schlüssel, [Kapitel 11](#k11)) |

**Passt zum Beispiel auf:** Fedora 41 und neuer (auch Bazzite und Aurora), Arch Linux mit
EndeavourOS, CachyOS und Manjaro, openSUSE Tumbleweed, KDE neon, Kubuntu 25.04 und neuer, Debian 13.

**Passt nicht auf** Systeme mit Plasma 5, etwa Kubuntu 24.04 LTS oder Debian 12.

> **Hinweis:** Getestet wurde mit Plasma 6.7 und Qt 6.11 auf Bazzite (Fedora). Die übrigen Systeme
> erfüllen die Voraussetzungen, wurden aber nicht eigens geprüft.

Die eigenen Versionen zeigen diese Befehle im Terminal:

```bash
plasmashell --version
qtpaths6 --qt-version
```

---

<a id="k3"></a>

## 3. Installieren

> **Kurz gesagt:** Doppelklick auf `Tux-Wetter-installieren.sh` – das Programm erledigt den Rest.

### Am einfachsten: mit dem Installationsprogramm

1. `Veröffentlichung.zip` entpacken: Rechtsklick → **Entpacken** → **Hierher entpacken**.
2. Im Ordner **Veröffentlichung** doppelt auf `Tux-Wetter-installieren.sh` klicken und **Ausführen** wählen.
3. Die Fragen mit **Ja** beantworten. Der Desktop verschwindet kurz und kommt gleich wieder.
4. Auf Wunsch legt das Programm das Widget gleich oben rechts auf den Desktop.

Das Programm erkennt selbst, ob Tux-Wetter neu installiert, auf eine neue Version aktualisiert oder von
einer älteren Version mit anderer Kennung umgestellt werden muss. Beim Umstellen sichert es vorher die
Plasma-Einstellungen; Widgets, Position und Einstellungen bleiben.

> **Bietet Dolphin nur „Öffnen“ an?** Dann Rechtsklick auf `Tux-Wetter-installieren.sh` → **Eigenschaften** →
> **Berechtigungen** → **Ausführbar** anhaken. Oder im Terminal im Ordner: `bash Tux-Wetter-installieren.sh`

### Weg A: mit der Maus

1. Rechtsklick auf den Desktop → **Miniprogramme hinzufügen oder verwalten …**
2. Oben **Neue Miniprogramme holen …** → **Miniprogramm aus lokaler Datei installieren …**
3. Die Datei `Tux-Wetter_v1.6.plasmoid` auswählen.
4. In der Liste **Tux-Wetter** suchen und auf den Desktop ziehen.

> **Achtung:** Dieser Weg geht nur bei der **ersten** Installation. Ist Tux-Wetter schon installiert,
> meldet Plasma „… existiert schon“. Eine neue Version spielt man mit einem Befehl im Terminal ein
> ([Kapitel 14](#k14)). Das Widget dafür **nicht** vom Desktop löschen.

### Weg B: im Terminal

1. In **Dolphin** den Ordner mit `Tux-Wetter_v1.6.plasmoid` öffnen.
2. Rechtsklick auf eine freie Stelle → **Terminal hier öffnen**.
3. Eingeben:
   ```bash
   kpackagetool6 -t Plasma/Applet -i Tux-Wetter_v1.6.plasmoid
   systemctl --user restart plasma-plasmashell
   ```
4. Weiter wie bei Weg A, Schritt 4.

Der zweite Befehl lädt Plasma neu: Der Desktop verschwindet kurz und kommt gleich wieder, offene
Programme bleiben offen.

> **Tipp:** Klappt der Neustart nicht, stattdessen `kquitapp6 plasmashell; kstart plasmashell` eingeben.

---

<a id="k4"></a>

## 4. In zwei Minuten eingerichtet

> **Kurz gesagt:** Ort suchen, Treffer anklicken, OK.

1. Rechtsklick auf das Widget → **Tux-Wetter einrichten …**
2. Bei **Ort suchen** den Ort eingeben und **Suchen** klicken.
3. Den passenden Treffer anklicken.
4. Mit **OK** bestätigen.

Fertig. Die Daten kommen von **Open-Meteo**, dafür braucht es kein Konto.

> **Achtung:** Nicht ins Feld **Angezeigter Name** tippen, um den Ort zu ändern. Es ändert nur die
> Beschriftung; das Wetter kommt weiter vom bisherigen Ort.

**Die Suche ist grosszügig.** Sie findet auch:

| Eingabe | findet |
|---|---|
| Zuerich, Muenchen | Zürich, München (ae/oe/ue statt Umlauten) |
| Neuchâtel, Bolzano, New York | Namen in der Landessprache oder auf Englisch |
| 8400, 80331 | Postleitzahlen |
| Schondra (DE), Luzern, CH | mit Länderkürzel: nur Orte in diesem Land |

**Gleich ausprobieren:**
- Weitere Orte speichern und umschalten: [Kapitel 8](#k8)
- Farben und Glas-Effekt anpassen: [Kapitel 10](#k10)
- Englisch einstellen: [Kapitel 10](#k10), Abschnitt Anzeige

---

# Teil 2 · Benutzen

<a id="k5"></a>

## 5. Die Karte

> **Kurz gesagt:** Oben das Wetter jetzt, in der Mitte die nächsten Stunden und die Infozeile, unten
> fünf Tage Vorschau. Über fast allen Werten erscheint beim Darüberfahren ein Tooltip mit Einzelheiten.

```
┌──────────────────────────────────────────────────────────────────┐
│ [Symbol]  Luzern                                       ‹ 2/3 ›   │  ┐
│           17 °C   Wind 12 km/h ➚  Regen 20 %   Feuchte 81 %      │  │ Kopf
│              °F                    Überwiegend sonnig            │  │
│                                     gefühlt 15°   13° / 3°       │  ┘
│           ▲ Sturmböen bis 75 km/h · bis 18:00 · DWD              │    Warnband
│  09:00   10:00   11:00   12:00   13:00   14:00                   │  ┐
│  [Symbole der nächsten sechs Stunden]                            │  │ Stunden
│   14°     15°     17°     19°     21°     23°                    │  ┘
│ ↑07:12 ↓17:58 ◐ UV: 3 Luft: gut Pollen: keine    Regen: ab 14:15 │    Infozeile
│ ──────────────────────────────────────────────────────────────   │
│  Fr   [Symbol]  60% · 4 mm   3°  ════════════════        13°     │  ┐ Vorschau
│  Sa   [Symbol]  10%          4°     ════════════         10°     │  ┘
│                       ! Stand 20:25                              │    nur bei alten Daten
└──────────────────────────────────────────────────────────────────┘
```

### Kopf

| Anzeige | Bedeutung |
|---|---|
| Grosses Symbol | das aktuelle Wetter, animiert |
| Ortsname | frei wählbar; lange Namen werden kleiner und dann gekürzt |
| ‹ 2/3 › | nur mit mehreren Orten: der wievielte Ort gezeigt wird ([Kapitel 8](#k8)) |
| Grosse Zahl | die aktuelle Temperatur – gemessen oder aus der Vorhersage (siehe unten) |
| °C / °F | die gewählte Einheit ist hell; ein Klick schaltet um |
| Wind | in km/h, bei einer Windwarnung in der Warnfarbe |
| Pfeil neben dem Wind | wohin der Wind weht; woher er kommt, steht im Tooltip |
| Regen (Schirm) | höchste Regenwahrscheinlichkeit **für heute** |
| Feuchte (Tropfen) | Luftfeuchtigkeit **jetzt** |
| Wetterlage | in Worten, z. B. „Leichte Regenschauer“ |
| gefühlt 15° | wie warm es sich mit Wind und Luftfeuchtigkeit anfühlt |
| 13° / 3° | Höchst- und Tiefstwert für heute |

**Gemessen oder vorhergesagt?** In der Schweiz, in Österreich und in Deutschland zeigt die grosse
Zahl den Messwert der nächsten Wetterstation. Der Tooltip nennt Station, Uhrzeit und Entfernung,
z. B. „Gemessen um 13:00 an der Station Luzern (MeteoSchweiz), 2 km entfernt“, und zum Vergleich den
Wert der Vorhersage. Anderswo steht der Wert der Vorhersage.

### Warnband

Gilt eine Warnung, erscheint unter der Temperatur ein farbiges Band, z. B.
„Sturmböen bis 75 km/h · bis 18:00 · DWD“. Alles dazu in [Kapitel 7](#k7).

### Stunden und Tagesdetails

- Die Zeile zeigt die nächsten sechs Stunden (bei OpenWeatherMap in 3-Stunden-Schritten).
- **Klick auf einen Tag der Vorschau:** Statt der Stunden erscheint die Temperaturkurve dieses Tages
  über 24 Stunden, darüber alle 3 Stunden Uhrzeit, Symbol und Temperatur. Die Infozeile nennt den Tag.
- **Zurück:** den Tag nochmals anklicken oder eine Minute warten.

### Infozeile

| Anzeige | Bedeutung |
|---|---|
| ↑ 07:12 ↓ 17:58 | Sonnenauf- und -untergang |
| Mondscheibe | die Mondphase; im Tooltip Mondauf- und -untergang |
| UV: 3 | höchster UV-Index von heute |
| Luft: gut | Luftqualität |
| Pollen: keine | stärkste Pollenbelastung; die Arten stehen im Tooltip |
| Regen: ab 14:15 | Regen der nächsten 2 Stunden; die Mengen je Viertelstunde im Tooltip |

Der Regen kann lauten: „ab 14:15“, „bis 13:30“, „noch über 2 Std.“ oder „keiner bis 16:00“.
Die Stufen von UV, Luft und Pollen erklärt [Kapitel 12](#k12).

### Vorschau

| Anzeige | Bedeutung |
|---|---|
| Fr | der Wochentag |
| 60% · 4 mm | Regenwahrscheinlichkeit und Menge; bei Neuschnee z. B. „8 cm“ mit Flocke |
| 3° ═══ 13° | Tiefst- und Höchstwert; der Balken zeigt die Spanne (cyan = kühl, orange = warm) |

### Hinweis „Stand …“

Erscheint unten links nur, wenn die Daten nicht mehr aktuell sind ([Kapitel 15](#k15)).

### Quellenangabe

Unten rechts steht klein, woher die Daten kommen, z. B. „Daten: Open-Meteo.com“ oder „Datenbasis:
Deutscher Wetterdienst · Open-Meteo.com“. Die Wetterdienste verlangen diese Angabe. Ein Klick auf einen
Namen öffnet die Seite des Dienstes; beim Darüberfahren erscheinen alle Quellen mit ihren Lizenzen
([Kapitel 12](#k12)).

### Animationen

Die Sonne dreht und pulsiert, der Mond schimmert, bei klarer Nacht funkeln Sterne, Wolken ziehen,
Regen und Schnee fallen, Blitze zucken. Abschalten lässt sich das in den Einstellungen.

### Grösse ändern

1. Rechtsklick auf den Desktop → **Bearbeitungsmodus starten**
2. Am Rand des Widgets ziehen.

Die Karte behält ihre Form und sitzt mittig in der Fläche. Kleinste Grösse: 240 × 187 Pixel.

---

<a id="k6"></a>

## 6. Bedienen

> **Kurz gesagt:** Klicken schaltet um, Darüberfahren zeigt Einzelheiten, der Rechtsklick öffnet das Menü.

### Klicken

| Wo | Was passiert |
|---|---|
| **°C** oder **°F** | Einheit umschalten |
| Ortsname | Daten sofort neu laden |
| **‹** oder **›** | vorheriger bzw. nächster Ort ([Kapitel 8](#k8)) |
| Warndreieck neben ‹ › | den Ort mit der Warnung zeigen |
| Tag der Vorschau | Tagesdetails ein- und ausblenden |
| Warnband | amtliche Warnseite im Browser öffnen |

**Mausrad** über der Karte: durch die gespeicherten Orte blättern.

### Darüberfahren

| Wo | Was erscheint |
|---|---|
| Grosse Temperatur | gemessen oder vorhergesagt, mit Station |
| Windpfeil | woher der Wind kommt |
| Werte der Infozeile | Einzelheiten zu Sonne, Mond, UV, Luft, Pollen, Regen |
| Regen und Schnee der Vorschau | Wahrscheinlichkeit, Menge, Neuschnee |
| Warnband | alle Warnungen ausführlich |
| Höchst-/Tiefstwert | bei OpenWeatherMap: ab wann sie gelten ([Kapitel 11](#k11)) |
| „Stand …“ | warum die Daten nicht aktuell sind |

### Rechtsklick

| Eintrag | Wirkung |
|---|---|
| **Jetzt aktualisieren** | Daten sofort neu laden |
| **Nächster Ort** / **Vorheriger Ort** | Ort wechseln (nur mit Ortsliste) |
| **Tux-Wetter einrichten …** | Einstellungen öffnen |

---

<a id="k7"></a>

## 7. Wetterwarnungen

> **Kurz gesagt:** Ein farbiges Band warnt vor Wetter in den nächsten 24 Stunden. Die Farbe zeigt die
> Stufe, ein Klick öffnet die amtliche Warnseite.

### Die Stufen

| Farbe | Bedeutung | beim Wind (Böen ab) |
|---|---|---|
| Gelb | Wetterwarnung | Windböen, 50 km/h |
| Orange | markante Warnung | Sturmböen, 62 km/h |
| Rot | Unwetterwarnung | schwere Sturmböen, 89 km/h |
| Violett | extremes Unwetter | Orkanböen, 118 km/h |

### Die Warnarten

| Warnart | Woher | Beispiel im Band |
|---|---|---|
| Wind | überall aus der Vorhersage, dazu amtlich | „Sturmböen bis 75 km/h · bis 18:00 · DWD“ |
| Gewitter | amtlich | „Starkes Gewitter · heute 15:00–19:00 · DWD“ |
| Starkregen | amtlich | „Regen, Gefahrenstufe 3 · bis 22:00 · MeteoSchweiz“ |
| Schnee | amtlich | „Schneewarnung · heute 21:00–morgen 06:00 · GeoSphere“ |
| Glätte und Frost | amtlich | „Frost · heute 22:00–morgen 09:00 · DWD“ |
| Hitze | amtlich | „Hitzewarnung · bis 20:00 · GeoSphere“ |

**Amtlich** heisst: von den Wetterdiensten dieser Länder, also nur für Orte dort.

| Land | Wetterdienst |
|---|---|
| Schweiz und Liechtenstein | MeteoSchweiz, über MeteoAlarm (EUMETNET) |
| Österreich | GeoSphere Austria |
| Deutschland | Deutscher Wetterdienst (DWD) |

### So liest man das Band

- Es zeigt die **stärkste** Warnung; bei gleicher Stufe die frühere.
- „· +2“ am Ende: Es gibt zwei weitere – alle stehen im Tooltip.
- Bei einer Windwarnung färbt sich auch der Windwert.
- **Klick:** öffnet die Warnseite des Wetterdienstes im Browser.
- In der **Leiste** steht ein kleines Warndreieck in der Warnfarbe am Symbol.

### Windwarnung aus zwei Quellen

- **Vorhersage:** die höchste Böe der nächsten 24 Stunden – überall auf der Welt.
- **Amtlich:** hat Vorrang. Sagt die Vorhersage stärkere Böen voraus, nennt der Tooltip sie zusätzlich.
- MeteoSchweiz nennt die Böen nach Höhenlage, z. B. „oberhalb von 600 m 70–90 km/h“ – das steht im
  Tooltip. Die Gefahrenstufen 2 bis 5 von MeteoSchweiz erscheinen als Gelb bis Violett.

> **Hinweis:** Die amtlichen Wetterdienste warnen manchmal schon bei knapp unter 50 km/h, etwa weil sie
> Böen in höheren Lagen einrechnen.

### Benachrichtigung

Kommt eine Warnung ab der eingestellten Stufe neu dazu (Standard: **Orange**), erscheint eine
Desktop-Benachrichtigung, z. B. „Unwetterwarnung (rot): Glatteis“ mit Ort, Zeitraum und Wetterdienst.

- Jede Warnung kommt **nur einmal** – erneut nur, wenn sie stärker wird oder nach ihrem Ende eine neue kommt.
- Das gilt auch nach einem Neustart und für mehrere Widgets mit demselben Ort.
- Auf Wunsch auch für die anderen Orte der Ortsliste ([Kapitel 8](#k8)).

### Gut zu wissen

- Jede Warnart und jedes Land lässt sich in den Einstellungen einzeln abschalten ([Kapitel 10](#k10)).
- Das Land eines Orts prüft das Widget einmal; danach fragt es nur dessen Wetterdienst.
- Alle amtlichen Warnungen kommen aus offenen Daten: GeoSphere Austria und DWD über ihre offiziellen
  Schnittstellen, MeteoSchweiz über **MeteoAlarm**, das Warnportal der europäischen Wetterdienste
  (EUMETNET). Ändert sich eine Schnittstelle, warnt das Widget dort nur noch vor Wind aus der Vorhersage.
- Für die Schweiz lädt das Widget alle Schweizer Warnungen auf einmal (etwa 1 MB, höchstens alle
  20 Minuten) und prüft selbst anhand der Warngebiete, ob der Ort betroffen ist. So geht der Ort nicht
  hinaus.
- Titel und Text der Schweizer Warnungen erscheinen im Wortlaut von MeteoSchweiz, auf Englisch in der
  englischen Fassung. MeteoAlarm kennt nur Gelb, Orange und Rot; die höchste Schweizer Stufe 5 zeigt
  das Widget trotzdem violett an.

> **Wichtig:** Die Warnungen sind ein Hinweis und ersetzen keine offizielle Unwetterwarnung.

---

<a id="k8"></a>

## 8. Mehrere Orte und Standort

> **Kurz gesagt:** Orte in die Ortsliste aufnehmen und auf der Karte umschalten. Warnungen an den
> anderen Orten zeigt ein Warndreieck.

### Orte speichern

In den Einstellungen, Abschnitt **Ort**:

- **+** neben einem Suchtreffer nimmt den Ort in die Liste auf.
- **Angezeigten Ort hinzufügen** nimmt den gerade gezeigten Ort auf.
- In der **Ortsliste** ist der gezeigte Ort fett. Mit den Pfeilen sortieren, mit **–** entfernen.

### Umschalten

- Auf der Karte mit **‹** und **›** neben dem Ortsnamen,
- mit dem **Mausrad** über der Karte,
- oder per Rechtsklick → **Nächster Ort** / **Vorheriger Ort** (so auch in der Leiste).

### Warnungen der anderen Orte

- Für alle gespeicherten Orte holt das Widget die **amtlichen** Warnungen.
- Gilt eine, steht neben ‹ › ein **Warndreieck** in deren Farbe. Der Tooltip nennt Ort und Warnung,
  ein Klick zeigt den Ort.
- Auf Wunsch kommt auch eine Benachrichtigung, z. B. „Wetterwarnung (orange): Sturmböen – Bern:
  Sturmböen bis 70 km/h, bis 21:00 (MeteoSchweiz)“.

### Standort automatisch

Mit **Standort: Automatisch bestimmen** ermittelt das Widget den ungefähren Ort über die IP-Adresse,
höchstens alle 10 Minuten. Der Standort steht dann als erster Eintrag vor der Ortsliste.

> **Hinweis:** Die Ortung über die IP-Adresse ist ungenau. Sie liefert meist den Ort des
> Internetanbieters in der Nähe. Für genaue Werte den Ort lieber suchen.

> **Tipp:** Statt einer Ortsliste kann man Tux-Wetter auch mehrmals auf den Desktop legen – jedes
> Widget mit eigenem Ort.

---

<a id="k9"></a>

## 9. Tux-Wetter in der Leiste

> **Kurz gesagt:** Klein mit Symbol und Temperatur; ein Klick öffnet die ganze Karte.

1. Rechtsklick auf die Leiste → **Bedienelemente hinzufügen …**
2. **Tux-Wetter** in die Leiste ziehen.

**Darüberfahren** zeigt ein Infofenster mit:
- Ort, Wetterlage und Temperatur (mit „gemessen“ bzw. gefühlter Temperatur)
- Regen der nächsten 2 Stunden
- Warnungen, auch der anderen Orte der Ortsliste
- Uhrzeit der Daten, Wetterdienst und gegebenenfalls eine Fehlermeldung
- eine neue Version von Tux-Wetter, falls es eine gibt

Bei einer Warnung steht ein kleines Warndreieck in der Warnfarbe am Symbol (unten rechts). Gibt es eine
neue Version, zeigt ein grüner Kreis mit Pfeil nach oben unten links am Symbol darauf hin; ein Klick
öffnet die Karte mit dem Hinweis ([Kapitel 14](#k14)).

> **Hinweis:** Der Glas-Effekt wirkt in der Leiste nicht.

---

# Teil 3 · Einstellen

<a id="k10"></a>

## 10. Die Einstellungen

> **Kurz gesagt:** Rechtsklick auf das Widget → **Tux-Wetter einrichten …** öffnet die Einstellungen.
> Die Seite hat fünf Abschnitte; Änderungen mit **OK** oder **Anwenden** übernehmen.

### Ort

| Feld | Was es bewirkt |
|---|---|
| **Ort suchen** | weltweit suchen, Treffer anklicken ([Kapitel 4](#k4)) |
| **+** neben einem Treffer | Ort in die Ortsliste aufnehmen |
| **Angezeigter Name** | nur die Beschriftung auf der Karte, z. B. „Zuhause“ |
| **Koordinaten** | Lage des Orts, nur zur Anzeige |
| **Ortsliste** | gespeicherte Orte ([Kapitel 8](#k8)) |
| **Standort** | Ort automatisch über die IP-Adresse bestimmen |

### Wetterdaten

| Feld | Was es bewirkt |
|---|---|
| **Wetteranbieter** | Open-Meteo, MET Norway, Deutscher Wetterdienst (MOSMIX), OpenWeatherMap oder WeatherAPI.com ([Kapitel 11](#k11)) |
| **Wettermodell** | nur bei Open-Meteo: welches Vorhersagemodell |
| **API-Schlüssel** | nur bei OpenWeatherMap und WeatherAPI.com |
| **Aktualisieren alle** | 10 bis 180 Minuten |

> **Tipp:** Häufiger als alle 15 Minuten lohnt sich nicht: Die Wetterdienste erneuern ihre Daten
> selten öfter, die Vorhersagen sogar nur alle 1–3 Stunden.

### Anzeige

| Feld | Was es bewirkt |
|---|---|
| **Sprache** | Automatisch (Deutsch bei deutscher Systemsprache, sonst Englisch), Deutsch oder English |
| **Einheit** | Fahrenheit statt Celsius |
| **Animation** | Wettersymbole bewegen sich |
| **Zusätzlich zeigen** | je an/aus: gefühlte Temperatur · gemessene Temperatur · Infozeile · Regen der nächsten 2 Stunden · Luftqualität und Pollen |

### Warnungen

| Feld | Was es bewirkt |
|---|---|
| **Warnen vor** | jede Warnart einzeln an/aus |
| **Amtliche Warnungen** | jedes Land einzeln an/aus; Schweiz über MeteoAlarm |
| **Benachrichtigung** | an/aus und ab welcher Stufe (Gelb, Orange, Rot, Violett) |
| **auch für die anderen Orte der Ortsliste** | Benachrichtigung auch für die gespeicherten Orte |

### Aussehen

| Feld | Was es bewirkt |
|---|---|
| **Farbschema** | Violett (Standard), Blau, Petrol, Grün, Bordeaux, Sonnenuntergang, Graphit, Nacht oder Eigene Farben; darunter eine Vorschau |
| **Eigene Farben** | zwei Farben, oben links und unten rechts |
| **Helle Karte** | dunkle Schrift auf heller Karte, für helle Hintergrundbilder |
| **Glas-Effekt** | das Hintergrundbild scheint verschwommen durch |
| **Tönung Glas** | 0–100 %: wie stark die Farbe über dem Bild liegt |
| **Abdunklung Glas** | 0–60 %: dunkelt das Bild ab, damit die Schrift lesbar bleibt |
| **Deckkraft Hintergrund** | 20–100 %, nur ohne Glas-Effekt |

> **Tipp:** Bei zu hellen eigenen Farben warnt die Seite, weil weisse Schrift darauf schlecht lesbar
> ist. Der Glas-Effekt wirkt am schönsten mit einem Foto als Hintergrundbild.

### Sicherung

| Feld | Was es bewirkt |
|---|---|
| **In Datei sichern …** | schreibt alle Einstellungen in eine Datei, z. B. `Tux-Wetter-Einstellungen.json` |
| **Aus Datei laden …** | holt die Einstellungen aus so einer Datei |
| **API-Schlüssel mitsichern** | nimmt die API-Schlüssel in die Datei auf (standardmässig aus) |
| **Automatisch gesichert** | die Sicherungen, die das Widget selbst angelegt hat, mit Datum und Ort; **Laden** holt die gewählte |

Geladene Einstellungen gelten erst nach **OK** oder **Anwenden** – vorher lässt sich mit **Abbrechen**
alles verwerfen ([Kapitel 14](#k14)).

### Neue Versionen

| Feld | Was es bewirkt |
|---|---|
| **Update-Hinweis** | einmal am Tag bei GitHub nach einer neueren Version fragen und sie auf der Karte melden (Standard: an) |

Nach einem neuen Ort, Modell oder Anbieter lädt das Widget sofort neue Daten; bis dahin steht
„Lade Wetterdaten …“ auf der Karte.

---

<a id="k11"></a>

## 11. Den Wetteranbieter wählen

> **Kurz gesagt:** Open-Meteo ist voreingestellt und für die meisten am besten. MET Norway und der
> Deutsche Wetterdienst sind gute Alternativen ohne Anmeldung.

| | Open-Meteo | MET Norway | DWD (MOSMIX) | OpenWeatherMap | WeatherAPI.com |
|---|---|---|---|---|---|
| Anmeldung | nein | nein | nein | kostenloser Schlüssel | kostenloser Schlüssel |
| Stundenwerte | stündlich | stündlich, ab Tag 3 alle 6 Std. | stündlich | alle 3 Stunden | stündlich |
| Vorschau | 5 Tage | 5 Tage | 5 Tage | 4–5 Tage | 2 Tage (die ersten 14 Tage: 5) |
| Besonderheit | 6 Modelle wählbar | siehe unten | siehe unten | siehe unten | – |

### Open-Meteo: die Modelle

| Modell | Geeignet für |
|---|---|
| Automatisch | **empfohlen** – wählt das beste Modell für den Ort |
| MeteoSchweiz ICON-CH2 | Schweiz und Umgebung, sehr genau; 4–5 Tage |
| Deutscher Wetterdienst ICON | Mitteleuropa |
| ECMWF IFS | Europa und weltweit |
| NOAA GFS | weltweit |
| Météo-France | 3–4 Tage, ohne Regenwahrscheinlichkeit (zeigt 0 %) |

### MET Norway

Der Wetterdienst Norwegens (bekannt von yr.no), ohne Anmeldung, für Europa sehr gut.
Ausserhalb Skandinaviens fehlen Böen und Regenwahrscheinlichkeit:

- Auf der Karte steht „–%“, in der Vorschau nur die Regenmenge.
- Die Windwarnung aus der Vorhersage entfällt; amtliche Warnungen kommen weiterhin.

### Deutscher Wetterdienst (MOSMIX)

Die Stationsvorhersage des DWD: für über 5000 Orte weltweit, sehr dicht in Deutschland, Österreich und
der Schweiz. Das Widget nimmt die nächste Vorhersagestation; die Werte sind auf ihren Standort
abgestimmt und darum oft genauer als ein reines Wettermodell. Abgerufen werden die freien DWD-Daten
über **Bright Sky** (brightsky.dev), das sie als einfache Abfrage anbietet – ohne Anmeldung und ohne
Schlüssel. Zugangsdaten beim DWD, z. B. für die WarnWetter-App oder pc_met, braucht es dafür nicht.

- Liegt keine Station im Umkreis von 50 km, meldet das Widget das; dann einen anderen Anbieter wählen.
- Luftfeuchtigkeit und gefühlte Temperatur berechnet das Widget aus Taupunkt und Wind.
- Ausserhalb Europas fehlen bei manchen Stationen Regenwahrscheinlichkeit und Böen („–%“).
- Ein DWD-Modell gibt es auch bei Open-Meteo (**Deutscher Wetterdienst ICON**). Das ist das reine
  Rechenmodell; MOSMIX ist die daraus abgeleitete Vorhersage für die Station.

### OpenWeatherMap

Der kostenlose Zugang liefert keine Werte für den ganzen heutigen Tag. Das Widget merkt sich darum
die Höchst- und Tiefstwerte, die es im Lauf des Tages sieht. Wurde der Rechner erst später
eingeschaltet, sagt der Tooltip über 13° / 3° z. B. „Höchst/Tiefst heute erst ab 18 Uhr bekannt“.

### API-Schlüssel holen

**OpenWeatherMap**
1. Auf https://home.openweathermap.org/users/sign_up ein Konto anlegen.
2. Den Link in der Bestätigungsmail anklicken.
3. Unter **API keys** den Schlüssel kopieren.

> **Geduld:** Ein neuer Schlüssel funktioniert oft erst nach 10 Minuten bis 2 Stunden. Bis dahin
> meldet das Widget „ungültig oder noch nicht freigeschaltet“.

**WeatherAPI.com**
1. Auf https://www.weatherapi.com/signup.aspx ein Konto anlegen.
2. Im **Dashboard** den Schlüssel kopieren. Er funktioniert sofort.

Den Schlüssel in den Einstellungen bei **API-Schlüssel** einfügen und **OK** klicken. Jeder Anbieter
behält seinen eigenen Schlüssel, auch wenn man wechselt.

---

# Teil 4 · Hintergrund

<a id="k12"></a>

## 12. Woher die Daten kommen

> **Kurz gesagt:** Das Wetter kommt vom gewählten Anbieter, die Zusatzwerte immer von denselben
> kostenlosen Diensten.

| Wert | Quelle |
|---|---|
| Wetter und Vorhersage | der gewählte Anbieter (DWD über Bright Sky) |
| Regen der nächsten 2 Stunden, Luft, Pollen | Open-Meteo |
| UV-Index | der Anbieter, sonst Open-Meteo |
| Mond | MET Norway |
| gemessene Temperatur | MeteoSchweiz, GeoSphere Austria bzw. DWD (über Bright Sky) |
| Warnungen | MeteoSchweiz, GeoSphere Austria, DWD |
| Ortssuche | Open-Meteo |

**Lizenzen:** Die Daten von Open-Meteo, MET Norway, MeteoSchweiz, GeoSphere Austria und dem DWD stehen
unter **CC BY 4.0**, die von OpenWeather unter **CC BY-SA 4.0**. Die Ortsnamen der Suche stammen von
GeoNames (CC BY 4.0), die Ortsprüfung in der Schweiz von © swisstopo. Luft und Pollen enthalten veränderte
Informationen des Copernicus Atmosphere Monitoring Service; weder die Europäische Kommission noch das ECMWF
sind für ihre Verwendung verantwortlich. Das Widget bereitet die Daten auf: Es rechnet
Einheiten um, fasst Stundenwerte zu Tageswerten zusammen und berechnet z. B. die gefühlte Temperatur.
Darum steht beim DWD „Datenbasis“ statt „Quelle“. Alle Angaben mit Links stehen in den Einstellungen
unter **Datenquellen und Lizenz** und im Tooltip der Quellenangabe auf der Karte.

### Die Stufen der Zusatzwerte

| Wert | Stufen |
|---|---|
| UV-Index | 0–2 niedrig · 3–5 mässig · 6–7 hoch · 8–10 sehr hoch · ab 11 extrem |
| Luft | gut · recht gut · mässig · schlecht · sehr schlecht · extrem schlecht (Europäischer Luftqualitätsindex, weltweit) |
| Pollen | keine · gering · mässig · stark · sehr stark (Birke, Gräser, Erle, Beifuss, Ambrosia, Olive; nur Europa) |
| Regen | ab 0,1 mm in der Viertelstunde gilt es als Regen |

### Gemessene Temperatur

- Es gilt die **nächste** Station bis 25 km Entfernung und höchstens 300 m Höhenunterschied.
- Der Wert darf höchstens 75 Minuten alt sein, sonst gilt die Vorhersage.
- Liegt ein Ort im Gebiet mehrerer Länder (z. B. am Bodensee), gewinnt die nächste Station aller Messnetze.

### Im Hintergrund

- **Sofort Daten beim Anmelden:** Das Widget zeigt gleich die zuletzt bekannten Werte (höchstens
  einen Tag alt) samt Mond, Luft, Regen und gültigem Messwert, und holt frische, sobald das
  Internet bereit ist.
- **Ohne Netz:** neuer Versuch nach 3, 6, 12, 24 und 48 Sekunden, danach jede Minute.
- **Nie der falsche Ort:** Nach einem Wechsel verschwinden die alten Werte, bis die neuen da sind.
- **Richtige Uhrzeiten** auch über die Zeitumstellung; alle Zeiten sind Ortszeit.
- **Sparsam:** Mondzeiten einmal am Tag, Luft und Pollen höchstens stündlich, in der Schweiz nur
  die Messwerte der nächsten Station. Wer Strom sparen möchte, schaltet die Animationen aus.

---

<a id="k13"></a>

## 13. Datenschutz

> **Kurz gesagt:** Hinaus gehen nur die Koordinaten der Orte, und nur an die
> Wetterdienste, die die Daten liefern. Dazu fragt das Widget einmal am Tag bei GitHub nach einer
> neuen Version, ohne Ort. Alles Zusätzliche lässt sich abschalten.

| Wer | bekommt | wofür |
|---|---|---|
| der gewählte Wetteranbieter | Koordinaten | Wetter und Vorhersage |
| Open-Meteo | Koordinaten, bei der Suche den Suchbegriff | Regen, UV, Luft, Pollen, Ortssuche |
| MET Norway | Koordinaten | Mond |
| swisstopo | Koordinaten, einmal je Ort | prüfen, ob der Ort in der Schweiz liegt |
| MeteoAlarm | nichts (lädt alle Schweizer Warnungen) | Warnungen von MeteoSchweiz |
| GeoSphere Austria, DWD | Koordinaten | Warnungen (und Prüfung des Landes) |
| Bright Sky | Koordinaten | gemessene Temperatur in Deutschland; Vorhersage beim Anbieter DWD |
| GeoJS | nur die eigene IP-Adresse | nur mit **Standort: Automatisch bestimmen** |
| GitHub | keinen Ort, nur die übliche Anfrage (IP-Adresse), einmal am Tag | Hinweis auf neue Versionen; abschaltbar unter **Neue Versionen** |

- Für die gemessene Temperatur in der Schweiz und in Österreich lädt das Widget Stationsdaten
  herunter – dabei geht **kein** Ort hinaus.
- Die Warnungen der anderen Orte der Ortsliste werden wie beim angezeigten Ort abgefragt.
- Die **API-Schlüssel** speichert Plasma unverschlüsselt in der Einstellungsdatei ([Kapitel 14](#k14)),
  ebenso die automatische Sicherung des Widgets. Diese Dateien nicht weitergeben – und eine
  Sicherungsdatei mit **API-Schlüssel mitsichern** auch nicht.

---

<a id="k14"></a>

## 14. Sichern, aktualisieren, entfernen

> **Kurz gesagt:** Neue Versionen mit `kpackagetool6 -u` einspielen, nicht über das Menü. Die
> Einstellungen sichert das Widget selbst; für einen neuen Rechner in eine Datei sichern.

### Auf einen neuen Rechner: neu einrichten

Am einfachsten mit **In Datei sichern …** und **Aus Datei laden …** (siehe oben). Ohne Datei dauert
es etwa eine Minute. Vorher notieren:

| Einstellung | Wo zu finden |
|---|---|
| Orte | **Angezeigter Name** und **Ortsliste**; die Orte auf dem neuen System neu suchen |
| Wetterdienst | **Wetteranbieter** und **Wettermodell** |
| Anzeige und Warnungen | Abschnitte **Anzeige** und **Warnungen** |
| Aussehen | **Farbschema** (bei eigenen Farben die zwei Farben), **Helle Karte**, **Glas-Effekt** mit Tönung und Abdunklung bzw. **Deckkraft** |
| API-Schlüssel | im Benutzerkonto beim Anbieter |

> **Tipp:** API-Schlüssel in einem Passwortmanager aufbewahren. Sie lassen sich auch jederzeit beim
> Anbieter wieder abrufen: bei OpenWeatherMap unter **API keys**, bei WeatherAPI.com im **Dashboard**.

### Für Fortgeschrittene: den ganzen Desktop übertragen

Plasma speichert alle Widgets und Leisten in einer Datei:
`~/.config/plasma-org.kde.plasma.desktop-appletsrc`. Die Befehle in einem Terminal ausführen
(es bleibt offen, während Plasma kurz beendet ist):

1. Auf dem neuen System zuerst das Widget installieren ([Kapitel 3](#k3)).
2. Die dortige Datei sichern:
   ```bash
   cp ~/.config/plasma-org.kde.plasma.desktop-appletsrc ~/.config/plasma-org.kde.plasma.desktop-appletsrc.vorher
   ```
3. Plasma beenden – der Desktop verschwindet, das Terminal bleibt:
   ```bash
   systemctl --user stop plasma-plasmashell
   ```
4. Die Datei vom alten Rechner an dieselbe Stelle kopieren.
5. Plasma wieder starten:
   ```bash
   systemctl --user start plasma-plasmashell
   ```

So kommen alle Widgets samt Einstellungen und API-Schlüsseln mit – am besten zwischen ähnlichen
Rechnern mit gleicher Bildschirmanordnung.

> **Falls etwas schiefgeht:** Plasma beenden, die Datei `….vorher` zurückkopieren und Plasma wieder starten.

### Neue Version einspielen

Gibt es eine neue Version, meldet das Widget das selbst auf der Karte (ausser der Hinweis ist unter
**Neue Versionen** abgeschaltet). **Download-Seite öffnen** führt zur Seite bei GitHub; dort
`Veröffentlichung.zip` oder die einzelnen Dateien herunterladen. Das Widget lädt nichts selbst herunter.

Die Einstellungen bleiben erhalten. Am einfachsten: Doppelklick auf `Tux-Wetter-installieren.sh` aus dem Ordner der neuen
Version ([Kapitel 3](#k3)). Oder im Terminal im Ordner mit der neuen Datei (Weg B):

```bash
kpackagetool6 -t Plasma/Applet -u Tux-Wetter_v1.6.plasmoid
systemctl --user restart plasma-plasmashell
```

> **Achtung:** Über **Miniprogramm aus lokaler Datei installieren …** lässt sich eine neue Version
> nicht einspielen; Plasma meldet „… existiert schon“. Das Widget dann **nicht** vom Desktop löschen
> und keine Ordner umbenennen, sondern den Befehl oben nehmen.

### Umstieg von Version 1.4 oder älter (einmalig)

Seit 1.5 hat das Widget die Kennung `ch.tuxwetter`. Für Plasma ist es damit ein neues Widget, und der
Befehl oben findet die alte Fassung nicht. **Am einfachsten erledigt das `Tux-Wetter-installieren.sh`** ([Kapitel 3](#k3)).
Von Hand geht es so; diese Befehle tauschen die Kennung der vorhandenen Widgets aus;
Leiste, Position, Grösse und alle Einstellungen bleiben. Im Terminal im Ordner mit der neuen Datei:

```bash
kpackagetool6 -t Plasma/Applet -i Tux-Wetter_v1.6.plasmoid
cp ~/.config/plasma-org.kde.plasma.desktop-appletsrc ~/.config/plasma-org.kde.plasma.desktop-appletsrc.vor-1.5
systemctl --user stop plasma-plasmashell
sed -i -E 's/^plugin=ch\.[a-z]+\.tuxwetter$/plugin=ch.tuxwetter/' ~/.config/plasma-org.kde.plasma.desktop-appletsrc
systemctl --user start plasma-plasmashell
kpackagetool6 -t Plasma/Applet -r "$(kpackagetool6 -t Plasma/Applet -l | grep -xE 'ch\.[a-z]+\.tuxwetter' | grep -vx ch.tuxwetter)"
```

1. Die erste Zeile installiert die neue Version neben der alten.
2. Die zweite sichert die Plasma-Einstellungen in `….vor-1.5`.
3. Dann wird Plasma kurz beendet (der Desktop verschwindet, das Terminal bleibt offen), die Kennung
   ausgetauscht und Plasma wieder gestartet.
4. Die letzte Zeile entfernt die alte Fassung.

> **Falls etwas schiefgeht:** Plasma beenden, die Datei `….vor-1.5` zurück nach
> `~/.config/plasma-org.kde.plasma.desktop-appletsrc` kopieren und Plasma wieder starten.

Ohne Terminal geht es auch: Die neue Version über **Miniprogramm aus lokaler Datei installieren …**
einspielen, das neue Tux-Wetter auf den Desktop ziehen und neu einrichten, dann das alte entfernen.
Die Einstellungen müssen dabei neu eingegeben werden, weil Versionen vor 1.5 keine Sicherung anlegen.

### Einstellungen sichern und übernehmen

Wird das Widget vom Desktop entfernt, löscht Plasma seine Einstellungen. Tux-Wetter sichert sie darum
selbst, bei jeder Änderung:

- **Neues Widget:** Legt man später wieder ein Tux-Wetter auf den Desktop, erscheint auf der Karte
  **Frühere Einstellungen gefunden** mit Datum und Ort. **Übernehmen** stellt alles wieder her, auch
  Ortsliste, Farben und API-Schlüssel. **Nein, neu einrichten** fragt nicht mehr.
- **Später:** Einstellungen → **Sicherung** → **Automatisch gesichert** zeigt die letzten Sicherungen.
  Eine wählen, **Laden**, dann **OK**.
- **Anderer Rechner:** Einstellungen → **Sicherung** → **In Datei sichern …**; auf dem neuen Rechner
  **Aus Datei laden …** und **OK**. Ohne **API-Schlüssel mitsichern** bleiben die Schlüssel draussen;
  dann auf dem neuen Rechner neu eintragen.

> **Gut zu wissen:** Die automatische Sicherung beginnt mit Version 1.5 und liegt im Benutzerordner
> ([Wo was gespeichert wird](#k14)). Bei einer Neuinstallation des ganzen Systems ist sie weg – dafür
> die Sicherung in eine Datei nehmen und die Datei aufbewahren.

### Entfernen

- **Nur vom Desktop nehmen:** Rechtsklick auf das Widget → **Tux-Wetter entfernen**. Es bleibt
  installiert und lässt sich wieder hinzufügen.
- **Ganz entfernen**, im Terminal:

```bash
kpackagetool6 -t Plasma/Applet -r ch.tuxwetter
```

### Wo was gespeichert wird

| Was | Ort |
|---|---|
| das Widget | `~/.local/share/plasma/plasmoids/ch.tuxwetter/` |
| Einstellungen, API-Schlüssel, Ortsliste | `~/.config/plasma-org.kde.plasma.desktop-appletsrc` |
| zuletzt geholte Daten, gemeldete Warnungen, automatische Sicherung der Einstellungen | `~/.local/share/plasmashell/QML/OfflineStorage/` |

`~` steht für den eigenen Benutzerordner, z. B. `/home/anna`.

---

# Teil 5 · Hilfe

<a id="k15"></a>

## 15. Meldungen auf der Karte

> **Kurz gesagt:** Die meisten Meldungen lösen sich von selbst. Bei Schlüssel-Meldungen den
> API-Schlüssel prüfen.

| Meldung | Bedeutung | Was tun |
|---|---|---|
| Lade Wetterdaten … | Daten werden geholt | kurz warten |
| Keine Wetterdaten (keine Verbindung) | kein Internet, oder es ist nach dem Anmelden noch nicht bereit | nichts – das Widget versucht es selbst erneut |
| Bitte … einen API-Schlüssel … eintragen | der Anbieter braucht einen Schlüssel | Schlüssel eintragen ([Kapitel 11](#k11)) |
| API-Schlüssel … ungültig oder noch nicht freigeschaltet | falsch kopiert, E-Mail nicht bestätigt oder Schlüssel zu neu | Schlüssel prüfen; bei OpenWeatherMap bis zu 2 Stunden warten |
| … verweigert die Abfrage: … | z. B. Monatskontingent aufgebraucht oder Schlüssel gesperrt | Meldung lesen, eventuell Anbieter wechseln |
| Keine Wetterdaten (Fehler …) | Störung beim Wetterdienst | nichts – wird wiederholt; hält es an, Anbieter wechseln |
| Wetterdaten von … nicht lesbar | unerwartete Antwort des Dienstes | wie oben |
| Keine Vorhersagestation des DWD in der Nähe (bis 50 km) | beim Anbieter DWD liegt keine Station nahe genug | einen anderen Wetteranbieter wählen ([Kapitel 11](#k11)) |
| Das gewählte Wettermodell deckt diesen Ort nicht ab | z. B. MeteoSchweiz ICON-CH2 ausserhalb des Alpenraums | ein anderes Wettermodell wählen ([Kapitel 11](#k11)) |

### „Stand …“ unten auf der Karte

Erscheint, wenn die Daten älter als zwei Aktualisierungen sind oder die letzte Abfrage nicht
geklappt hat (dann mit „· keine aktuellen Daten“). Die Karte zeigt so lange die letzten Werte; die
Ursache steht im Tooltip. Bei Daten von einem früheren Tag steht das Datum dabei, z. B. „Stand 23.10. 20:25“.

---

<a id="k16"></a>

## 16. Häufige Fragen

**Das Widget erscheint nach der Installation nicht in der Liste.**
Plasma neu laden: `systemctl --user restart plasma-plasmashell`

**Nach dem Umstieg auf 1.5 gibt es Tux-Wetter zweimal in der Liste der Widgets.**
Die alte Fassung ist noch installiert. Der Umstieg in [Kapitel 14](#k14) entfernt sie mit der letzten Zeile.

**Beim Installieren einer neuen Version meldet Plasma „… existiert schon“.**
Über das Menü lässt sich eine neue Version nicht einspielen. Stattdessen im Terminal
`kpackagetool6 -t Plasma/Applet -u Tux-Wetter_v1.6.plasmoid` und danach `systemctl --user restart plasma-plasmashell`
([Kapitel 14](#k14)). Das Widget nicht vom Desktop löschen.

**Nach dem Löschen und neu Hinzufügen sind meine Einstellungen weg.**
Ab Version 1.5 bietet das neue Widget an, die Einstellungen zu übernehmen. Wurde das abgelehnt:
Einstellungen → **Sicherung** → **Automatisch gesichert** → **Laden** → **OK**.

**Beim Anmelden steht kurz „Stand … · keine aktuellen Daten“.**
Normal: Bis das Internet bereit ist, zeigt das Widget die letzten Werte. Nach wenigen Sekunden kommen frische.

**Die Temperatur weicht von anderen Wetter-Apps ab.**
Tux-Wetter zeigt in der Schweiz, in Österreich und in Deutschland den Messwert der nächsten Station,
viele Apps den Wert einer Vorhersage – oft 1–2 °C Unterschied. Wer den Vorhersagewert sehen möchte,
schaltet **Gemessene Temperatur** aus.

**Ich habe den Ort geändert, aber das Wetter stimmt nicht.**
Wahrscheinlich wurde nur der **Angezeigte Name** geändert. Den Ort bei **Ort suchen** suchen und den
Treffer anklicken.

**Kann ich mehrere Orte anzeigen?**
Ja: über die Ortsliste in einem Widget ([Kapitel 8](#k8)) oder mit mehreren Widgets.

**Der automatische Standort zeigt einen Nachbarort.**
Die Ortung über die IP-Adresse kennt meist nur den Ort des Internetanbieters. Den Ort lieber suchen.

**Wie stelle ich Englisch ein?**
Einstellungen → Abschnitt **Anzeige** → **Sprache** → **English**.

**Die Regenwahrscheinlichkeit zeigt 0 % oder „–%“.**
0 % stimmt bei trockenem Wetter; das Modell Météo-France liefert den Wert nie. „–%“ erscheint bei
MET Norway ausserhalb Skandinaviens und beim DWD bei manchen Stationen ausserhalb Europas.

**Gibt es beim DWD einen API-Schlüssel oder Zugangsdaten?**
Nein, das braucht es nicht: Die Vorhersagedaten des DWD sind frei. Zugänge wie für die
WarnWetter-App, pc_met oder FeWIS gelten nur für diese Angebote und lassen sich im Widget nicht nutzen.

**Die Vorschau zeigt weniger als fünf Tage.**
Manche Anbieter und Modelle reichen nicht so weit ([Kapitel 11](#k11)).

**Die Infozeile zeigt keine Pollen.**
Pollendaten gibt es nur für Europa; ausserhalb der Blütezeit steht „keine“.

**Der Glas-Effekt ist nicht zu sehen.**
Er wirkt nur direkt auf dem Desktop und am besten mit einem Foto als Hintergrundbild. Die
**Tönung Glas** nicht zu hoch stellen.

---

<a id="k17"></a>

## 17. Begriffe

| Begriff | Bedeutung |
|---|---|
| Widget / Miniprogramm | ein kleines Programm auf dem Desktop oder in einer Leiste |
| KDE Plasma | die Desktop-Oberfläche, auf der Tux-Wetter läuft |
| Qt | die Programmbibliothek unter Plasma; sie kommt mit Plasma |
| Leiste | die Kontrollleiste am Bildschirmrand, z. B. mit Startmenü und Uhr |
| Terminal | ein Fenster für Textbefehle, unter KDE meist *Konsole* |
| API-Schlüssel | persönlicher Zugangscode für einen Wetterdienst, ähnlich einem Passwort |
| Wettermodell | das Rechenverfahren hinter einer Vorhersage |
| Messstation | ein Messgerät eines Wetterdienstes; misst alle 10 Minuten |
| gefühlte Temperatur | wie warm oder kalt es sich wegen Wind und Feuchtigkeit anfühlt |
| UV-Index | Mass für die Sonnenstrahlung, die Sonnenbrand verursacht |
| Luftqualitätsindex | fasst Feinstaub, Ozon, Stickstoffdioxid und Schwefeldioxid in einer Zahl zusammen |
