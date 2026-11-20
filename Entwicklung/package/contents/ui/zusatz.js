.pragma library

.import "sprache.js" as T

// SPDX-FileCopyrightText: 2026 R.Bruns
// SPDX-License-Identifier: GPL-3.0-or-later

// Zusatzdaten, unabhängig vom gewählten Wetteranbieter:
//  - Open-Meteo: Niederschlag der nächsten 2 Stunden in 15-Minuten-Schritten, UV-Index von heute,
//    Sonnenzeiten, Höhe und Zeitzone des Orts
//  - Open-Meteo: Luftqualität (Europäischer Luftqualitätsindex) und Pollen (nur Europa)
//  - MET Norway: Mondauf- und -untergang und Mondphase

function regenAdresse(breite, laenge) {
    return "https://api.open-meteo.com/v1/forecast?latitude=" + breite + "&longitude=" + laenge
           + "&minutely_15=precipitation&past_minutely_15=1&forecast_minutely_15=9"
           + "&daily=uv_index_max,sunrise,sunset&forecast_days=1&timezone=auto"
}

const POLLEN = [
    // Grenzen für gering, mässig, stark, sehr stark in Pollen/m³ (angelehnt an MeteoSchweiz)
    { feld: "birch_pollen", name: "Birke", grenzen: [1, 11, 70, 300] },
    { feld: "grass_pollen", name: "Gräser", grenzen: [1, 20, 50, 150] },
    { feld: "alder_pollen", name: "Erle", grenzen: [1, 11, 70, 250] },
    { feld: "mugwort_pollen", name: "Beifuss", grenzen: [1, 6, 15, 50] },
    { feld: "ragweed_pollen", name: "Ambrosia", grenzen: [1, 6, 11, 40] },
    { feld: "olive_pollen", name: "Olive", grenzen: [1, 11, 70, 300] }
]

function luftAdresse(breite, laenge) {
    return "https://air-quality-api.open-meteo.com/v1/air-quality?latitude=" + breite + "&longitude=" + laenge
           + "&current=european_aqi," + POLLEN.map(p => p.feld).join(",") + "&timezone=auto"
}

// Open-Meteo liefert Ortszeiten ohne Versatz; utc_offset_seconds rechnet sie in echte Zeitpunkte um.
// Liegt der Ort in der Zeitzone dieses Rechners, rechnet die Systemzeit (mit Zeitumstellung).
function wieSystemzeit(versatzSek) {
    return -new Date().getTimezoneOffset() * 60 === (versatzSek || 0)
}

function zeitpunkt(text, versatzSek) {
    const s = String(text)
    if (wieSystemzeit(versatzSek))
        return new Date(+s.substring(0, 4), +s.substring(5, 7) - 1, +s.substring(8, 10), +s.substring(11, 13), +s.substring(14, 16)).getTime()
    return Date.UTC(+s.substring(0, 4), +s.substring(5, 7) - 1, +s.substring(8, 10),
                    +s.substring(11, 13), +s.substring(14, 16)) - (versatzSek || 0) * 1000
}

// → { regen: [{ zeit (ms, Beginn der Viertelstunde), mm, versatz (s, Zeitzone des Orts) }], uv,
//     versatz, hoehe (m, null = unbekannt), datum ("JJJJ-MM-TT" am Ort), sonnenAuf, sonnenUnter }
function ausRegen(d) {
    const m = d.minutely_15 || {}
    const regen = []
    for (let i = 0; i < (m.time || []).length; i++)
        if (m.precipitation[i] !== null && m.precipitation[i] !== undefined)
            // versatz nur bei fremder Zeitzone; sonst zeigt uhr() die Systemzeit
            regen.push({ zeit: zeitpunkt(m.time[i], d.utc_offset_seconds), mm: m.precipitation[i],
                         versatz: wieSystemzeit(d.utc_offset_seconds) ? undefined : d.utc_offset_seconds || 0 })
    const t = d.daily || {}
    const uv = t.uv_index_max ? t.uv_index_max[0] : null
    const uhr = s => (s ? String(s).substring(11, 16) : "")
    return { regen: regen, uv: uv === undefined ? null : uv, versatz: d.utc_offset_seconds || 0,
             hoehe: d.elevation === undefined || d.elevation === null || isNaN(d.elevation) ? null : d.elevation,
             datum: t.time ? t.time[0] : "", sonnenAuf: t.sunrise ? uhr(t.sunrise[0]) : "", sonnenUnter: t.sunset ? uhr(t.sunset[0]) : "" }
}

