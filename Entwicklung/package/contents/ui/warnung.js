.pragma library

.import "sprache.js" as T

// SPDX-FileCopyrightText: 2026 R.Bruns
// SPDX-License-Identifier: GPL-3.0-or-later

// Wetterwarnungen aus zwei Quellen:
//  1. Amtliche Warnungen des Wetterdienstes für Orte in der Schweiz (MeteoSchweiz), in Österreich
//     (GeoSphere Austria) und in Deutschland (DWD), siehe DIENSTE: Wind, Gewitter, Regen, Schnee,
//     Glätte/Frost und Hitze (siehe TYPEN).
//  2. Eigene Auswertung der Vorhersage (alle Orte, nur Wind): höchste Böe der nächsten 24 Stunden.
// Je Warnart zählt die stärkste amtliche Warnung. Beim Wind gilt ohne amtliche Warnung die eigene
// Auswertung; liegt sie höher als die amtliche, steht sie zusätzlich im Tooltip.
//
// Format einer Warnung: { typ (siehe TYPEN), stufe (1–4), titel, kmh (höchste Böe, 0 = unbekannt),
//                         von, bis (ms seit 1970), quelle, amtlich, info (Zusatztext für den Tooltip, optional),
//                         vorhersage (höhere eigene Warnung neben einer amtlichen, optional) }
// stufe: 1 gelb, 2 orange, 3 rot, 4 violett – wie die Warnstufen des DWD
// (beim Wind: Windböen, Sturmböen, schwere Sturmböen/orkanartige Böen, Orkanböen)

// Warnarten mit dem Schalter in den Einstellungen; die Reihenfolge gilt bei gleicher Stufe
const TYPEN = [
    { typ: "gewitter", name: "Gewitter", schalter: "thunderWarning" },
    { typ: "wind", name: "Wind", schalter: "windWarning" },
    { typ: "regen", name: "Starkregen", schalter: "rainWarning" },
    { typ: "schnee", name: "Schnee", schalter: "snowWarning" },
    { typ: "glaette", name: "Glätte und Frost", schalter: "iceWarning" },
    { typ: "hitze", name: "Hitze", schalter: "heatWarning" }
]

function typNr(typ) {
    const i = TYPEN.findIndex(t => t.typ === typ)
    return i < 0 ? TYPEN.length : i
}

// Schwellen für die eigene Auswertung (Böen in km/h, nach Beaufort, angelehnt an den DWD)
const SCHWELLEN = [
    { kmh: 118, stufe: 4, titel: "Orkanböen" },
    { kmh: 89, stufe: 3, titel: "Schwere Sturmböen" },
    { kmh: 62, stufe: 2, titel: "Sturmböen" },
    { kmh: 50, stufe: 1, titel: "Windböen" }
]

const FARBEN = ["", "#F5C400", "#FF8A00", "#E53935", "#9C27B0"]
// Schrift auf der Warnfarbe: dunkel auf Gelb und Orange, weiss auf Rot und Violett
const SCHRIFT = ["", "#1A1A1A", "#1A1A1A", "#FFFFFF", "#FFFFFF"]
// Hellere Töne für Schrift direkt auf der blauen Karte (Windwert), damit Rot und Violett lesbar bleiben
const AUF_KARTE = ["", "#F5C400", "#FF9A2E", "#FF6B5E", "#E08CFF"]
// Dunklere Töne für Schrift auf der hellen Karte
const AUF_HELL = ["", "#9A7600", "#C25E00", "#C62828", "#8E24AA"]

