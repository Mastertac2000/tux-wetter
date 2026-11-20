#!/usr/bin/env python3
"""Rendert Karte.qml offscreen mit Beispielwerten (wie in Wetter.png) zu einer PNG-Datei.
Aufruf: python3 vorschau.py ausgabe.png [breite] [höhe] [bilder]
Mit bilder > 1 entstehen ausgabe-1.png, ausgabe-2.png … im Abstand von 150 ms (für Animationen).
Ist die Umgebungsvariable HINTERGRUND auf ein Bild gesetzt, liegt die Karte darauf, mit Glas-Effekt.
Mit VERALTET=1 zeigt die Karte den Hinweis auf veraltete Daten.
Mit WARNUNG=1…4 zeigt die Karte eine Windwarnung dieser Stufe (1 = Windböen wie in Chemnitz),
mit WARNUNG_QUELLE=DWD, MeteoSchweiz oder GeoSphere als amtliche Warnung, sonst aus der Vorhersage.
Mit WARNART=gewitter, regen, schnee, glaette oder hitze ist es eine andere Warnart (nur amtlich sinnvoll),
mit WEITERE=2 kommen zwei schwächere Warnungen dazu (Band zeigt „· +2“, Tooltip alle).
Mit FARBE=petrol (oder FARBE=eigen FARBE1=#… FARBE2=#…) zeigt die Karte ein anderes Farbschema.
Mit HEUTE_AB=23 gelten Höchst/Tiefst wie bei OpenWeatherMap erst ab 23 Uhr.
Mit SPRACHE=en englisch; ORTE=3 zeigt den Ortsumschalter (2/3); TAG=1 öffnet die Tagesdetails des
zweiten Vorschautags; REGEN=jetzt|spaeter|kein wählt die Regenvorhersage; DETAILS=0 blendet die Infozeile
aus; POLLEN=0 wie ausserhalb Europas (ohne Pollen); HELL=1 helle Karte; MOND=0..359 Mondphase in Grad;
GEMESSEN=0 ohne Messstation (Modellwert); GELADEN=0 ohne Daten (mit FEHLER="Text" als Meldung);
FAHRENHEIT=1; NAME="langer Ortsname"; TEMP=-23.4 (aktuelle Temperatur, z. B. für dreistellige °F-Werte); ANDERE=1..4 Warnung dieser Stufe an einem anderen Ort der Ortsliste;
ANGEBOT=1 zeigt das Angebot, die Einstellungen eines früheren Widgets zu übernehmen;
ANBIETER=dwd|metno|openweathermap|weatherapi für die Quellenzeile unten rechts.
Achtung: offscreen rendert Qt ohne Grafikkarte und lässt Shader-Effekte (Glas-Unschärfe) einfach weg.
Dafür QT_QPA_PLATFORM=wayland setzen; dann erscheint kurz ein Fenster."""
import os, re, sys, pathlib, tempfile, shutil
os.environ.setdefault("QT_QPA_PLATFORM", "offscreen")
from PySide6.QtCore import QUrl, QTimer, qInstallMessageHandler
from PySide6.QtGui import QGuiApplication
from PySide6.QtQuick import QQuickView

UI = pathlib.Path(__file__).resolve().parent.parent / "package" / "contents"
tmp = pathlib.Path(tempfile.mkdtemp())
shutil.copytree(UI, tmp / "contents")
for name in ("Karte.qml", "WetterSymbol.qml"):
    datei = tmp / "contents/ui" / name
    q = re.sub(r"import org\.kde\.plasma[^\n]*\n", "", datei.read_text())
    q = q.replace("Plasmoid.configuration", "vorschauKonfig").replace("Plasmoid.containment", "vorschauContainment").replace("Kirigami.Theme.defaultFont.family", "'Noto Sans'").replace("PC3.Button", "QQC2.Button")
    datei.write_text(q)