// → { eaqi (null = unbekannt), pollen: [{ name, wert, stufe }] oder null ausserhalb Europas }
function ausLuft(d) {
    const c = d.current || {}
    const da = POLLEN.filter(p => c[p.feld] !== null && c[p.feld] !== undefined)
    return {
        eaqi: c.european_aqi === null || c.european_aqi === undefined ? null : c.european_aqi,
        pollen: da.length ? da.map(p => ({ name: p.name, wert: c[p.feld], stufe: pollenStufe(p, c[p.feld]) })) : null
    }
}

function pollenStufe(p, wert) {
    let stufe = 0
    p.grenzen.forEach((g, i) => { if (wert >= g) stufe = i + 1 })
    return stufe
}

const STUFEN = ["keine", "gering", "mässig", "stark", "sehr stark"]

// Stärke der stärksten Pollenart, z. B. „mässig“ (welche Art, steht im Tooltip), oder „keine“
function pollenKurz(pollen, sp) {
    if (!pollen)
        return ""
    return T.t(sp, STUFEN[Math.max(...pollen.map(p => p.stufe))])
}

function pollenLang(pollen, sp) {
    return pollen.map(p => T.t(sp, p.name) + ": " + T.t(sp, STUFEN[p.stufe]) + " (" + Math.round(p.wert) + " " + T.t(sp, "Pollen/m³") + ")").join("\n")
}

// Europäischer Luftqualitätsindex: 0–20 gut … über 100 extrem schlecht
function luftStufe(eaqi) {
    return eaqi < 20 ? 0 : eaqi < 40 ? 1 : eaqi < 60 ? 2 : eaqi < 80 ? 3 : eaqi < 100 ? 4 : 5
}
const LUFT = ["gut", "recht gut", "mässig", "schlecht", "sehr schlecht", "extrem schlecht"]

function luftText(eaqi, sp) {
    return T.t(sp, LUFT[luftStufe(eaqi)])
}

// UV-Index nach WHO: 0–2 niedrig, 3–5 mässig, 6–7 hoch, 8–10 sehr hoch, ab 11 extrem
function uvText(uv, sp) {
    const u = Math.round(uv)
    return T.t(sp, u < 3 ? "niedrig" : u < 6 ? "mässig" : u < 8 ? "hoch" : u < 11 ? "sehr hoch" : "extrem")
}

// Ab 0,1 mm in der Viertelstunde gilt es als Regen
const NASS = 0.1

// Die Viertelstunden ab jetzt (höchstens 8 = 2 Stunden)
function naechsteZwei(regen, jetztMs) {
    return (regen || []).filter(r => r.zeit + 15 * 60000 > jetztMs).slice(0, 8)
}

// Uhrzeit am Ort (wie Stundenwerte und Sonnenzeiten); ohne Versatz die Zeit dieses Rechners
function uhr(r, ms) {
    const z = n => (n < 10 ? "0" : "") + n
    if (r.versatz === undefined) {
        const d = new Date(ms)
        return z(d.getHours()) + ":" + z(d.getMinutes())
    }
    const d = new Date(ms + r.versatz * 1000)
    return z(d.getUTCHours()) + ":" + z(d.getUTCMinutes())
}

