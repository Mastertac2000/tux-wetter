.pragma library

// SPDX-FileCopyrightText: 2026 R.Bruns
// SPDX-License-Identifier: GPL-3.0-or-later

// Echte Messwerte der nächsten Wetterstation statt des Modellwerts (die Modelle liegen oft 1–2 °C daneben):
//  - Schweiz: MeteoSchweiz (offene Daten). Die nächste Station sucht das Widget einmal in der Datei mit
//    allen Stationen (rund 170 KB); danach holt es nur noch die Datei dieser Station (rund 14 KB).
//  - Österreich: GeoSphere Austria, Stationsnetz TAWES (10-Minuten-Werte, offene Daten)
//  - Deutschland: DWD-Stationen über Bright Sky (api.brightsky.dev)
// Liegt ein Ort in mehreren Gebieten (z. B. am Bodensee), gilt die erste passende Station in der
// Reihenfolge Schweiz, Österreich, Deutschland.
// Genommen wird die nächste Station bis 25 km, deren Höhe höchstens 300 m vom Ort abweicht, und nur
// Werte, die höchstens 75 Minuten alt sind.
// Ergebnis: { temp, station, km, zeit (ms), quelle } oder null

const MAX_KM = 25
const MAX_HOEHE = 300
const MAX_ALTER = 75 * 60000

const SCHWEIZ = [45.8, 47.85, 5.9, 10.5]
const DEUTSCHLAND = [47.2, 55.1, 5.8, 15.1]
const OESTERREICH = [46.3, 49.1, 9.5, 17.2]

function inBox(b, breite, laenge) {
    return breite >= b[0] && breite <= b[1] && laenge >= b[2] && laenge <= b[3]
}

const METEOSCHWEIZ_ADRESSE = "https://data.geo.admin.ch/ch.meteoschweiz.messwerte-lufttemperatur-10min/"
                             + "ch.meteoschweiz.messwerte-lufttemperatur-10min_de.json"

function brightSkyAdresse(breite, laenge) {
    return "https://api.brightsky.dev/current_weather?lat=" + breite + "&lon=" + laenge + "&max_dist=" + MAX_KM * 1000
}

// WGS84 → Schweizer Landeskoordinaten LV95 (Näherungsformeln von swisstopo, auf etwa 1 m genau)
function lv95(breite, laenge) {
    const p = (breite * 3600 - 169028.66) / 10000, l = (laenge * 3600 - 26782.5) / 10000
    return [2600072.37 + 211455.93 * l - 10938.51 * l * p - 0.36 * l * p * p - 44.54 * l * l * l,
            1200147.07 + 308807.95 * p + 3745.25 * l * l + 76.63 * p * p - 194.56 * l * l * p + 119.79 * p * p * p]
}

// Entfernung zweier Punkte in km (für Abstände bis einige 100 km genau genug)
function km(b1, l1, b2, l2) {
    return Math.hypot((b2 - b1) * 111.2, (l2 - l1) * 111.2 * Math.cos((b1 + b2) / 2 * Math.PI / 180))
}