breite = int(sys.argv[2]) if len(sys.argv) > 2 else 700
hoehe = int(sys.argv[3]) if len(sys.argv) > 3 else round(breite * 545 / 700)
bilder = int(sys.argv[4]) if len(sys.argv) > 4 else 1
bild = os.environ.get("HINTERGRUND", "")
glas = "true" if bild else "false"
veraltet = "true" if os.environ.get("VERALTET") == "1" else "false"
stufe = int(os.environ.get("WARNUNG", "0"))
titel, kmh = [None, ("Windböen", 60), ("Sturmböen", 75), ("Schwere Sturmböen", 95), ("Orkanböen", 125)][stufe] or ("", 0)
quelle = os.environ.get("WARNUNG_QUELLE", "")
von, bis = "Date.now() - 3600000", "Date.now() + 5 * 3600000"
if quelle == "MeteoSchweiz":
    # wie die Warnung vom 25.10.2026 für Winterthur: morgen 06:00–20:00, Böen nur im Zusatztext
    titel, kmh = f"Wind, Gefahrenstufe {stufe + 1}", 0
    von, bis = "new Date(Date.now() + 86400000).setHours(6, 0, 0, 0)", "new Date(Date.now() + 86400000).setHours(20, 0, 0, 0)"
art = os.environ.get("WARNART", "wind")
if art != "wind":
    titel, kmh = {"gewitter": ("Starkes Gewitter", 0), "regen": ("Dauerregen", 0), "schnee": ("Leichter Schneefall", 0),
                  "glaette": ("Glätte", 0), "hitze": ("Starke Hitze", 0)}[art]
    if quelle == "MeteoSchweiz":
        titel = {"gewitter": "Gewitter", "regen": "Regen", "schnee": "Schnee", "glaette": "Strassenglätte",
                 "hitze": "Hitze"}[art] + f", Gefahrenstufe {stufe + 1}"
liste = [f'{{ typ: "{art}", stufe: {stufe}, titel: "{titel}", kmh: {kmh}, von: {von}, bis: {bis},'
         f' quelle: "{quelle or "Vorhersage"}", amtlich: {"true" if quelle else "false"} }}'] if stufe else []
for i in range(int(os.environ.get("WEITERE", "0")) if stufe else 0):
    liste.append(f'{{ typ: "{["regen", "glaette", "schnee"][i % 3]}", stufe: 1, titel: "{["Dauerregen", "Frost", "Schneefall"][i % 3]}",'
                 f' kmh: 0, von: Date.now() + 7200000, bis: Date.now() + 9 * 3600000, quelle: "{quelle or "DWD"}", amtlich: true }}')
warnungen = "[" + ", ".join(liste) + "]"
sprache = os.environ.get("SPRACHE", "de")
messung = "null" if os.environ.get("GEMESSEN") == "0" else \
    '({temp: ' + os.environ.get("TEMP", "16.1") + ', station: "Luzern", km: 1.2, zeit: Date.now() - 600000, quelle: "MeteoSchweiz"})'