// ── Amtliche Warndienste ──
// Alle Schweizer Warnungen von MeteoSchweiz über MeteoAlarm (siehe ausMeteoAlarm)
const METEOALARM_CH = "https://feeds.meteoalarm.org/api/v1/warnings/feeds-switzerland"
// box: grobe Fläche des Landes [Breite von, bis, Länge von, bis]; sie schliesst Nachbargebiete ein.
// Ob ein Ort wirklich im Land liegt, klärt einmal pruefAdresse/pruefe (main.qml merkt sich das Ergebnis).
// pruefe(antwort) gibt zurück, ob der Ort im Land liegt, und als zusatz, was die Warnungsabfrage
// braucht. Reihenfolge: zuerst die kleinen Länder, dann Deutschland.
// auswerten(antwort, jetztMs, breite, laenge, sprache) liefert die Warnungen für den Ort.
// zwischenspeichern: Minuten, die eine Antwort für alle Orte gilt (die Schweiz lädt alle Warnungen auf einmal).
const DIENSTE = [
    {
        land: "CH", name: "MeteoSchweiz", schalter: "meteoSwissWarnings", box: [45.8, 47.85, 5.9, 10.5],
        // Amtliches Ortschaftenverzeichnis der Schweiz (swisstopo), auch für Liechtenstein
        pruefAdresse: (b, l) => "https://api3.geo.admin.ch/rest/services/api/MapServer/identify?geometryType=esriGeometryPoint"
                                + "&geometry=" + l + "," + b + "&sr=4326&layers=all:ch.swisstopo-vd.ortschaftenverzeichnis_plz"
                                + "&tolerance=0&returnGeometry=false",
        pruefe: antwort => ({ drin: (antwort.results || []).some(r => r.attributes && r.attributes.plz), zusatz: "" }),
        // Amtliche Warnungen von MeteoSchweiz über MeteoAlarm (EUMETNET): alle Schweizer Warnungen mit ihrer
        // Fläche; ob der Ort betroffen ist, prüft das Widget selbst. Frei weiterverwendbar mit Quellenangabe.
        adresse: () => METEOALARM_CH,
        zwischenspeichern: 20,
        auswerten: (antwort, jetztMs, b, l, sp) => ausMeteoAlarm(antwort, jetztMs, b, l, sp)
    },
    {
        land: "AT", name: "GeoSphere", schalter: "geoSphereWarnings", box: [46.3, 49.1, 9.5, 17.2],
        // Warnungen der Gemeinde; ausserhalb Österreichs antwortet der Dienst mit 404
        pruefAdresse: (b, l, sp) => geoSphereAdresse(b, l, sp),
        pruefe: antwort => ({ drin: !!(antwort.properties && antwort.properties.location), zusatz: "" }),
        pruefIstAbfrage: true,  // die Antwort der Prüfung enthält schon die Warnungen
        adresse: (b, l, zusatz, sp) => geoSphereAdresse(b, l, sp),
        auswerten: (antwort, jetztMs) => ausGeoSphere(antwort, jetztMs)
    },
    {
        land: "DE", name: "DWD", schalter: "dwdWarnings", box: [47.2, 55.1, 5.8, 15.1],
        // Liegt der Ort in einem deutschen Bundesland? (Antwort mit einem Treffer = ja)
        pruefAdresse: (b, l) => "https://maps.dwd.de/geoserver/dwd/ows?service=WFS&version=2.0.0&request=GetFeature"
                                + "&typeName=dwd:Warngebiete_Bundeslaender&outputFormat=application/json&propertyName=NAME&count=1"
                                + "&CQL_FILTER=" + encodeURIComponent("INTERSECTS(SHAPE,POINT(" + b + " " + l + "))"),
        pruefe: antwort => ({ drin: (antwort.features || []).length > 0, zusatz: "" }),
        adresse: (b, l) => "https://maps.dwd.de/geoserver/dwd/ows?service=WFS&version=2.0.0&request=GetFeature"
                           + "&typeName=dwd:Warnungen_Gemeinden&outputFormat=application/json"
                           + "&propertyName=EVENT,EC_GROUP,SEVERITY,ONSET,EXPIRES,HEADLINE,PARAMETERNAME,PARAMETERVALUE"
                           + "&CQL_FILTER=" + encodeURIComponent("INTERSECTS(THE_GEOM,POINT(" + b + " " + l + "))"),
        auswerten: (antwort, jetztMs) => ausDwd(antwort, jetztMs)
    }
]

function dienst(land) {
    return DIENSTE.find(d => d.land === land) || null
}

function inBox(d, breite, laenge) {
    return breite >= d.box[0] && breite <= d.box[1] && laenge >= d.box[2] && laenge <= d.box[3]
}

// Gilt die Warnung jetzt oder in den nächsten 24 Stunden?
function bald(von, bis, jetztMs) {
    return bis >= jetztMs && von <= jetztMs + 24 * 3600000
}

// sp: Sprache des Warntexts (de oder en)
function geoSphereAdresse(breite, laenge, sp) {
    return "https://warnungen.zamg.at/wsapp/api/getWarningsForCoords?lon=" + laenge + "&lat=" + breite
           + "&lang=" + (sp === "en" ? "en" : "de")
}

