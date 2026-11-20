.pragma library

.import "sprache.js" as T

// SPDX-FileCopyrightText: 2026 R.Bruns
// SPDX-License-Identifier: GPL-3.0-or-later

// WMO-Wettercodes von Open-Meteo → Text (Deutsch oder Englisch, sp) und Symbolname

function beschreibung(code, tag, sp) {
    return T.t(sp, beschreibungDe(code, tag))
}

function beschreibungDe(code, tag) {
    switch (code) {
    case 0: return tag ? "Sonnig" : "Klar"
    case 1: return tag ? "Überwiegend sonnig" : "Überwiegend klar"
    case 2: return "Teilweise bewölkt"
    case 3: return "Bedeckt"
    case 45: case 48: return "Nebel"
    case 51: case 53: case 55: return "Nieselregen"
    case 56: case 57: return "Gefrierender Niesel"
    case 61: return "Leichter Regen"
    case 63: return "Regen"
    case 65: return "Starker Regen"
    case 66: case 67: return "Gefrierender Regen"
    case 68: return "Schneeregen"   // WMO 68: Regen und Schnee (nur von MET Norway)
    case 71: return "Leichter Schneefall"
    case 73: return "Schneefall"
    case 75: return "Starker Schneefall"
    case 77: return "Schneegriesel"
    case 80: return "Leichte Regenschauer"
    case 81: return "Regenschauer"
    case 82: return "Heftige Regenschauer"
    case 85: case 86: return "Schneeschauer"
    case 95: return "Gewitter"
    case 96: case 99: return "Gewitter mit Hagel"
    }
    return "Unbekannt"
}

function symbol(code, tag) {
    let name
    if (code === 0) name = tag ? "clear-day" : "clear-night"
    else if (code <= 2) name = tag ? "partly-day" : "partly-night"
    else if (code === 3) name = "cloudy"
    else if (code === 45 || code === 48) name = "fog"
    else if (code >= 51 && code <= 57) name = "drizzle"
    else if (code >= 61 && code <= 68) name = "rain"
    else if (code >= 80 && code <= 82) name = tag ? "showers-day" : "showers-night"
    else if ((code >= 71 && code <= 77) || code === 85 || code === 86) name = "snow"
    else if (code >= 95) name = "thunder"
    else name = "cloudy"
    return name
}

// Art des fallenden Niederschlags für die Animation ("" = keine Animation)
function niederschlag(code) {
    if (code >= 51 && code <= 57) return "niesel"
    if (code >= 61 && code <= 68) return "regen"
    if (code >= 80 && code <= 82) return "schauer"
    if ((code >= 71 && code <= 77) || code === 85 || code === 86) return "schnee"
    return ""
}

const TAGE = ["So", "Mo", "Di", "Mi", "Do", "Fr", "Sa"]
const TAGE_LANG = ["Sonntag", "Montag", "Dienstag", "Mittwoch", "Donnerstag", "Freitag", "Samstag"]

function datumAus(isoDatum) {
    const t = String(isoDatum).split("-")
    return new Date(t[0], t[1] - 1, t[2])
}

function kurzerTag(isoDatum, sp) {
    return T.t(sp, TAGE[datumAus(isoDatum).getDay()])
}

// „Montag, 27.10.“ bzw. „Monday, 10/27“
function langerTag(isoDatum, sp) {
    const d = datumAus(isoDatum), z = n => (n < 10 ? "0" : "") + n
    return T.t(sp, TAGE_LANG[d.getDay()]) + ", "
           + (sp === "en" ? (d.getMonth() + 1) + "/" + d.getDate() : z(d.getDate()) + "." + z(d.getMonth() + 1) + ".")
}

// Woher der Wind kommt: 8 Himmelsrichtungen
const RICHTUNGEN = ["N", "NO", "O", "SO", "S", "SW", "W", "NW"]
const RICHTUNGEN_LANG = ["Nord", "Nordost", "Ost", "Südost", "Süd", "Südwest", "West", "Nordwest"]

function himmelsrichtung(grad, sp, lang) {
    const i = Math.round(((grad % 360) + 360) % 360 / 45) % 8
    return T.t(sp, (lang ? RICHTUNGEN_LANG : RICHTUNGEN)[i])
}

// Farbverlauf der Temperaturbalken: kühl (cyan) → warm (orange)
const VERLAUF = [
    [0.0, [0.31, 0.78, 0.98]],
    [0.4, [0.62, 0.90, 0.45]],
    [0.7, [1.00, 0.84, 0.30]],
    [1.0, [1.00, 0.60, 0.22]]
]

function farbeBei(anteil) {
    const f = Math.max(0, Math.min(1, anteil))
    for (let i = 1; i < VERLAUF.length; i++) {
        if (f <= VERLAUF[i][0]) {
            const a = VERLAUF[i - 1], b = VERLAUF[i]
            const k = (f - a[0]) / (b[0] - a[0])
            return Qt.rgba(a[1][0] + (b[1][0] - a[1][0]) * k,
                           a[1][1] + (b[1][1] - a[1][1]) * k,
                           a[1][2] + (b[1][2] - a[1][2]) * k, 1)
        }
    }
    return Qt.rgba(1, 0.6, 0.22, 1)
}