// „Regen ab 14:15“, „Regen bis 13:30“, „Kein Regen bis 15:00“ oder "" ohne Daten
function regenText(regen, jetztMs, sp) {
    const v = naechsteZwei(regen, jetztMs)
    if (!v.length)
        return ""
    if (v[0].mm >= NASS) {
        const trocken = v.findIndex(r => r.mm < NASS)
        return trocken < 0 ? T.t(sp, "Regen noch über 2 Std.") : T.t(sp, "Regen bis %1", uhr(v[0], v[trocken].zeit))
    }
    const nass = v.findIndex(r => r.mm >= NASS)
    return nass < 0 ? T.t(sp, "Kein Regen bis %1", uhr(v[0], v[v.length - 1].zeit + 15 * 60000))
                    : T.t(sp, "Regen ab %1", uhr(v[0], v[nass].zeit))
}

// Nur der Wert für die Infozeile (Beschriftung „Regen:“ steht davor): „ab 14:15“, „bis 13:30“,
// „noch über 2 Std.“, „keiner bis 15:00“ oder "" ohne Daten
function regenKurz(regen, jetztMs, sp) {
    const v = naechsteZwei(regen, jetztMs)
    if (!v.length)
        return ""
    if (v[0].mm >= NASS) {
        const trocken = v.findIndex(r => r.mm < NASS)
        return trocken < 0 ? T.t(sp, "noch über 2 Std.") : T.t(sp, "bis %1", uhr(v[0], v[trocken].zeit))
    }
    const nass = v.findIndex(r => r.mm >= NASS)
    return nass < 0 ? T.t(sp, "keiner bis %1", uhr(v[0], v[v.length - 1].zeit + 15 * 60000))
                    : T.t(sp, "ab %1", uhr(v[0], v[nass].zeit))
}

// Für den Tooltip: jede Viertelstunde mit Menge
function regenLang(regen, jetztMs, sp) {
    return naechsteZwei(regen, jetztMs).map(r => uhr(r, r.zeit) + "  " + (r.mm >= NASS ? r.mm.toFixed(1) + " mm" : "–")).join("\n")
           + "\n" + T.t(sp, "Niederschlag je Viertelstunde (Open-Meteo)")
}

// ── Mond (MET Norway) ──
// MET verlangt eine Kennung des Programms (siehe A.KENNUNG); versatz: Zeitzone des Orts in Sekunden
function mondAdresse(breite, laenge, datum, versatz) {
    const v = Math.abs(versatz), z = n => (n < 10 ? "0" : "") + n
    return "https://api.met.no/weatherapi/sunrise/3.0/moon?lat=" + (+breite).toFixed(4) + "&lon=" + (+laenge).toFixed(4)
           + "&date=" + datum + "&offset=" + (versatz < 0 ? "-" : "%2B") + z(Math.floor(v / 3600)) + ":" + z(Math.floor(v % 3600 / 60))
}

// → { auf, unter ("HH:MM" oder "" an Tagen ohne), phase (Grad: 0 Neumond, 90 erstes Viertel, 180 Vollmond, 270 letztes Viertel) }
function ausMond(d) {
    const p = d.properties || {}
    const uhr = x => (x && x.time ? String(x.time).substring(11, 16) : "")
    return { auf: uhr(p.moonrise), unter: uhr(p.moonset), phase: p.moonphase === undefined ? null : p.moonphase }
}

// Beleuchteter Anteil der Mondscheibe in % (0 bei Neumond, 100 bei Vollmond)
function mondLicht(phase) {
    return Math.round((1 - Math.cos(phase * Math.PI / 180)) / 2 * 100)
}

function mondName(phase, sp) {
    const p = ((phase % 360) + 360) % 360
    const name = p < 10 || p >= 350 ? "Neumond" : p < 80 ? "Zunehmende Sichel" : p < 100 ? "Erstes Viertel"
               : p < 170 ? "Zunehmender Mond" : p < 190 ? "Vollmond" : p < 260 ? "Abnehmender Mond"
               : p < 280 ? "Letztes Viertel" : "Abnehmende Sichel"
    return T.t(sp, name)
}