// ── MeteoSchweiz über MeteoAlarm ──
// CAP-Meldungen im JSON-Format, je Meldung Texte in mehreren Sprachen und die betroffene Fläche als Polygon
// ("Breite,Länge Breite,Länge …"). awareness_level: 2 gelb, 3 orange, 4 rot; die Schweizer Gefahrenstufe 5
// (sehr gross) kommt als rot mit severity "Extreme". awareness_type: 1 Wind, 2 Schnee/Glätte, 3 Gewitter,
// 5 Hitze, 6 Kälte, 10 Regen, 13 Regen/Hochwasser (andere wie Waldbrand oder Lawinen bleiben weg).
// MeteoSchweiz wünscht, dass Warnungen unverändert weitergegeben werden: Titel und Text bleiben im Original.
const METEOALARM_ART = { 1: "wind", 2: "schnee", 3: "gewitter", 5: "hitze", 6: "glaette", 10: "regen", 13: "regen" }

// Liegt der Punkt im Polygon? (Strahlverfahren; punkte: [[Breite, Länge], …])
function imPolygon(b, l, punkte) {
    let drin = false
    for (let i = 0, j = punkte.length - 1; i < punkte.length; j = i++) {
        const bi = punkte[i][0], li = punkte[i][1], bj = punkte[j][0], lj = punkte[j][1]
        if ((li > l) !== (lj > l) && b < (bj - bi) * (l - li) / (lj - li) + bi)
            drin = !drin
    }
    return drin
}

// Zwischenspeicher für Antworten, die für alle Orte gelten (gemeinsam für alle Widgets dieser Sitzung)
const ZWISCHEN = {}
function gespeichert(url, minuten, jetztMs) {
    const z = ZWISCHEN[url]
    return z && jetztMs - z.zeit < minuten * 60000 ? z.antwort : null
}
function speichern(url, antwort, jetztMs) {
    ZWISCHEN[url] = { zeit: jetztMs, antwort: antwort }
}

function polygonPunkte(text) {
    return String(text).trim().split(/\s+/).map(p => p.split(",").map(Number)).filter(p => p.length === 2 && !isNaN(p[0]) && !isNaN(p[1]))
}

function parameter(info, name) {
    const p = (info.parameter || []).find(x => x.valueName === name)
    return p ? String(p.value) : ""
}

function ausMeteoAlarm(antwort, jetztMs, b, l, sp) {
    const meldungen = ((antwort && antwort.warnings) || []).map(w => w.alert).filter(a => a && a.status === "Actual")
    // Ersetzte oder aufgehobene Meldungen: references = "Absender,Kennung,Zeit …"
    const ersetzt = {}
    for (const a of meldungen)
        for (const r of String(a.references || "").split(/\s+/))
            if (r.split(",")[1])
                ersetzt[r.split(",")[1]] = true
    const liste = [], gesehen = {}
    for (const a of meldungen) {
        if (a.msgType === "Cancel" || ersetzt[a.identifier] || !a.info || !a.info.length)
            continue
        const info = a.info.find(i => String(i.language).indexOf(sp === "en" ? "en" : "de") === 0) || a.info[0]
        let typ = METEOALARM_ART[parseInt(parameter(info, "awareness_type"))]
        const stufeMa = parseInt(parameter(info, "awareness_level"))
        if (!typ || !(stufeMa >= 2))
            continue
        const titel = String(info.event || info.headline || "")
        if (typ === "schnee" && /glätte|glatt|frost|eis|ice|slippery/i.test(titel))
            typ = "glaette"
        const von = Date.parse(info.onset || info.effective || a.sent), bis = Date.parse(info.expires || "") || von + 24 * 3600000
        if (isNaN(von) || !bald(von, bis, jetztMs))
            continue
        const flaechen = (info.area || []).reduce((alle, f) => alle.concat(f.polygon || []), [])
        if (!flaechen.some(p => imPolygon(b, l, polygonPunkte(p))))
            continue
        const stufe = stufeMa >= 4 ? (info.severity === "Extreme" ? 4 : 3) : stufeMa - 1
        // Dieselbe Warnung kommt je Teilgebiet einmal; nur einmal zeigen
        const schluessel = [typ, stufe, von, bis, titel].join("|")
        if (gesehen[schluessel])
            continue
        gesehen[schluessel] = true
        const text = [info.description, info.instruction].filter(x => x).join("\n").trim()
        liste.push({ typ: typ, stufe: stufe, titel: titel, original: true, kmh: 0, von: von, bis: bis,
                     quelle: "MeteoSchweiz", ueber: "MeteoAlarm", amtlich: true, info: text })
    }
    return liste
}