orte = int(os.environ.get("ORTE", "1"))
regenArt = os.environ.get("REGEN", "spaeter")
regenMm = {"jetzt": [0.8, 1.6, 0.6, 0.2, 0, 0, 0, 0], "kein": [0] * 8}.get(regenArt, [0, 0, 0, 0, 0, 0.3, 1.2, 2.4])
regen = "[" + ", ".join(f"{{zeit: Math.floor(Date.now() / 900000) * 900000 + {i} * 900000, mm: {m}}}" for i, m in enumerate(regenMm)) + "]"
details = "false" if os.environ.get("DETAILS") == "0" else "true"
pollen = "null" if os.environ.get("POLLEN") == "0" else '[{name: "Gräser", wert: 32, stufe: 2}, {name: "Birke", wert: 3, stufe: 1}]'
(tmp / "contents/ui/Vorschau.qml").write_text(f"""
import QtQuick
import "sprache.js" as T
Rectangle {{
    width: {breite} + 80; height: {hoehe} + 60
    color: "#0E0B1E"
    Image {{
        id: hintergrundBild
        anchors.fill: parent
        source: "{QUrl.fromLocalFile(bild).toString() if bild else ""}"
        fillMode: Image.PreserveAspectCrop
    }}
    QtObject {{
        id: vorschauContainment
        property var wallpaperGraphicsObject: {glas} ? hintergrundBild : null
    }}
    QtObject {{
        id: vorschauKonfig
        property string locationName: "{os.environ.get('NAME', 'Luzern')}"; property bool useFahrenheit: {"true" if os.environ.get("FAHRENHEIT") == "1" else "false"}
        property int backgroundOpacity: 94; property bool animations: true
        property string colorScheme: "{os.environ.get('FARBE', 'violett')}"; property string customColorStart: "{os.environ.get('FARBE1', '#2B2763')}"; property string customColorEnd: "{os.environ.get('FARBE2', '#5A3AD4')}"
        property bool glassEffect: {glas}; property int glassTint: 45; property int glassDarken: 18
        property bool showDetails: {details}; property bool feelsLike: true; property bool rainNowcast: true
        property bool lightCard: {"true" if os.environ.get("HELL") == "1" else "false"}
    }}
    QtObject {{
        id: w
        property bool geladen: {"false" if os.environ.get("GELADEN") == "0" else "true"}
        property string fehler: "{os.environ.get('FEHLER', '')}"
        property bool fahrenheit: {"true" if os.environ.get("FAHRENHEIT") == "1" else "false"}
        property real temperatur: {os.environ.get('TEMP', '17.2')}
        property int code: 1
        property bool tag: true
        property real wind: 42
        property string sprache: "{sprache}"
        function t(text) {{ return T.t.apply(null, [sprache].concat(Array.prototype.slice.call(arguments))) }}
        property var gefuehlt: 15.4
        property var windRichtung: 225
        property string sonnenAuf: "07:12"
        property string sonnenUnter: "17:58"
        readonly property string sonneAuf: sonnenAuf
        readonly property string sonneUnter: sonnenUnter
        property var mond: ({{ auf: "16:37", unter: "06:04", phase: {os.environ.get("MOND", "130")} }})
        property var messung: {messung}
        readonly property bool gemessen: messung !== null
        readonly property real anzeigeTemp: gemessen ? messung.temp : temperatur
        property var uv: 3
        property var regen: {regen}
        property var luft: ({{ eaqi: 24, pollen: {pollen} }})
        property var ortsListe: Array({orte})
        property int ortsIndex: {orte} > 1 ? 1 : -1
        readonly property bool mehrereOrte: {orte} > 1
        property var angebot: {'({stand: Date.now() - 2 * 86400000, einstellungen: {locationName: "Winterthur", places: JSON.stringify([1, 2, 3])}})' if os.environ.get("ANGEBOT") == "1" else "null"}
        property string anbieter: "{os.environ.get('ANBIETER', 'openmeteo')}"
        function angebotAnnehmen() {{}}
        function angebotAblehnen() {{}}
        function ortWechseln(s) {{}}
        function ortZeigen(o) {{}}
        property var andereWarnungen: {('[{ort: {name: "Bern", lat: 46.9, lon: 7.4}, liste: [{typ: "gewitter", stufe: ' + os.environ.get("ANDERE") + ', titel: "Gewitter, Gefahrenstufe 3", kmh: 0, von: Date.now(), bis: Date.now() + 7200000, quelle: "MeteoSchweiz", amtlich: true}]}]') if os.environ.get("ANDERE") else "[]"}
        property int niederschlag: 20
        property int feuchte: 100
        property real heuteMax: 23
        property real heuteMin: 11
        property int heuteAb: {os.environ.get('HEUTE_AB', '0')}
        property var stunden: [
            {{zeit:"09:00",temp:14,code:2,tag:true}},{{zeit:"10:00",temp:15,code:2,tag:true}},
            {{zeit:"11:00",temp:17,code:0,tag:true}},{{zeit:"12:00",temp:19,code:0,tag:true}},
            {{zeit:"13:00",temp:21,code:80,tag:true}},{{zeit:"14:00",temp:23,code:81,tag:true}}]
        property var tage: [
            {{name:"Do",datum:"2026-10-29",code:80,min:10,max:19,regen:60,menge:4.2,schnee:null,stunden:[{{zeit:"06:00",temp:10,code:3,tag:false}},{{zeit:"09:00",temp:12,code:80,tag:true}},{{zeit:"12:00",temp:17,code:81,tag:true}},{{zeit:"15:00",temp:19,code:2,tag:true}},{{zeit:"18:00",temp:15,code:1,tag:false}},{{zeit:"21:00",temp:12,code:0,tag:false}}],verlauf:[{{h: 0, temp: 10}}, {{h: 1, temp: 10}}, {{h: 2, temp: 10}}, {{h: 3, temp: 10}}, {{h: 4, temp: 10}}, {{h: 5, temp: 10}}, {{h: 6, temp: 10.9}}, {{h: 7, temp: 11.8}}, {{h: 8, temp: 12.7}}, {{h: 9, temp: 13.6}}, {{h: 10, temp: 14.5}}, {{h: 11, temp: 15.4}}, {{h: 12, temp: 16.3}}, {{h: 13, temp: 17.2}}, {{h: 14, temp: 18.1}}, {{h: 15, temp: 19.0}}, {{h: 16, temp: 18.1}}, {{h: 17, temp: 17.2}}, {{h: 18, temp: 16.3}}, {{h: 19, temp: 15.4}}, {{h: 20, temp: 14.5}}, {{h: 21, temp: 13.6}}, {{h: 22, temp: 12.7}}, {{h: 23, temp: 11.8}}]}},
            {{name:"Fr",datum:"2026-10-30",code:63,min:9,max:15,regen:90,menge:12.5,schnee:null,stunden:[{{zeit:"06:00",temp:9,code:61,tag:false}},{{zeit:"09:00",temp:10,code:63,tag:true}},{{zeit:"12:00",temp:13,code:63,tag:true}},{{zeit:"15:00",temp:15,code:61,tag:true}},{{zeit:"18:00",temp:12,code:3,tag:false}},{{zeit:"21:00",temp:10,code:3,tag:false}}],verlauf:[{{h: 0, temp: 9}}, {{h: 1, temp: 9}}, {{h: 2, temp: 9}}, {{h: 3, temp: 9}}, {{h: 4, temp: 9}}, {{h: 5, temp: 9}}, {{h: 6, temp: 9.6}}, {{h: 7, temp: 10.2}}, {{h: 8, temp: 10.8}}, {{h: 9, temp: 11.4}}, {{h: 10, temp: 12.0}}, {{h: 11, temp: 12.6}}, {{h: 12, temp: 13.2}}, {{h: 13, temp: 13.8}}, {{h: 14, temp: 14.4}}, {{h: 15, temp: 15.0}}, {{h: 16, temp: 14.4}}, {{h: 17, temp: 13.8}}, {{h: 18, temp: 13.2}}, {{h: 19, temp: 12.6}}, {{h: 20, temp: 12.0}}, {{h: 21, temp: 11.4}}, {{h: 22, temp: 10.8}}, {{h: 23, temp: 10.2}}]}},
            {{name:"Sa",datum:"2026-10-31",code:73,min:-1,max:3,regen:70,menge:6,schnee:7.5,stunden:[],verlauf:[{{h: 0, temp: -1}}, {{h: 1, temp: -1}}, {{h: 2, temp: -1}}, {{h: 3, temp: -1}}, {{h: 4, temp: -1}}, {{h: 5, temp: -1}}, {{h: 6, temp: -0.6}}, {{h: 7, temp: -0.2}}, {{h: 8, temp: 0.2}}, {{h: 9, temp: 0.6}}, {{h: 10, temp: 1.0}}, {{h: 11, temp: 1.4}}, {{h: 12, temp: 1.8}}, {{h: 13, temp: 2.2}}, {{h: 14, temp: 2.6}}, {{h: 15, temp: 3.0}}, {{h: 16, temp: 2.6}}, {{h: 17, temp: 2.2}}, {{h: 18, temp: 1.8}}, {{h: 19, temp: 1.4}}, {{h: 20, temp: 1.0}}, {{h: 21, temp: 0.6}}, {{h: 22, temp: 0.2}}, {{h: 23, temp: -0.2}}]}},
            {{name:"So",datum:"2026-11-01",code:2,min:7,max:17,regen:10,menge:0,schnee:null,stunden:[],verlauf:[{{h: 0, temp: 7}}, {{h: 1, temp: 7}}, {{h: 2, temp: 7}}, {{h: 3, temp: 7}}, {{h: 4, temp: 7}}, {{h: 5, temp: 7}}, {{h: 6, temp: 8.0}}, {{h: 7, temp: 9.0}}, {{h: 8, temp: 10.0}}, {{h: 9, temp: 11.0}}, {{h: 10, temp: 12.0}}, {{h: 11, temp: 13.0}}, {{h: 12, temp: 14.0}}, {{h: 13, temp: 15.0}}, {{h: 14, temp: 16.0}}, {{h: 15, temp: 17.0}}, {{h: 16, temp: 16.0}}, {{h: 17, temp: 15.0}}, {{h: 18, temp: 14.0}}, {{h: 19, temp: 13.0}}, {{h: 20, temp: 12.0}}, {{h: 21, temp: 11.0}}, {{h: 22, temp: 10.0}}, {{h: 23, temp: 9.0}}]}},
            {{name:"Mo",datum:"2026-11-02",code:0,min:9,max:20,regen:5,menge:0.3,schnee:null,stunden:[],verlauf:[{{h: 0, temp: 9}}, {{h: 1, temp: 9}}, {{h: 2, temp: 9}}, {{h: 3, temp: 9}}, {{h: 4, temp: 9}}, {{h: 5, temp: 9}}, {{h: 6, temp: 10.1}}, {{h: 7, temp: 11.2}}, {{h: 8, temp: 12.3}}, {{h: 9, temp: 13.4}}, {{h: 10, temp: 14.5}}, {{h: 11, temp: 15.6}}, {{h: 12, temp: 16.7}}, {{h: 13, temp: 17.8}}, {{h: 14, temp: 18.9}}, {{h: 15, temp: 20.0}}, {{h: 16, temp: 18.9}}, {{h: 17, temp: 17.8}}, {{h: 18, temp: 16.7}}, {{h: 19, temp: 15.6}}, {{h: 20, temp: 14.5}}, {{h: 21, temp: 13.4}}, {{h: 22, temp: 12.3}}, {{h: 23, temp: 11.2}}]}}]
        property real bereichMin: -1
        property real bereichMax: 20
        function grad(c) {{ return Math.round(fahrenheit ? c * 9 / 5 + 32 : c) }}
        function aktualisieren() {{}}
        function standText() {{ return Qt.formatTime(stand, "HH:mm") }}
        property real animationsZeit: 0
        property bool veraltet: {veraltet}
        property date stand: new Date(Date.now() - 3 * 3600000)
        property double jetzt: Date.now()
        property var warnungen: {warnungen}
        readonly property var warnung: warnungen.length ? warnungen[0] : null
        readonly property var windWarnung: warnungen.find(x => x.typ === "wind") || null
    }}
    Timer {{
        interval: 40; repeat: true; running: true
        onTriggered: w.animationsZeit += 0.04
    }}
    Karte {{ x: 40; y: 30; width: {breite}; height: {hoehe}; wetter: w; gewaehlterTag: {os.environ.get("TAG", "-1")} }}
}}
""")
# QML-Laufzeitwarnungen (z.B. "Unable to assign [undefined]") ausgeben, nicht nur Ladefehler
qInstallMessageHandler(lambda art, ort, text: print(text) if ".qml" in text or ".js" in text else None)
app = QGuiApplication(sys.argv)
v = QQuickView()
v.statusChanged.connect(lambda s: [print(e.toString()) for e in v.errors()])
v.setSource(QUrl.fromLocalFile(str(tmp / "contents/ui/Vorschau.qml")))
for e in v.errors(): print(e.toString())
v.show()
aufnahmen = []
def aufnehmen():
    aufnahmen.append(v.grabWindow())
    if len(aufnahmen) < bilder:
        QTimer.singleShot(150, aufnehmen)
        return
    if bilder == 1:
        aufnahmen[0].save(sys.argv[1])
    else:
        stamm = sys.argv[1].removesuffix(".png")
        for i, bild in enumerate(aufnahmen, 1):
            bild.save(f"{stamm}-{i}.png")
    app.quit()
QTimer.singleShot(1500, aufnehmen)
app.exec()