// „ACHENKIRCH CAMPINGPLATZ“ → „Achenkirch Campingplatz“, „MUENCHEN-STADT“ → „Muenchen-Stadt“
function lesbar(name) {
    return String(name || "").toLowerCase().replace(/(^|[\s\-(\/])(\S)/g, (x, a, b) => a + b.toUpperCase())
}

function hoeheOk(stationHoehe, hoehe) {
    return hoehe === null || hoehe === undefined || isNaN(stationHoehe) || Math.abs(stationHoehe - hoehe) <= MAX_HOEHE
}

function ausMeteoSchweiz(d, breite, laenge, hoehe, jetztMs) {
    const [e, n] = lv95(breite, laenge)
    let beste = null
    for (const f of (d && d.features) || []) {
        const p = f.properties || {}, c = f.geometry && f.geometry.coordinates
        if (!c || p.value === null || p.value === undefined || isNaN(p.value))
            continue
        const km = Math.hypot(c[0] - e, c[1] - n) / 1000
        const zeit = Date.parse(p.reference_ts)
        if (km > MAX_KM || !hoeheOk(parseFloat(p.altitude), hoehe) || !(jetztMs - zeit <= MAX_ALTER))
            continue
        if (!beste || km < beste.km)
            beste = { temp: +p.value, station: p.station_name, km: km, zeit: zeit, quelle: "MeteoSchweiz", id: String(f.id || "") }
    }
    return beste
}

// Datei einer einzelnen Station (Kürzel wie "LUZ"): Messwerte der letzten Stunden, Zeiten in UTC
function meteoSchweizStationAdresse(id) {
    const k = String(id).toLowerCase()
    return "https://data.geo.admin.ch/ch.meteoschweiz.ogd-smn/" + k + "/ogd-smn_" + k + "_t_now.csv"
}

// Letzter Wert der Lufttemperatur (Spalte tre200s0) aus der Stationsdatei; station: wie von ausMeteoSchweiz.
// Die jüngste Zeile ist oft noch leer, dann gilt die davor.
function ausMeteoSchweizStation(text, station, jetztMs) {
    const zeilen = String(text || "").split(/\r?\n/).filter(z => z.trim()).map(z => z.split(";"))
    if (zeilen.length < 2)
        return null
    const spalte = zeilen[0].indexOf("tre200s0"), zeitSpalte = zeilen[0].indexOf("reference_timestamp")
    if (spalte < 0 || zeitSpalte < 0)
        return null
    for (let i = zeilen.length - 1; i > 0; i--) {
        const w = (zeilen[i][spalte] || "").trim()
        if (w === "" || isNaN(w))
            continue
        // "25.10.2026 17:50" (UTC)
        const m = String(zeilen[i][zeitSpalte]).match(/(\d{2})\.(\d{2})\.(\d{4}) (\d{2}):(\d{2})/)
        const zeit = m ? Date.UTC(+m[3], +m[2] - 1, +m[1], +m[4], +m[5]) : NaN
        if (!(jetztMs - zeit <= MAX_ALTER))
            return null
        return { temp: +w, station: station.station, km: station.km, zeit: zeit, quelle: "MeteoSchweiz", id: station.id }
    }
    return null
}

function ausBrightSky(d, hoehe, jetztMs) {
    const w = d && d.weather
    if (!w || w.temperature === null || w.temperature === undefined)
        return null
    const s = (d.sources || []).find(x => x.id === w.source_id) || (d.sources || [])[0] || {}
    const zeit = Date.parse(w.timestamp)
    if (!hoeheOk(s.height, hoehe) || !(jetztMs - zeit <= MAX_ALTER) || (s.distance || 0) > MAX_KM * 1000)
        return null
    return { temp: w.temperature, station: lesbar(s.station_name), km: (s.distance || 0) / 1000, zeit: zeit, quelle: "DWD" }
}

// ── Österreich: zuerst die Stationsliste (einmal je Sitzung), dann die Werte der nächsten Stationen ──
const GEOSPHERE_STATIONEN = "https://dataset.api.hub.geosphere.at/v1/station/current/tawes-v1-10min/metadata"

// Die bis zu 3 nächsten aktiven Stationen, die Entfernung und Höhe erfüllen: [{ id, name, km }]
function geoSphereKandidaten(meta, breite, laenge, hoehe) {
    return ((meta && meta.stations) || [])
        .filter(s => s.is_active !== false && isFinite(s.lat) && isFinite(s.lon) && hoeheOk(s.altitude, hoehe))
        .map(s => ({ id: String(s.id), name: lesbar(s.name), km: km(breite, laenge, s.lat, s.lon) }))
        .filter(s => s.km <= MAX_KM)
        .sort((a, b) => a.km - b.km)
        .slice(0, 3)
}

function geoSphereAdresse(kandidaten) {
    return "https://dataset.api.hub.geosphere.at/v1/station/current/tawes-v1-10min?parameters=TL&station_ids="
           + kandidaten.map(k => k.id).join(",")
}

// Die nächste Station mit einem aktuellen Wert. Melden die Stationen zu verschiedenen Zeiten, liefert
// GeoSphere mehrere Zeitpunkte (timestamps) und je Station eine Werteliste dazu, in der nur bei ihrem
// Zeitpunkt etwas steht; es gilt je Station der letzte vorhandene Wert.
function ausGeoSphereMessung(d, kandidaten, jetztMs) {
    const zeiten = ((d && d.timestamps) || []).map(z => Date.parse(z))
    const werte = {}
    for (const f of (d && d.features) || []) {
        const tl = f.properties && f.properties.parameters && f.properties.parameters.TL
        const reihe = (tl && tl.data) || []
        for (let i = reihe.length - 1; i >= 0; i--) {
            if (reihe[i] !== null && reihe[i] !== undefined && !isNaN(reihe[i]) && jetztMs - zeiten[i] <= MAX_ALTER) {
                werte[String(f.properties.station)] = { temp: reihe[i], zeit: zeiten[i] }
                break
            }
        }
    }
    const k = kandidaten.find(x => werte[x.id] !== undefined)
    return k ? { temp: werte[k.id].temp, station: k.name, km: k.km, zeit: werte[k.id].zeit, quelle: "GeoSphere" } : null
}