// GeoSphere Austria: warntypid 1 Wind, 2 Regen, 3 Schnee, 4 Glatteis, 5 Gewitter, 6 Hitze, 7 Kälte;
// warnstufeid 1 gelb, 2 orange, 3 rot; rawinfo.start/end in Sekunden.
// Die Böen stehen im Text, z. B. „Spitzen von 60 bis 80 km/h“.
const GEOSPHERE_ART = {
    1: ["wind", "Windwarnung"], 2: ["regen", "Regenwarnung"], 3: ["schnee", "Schneewarnung"],
    4: ["glaette", "Glatteiswarnung"], 5: ["gewitter", "Gewitterwarnung"], 6: ["hitze", "Hitzewarnung"],
    7: ["glaette", "Kältewarnung"]
}

function ausGeoSphere(antwort, jetztMs) {
    const liste = []
    const warnungen = (antwort && antwort.properties && antwort.properties.warnings) || []
    for (const f of warnungen) {
        const p = f.properties || f
        const roh = p.rawinfo || {}
        const art = GEOSPHERE_ART[Number(p.warntypid || roh.wtype)]
        if (!art)
            continue
        const ms = s => (Number(s) > 1e11 ? Number(s) : Number(s) * 1000)
        const von = ms(roh.start), bis = ms(roh.end)
        if (isNaN(von) || isNaN(bis) || !bald(von, bis, jetztMs))
            continue
        const stufe = Math.max(1, Math.min(3, Number(p.warnstufeid || roh.wlevel) || 1))
        const zahlen = (String(p.text || "").match(/\d+(?=\s*km\/h)/g) || []).map(Number)
        liste.push({ typ: art[0], stufe: stufe, titel: art[1], kmh: zahlen.length ? Math.max(...zahlen) : 0,
                     von: von, bis: bis, quelle: "GeoSphere", amtlich: true, info: String(p.text || "") })
    }
    return liste
}

const DWD_STUFE = { Minor: 1, Moderate: 2, Severe: 3, Extreme: 4 }

// Höchste Böe aus den Parametern einer DWD-Warnung („gusts“ = „<60 [km/h]“ oder „60-70 [km/h]“)
function dwdBoe(p) {
    const namen = String(p.PARAMETERNAME || "").split(";")
    const werte = String(p.PARAMETERVALUE || "").split(";")
    const i = namen.indexOf("gusts")
    const zahlen = i >= 0 ? (werte[i] || "").match(/\d+/g) : null
    return zahlen ? Math.max(...zahlen.map(Number)) : 0
}

// Warngruppen des DWD (EC_GROUP, bei Gewittern oft mehrere, z. B. „THUNDERSTORM;WIND;HAIL“);
// die erste passende Zeile bestimmt die Warnart. Nebel, Tauwetter, UV usw. bleiben weg.
const DWD_ART = [
    ["gewitter", ["THUNDERSTORM", "HAIL"]],
    ["wind", ["WIND", "TORNADO"]],
    ["regen", ["RAIN"]],
    ["schnee", ["SNOWFALL", "SNOWDRIFT"]],
    ["glaette", ["GLAZE", "FROST"]],
    ["hitze", ["HEAT"]]
]

function dwdArt(gruppe) {
    const g = String(gruppe || "").toUpperCase().split(/[;,\s]+/)
    const art = DWD_ART.find(a => a[1].some(x => g.indexOf(x) >= 0))
    return art ? art[0] : ""
}

