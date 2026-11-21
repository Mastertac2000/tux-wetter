// SPDX-FileCopyrightText: 2026 R.Bruns
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Layouts
import QtQuick.LocalStorage as Speicher
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.notification
import "wetter.js" as W
import "anbieter.js" as A
import "warnung.js" as Wa
import "zusatz.js" as Z
import "sprache.js" as T
import "orte.js" as O
import "messung.js" as M
import "sicherung.js" as S

PlasmoidItem {
    id: root

    readonly property real breite: Plasmoid.configuration.latitude
    readonly property real laenge: Plasmoid.configuration.longitude
    readonly property bool fahrenheit: Plasmoid.configuration.useFahrenheit
    // Anzeigesprache: "de" oder "en" (Einstellung, sonst nach der Systemsprache)
    readonly property string sprache: T.aufloesen(Plasmoid.configuration.language, Qt.locale().name)

    // Text in der Anzeigesprache; t("Regen ab %1", "14:15")
    function t(text) {
        return T.t.apply(null, [sprache].concat(Array.prototype.slice.call(arguments)))
    }

    // Wetterdaten (immer in °C und km/h gespeichert)
    property bool geladen: false
    property string fehler: ""
    property date stand
    property real temperatur: 0
    property int code: 0
    property bool tag: true
    property real wind: 0
    property var gefuehlt: null      // gefühlte Temperatur in °C (null = unbekannt)
    property var windRichtung: null  // woher der Wind kommt, in Grad
    property string sonnenAuf: ""
    property string sonnenUnter: ""
    property var uvAnbieter: null    // UV-Index vom Wetteranbieter, sonst aus den Zusatzdaten
    property var boeen: []         // Böen der nächsten 24 Stunden: [{ zeit, kmh }]

    // Zusatzdaten von Open-Meteo (für alle Anbieter): Regen der nächsten 2 Stunden, UV, Luft und Pollen
    property var regen: []           // [{ zeit, mm }] je Viertelstunde
    property var uvZusatz: null
    property var luft: null          // { eaqi, pollen } oder null
    property var mond: null          // { auf, unter, phase } von MET Norway
    property var ortZusatz: null     // { versatz, hoehe, datum, sonnenAuf, sonnenUnter } von Open-Meteo
    property var messung: null       // gemessene Temperatur der nächsten Station (siehe messung.js)
    readonly property var uv: uvAnbieter !== null ? uvAnbieter : uvZusatz
    // Angezeigte Temperatur: gemessen, wenn eingeschaltet und eine passende Station da ist, sonst das Modell
    readonly property bool gemessen: Plasmoid.configuration.measuredTemp && messung !== null
    readonly property real anzeigeTemp: gemessen ? messung.temp : temperatur
    // Sonnenzeiten vom Anbieter, sonst aus den Zusatzdaten
    readonly property string sonneAuf: sonnenAuf || (ortZusatz ? ortZusatz.sonnenAuf : "")
    readonly property string sonneUnter: sonnenUnter || (ortZusatz ? ortZusatz.sonnenUnter : "")
    property var amtlicheWarnungen: []  // amtliche Wetterwarnungen (nur Orte in CH, AT, DE)

    // Eingeschaltete Warnarten, z. B. { wind: true, gewitter: false, … }
    readonly property var warnartenAn: {
        const k = Plasmoid.configuration, an = {}
        for (const t of Wa.TYPEN)
            an[t.typ] = !!k[t.schalter]
        return an
    }
    // Alle Warnungen (je Warnart eine, die stärkste zuerst) aus amtlichen Warnungen und Vorhersage
    readonly property var warnungen: geladen
        ? Wa.alle(amtlicheWarnungen.filter(w => w.bis > jetzt),
                  Wa.ausVorhersage(boeen.filter(b => b.zeit >= jetzt - 3600000)), typ => warnartenAn[typ])
        : []
    readonly property var warnung: warnungen.length ? warnungen[0] : null      // die wichtigste, für die Karte
    readonly property var windWarnung: warnungen.find(w => w.typ === "wind") || null
    property int niederschlag: 0   // höchste Regenwahrscheinlichkeit heute in %
    property int feuchte: 0        // relative Luftfeuchtigkeit jetzt in %
    property real heuteMax: 0
    property real heuteMin: 0
    property string heuteDatum: ""
    property int heuteAb: 0        // Stunde, ab der heuteMax/heuteMin gelten (0 = ganzer Tag)
    property var stunden: []   // { zeit, temp, code, tag }
    property var tage: []      // { name, code, min, max }
    property real bereichMin: 0
    property real bereichMax: 1

    // Gemeinsamer Animationstakt aller Wettersymbole in Sekunden. 25 Bilder pro Sekunde reichen
    // für die langsamen Bewegungen; mit der Bildrate des Monitors müsste plasmashell den ganzen
    // Desktop viel öfter neu zeichnen.
    readonly property double animationsStart: Date.now()
    property real animationsZeit: 0

    function grad(celsius) {
        return Math.round(fahrenheit ? celsius * 9 / 5 + 32 : celsius)
    }

    // Zeitpunkt der Daten: nur die Uhrzeit, bei Daten von einem früheren Tag mit Datum
    function standText() {
        return stand.toDateString() === new Date(jetzt).toDateString()
               ? Qt.formatTime(stand, "HH:mm") : Qt.formatDateTime(stand, "dd.MM. HH:mm")
    }

    readonly property string anbieter: Plasmoid.configuration.provider
    readonly property string modell: Plasmoid.configuration.weatherModel
    readonly property string schluessel: anbieter === "openweathermap" ? Plasmoid.configuration.owmApiKey.trim()
                                       : anbieter === "weatherapi" ? Plasmoid.configuration.weatherApiKey.trim() : ""
    // ── Mehrere Orte: Liste aus den Einstellungen, auf Wunsch mit dem automatisch bestimmten Standort ──
    readonly property var orte: O.liste(Plasmoid.configuration.places)
    readonly property bool standortAn: Plasmoid.configuration.autoLocation
    // Standort (falls an) zuerst, dann die gespeicherten Orte
    readonly property var ortsListe: (standortAn ? [{ auto: true }] : []).concat(orte)
    // Welcher Eintrag gerade gezeigt wird; -1 = ein Ort, der nicht in der Liste steht
    readonly property int ortsIndex: O.index(orte, standortAn, Plasmoid.configuration.autoActive, breite, laenge)
    // Lässt sich umschalten? (mindestens ein anderer Ort als der gezeigte)
    readonly property bool mehrereOrte: ortsListe.length > 1 || (ortsListe.length === 1 && ortsIndex < 0)

    function ortWechseln(schritt) {
        const o = O.naechster(ortsListe, ortsIndex, schritt), k = Plasmoid.configuration
        if (!o)
            return
        if (o.auto) {
            k.autoActive = true
            // Den zuletzt bestimmten Standort gleich zeigen; die Bestimmung läuft danach neu
            try {
                const s = JSON.parse(k.autoPlace || "{}")
                if (isFinite(s.lat) && isFinite(s.lon))
                    ortSetzen(s.name, s.lat, s.lon)
            } catch (e) {}
            standortZeit = 0
            ortGeaendert.restart()
        } else {
            k.autoActive = false
            ortSetzen(o.name, o.lat, o.lon)
        }
    }

    function ortSetzen(name, b, l) {
        const k = Plasmoid.configuration
        k.locationName = name
        k.latitude = b
        k.longitude = l
    }

    // ── Standort über die IP-Adresse (GeoJS), höchstens alle 10 Minuten ──
    property double standortZeit: 0
    function standortBestimmen(dann) {
        const xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return
            const k = Plasmoid.configuration
            try {
                if (xhr.status !== 200)
                    throw new Error("Status " + xhr.status)
                const s = O.ausGeoJs(JSON.parse(xhr.responseText), t("Aktueller Standort"))
                if (!s)
                    throw new Error("keine Koordinaten")
                standortZeit = Date.now()
                k.autoPlace = JSON.stringify(s)
                // Kleine Schwankungen der Ortung (unter 2 km) nicht als Ortswechsel werten
                if (k.autoLocation && k.autoActive && (O.km(breite, laenge, s.lat, s.lon) >= 2 || s.name !== k.locationName))
                    ortSetzen(s.name, s.lat, s.lon)
            } catch (e) {
                console.warn("Tux-Wetter: Standort nicht bestimmbar:", e)
            }
            dann()
        }
        xhr.open("GET", "https://get.geojs.io/v1/ip/geo.json")
        xhr.send()
    }

    // Zählt die Abfragen, damit eine verspätete Antwort keine neuere überschreibt
    property int abfrageNr: 0
    // Fehlgeschlagene Abfragen in Folge; bestimmt die Wartezeit bis zum nächsten Versuch
    property int fehlversuche: 0

    // Die Anbieter erneuern ihre Daten höchstens alle 15 Minuten; öfter abzufragen bringt nichts
    readonly property int intervallMinuten: Math.max(10, Plasmoid.configuration.updateInterval)
    // Uhr für den Hinweis auf veraltete Daten
    property double jetzt: Date.now()
    // Daten älter als zwei Aktualisierungen oder letzte Abfrage gescheitert
    readonly property bool veraltet: geladen && (fehler !== "" || jetzt - stand.getTime() > 2 * intervallMinuten * 60000)

    // ── Zwischenspeicher: die letzten Daten erscheinen beim Start sofort, bis frische da sind ──
    // Beim Anmelden ist das Netz oft erst einige Sekunden nach Plasma bereit.
    // Anbieter, Modell und Ort als Schlüssel. Direkt aus den Einstellungen gebildet: In den
    // on…Changed-Reaktionen wären abgeleitete Eigenschaften wie breite noch nicht nachgeführt.
    function schluesselJetzt() {
        const k = Plasmoid.configuration
        return [k.provider, k.weatherModel, k.latitude, k.longitude].join("|")
    }
    // Für welchen Anbieter, welches Modell und welchen Ort die angezeigten Daten gelten
    property string datenSchluessel: ""
    // Erst nach dem Start auf geänderte Einstellungen reagieren; beim Laden melden sie sich auch
    property bool bereit: false

    // ── Sicherung der Einstellungen (siehe sicherung.js) ──
    // Plasma löscht die Einstellungen mit dem Widget. Darum liegen sie zusätzlich im Speicher des Widgets,
    // je Widget die letzte Fassung. Ein neu hinzugefügtes Widget bietet die neueste Sicherung eines
    // anderen Widgets zur Übernahme an: angebot = { stand, einstellungen } oder null.
    property var angebot: null

    function sicherungTabelle(tx) {
        tx.executeSql("CREATE TABLE IF NOT EXISTS einstellungen (widget TEXT PRIMARY KEY, stand REAL, inhalt TEXT)")
    }

    function einstellungenSichern() {
        const k = Plasmoid.configuration
        if (!S.eingerichtet(n => k[n]))
            return
        // Wer selbst etwas einstellt, braucht das Angebot nicht mehr
        if (angebot !== null || !k.restoreChecked) {
            angebot = null
            k.restoreChecked = true
        }
        try {
            Speicher.LocalStorage.openDatabaseSync("TuxWetter", "", "Letzte Wetterdaten", 100000).transaction(function (tx) {
                sicherungTabelle(tx)
                tx.executeSql("INSERT OR REPLACE INTO einstellungen VALUES (?, ?, ?)",
                              [String(Plasmoid.id), Date.now(), S.datei(n => k[n], true, Date.now())])
                // Die zehn neuesten genügen
                tx.executeSql("DELETE FROM einstellungen WHERE widget NOT IN "
                              + "(SELECT widget FROM einstellungen ORDER BY stand DESC LIMIT 10)")
            })
        } catch (e) {
            console.warn("Tux-Wetter: Einstellungen nicht gesichert:", e)
        }
    }

    // Mehrere Änderungen kurz nacheinander (Einstellungsdialog) nur einmal sichern
    Timer {
        id: sicherungZeit
        interval: 3000
        onTriggered: root.einstellungenSichern()
    }

    // Beim Start: Ist das Widget neu (alles auf Standard) und gibt es die Sicherung eines anderen Widgets?
    function sicherungPruefen() {
        const k = Plasmoid.configuration
        if (k.restoreChecked || S.eingerichtet(n => k[n]))
            return einstellungenSichern()
        let zeile = null
        try {
            Speicher.LocalStorage.openDatabaseSync("TuxWetter", "", "Letzte Wetterdaten", 100000).transaction(function (tx) {
                sicherungTabelle(tx)
                const r = tx.executeSql("SELECT stand, inhalt FROM einstellungen WHERE widget <> ? ORDER BY stand DESC LIMIT 1",
                                        [String(Plasmoid.id)])
                if (r.rows.length)
                    zeile = r.rows.item(0)
            })
        } catch (e) {
            console.warn("Tux-Wetter: Sicherung nicht lesbar:", e)
        }
        const s = zeile ? S.pruefen(zeile.inhalt) : null
        if (s && S.eingerichtet(n => s.einstellungen[n] !== undefined ? s.einstellungen[n] : S.STANDARD[n]))
            angebot = { stand: zeile.stand, einstellungen: s.einstellungen }
        else
            k.restoreChecked = true
    }

    function angebotAnnehmen() {
        if (!angebot)
            return
        const e = angebot.einstellungen, k = Plasmoid.configuration
        angebot = null
        for (const n in e)
            if (!S.gleich(k[n], e[n]))
                k[n] = e[n]
        k.restoreChecked = true
    }

    function angebotAblehnen() {
        angebot = null
        Plasmoid.configuration.restoreChecked = true
    }

    // ── Neue Version auf GitHub: nur ein Hinweis, das Widget lädt nichts herunter ──
    // Alle Tux-Wetter-Widgets teilen sich im Speicher: wann zuletzt gefragt wurde, die neueste Version,
    // die übersprungene Version und bis wann „Später“ gilt. So fragt höchstens eines einmal am Tag.
    readonly property string updateAdresse: "https://api.github.com/repos/Mastertac2000/tux-wetter/releases/latest"
    readonly property string eigeneVersion: String(Plasmoid.metaData.version || "")
    property var neueVersion: null   // { version, url, name, text } oder null

    // "V1.5" → [1, 5]
    function versionZahlen(v) {
        return String(v).split(/[^0-9]+/).filter(x => x !== "").map(Number)
    }
    // Ist Version a neuer als b?
    function versionNeuer(a, b) {
        const x = versionZahlen(a), y = versionZahlen(b)
        for (let i = 0; i < Math.max(x.length, y.length); i++) {
            const d = (x[i] || 0) - (y[i] || 0)
            if (d !== 0)
                return d > 0
        }
        return false
    }

    function programmWert(name) {
        let wert = ""
        try {
            Speicher.LocalStorage.openDatabaseSync("TuxWetter", "", "Letzte Wetterdaten", 100000).transaction(function (tx) {
                tx.executeSql("CREATE TABLE IF NOT EXISTS programm (name TEXT PRIMARY KEY, wert TEXT)")
                const r = tx.executeSql("SELECT wert FROM programm WHERE name = ?", [name])
                if (r.rows.length)
                    wert = r.rows.item(0).wert
            })
        } catch (e) {
            console.warn("Tux-Wetter: Speicher nicht lesbar:", e)
        }
        return wert
    }

    function programmSetzen(name, wert) {
        try {
            Speicher.LocalStorage.openDatabaseSync("TuxWetter", "", "Letzte Wetterdaten", 100000).transaction(function (tx) {
                tx.executeSql("CREATE TABLE IF NOT EXISTS programm (name TEXT PRIMARY KEY, wert TEXT)")
                tx.executeSql("INSERT OR REPLACE INTO programm VALUES (?, ?)", [name, String(wert)])
            })
        } catch (e) {
            console.warn("Tux-Wetter: Speicher nicht beschreibbar:", e)
        }
    }

    // Hinweis zeigen, wenn die gemerkte neueste Version neuer ist und nicht weggeklickt wurde
    function updateAnzeigen() {
        let r = null
        try {
            r = JSON.parse(programmWert("neueste") || "null")
        } catch (e) {}
        neueVersion = Plasmoid.configuration.checkUpdates && r && versionNeuer(r.version, eigeneVersion)
                      && r.version !== programmWert("uebersprungen")
                      && Date.now() >= Number(programmWert("erinnern") || 0)
                      ? r : null
    }

    function updatePruefen() {
        if (!Plasmoid.configuration.checkUpdates) {
            neueVersion = null
            return
        }
        // Höchstens einmal am Tag bei GitHub fragen, sonst die gemerkte Antwort nehmen
        if (Date.now() - Number(programmWert("geprueft") || 0) < 86400000)
            return updateAnzeigen()
        const xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return
            // Fehler oder kein Netz: beim nächsten Durchgang (in 5 Minuten) erneut versuchen
            if (xhr.status !== 200)
                return
            try {
                const j = JSON.parse(xhr.responseText)
                if (!j.tag_name || j.draft || j.prerelease)
                    return
                programmSetzen("neueste", JSON.stringify({
                    version: String(j.tag_name),
                    url: String(j.html_url || "https://github.com/Mastertac2000/tux-wetter/releases"),
                    name: String(j.name || j.tag_name),
                    text: String(j.body || "").replace(/\r/g, "").substring(0, 1500)
                }))
                programmSetzen("geprueft", Date.now())
                updateAnzeigen()
            } catch (e) {
                console.warn("Tux-Wetter: Antwort von GitHub nicht lesbar:", e)
            }
        }
        xhr.open("GET", updateAdresse)
        xhr.setRequestHeader("Accept", "application/vnd.github+json")
        xhr.send()
    }

    function updateSeiteOeffnen() {
        if (neueVersion)
            Qt.openUrlExternally(neueVersion.url)
        updateSpaeter()
    }

    // Nach dem Öffnen der Download-Seite in drei Tagen wieder erinnern (falls dann noch nicht installiert)
    function updateSpaeter() {
        programmSetzen("erinnern", Date.now() + 3 * 86400000)
        neueVersion = null
    }

    function updateUeberspringen() {
        if (neueVersion)
            programmSetzen("uebersprungen", neueVersion.version)
        neueVersion = null
    }

    // Erst nach dem Start (Netz ist dann meist da), danach alle 5 Minuten: fragt GitHub höchstens
    // einmal am Tag und übernimmt sonst aus dem Speicher, was ein anderes Widget geholt oder
    // weggeklickt hat (so verschwindet auch die Markierung in der Leiste bald)
    Timer {
        interval: 30000
        running: true
        onTriggered: root.updatePruefen()
    }
    Timer {
        interval: 300000
        running: Plasmoid.configuration.checkUpdates
        repeat: true
        onTriggered: root.updatePruefen()
    }

    function speicherTabelle(tx) {
        tx.executeSql("CREATE TABLE IF NOT EXISTS wetter (widget TEXT PRIMARY KEY, schluessel TEXT, stand REAL, inhalt TEXT)")
        // Zusatzdaten (Regen, UV, Luft, Mond, Messwert) je Widget und Ort, damit die Karte beim Start gleich vollständig ist
        tx.executeSql("CREATE TABLE IF NOT EXISTS zusatz (widget TEXT PRIMARY KEY, ort TEXT, stand REAL, inhalt TEXT)")
    }

    function zusatzSpeichern() {
        try {
            const inhalt = { regen: regen, uvZusatz: uvZusatz, ortZusatz: ortZusatz, luft: luft, luftOrt: luftOrt,
                             luftZeit: luftZeit, mond: mond, mondTag: mondTag, messung: messung, chStation: chStation }
            Speicher.LocalStorage.openDatabaseSync("TuxWetter", "", "Letzte Wetterdaten", 100000).transaction(function (tx) {
                speicherTabelle(tx)
                tx.executeSql("INSERT OR REPLACE INTO zusatz VALUES (?, ?, ?, ?)",
                              [String(Plasmoid.id), breite + "|" + laenge, Date.now(), JSON.stringify(inhalt)])
            })
        } catch (e) {
            console.warn("Tux-Wetter: Zwischenspeicher nicht beschreibbar:", e)
        }
    }

    // Kommen mehrere Zusatzdaten kurz nacheinander an, nur einmal speichern
    Timer {
        id: zusatzSpeicher
        interval: 3000
        onTriggered: root.zusatzSpeichern()
    }
    onRegenChanged: if (bereit) zusatzSpeicher.restart()
    onLuftChanged: if (bereit) zusatzSpeicher.restart()
    onMondChanged: if (bereit) zusatzSpeicher.restart()
    onMessungChanged: if (bereit) zusatzSpeicher.restart()

    function zwischenspeichern(d) {
        try {
            Speicher.LocalStorage.openDatabaseSync("TuxWetter", "", "Letzte Wetterdaten", 100000).transaction(function (tx) {
                speicherTabelle(tx)
                tx.executeSql("INSERT OR REPLACE INTO wetter VALUES (?, ?, ?, ?)",
                              [String(Plasmoid.id), datenSchluessel, stand.getTime(), JSON.stringify(d)])
            })
        } catch (e) {
            console.warn("Tux-Wetter: Zwischenspeicher nicht beschreibbar:", e)
        }
    }

    function ausSpeicherLaden() {
        try {
            let zeile = null
            Speicher.LocalStorage.openDatabaseSync("TuxWetter", "", "Letzte Wetterdaten", 100000).transaction(function (tx) {
                speicherTabelle(tx)
                const r = tx.executeSql("SELECT stand, inhalt FROM wetter WHERE widget = ? AND schluessel = ?",
                                        [String(Plasmoid.id), schluesselJetzt()])
                if (r.rows.length)
                    zeile = r.rows.item(0)
            })
            // Mehr als einen Tag alte Daten helfen nicht weiter
            if (zeile && Date.now() - zeile.stand < 24 * 3600000)
                uebernehmen(JSON.parse(zeile.inhalt), schluesselJetzt(), new Date(zeile.stand))
            zusatzLaden()
        } catch (e) {
            console.warn("Tux-Wetter: Zwischenspeicher nicht lesbar:", e)
        }
    }

    // Zusatzdaten vom selben Ort, höchstens 3 Stunden alt; der Messwert nur, solange er noch gilt
    function zusatzLaden() {
        let zeile = null
        Speicher.LocalStorage.openDatabaseSync("TuxWetter", "", "Letzte Wetterdaten", 100000).transaction(function (tx) {
            speicherTabelle(tx)
            const r = tx.executeSql("SELECT stand, inhalt FROM zusatz WHERE widget = ? AND ort = ?",
                                    [String(Plasmoid.id), breite + "|" + laenge])
            if (r.rows.length)
                zeile = r.rows.item(0)
        })
        if (!zeile || Date.now() - zeile.stand > 3 * 3600000)
            return
        const z = JSON.parse(zeile.inhalt)
        regen = z.regen || []
        uvZusatz = z.uvZusatz === undefined ? null : z.uvZusatz
        ortZusatz = z.ortZusatz || null
        luft = z.luft || null
        luftOrt = z.luftOrt || ""
        luftZeit = z.luftZeit || 0
        mond = z.mond || null
        mondTag = z.mondTag || ""
        chStation = z.chStation || null
        messung = z.messung && Date.now() - z.messung.zeit <= M.MAX_ALTER ? z.messung : null
    }

    function fehlgeschlagen(meldung, wiederholbar) {
        fehler = meldung
        if (wiederholbar)
            wiederholen.start()
    }

    // Amtliche Wetterwarnungen für einen Ort (Schweiz, Österreich, Deutschland; Fehler stören die Wetterdaten nicht).
    // In welchem Land der Ort liegt, wird einmal je Ort geprüft und gemerkt:
    // "Breite|Länge|geprüfte Länder|Land oder -|Zusatz", z. B. "…|CH|CH|840000" oder "…|CHDE|-|".
    // So gehen die Koordinaten von Orten ausserhalb dieser Länder nicht bei jeder Aktualisierung hinaus.
    // merk: die gemerkte Angabe; merken(neu) speichert sie; fertig(liste) erhält die Warnungen;
    // gilt() sagt, ob die Antwort noch gebraucht wird.
    function amtlichFuer(b, l, merk, merken, fertig, gilt) {
        const k = Plasmoid.configuration
        const kandidaten = Wa.TYPEN.some(t => k[t.schalter]) ? Wa.DIENSTE.filter(d => k[d.schalter] && Wa.inBox(d, b, l)) : []
        const ort = b + "|" + l
        const teile = String(merk || "").split("|")
        const gemerkt = teile.length === 5 && teile[0] + "|" + teile[1] === ort
        // keine Warnungen gewünscht, oder der Ort liegt in einem Land, dessen Warnungen ausgeschaltet sind
        if (!kandidaten.length || (gemerkt && teile[3] !== "-" && !kandidaten.some(d => d.land === teile[3])))
            return fertig([])
        if (gemerkt && teile[3] !== "-")
            return warnungenFuer(Wa.dienst(teile[3]), b, l, teile[4], fertig, gilt)
        const offen = kandidaten.filter(d => !(gemerkt && teile[2].indexOf(d.land) >= 0))
        if (!offen.length)
            return fertig([])
        landPruefen(offen, 0, gemerkt ? teile[2] : "", b, l, merken, fertig, gilt)
    }

    // Prüft der Reihe nach, ob der Ort in einem der Länder liegt, und merkt sich das Ergebnis
    function landPruefen(offen, i, geprueft, b, l, merken, fertig, gilt) {
        const ort = b + "|" + l
        if (i >= offen.length) {
            merken(ort + "|" + geprueft + "|-|")
            return fertig([])
        }
        const d = offen[i]
        const xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE || !gilt())
                return
            // 404: GeoSphere kennt keine Gemeinde an diesem Punkt, der Ort liegt also nicht in Österreich
            if (xhr.status !== 200 && xhr.status !== 404)
                return console.warn("Tux-Wetter: Land für", d.name, "nicht prüfbar, Status", xhr.status)
            try {
                const antwort = xhr.status === 200 ? JSON.parse(xhr.responseText) : {}
                const ergebnis = d.pruefe(antwort)
                if (!ergebnis.drin)
                    return landPruefen(offen, i + 1, geprueft + d.land, b, l, merken, fertig, gilt)
                merken(ort + "|" + geprueft + d.land + "|" + d.land + "|" + ergebnis.zusatz)
                if (d.pruefIstAbfrage)
                    fertig(d.auswerten(antwort, Date.now()))
                else
                    warnungenFuer(d, b, l, ergebnis.zusatz, fertig, gilt)
            } catch (e) {
                console.warn("Tux-Wetter: Land für", d.name, "nicht lesbar:", e)
            }
        }
        xhr.open("GET", d.pruefAdresse(b, l, sprache))
        xhr.send()
    }

    function warnungenFuer(d, b, l, zusatz, fertig, gilt) {
        const url = d.adresse(b, l, zusatz, sprache)
        // Antworten für alle Orte (Schweiz) nur alle paar Minuten neu laden
        const alt = d.zwischenspeichern ? Wa.gespeichert(url, d.zwischenspeichern, Date.now()) : null
        if (alt) {
            try {
                fertig(d.auswerten(alt, Date.now(), b, l, sprache))
            } catch (e) {
                console.warn("Tux-Wetter: Warnungen von", d.name, "nicht lesbar:", e)
            }
            return
        }
        const xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE || !gilt())
                return
            if (xhr.status !== 200)
                return console.warn("Tux-Wetter: Warnungen von", d.name, "nicht abrufbar, Status", xhr.status)
            try {
                const antwort = JSON.parse(xhr.responseText)
                if (d.zwischenspeichern)
                    Wa.speichern(url, antwort, Date.now())
                fertig(d.auswerten(antwort, Date.now(), b, l, sprache))
            } catch (e) {
                console.warn("Tux-Wetter: Warnungen von", d.name, "nicht lesbar:", e)
            }
        }
        xhr.open("GET", url)
        const kopf = d.kopf ? d.kopf(sprache) : {}
        for (const name in kopf)
            xhr.setRequestHeader(name, kopf[name])
        xhr.send()
    }

    // Der angezeigte Ort: gemerkt in warnArea
    function amtlichAbfragen(nr, sk) {
        amtlichFuer(breite, laenge, Plasmoid.configuration.warnArea, v => Plasmoid.configuration.warnArea = v,
                    liste => amtlicheWarnungen = liste, () => nr === abfrageNr && sk === schluesselJetzt())
    }

    // ── Warnungen für die anderen Orte der Ortsliste (nur amtliche) ──
    // Gemerkt wird das Land je Ort in warnAreas (JSON: { "Breite|Länge": "…" }).
    property var orteWarnungen: ({})     // { "Breite|Länge": [Warnungen] }
    function orteWarnungenAbfragen() {
        let merk = {}
        try {
            merk = JSON.parse(Plasmoid.configuration.warnAreas || "{}") || {}
        } catch (e) {}
        for (const o of orte) {
            if (O.gleich(o, breite, laenge))
                continue
            const schl = o.lat + "|" + o.lon
            amtlichFuer(o.lat, o.lon, merk[schl], function (v) {
                let m = {}
                try {
                    m = JSON.parse(Plasmoid.configuration.warnAreas || "{}") || {}
                } catch (e) {}
                m[schl] = v
                Plasmoid.configuration.warnAreas = JSON.stringify(m)
            }, function (liste) {
                const neu = Object.assign({}, orteWarnungen)
                neu[schl] = liste
                orteWarnungen = neu
            }, () => orte.some(x => x.lat + "|" + x.lon === schl))
        }
    }
    // Je anderer Ort mit Warnungen: { ort, liste } (eingeschaltete Warnarten, noch gültig, stärkste zuerst)
    readonly property var andereWarnungen: orte.filter(o => !O.gleich(o, breite, laenge))
        .map(o => ({ ort: o, liste: Wa.alle((orteWarnungen[o.lat + "|" + o.lon] || []).filter(w => w.bis > jetzt), null,
                                            typ => warnartenAn[typ]) }))
        .filter(x => x.liste.length)
        .sort((a, b) => b.liste[0].stufe - a.liste[0].stufe)

    function ortZeigen(o) {
        Plasmoid.configuration.autoActive = false
        ortSetzen(o.name, o.lat, o.lon)
    }

    // Eine Zusatzabfrage; fertig(antwort) nur, wenn sie noch zur aktuellen Abfrage und zum Ort passt
    // fehlschlag() (falls angegeben) bei einem Fehler; alsText: die Antwort nicht als JSON lesen (CSV)
    function zusatzHolen(url, was, fertig, nr, sk, kopf, fehlschlag, alsText) {
        const xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE || nr !== abfrageNr || sk !== schluesselJetzt())
                return
            if (xhr.status !== 200) {
                // 404 heisst bei den Messwerten „keine Station in der Nähe“ (Bright Sky): kein Fehler
                if (!(fehlschlag && xhr.status === 404))
                    console.warn("Tux-Wetter:", was, "nicht abrufbar, Status", xhr.status)
                return fehlschlag ? fehlschlag() : undefined
            }
            let d
            try {
                d = alsText ? xhr.responseText : JSON.parse(xhr.responseText)
            } catch (e) {
                console.warn("Tux-Wetter:", was, "nicht lesbar:", e)
                return fehlschlag ? fehlschlag() : undefined
            }
            fertig(d)
        }
        xhr.open("GET", url)
        for (const name in kopf || {})
            xhr.setRequestHeader(name, kopf[name])
        xhr.send()
    }

    // Open-Meteo: Regen der nächsten 2 Stunden, UV-Index, Höhe und Zeitzone des Orts. Danach mit diesen
    // Angaben der Mond (MET Norway) und die gemessene Temperatur der nächsten Station.
    // Luftqualität und Pollen nur, wenn eingeschaltet.
    function zusatzAbfragen(nr, sk) {
        const k = Plasmoid.configuration
        if (k.showDetails || k.measuredTemp || anbieter === "metno")
            zusatzHolen(Z.regenAdresse(breite, laenge), "Regen der nächsten Stunden", function (d) {
                const z = Z.ausRegen(d)
                regen = z.regen
                uvZusatz = z.uv
                ortZusatz = z
                // Mondauf- und -untergang ändern sich nur täglich: einmal je Ort und Tag
                const mondSchluessel = breite + "|" + laenge + "|" + z.datum
                if (k.showDetails && z.datum && (mond === null || mondTag !== mondSchluessel))
                    zusatzHolen(Z.mondAdresse(breite, laenge, z.datum, z.versatz), "Mond", function (d) {
                        mond = Z.ausMond(d)
                        mondTag = mondSchluessel
                    }, nr, sk, { "User-Agent": A.KENNUNG })
                messungAbfragen(z.hoehe, nr, sk)
            }, nr, sk)
        else
            messung = null
        // Luftqualität und Pollen gibt es stündlich: höchstens einmal je Stunde und Ort
        const luftSchluessel = breite + "|" + laenge
        if (k.showDetails && k.airQuality) {
            if (luft === null || luftOrt !== luftSchluessel || Date.now() - luftZeit > 55 * 60000)
                zusatzHolen(Z.luftAdresse(breite, laenge), "Luftqualität", function (d) {
                    luft = Z.ausLuft(d)
                    luftOrt = luftSchluessel
                    luftZeit = Date.now()
                }, nr, sk)
        } else {
            luft = null
        }
    }
    property string mondTag: ""       // Ort und Datum des geladenen Monds
    property string luftOrt: ""
    property double luftZeit: 0

    // Gemessene Temperatur: Schweiz (MeteoSchweiz), Österreich (GeoSphere), Deutschland (DWD über Bright Sky).
    // Alle Messnetze, in deren Gebiet der Ort liegt, werden gefragt; es gilt die nächste passende Station
    // (am Bodensee z. B. Bregenz statt einer Schweizer Station am anderen Ufer).
    property var geoSphereStationen: null   // Stationsliste von GeoSphere, einmal je Sitzung geholt
    property var chStation: null            // gemerkte nächste MeteoSchweiz-Station { ort, id, station, km }

    function messungAbfragen(hoehe, nr, sk) {
        if (!Plasmoid.configuration.measuredTemp) {
            messung = null
            return
        }
        const b = breite, l = laenge, quellen = []
        if (M.inBox(M.SCHWEIZ, b, l))
            quellen.push(function (weiter) {
                // Station bekannt: nur ihre Datei; liefert sie nichts (Ausfall), beim nächsten Mal neu suchen
                const ort = b + "|" + l
                if (chStation && chStation.ort === ort)
                    return zusatzHolen(M.meteoSchweizStationAdresse(chStation.id), "Messwerte MeteoSchweiz", function (text) {
                        const m = M.ausMeteoSchweizStation(text, chStation, Date.now())
                        if (!m)
                            chStation = null
                        weiter(m)
                    }, nr, sk, {}, function () {
                        chStation = null
                        weiter(null)
                    }, true)
                // Sonst die nächste Station in der Datei mit allen Stationen suchen und merken
                zusatzHolen(M.METEOSCHWEIZ_ADRESSE, "Messwerte MeteoSchweiz", function (d) {
                    const m = M.ausMeteoSchweiz(d, b, l, hoehe, Date.now())
                    chStation = m && m.id ? { ort: ort, id: m.id, station: m.station, km: m.km } : null
                    weiter(m)
                }, nr, sk, {}, () => weiter(null))
            })
        if (M.inBox(M.OESTERREICH, b, l))
            quellen.push(function (weiter) {
                const mitStationen = function (meta) {
                    const k = M.geoSphereKandidaten(meta, b, l, hoehe)
                    if (!k.length)
                        return weiter(null)
                    zusatzHolen(M.geoSphereAdresse(k), "Messwerte GeoSphere", d => weiter(M.ausGeoSphereMessung(d, k, Date.now())),
                                nr, sk, {}, () => weiter(null))
                }
                if (geoSphereStationen)
                    mitStationen(geoSphereStationen)
                else
                    zusatzHolen(M.GEOSPHERE_STATIONEN, "Stationen GeoSphere", function (meta) {
                        geoSphereStationen = meta
                        mitStationen(meta)
                    }, nr, sk, {}, () => weiter(null))
            })
        if (M.inBox(M.DEUTSCHLAND, b, l))
            quellen.push(weiter => zusatzHolen(M.brightSkyAdresse(b, l), "Messwerte DWD",
                                               d => weiter(M.ausBrightSky(d, hoehe, Date.now())), nr, sk, {}, () => weiter(null)))
        // Alle gleichzeitig; sobald alle geantwortet haben, gilt die nächste Station (oder keine)
        let offen = quellen.length, beste = null
        if (!offen)
            messung = null
        for (const q of quellen)
            q(function (m) {
                if (m && (!beste || m.km < beste.km))
                    beste = m
                if (--offen === 0)
                    messung = beste
            })
    }

    function aktualisieren() {
        // Automatischer Standort: zuerst den Ort bestimmen (höchstens alle 10 Minuten)
        if (standortAn && Plasmoid.configuration.autoActive && Date.now() - standortZeit > 10 * 60000)
            standortBestimmen(abfragen)
        else
            abfragen()
    }

    function abfragen() {
        const nr = ++abfrageNr
        const a = anbieter
        const sk = schluesselJetzt()
        amtlichAbfragen(nr, sk)
        orteWarnungenAbfragen()
        zusatzAbfragen(nr, sk)
        if (A.brauchtSchluessel(a) && !schluessel) {
            fehler = t("Bitte in den Einstellungen einen API-Schlüssel für %1 eintragen", A.anbieterName(a))
            geladen = false
            return
        }
        const adressen = A.adressen(a, modell, breite, laenge, schluessel)
        const antworten = []
        let offen = adressen.length
        let abgebrochen = false
        adressen.forEach(function (eintrag, i) {
            const url = typeof eintrag === "string" ? eintrag : eintrag.url
            const xhr = new XMLHttpRequest()
            xhr.onreadystatechange = function () {
                // Verspätete Antworten und solche zu inzwischen geänderten Einstellungen verwerfen
                if (xhr.readyState !== XMLHttpRequest.DONE || nr !== abfrageNr || abgebrochen || sk !== schluesselJetzt())
                    return
                if (xhr.status !== 200) {
                    abgebrochen = true
                    // Ein falscher Schlüssel wird durch Wiederholen nicht richtig
                    root.fehlgeschlagen(A.fehlerText(a, xhr.status, xhr.responseText, root.sprache), xhr.status !== 401 && xhr.status !== 403)
                    return
                }
                try {
                    antworten[i] = JSON.parse(xhr.responseText)
                } catch (e) {
                    abgebrochen = true
                    root.fehlgeschlagen(root.t("Wetterdaten nicht lesbar: %1", e), true)
                    return
                }
                if (--offen > 0)
                    return
                let d
                try {
                    d = mitTagesverlauf(A.auswerten(a, antworten), sk)
                    uebernehmen(d, sk)
                } catch (e) {
                    root.fehlgeschlagen(root.t("Wetterdaten von %1 nicht lesbar: %2", A.anbieterName(a), e), true)
                    return
                }
                fehler = ""
                fehlversuche = 0
                wiederholen.stop()
                zwischenspeichern(d)
            }
            xhr.open("GET", url)
            for (const name in eintrag.kopf || {})
                xhr.setRequestHeader(name, eintrag.kopf[name])
            xhr.send()
        })
    }

    // Liefert der Anbieter für heute nur Werte ab jetzt (OpenWeatherMap), die früher am selben Tag
    // gesehenen Höchst- und Tiefstwerte behalten; um Mitternacht beginnt es neu
    function mitTagesverlauf(d, schluessel) {
        if (d.heuteAb > 0 && geladen && datenSchluessel === schluessel && heuteDatum === d.heuteDatum) {
            d.heuteMax = Math.max(d.heuteMax, heuteMax)
            d.heuteMin = Math.min(d.heuteMin, heuteMin)
            d.heuteAb = Math.min(d.heuteAb, heuteAb)
        }
        return d
    }

    // schluessel: Anbieter, Modell und Ort der Daten; zeitpunkt: wann sie abgefragt wurden
    // (aus dem Zwischenspeicher älter als jetzt)
    function uebernehmen(d, schluessel, zeitpunkt) {
        temperatur = d.temperatur
        code = d.code
        tag = d.tag
        wind = d.wind
        // Ältere Daten aus dem Zwischenspeicher kennen die folgenden Werte noch nicht
        gefuehlt = d.gefuehlt === undefined ? null : d.gefuehlt
        windRichtung = d.windRichtung === undefined ? null : d.windRichtung
        sonnenAuf = d.sonnenAuf || ""
        sonnenUnter = d.sonnenUnter || ""
        uvAnbieter = d.uv === undefined ? null : d.uv
        boeen = d.boeen || []
        feuchte = d.feuchte
        niederschlag = d.niederschlag
        heuteMax = d.heuteMax
        heuteMin = d.heuteMin
        heuteDatum = d.heuteDatum || ""
        heuteAb = d.heuteAb || 0
        stunden = d.stunden

        // Spanne der Temperaturbalken über alle Folgetage
        let lo = Infinity, hi = -Infinity
        for (const t of d.tage) {
            lo = Math.min(lo, t.min)
            hi = Math.max(hi, t.max)
        }
        bereichMin = isFinite(lo) ? lo : 0
        bereichMax = hi > lo ? hi : bereichMin + 1
        tage = d.tage

        stand = zeitpunkt || new Date()
        jetzt = Date.now()
        datenSchluessel = schluessel
        geladen = true
    }

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: Plasmoid.formFactor === PlasmaCore.Types.Planar
                             || Plasmoid.formFactor === PlasmaCore.Types.MediaCenter
                             ? fullRepresentation : compactRepresentation

    toolTipMainText: Plasmoid.configuration.locationName
    toolTipSubText: geladen
        ? W.beschreibung(code, tag, sprache) + ", " + grad(anzeigeTemp) + (fahrenheit ? " °F" : " °C")
          + (gemessen ? " (" + t("gemessen") + ")" : "")
          + (gefuehlt !== null && Plasmoid.configuration.feelsLike ? " (" + t("gefühlt %1°", grad(gefuehlt)) + ")" : "")
          // Ohne Werte vom Morgen (OpenWeatherMap) gilt die Spanne auf der Karte erst ab dieser Stunde
          + (heuteAb >= 9 ? "\n" + t("Höchst/Tiefst heute %1° / %2°, erst ab %3 Uhr bekannt", grad(heuteMax), grad(heuteMin), heuteAb) : "")
          + (Plasmoid.configuration.showDetails && Z.regenText(regen, jetzt, sprache) ? "\n" + Z.regenText(regen, jetzt, sprache) : "")
          + warnungen.map(w => "\n⚠ " + Wa.langtext(w, jetzt, sprache)).join("")
          + andereWarnungen.map(x => "\n⚠ " + x.ort.name + ": " + Wa.kurztext(x.liste[0], jetzt, x.liste.length - 1, sprache)).join("")
          + "\n" + t("Stand: %1", standText()) + " · " + A.anbieterName(anbieter)
          + (fehler ? "\n" + fehler : "")
          + (neueVersion ? "\n⬆ " + t("Tux-Wetter %1 ist erschienen", neueVersion.version) : "")
        : (fehler || t("Lade Wetterdaten …"))

    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: root.t("Jetzt aktualisieren")
            icon.name: "view-refresh"
            onTriggered: root.aktualisieren()
        },
        PlasmaCore.Action {
            text: root.t("Nächster Ort")
            icon.name: "go-next"
            visible: root.mehrereOrte
            onTriggered: root.ortWechseln(1)
        },
        PlasmaCore.Action {
            text: root.t("Vorheriger Ort")
            icon.name: "go-previous"
            visible: root.mehrereOrte
            onTriggered: root.ortWechseln(-1)
        }
    ]

    // ── Desktop-Benachrichtigung bei einer neuen oder stärkeren Warnung ──
    // Gemerkt wird je Ort und Warnart (im gemeinsamen Speicher, damit zwei Widgets für denselben Ort
    // nicht doppelt melden und nach einem Neustart nicht erneut): die gemeldete Stufe und bis wann sie gilt.
    Component {
        id: meldungVorlage
        Notification {
            componentName: "plasma_workspace"
            eventId: "notification"
            iconName: "weather-storm"
            autoDelete: true
        }
    }

    // Meldet die Warnungen eines Orts, die neu oder stärker sind (name: Ortsname in der Meldung)
    // Zuletzt geprüfte Warnungen je Ort: Die Warnlisten werden alle 30 Sekunden neu berechnet; die
    // Datenbank wird nur gefragt, wenn sich an den fälligen Warnungen etwas geändert hat
    property var meldeStand: ({})
    function meldenFuer(name, b, l, liste) {
        const k = Plasmoid.configuration
        const faellig = liste.filter(w => w.stufe >= k.notifyLevel)
        const ort = b.toFixed(2) + "|" + l.toFixed(2)
        const stand = k.notifications ? faellig.map(w => [w.typ, w.stufe, w.von, w.bis, w.quelle].join(",")).join(";") : ""
        if (meldeStand[ort] === stand)
            return
        meldeStand[ort] = stand
        if (!k.notifications || !faellig.length)
            return
        const jetztMs = Date.now()
        try {
            Speicher.LocalStorage.openDatabaseSync("TuxWetter", "", "Letzte Wetterdaten", 100000).transaction(function (tx) {
                tx.executeSql("CREATE TABLE IF NOT EXISTS meldungen (ort TEXT, typ TEXT, stufe INTEGER, bis REAL, PRIMARY KEY (ort, typ))")
                for (const w of faellig) {
                    const typ = w.typ || "wind"
                    const r = tx.executeSql("SELECT stufe, bis FROM meldungen WHERE ort = ? AND typ = ?", [ort, typ])
                    const alt = r.rows.length ? r.rows.item(0) : null
                    if (!alt || alt.bis < jetztMs || w.stufe > alt.stufe) {
                        const n = meldungVorlage.createObject(root, { title: Wa.meldungTitel(w, sprache),
                                                                    text: name + ": "
                                                                          + Wa.meldungText(w, jetztMs, sprache),
                                                                    urgency: w.stufe >= 3 ? Notification.HighUrgency : Notification.NormalUrgency })
                        n.sendEvent()
                        tx.executeSql("INSERT OR REPLACE INTO meldungen VALUES (?, ?, ?, ?)", [ort, typ, w.stufe, w.bis])
                    } else if (w.bis > alt.bis) {
                        // Dieselbe Warnung dauert länger: nicht erneut melden, wenn die alte Zeit abläuft
                        tx.executeSql("UPDATE meldungen SET bis = ? WHERE ort = ? AND typ = ?", [w.bis, ort, typ])
                    }
                }
            })
        } catch (e) {
            console.warn("Tux-Wetter: Benachrichtigung nicht möglich:", e)
        }
    }
    onWarnungenChanged: if (geladen) meldenFuer(Plasmoid.configuration.locationName, breite, laenge, warnungen)
    // Die anderen Orte der Ortsliste, wenn gewünscht
    onAndereWarnungenChanged: {
        if (Plasmoid.configuration.notifyAllPlaces)
            for (const x of andereWarnungen)
                meldenFuer(x.ort.name, x.ort.lat, x.ort.lon, x.liste)
    }
    onOrteChanged: if (bereit) orteWarnungenAbfragen()

    Timer {
        interval: root.intervallMinuten * 60000
        running: true
        repeat: true
        onTriggered: root.aktualisieren()
    }

    // Nach einem Fehler (z.B. Netz beim Start noch nicht da) rasch erneut versuchen:
    // nach 3, 6, 12, 24 und 48 Sekunden, danach jede Minute
    Timer {
        id: wiederholen
        interval: Math.min(60000, 3000 * Math.pow(2, root.fehlversuche))
        onTriggered: {
            root.fehlversuche++
            root.aktualisieren()
        }
    }

    Timer {
        interval: 30000
        running: root.geladen
        repeat: true
        onTriggered: root.jetzt = Date.now()
    }

    Timer {
        id: ortGeaendert
        interval: 300
        onTriggered: root.aktualisieren()
    }

    Timer {
        interval: 40
        repeat: true
        // Ohne Daten ist kein Wettersymbol zu sehen
        running: Plasmoid.configuration.animations && root.geladen
        onTriggered: root.animationsZeit = (Date.now() - root.animationsStart) / 1000
    }

    // Anbieter, Modell oder Ort geändert: nicht weiter Daten oder Fehler der alten Einstellung zeigen
    function einstellungGeaendert() {
        if (!bereit)
            return
        if (datenSchluessel !== schluesselJetzt()) {
            geladen = false
            fehler = ""
            fehlversuche = 0
            amtlicheWarnungen = []
            regen = []
            uvZusatz = null
            luft = null
            mond = null
            ortZusatz = null
            messung = null
        }
        ortGeaendert.restart()
    }

    onBreiteChanged: einstellungGeaendert()
    onLaengeChanged: einstellungGeaendert()
    onModellChanged: einstellungGeaendert()
    onAnbieterChanged: einstellungGeaendert()
    onSchluesselChanged: if (bereit) ortGeaendert.restart()
    // Warnungen ein- oder ausgeschaltet: amtliche Warnungen gleich neu holen bzw. verwerfen
    Connections {
        target: Plasmoid.configuration
        function onWindWarningChanged() { root.amtlichAbfragen(root.abfrageNr, root.schluesselJetzt()) }
        function onThunderWarningChanged() { root.amtlichAbfragen(root.abfrageNr, root.schluesselJetzt()) }
        function onRainWarningChanged() { root.amtlichAbfragen(root.abfrageNr, root.schluesselJetzt()) }
        function onSnowWarningChanged() { root.amtlichAbfragen(root.abfrageNr, root.schluesselJetzt()) }
        function onIceWarningChanged() { root.amtlichAbfragen(root.abfrageNr, root.schluesselJetzt()) }
        function onHeatWarningChanged() { root.amtlichAbfragen(root.abfrageNr, root.schluesselJetzt()) }
        function onMeteoSwissWarningsChanged() { root.amtlichAbfragen(root.abfrageNr, root.schluesselJetzt()) }
        function onGeoSphereWarningsChanged() { root.amtlichAbfragen(root.abfrageNr, root.schluesselJetzt()) }
        function onDwdWarningsChanged() { root.amtlichAbfragen(root.abfrageNr, root.schluesselJetzt()) }
        function onShowDetailsChanged() { root.zusatzAbfragen(root.abfrageNr, root.schluesselJetzt()) }
        function onAirQualityChanged() { root.zusatzAbfragen(root.abfrageNr, root.schluesselJetzt()) }
        function onMeasuredTempChanged() { root.zusatzAbfragen(root.abfrageNr, root.schluesselJetzt()) }
        // Sprache gewechselt: Warntexte der Dienste in der neuen Sprache holen
        function onLanguageChanged() { root.amtlichAbfragen(root.abfrageNr, root.schluesselJetzt()) }
        // Standort ein- oder ausgeschaltet bzw. in der Ortsliste gewählt
        function onAutoLocationChanged() { root.standortGeaendert() }
        function onAutoActiveChanged() { root.standortGeaendert() }
        // Suche nach neuen Versionen ein- oder ausgeschaltet
        function onCheckUpdatesChanged() { root.updatePruefen() }
        // Eine Einstellung des Benutzers geändert: Sicherung erneuern
        function onValueChanged(name, wert) {
            if (root.bereit && S.SCHLUESSEL.indexOf(name) >= 0)
                sicherungZeit.restart()
        }
    }

    function standortGeaendert() {
        if (!bereit)
            return
        standortZeit = 0
        if (standortAn && Plasmoid.configuration.autoActive)
            ortGeaendert.restart()
    }
    Component.onCompleted: {
        ausSpeicherLaden()
        aktualisieren()
        bereit = true
        sicherungPruefen()
    }

    compactRepresentation: MouseArea {
        Layout.minimumWidth: zeile.implicitWidth
        Layout.preferredWidth: zeile.implicitWidth
        onClicked: root.expanded = !root.expanded

        RowLayout {
            id: zeile
            anchors.fill: parent
            spacing: Kirigami.Units.smallSpacing

            WetterSymbol {
                id: leistenSymbol
                Layout.fillHeight: true
                Layout.preferredWidth: height
                code: root.code
                tag: root.tag
                zeit: root.animationsZeit

                // Neue Version auf GitHub: grüner Kreis mit Pfeil nach oben unten links am Symbol
                // (unten rechts sitzt das Warndreieck); ein Klick öffnet die Karte mit dem Hinweis
                Canvas {
                    id: leistenUpdate
                    visible: root.neueVersion !== null
                    anchors.left: parent.left
                    anchors.bottom: parent.bottom
                    width: parent.width * 0.46
                    height: width
                    onVisibleChanged: requestPaint()
                    onWidthChanged: requestPaint()
                    onPaint: {
                        const c = getContext("2d"), b = width
                        c.reset()
                        c.lineWidth = Math.max(1, b * 0.08)
                        c.strokeStyle = "#1A1A1A"
                        c.fillStyle = "#2EA05A"
                        c.beginPath(); c.arc(b / 2, b / 2, b * 0.44, 0, 2 * Math.PI); c.fill(); c.stroke()
                        c.strokeStyle = "#FFFFFF"
                        c.lineWidth = Math.max(1.2, b * 0.12)
                        c.lineCap = "round"
                        c.lineJoin = "round"
                        c.beginPath(); c.moveTo(b / 2, b * 0.74); c.lineTo(b / 2, b * 0.28); c.stroke()
                        c.beginPath(); c.moveTo(b * 0.31, b * 0.46); c.lineTo(b / 2, b * 0.27); c.lineTo(b * 0.69, b * 0.46); c.stroke()
                    }
                }
                // Wetterwarnung: kleines Warndreieck in der Farbe der stärksten Warnung unten rechts am Symbol
                Canvas {
                    id: leistenWarnung
                    visible: root.warnung !== null
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    width: parent.width * 0.5
                    height: width
                    readonly property int stufe: root.warnung ? root.warnung.stufe : 0
                    onStufeChanged: requestPaint()
                    onWidthChanged: requestPaint()
                    onPaint: {
                        const c = getContext("2d"), b = width
                        c.reset()
                        if (!stufe)
                            return
                        c.lineJoin = "round"
                        c.lineWidth = Math.max(1, b * 0.08)
                        c.strokeStyle = "#1A1A1A"
                        c.fillStyle = Wa.FARBEN[stufe]
                        c.beginPath(); c.moveTo(b / 2, b * 0.08); c.lineTo(b * 0.95, b * 0.9); c.lineTo(b * 0.05, b * 0.9); c.closePath()
                        c.fill(); c.stroke()
                        c.fillStyle = Wa.SCHRIFT[stufe]
                        c.fillRect(b * 0.45, b * 0.36, b * 0.1, b * 0.3)
                        c.fillRect(b * 0.45, b * 0.72, b * 0.1, b * 0.1)
                    }
                }
            }
            Text {
                text: root.geladen ? root.grad(root.anzeigeTemp) + "°" : "–"
                color: Kirigami.Theme.textColor
                font.pixelSize: Math.max(12, parent.height * 0.5)
            }
        }
    }

    fullRepresentation: Item {
        id: flaeche
        // Plasma merkt sich Ort und Grösse auf der Arbeitsfläche je Bildschirmauflösung. Meldet der
        // Bildschirm beim Anmelden kurz eine andere Auflösung (Wayland mit Skalierung, Dock, zweiter
        // Monitor), stellt Plasma das Widget neu auf – in der Grösse, die es hier meldet. Darum
        // meldet es die zuletzt eingestellte Grösse statt fest 560×436.
        Layout.preferredWidth: Plasmoid.configuration.lastWidth >= 240 ? Plasmoid.configuration.lastWidth : 560
        Layout.preferredHeight: Plasmoid.configuration.lastHeight >= 187 ? Plasmoid.configuration.lastHeight : 436
        Layout.minimumWidth: 240
        Layout.minimumHeight: 187

        readonly property bool aufArbeitsflaeche: Plasmoid.formFactor === PlasmaCore.Types.Planar
                                                  || Plasmoid.formFactor === PlasmaCore.Types.MediaCenter
        // Erst merken, wenn Plasma nach dem Start fertig aufgestellt hat
        property bool bereit: false
        Timer {
            running: true
            interval: 15000
            // Auch ohne Ziehen einmal merken (z. B. Grösse aus einer älteren Version)
            onTriggered: {
                flaeche.bereit = true
                groesseMerken.restart()
            }
        }
        onWidthChanged: if (bereit) groesseMerken.restart()
        onHeightChanged: if (bereit) groesseMerken.restart()
        Timer {
            id: groesseMerken
            interval: 2000
            onTriggered: {
                const b = Math.round(flaeche.width), h = Math.round(flaeche.height)
                if (!flaeche.aufArbeitsflaeche || b < 240 || h < 187)
                    return
                if (Plasmoid.configuration.lastWidth !== b)
                    Plasmoid.configuration.lastWidth = b
                if (Plasmoid.configuration.lastHeight !== h)
                    Plasmoid.configuration.lastHeight = h
            }
        }

        // Die Karte behält immer das Seitenverhältnis der 700×545-Vorlage und sitzt mittig in der
        // Fläche, die beim Ziehen am Rand entsteht (Plasma kann das Ziehen selbst nicht einrasten)
        Karte {
            anchors.centerIn: parent
            width: Math.min(parent.width, parent.height * 700 / 545)
            height: width * 545 / 700
            wetter: root
        }
    }
}
