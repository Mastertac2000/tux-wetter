.pragma library

// SPDX-FileCopyrightText: 2026 R.Bruns
// SPDX-License-Identifier: GPL-3.0-or-later

// Mehrere Orte: gespeicherte Liste (Einstellung places, JSON) und auf Wunsch der automatisch bestimmte
// Standort als erster Eintrag ({ auto: true }).

function liste(placesJson) {
    try {
        const o = JSON.parse(placesJson || "[]")
        return Array.isArray(o) ? o.filter(x => x && x.name !== undefined && isFinite(x.lat) && isFinite(x.lon)) : []
    } catch (e) {
        return []
    }
}

function gleich(o, breite, laenge) {
    return Math.abs(o.lat - breite) < 1e-4 && Math.abs(o.lon - laenge) < 1e-4
}

// Welcher Eintrag gerade gezeigt wird; -1 = ein Ort, der nicht in der Liste steht
function index(orte, standortAn, standortAktiv, breite, laenge) {
    if (standortAn && standortAktiv)
        return 0
    const i = orte.findIndex(o => gleich(o, breite, laenge))
    return i < 0 ? -1 : i + (standortAn ? 1 : 0)
}

// Der Eintrag nach einem Schritt (+1 oder -1); von einem Ort ausserhalb der Liste geht es zum ersten
// bzw. letzten Eintrag. null, wenn es nichts umzuschalten gibt.
function naechster(eintraege, aktuell, schritt) {
    const n = eintraege.length
    if (!n || (n === 1 && aktuell === 0))
        return null
    return eintraege[aktuell < 0 ? (schritt > 0 ? 0 : n - 1) : ((aktuell + schritt) % n + n) % n]
}

// Antwort von GeoJS → { name, lat, lon } (auf 4 Stellen gerundet) oder null
function ausGeoJs(d, ersatzName) {
    const b = Math.round(+d.latitude * 10000) / 10000, l = Math.round(+d.longitude * 10000) / 10000
    if (!isFinite(b) || !isFinite(l) || (b === 0 && l === 0) || d.latitude === undefined || d.longitude === undefined)
        return null
    return { name: d.city || d.region || ersatzName, lat: b, lon: l }
}

// Ungefähre Entfernung in km (für kleine Abstände genau genug)
function km(b1, l1, b2, l2) {
    return Math.hypot((b2 - b1) * 111.2, (l2 - l1) * 111.2 * Math.cos((b1 + b2) / 2 * Math.PI / 180))
}