// Warnungen aus der DWD-Antwort, die jetzt oder in den nächsten 24 Stunden gelten
function ausDwd(antwort, jetztMs) {
    const liste = []
    for (const f of (antwort && antwort.features) || []) {
        const p = f.properties || {}
        const typ = dwdArt(p.EC_GROUP)
        if (!typ)
            continue
        const von = Date.parse(p.ONSET), bis = p.EXPIRES ? Date.parse(p.EXPIRES) : von + 24 * 3600000
        if (!bald(von, bis, jetztMs))
            continue
        // „WINDBÖEN“ → „Windböen“, „SCHWERE STURMBÖEN“ → „Schwere Sturmböen“ (jedes Wort gross)
        const titel = String(p.EVENT || TYPEN[typNr(typ)].name).toLowerCase().replace(/(^|\s)(\S)/g, (x, a, b) => a + b.toUpperCase())
        liste.push({ typ: typ, stufe: DWD_STUFE[p.SEVERITY] || 1, titel: titel,
                     kmh: dwdBoe(p), von: von, bis: bis, quelle: "DWD", amtlich: true })
    }
    return liste
}

// Eigene Warnung aus der Vorhersage: höchste Böe der nächsten 24 Stunden und der Zeitraum, in dem
// die Böen die Warnschwelle (50 km/h) erreichen
function ausVorhersage(boeen) {
    if (!boeen || !boeen.length)
        return null
    const hoechste = boeen.reduce((a, b) => (b.kmh > a.kmh ? b : a))
    const schwelle = SCHWELLEN.find(s => hoechste.kmh >= s.kmh)
    if (!schwelle)
        return null
    const ueber = boeen.filter(b => b.kmh >= SCHWELLEN[SCHWELLEN.length - 1].kmh)
    return { typ: "wind", stufe: schwelle.stufe, titel: schwelle.titel, kmh: Math.round(hoechste.kmh),
             von: Math.min(...ueber.map(b => b.zeit)), bis: Math.max(...ueber.map(b => b.zeit)) + 3600000,
             quelle: "Vorhersage", amtlich: false }
}

// Die zu zeigende Warnung: die stärkste amtliche, sonst die eigene aus der Vorhersage.
// Liegt die eigene höher als die amtliche, hängt sie als vorhersage an der amtlichen.
function staerkste(amtliche, eigene) {
    if (amtliche && amtliche.length) {
        const a = amtliche.reduce((x, y) => (y.stufe > x.stufe ? y : x))
        return eigene && eigene.stufe > a.stufe ? Object.assign({}, a, { vorhersage: eigene }) : a
    }
    return eigene || null
}

// Alle zu zeigenden Warnungen, je Warnart eine, die stärkste zuerst (bei gleicher Stufe die frühere,
// dann nach der Reihenfolge in TYPEN). an(typ) sagt, ob die Warnart eingeschaltet ist;
// eigeneWind ist die eigene Auswertung der Vorhersage (oder null).
function alle(amtliche, eigeneWind, an) {
    const liste = []
    for (const t of TYPEN) {
        if (!an(t.typ))
            continue
        const w = staerkste((amtliche || []).filter(a => (a.typ || "wind") === t.typ), t.typ === "wind" ? eigeneWind : null)
        if (w)
            liste.push(w)
    }
    return liste.sort((a, b) => b.stufe - a.stufe || a.von - b.von || typNr(a.typ) - typNr(b.typ))
}

function zwei(n) {
    return (n < 10 ? "0" : "") + n
}

// Titel in der Anzeigesprache. Gespeichert sind die Titel auf Deutsch; MeteoSchweiz-Titel haben die Form
// „Wind, Gefahrenstufe 2“. Für DWD-Ereignisse ohne Übersetzung steht die Warnart („Wind warning“).
function titelText(w, sp) {
    // Titel im Wortlaut des Wetterdienstes (MeteoAlarm, schon in der Anzeigesprache geholt)
    if (sp !== "en" || w.original)
        return w.titel
    const m = String(w.titel).match(/^(.*), Gefahrenstufe (\d)$/)
    if (m)
        return T.t(sp, m[1]) + ", " + T.t(sp, "Gefahrenstufe") + " " + m[2]
    if (T.hat(w.titel))
        return T.t(sp, w.titel)
    return T.t(sp, "%1-Warnung", T.t(sp, TYPEN[typNr(w.typ || "wind")] ? TYPEN[typNr(w.typ || "wind")].name : "Wind"))
}

// „bis 18:00“, „heute 14:00–20:00“, „morgen 09:00–12:00“ (Ortszeit dieses Rechners)
function zeitraum(w, jetztMs, sp) {
    const tag = ms => {
        const d = new Date(ms), h = new Date(jetztMs)
        const t = Math.round((new Date(d.getFullYear(), d.getMonth(), d.getDate()) - new Date(h.getFullYear(), h.getMonth(), h.getDate())) / 86400000)
        return t === 0 ? "" : t === 1 ? T.t(sp, "morgen")
               : sp === "en" ? (d.getMonth() + 1) + "/" + d.getDate() : zwei(d.getDate()) + "." + zwei(d.getMonth() + 1) + "."
    }
    const uhr = ms => { const d = new Date(ms); return zwei(d.getHours()) + ":" + zwei(d.getMinutes()) }
    const mitTag = ms => (tag(ms) ? tag(ms) + " " : "") + uhr(ms)
    if (w.von <= jetztMs)
        return T.t(sp, "bis %1", mitTag(w.bis))
    return (tag(w.von) || T.t(sp, "heute")) + " " + uhr(w.von) + "–" + (tag(w.bis) === tag(w.von) ? "" : (tag(w.bis) || T.t(sp, "heute")) + " ") + uhr(w.bis)
}

function bisKmh(w, sp) {
    return w.kmh ? " " + T.t(sp, "bis %1 km/h", w.kmh) : ""
}

// Kurzer Text für die Karte, z. B. „Windböen bis 60 km/h · bis 18:00 · DWD“;
// weitere zeigt an, wie viele Warnungen noch im Tooltip stehen („· +2“)
function kurztext(w, jetztMs, weitere, sp) {
    return titelText(w, sp) + bisKmh(w, sp) + " · " + zeitraum(w, jetztMs, sp)
           + (w.amtlich ? " · " + w.quelle : "") + (weitere > 0 ? " · +" + weitere : "")
}

// Ausführlicher Text für den Tooltip
function langtext(w, jetztMs, sp) {
    return (w.amtlich ? T.t(sp, "Amtliche Warnung (%1)", quelleText(w, sp)) + ": " : T.t(sp, "Vorhersage") + ": ") + titelText(w, sp)
           + bisKmh(w, sp) + ", " + zeitraum(w, jetztMs, sp)
           + (w.info ? "\n" + w.info : "")
           + (w.vorhersage ? "\n" + T.t(sp, "Vorhersage") + ": " + titelText(w.vorhersage, sp) + bisKmh(w.vorhersage, sp)
                             + ", " + zeitraum(w.vorhersage, jetztMs, sp) : "")
}

// „MeteoSchweiz über MeteoAlarm (EUMETNET)“: Quellenangabe, wie MeteoAlarm sie verlangt
function quelleText(w, sp) {
    return w.ueber ? T.t(sp, "%1 über %2", w.quelle, w.ueber + " (EUMETNET)") : w.quelle
}

// Amtliche Warnseite des Wetterdienstes zum Öffnen im Browser ("" bei eigener Auswertung)
function warnSeite(w, sp) {
    if (!w || !w.amtlich)
        return ""
    switch (w.quelle) {
    case "MeteoSchweiz":
        return sp === "en" ? "https://www.meteoswiss.admin.ch/weather/hazards.html"
                           : "https://www.meteoschweiz.admin.ch/wetter/gefahren.html"
    case "GeoSphere":
        return "https://warnungen.zamg.at/wsapp/" + (sp === "en" ? "en" : "de") + "/"
    case "DWD":
        // Eine englische Fassung der Gemeinde-Warnseite gibt es nicht
        return "https://www.dwd.de/DE/wetter/warnungen_gemeinden/warnWetter_node.html"
    }
    return ""
}

// Text der Desktop-Benachrichtigung: Titel und Zeile mit Zeitraum und Quelle
function meldungTitel(w, sp) {
    return T.t(sp, ["", "Wetterwarnung (gelb)", "Wetterwarnung (orange)", "Unwetterwarnung (rot)", "Extreme Unwetterwarnung (violett)"][w.stufe])
           + ": " + titelText(w, sp)
}

function meldungText(w, jetztMs, sp) {
    return titelText(w, sp) + bisKmh(w, sp) + ", " + zeitraum(w, jetztMs, sp)
           + " (" + (w.amtlich ? quelleText(w, sp) : T.t(sp, "Vorhersage")) + ")" + (w.info ? "\n" + w.info : "")
}
