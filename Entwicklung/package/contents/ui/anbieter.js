.pragma library

.import "wetter.js" as W
.import "sprache.js" as T

// SPDX-FileCopyrightText: 2026 R.Bruns
// SPDX-License-Identifier: GPL-3.0-or-later

// Wetteranbieter: baut die Abfrage-Adressen und rechnet jede Antwort in ein gemeinsames Format um,
// damit die Anzeige nicht wissen muss, woher die Daten stammen. Wettercodes werden dabei in
// WMO-Codes (wie bei Open-Meteo) übersetzt, Wind in km/h, Wahrscheinlichkeiten in %.
//
// Gemeinsames Format:
//   { temperatur, gefuehlt, code, tag, wind, windRichtung, boeen, feuchte, niederschlag, heuteMax, heuteMin,
//     heuteDatum, heuteAb, sonnenAuf, sonnenUnter, uv,
//     stunden: [{ zeit, temp, code, tag }] (6 Einträge),
//     tage: [{ name, datum, code, min, max, regen, menge, schnee, stunden: [{ zeit, temp, code, tag }],
//              verlauf: [{ h, temp }] }] (bis 5) }
// heuteAb: Stunde, ab der heuteMax/heuteMin gelten (0 = ganzer Tag); heuteDatum: "JJJJ-MM-TT" am Ort
// boeen: Windböen jetzt und für die nächsten 24 Stunden: [{ zeit (ms seit 1970), kmh }]
// windRichtung: woher der Wind kommt, in Grad (0 = Nord, 90 = Ost), null = unbekannt
// sonnenAuf/sonnenUnter: Ortszeit "HH:MM" ("" = unbekannt); uv: höchster UV-Index heute (null = unbekannt)
// tage[].stunden: Stundenwerte des Tages alle 3 Stunden von 6 bis 21 Uhr (soweit vorhanden)
// tage[].regen: Regenwahrscheinlichkeit in % (null = unbekannt); menge: Niederschlag in mm; schnee: Neuschnee
//   in cm (null = unbekannt); verlauf: Temperatur über den Tag für die Kurve (h = Stunde 0–23 in Ortszeit)
// niederschlag: Regenwahrscheinlichkeit heute in %, -1 = unbekannt (MET Norway)

const ANBIETER = [
    { id: "openmeteo", name: "Open-Meteo", schluessel: false, seite: "https://open-meteo.com" },
    { id: "metno", name: "MET Norway (yr.no)", schluessel: false, seite: "https://api.met.no" },
    { id: "dwd", name: "Deutscher Wetterdienst (MOSMIX)", schluessel: false, seite: "https://brightsky.dev" },
    { id: "openweathermap", name: "OpenWeatherMap", schluessel: true, seite: "https://home.openweathermap.org/users/sign_up" },
    { id: "weatherapi", name: "WeatherAPI.com", schluessel: true, seite: "https://www.weatherapi.com/signup.aspx" }
]

// ── Quellenangaben ──
// Die Anbieter verlangen eine sichtbare Nennung dort, wo ihre Daten erscheinen (Open-Meteo: Link neben den
// Daten; OpenWeather: genau „Weather data provided by OpenWeather“; WeatherAPI.com: Name als Quelle; CC BY 4.0:
// Name, Link zur Lizenz, Hinweis auf Änderungen). Der DWD verlangt bei aufbereiteten Daten „Datenbasis:“.
const LIZENZEN = {
    "CC BY 4.0": "https://creativecommons.org/licenses/by/4.0/",
    "CC BY-SA 4.0": "https://creativecommons.org/licenses/by-sa/4.0/"
}
const QUELLEN = {
    openmeteo: { vorlage: "Daten: %1", name: "Open-Meteo.com", url: "https://open-meteo.com/", lizenz: "CC BY 4.0" },
    metno: { vorlage: "Daten: %1", name: "MET Norway", url: "https://www.met.no/en", lizenz: "CC BY 4.0" },
    dwd: { vorlage: "Datenbasis: %1", name: "Deutscher Wetterdienst", url: "https://www.dwd.de/", lizenz: "CC BY 4.0" },
    // Wortlaut von OpenWeather vorgegeben, darum in beiden Sprachen englisch
    openweathermap: { vorlage: "Weather data provided by %1", name: "OpenWeather", url: "https://openweathermap.org/", lizenz: "CC BY-SA 4.0" },
    weatherapi: { vorlage: "Daten: %1", name: "WeatherAPI.com", url: "https://www.weatherapi.com/", lizenz: "" }
}

function verweis(name, url) {
    return '<a href="' + url + '">' + name + '</a>'
}

function lizenzVerweis(lizenz) {
    return LIZENZEN[lizenz] ? verweis(lizenz, LIZENZEN[lizenz]) : lizenz
}

// Kurze Zeile für die Karte (StyledText mit Links): Wetteranbieter und Open-Meteo, das für alle Anbieter
// Regen, UV, Luft, Sonnenzeiten und Zeitzone liefert
function quellenZeile(anbieter, sp) {
    const q = QUELLEN[anbieter] || QUELLEN.openmeteo
    const om = QUELLEN.openmeteo
    return (q.vorlage.indexOf("Weather data") === 0 ? q.vorlage.replace("%1", verweis(q.name, q.url))
                                                    : T.t(sp, q.vorlage, verweis(q.name, q.url)))
           + (anbieter !== "openmeteo" && QUELLEN[anbieter] ? " · " + verweis(om.name, om.url) : "")
}

// Alle Quellen mit Lizenz (StyledText, Zeilen mit <br>), für den Tooltip und die Einstellungen
function quellenListe(anbieter, sp, mitLinks) {
    const q = QUELLEN[anbieter] || QUELLEN.openmeteo
    const v = (name, url) => mitLinks ? verweis(name, url) : name
    const l = lizenz => mitLinks ? lizenzVerweis(lizenz) : lizenz
    const cc = l("CC BY 4.0")
    return [
        T.t(sp, "Wetterdaten: %1", v(q.name, q.url) + (anbieter === "dwd" ? " " + T.t(sp, "über %1", v("Bright Sky", "https://brightsky.dev/")) : "")
                                    + (q.lizenz ? " (" + l(q.lizenz) + ")" : "")),
        T.t(sp, "Ortssuche, Regen, UV, Sonnenzeiten: %1", v("Open-Meteo.com", "https://open-meteo.com/") + " (" + cc + ")"),
        T.t(sp, "Ortsnamen der Suche: %1", v("GeoNames", "https://www.geonames.org/") + " (" + cc + ")"),
        // Copernicus verlangt diesen Vermerk mit Jahr; die Werte sind von Open-Meteo zu Stufen aufbereitet
        T.t(sp, "Luft und Pollen: %1", v("Open-Meteo.com", "https://open-meteo.com/") + " (" + cc + "). "
            + T.t(sp, "Enthält veränderte Informationen des %1 %2.", v("Copernicus Atmosphere Monitoring Service", "https://atmosphere.copernicus.eu/"),
                  new Date().getFullYear()) + " "
            + T.t(sp, "Weder die Europäische Kommission noch das ECMWF sind für die Verwendung dieser Informationen verantwortlich.")),
        T.t(sp, "Mond: %1", v("MET Norway", "https://www.met.no/en") + " (" + cc + ")"),
        T.t(sp, "Messwerte: %1", v("MeteoSchweiz", "https://www.meteoschweiz.admin.ch/") + " (" + cc + "), "
            + v("GeoSphere Austria", "https://data.hub.geosphere.at/") + " (" + cc + "), "
            + T.t(sp, "Datenbasis: %1", v("Deutscher Wetterdienst", "https://www.dwd.de/")) + " " + T.t(sp, "über %1", "Bright Sky") + " (" + cc + ")"),
        T.t(sp, "Warnungen: %1", v("GeoSphere Austria", "https://warnungen.zamg.at/") + " (" + cc + "), "
            + v("Deutscher Wetterdienst", "https://www.dwd.de/") + " (" + cc + "), "
            + T.t(sp, "%1 über %2", v("MeteoSchweiz", "https://www.meteoschweiz.admin.ch/"), v("EUMETNET – MeteoAlarm", "https://www.meteoalarm.org/")) + " (" + cc + ")"),
        T.t(sp, "Ortsprüfung: %1 · Standort: %2", "© " + v("swisstopo", "https://www.swisstopo.admin.ch/"), v("GeoJS", "https://www.geojs.io/")),
        T.t(sp, "Die Daten werden vom Widget aufbereitet: umgerechnet, zusammengefasst und zum Teil daraus berechnet (z. B. Tageswerte, gefühlte Temperatur).")
    ].join("<br>")
}

// Wettermodelle, die Open-Meteo anbietet
const MODELLE = [
    { id: "best_match", name: "Automatisch (bestes Modell für den Ort)" },
    { id: "meteoswiss_icon_ch2", name: "MeteoSchweiz ICON-CH2 (Alpenraum, 4–5 Tage)" },
    { id: "icon_seamless", name: "Deutscher Wetterdienst ICON" },
    { id: "ecmwf_ifs025", name: "ECMWF IFS (Europäisches Zentrum)" },
    { id: "gfs_seamless", name: "NOAA GFS (USA)" },
    { id: "meteofrance_seamless", name: "Météo-France (3–4 Tage, ohne Regenwahrscheinlichkeit)" }
]

function anbieterName(id) {
    const a = ANBIETER.find(x => x.id === id)
    return a ? a.name : ANBIETER[0].name
}

function brauchtSchluessel(id) {
    const a = ANBIETER.find(x => x.id === id)
    return a ? a.schluessel : false
}

// MET Norway verlangt eine Kennung des Programms (ohne antwortet der Dienst mit 403) und wünscht darin
// eine Kontaktmöglichkeit, damit es bei Problemen nachfragen kann statt zu sperren
const KONTAKT = ""
const KENNUNG = "TuxWetter/1.6 (KDE Plasma widget" + (KONTAKT ? "; " + KONTAKT : "") + ")"

// Liste der abzufragenden Adressen; manche Anbieter brauchen mehrere Abfragen. Ein Eintrag ist eine
// Adresse oder { url, kopf } mit zusätzlichen Kopfzeilen.
function adressen(anbieter, modell, breite, laenge, schluessel) {
    const k = encodeURIComponent(schluessel)
    switch (anbieter) {
    case "metno":
        // Dazu bei Open-Meteo die Zeitzone des Orts sowie Sonnenauf- und -untergang (MET liefert nur UTC)
        return [{ url: "https://api.met.no/weatherapi/locationforecast/2.0/complete?lat=" + (+breite).toFixed(4)
                       + "&lon=" + (+laenge).toFixed(4), kopf: { "User-Agent": KENNUNG } },
                "https://api.open-meteo.com/v1/forecast?latitude=" + breite + "&longitude=" + laenge
                + "&daily=sunrise,sunset&timezone=auto&forecast_days=1"]
    case "dwd": {
        // DWD-Stationsvorhersage MOSMIX über Bright Sky (freie DWD-Daten als JSON); Zeiten in UTC, ab der
        // letzten vollen Stunde gut 7 Tage. Dazu wie bei MET Norway Zeitzone und Sonnenzeiten von Open-Meteo.
        const ab = new Date(Math.floor(Date.now() / 3600000) * 3600000 - 3600000)
        const bis = new Date(ab.getTime() + 8 * 86400000)
        return ["https://api.brightsky.dev/weather?lat=" + (+breite).toFixed(4) + "&lon=" + (+laenge).toFixed(4)
                + "&date=" + ab.toISOString().substring(0, 16) + "Z&last_date=" + bis.toISOString().substring(0, 10),
                "https://api.open-meteo.com/v1/forecast?latitude=" + breite + "&longitude=" + laenge
                + "&daily=sunrise,sunset&timezone=auto&forecast_days=1"]
    }
    case "openweathermap": {
        const basis = "https://api.openweathermap.org/data/2.5/"
        const rest = "?lat=" + breite + "&lon=" + laenge + "&units=metric&lang=de&appid=" + k
        return [basis + "weather" + rest, basis + "forecast" + rest]
    }
    case "weatherapi":
        return ["https://api.weatherapi.com/v1/forecast.json?key=" + k + "&q=" + breite + "," + laenge
                + "&days=6&aqi=no&alerts=no&lang=de"]
    }
    return ["https://api.open-meteo.com/v1/forecast"
            + "?latitude=" + breite + "&longitude=" + laenge
            + "&current=temperature_2m,weather_code,wind_speed_10m,wind_gusts_10m,is_day,relative_humidity_2m,"
            + "apparent_temperature,wind_direction_10m"
            + "&hourly=temperature_2m,weather_code,is_day,wind_gusts_10m"
            + "&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max,"
            + "sunrise,sunset,uv_index_max,precipitation_sum,snowfall_sum"
            + "&timezone=auto&forecast_days=7"
            + (modell && modell !== "best_match" ? "&models=" + modell : "")]
}

// Verständliche Meldung zu einer fehlgeschlagenen Abfrage
function fehlerText(anbieter, status, antwort, sp) {
    if (!status)
        return T.t(sp, "Keine Wetterdaten (keine Verbindung)")
    let grund = ""
    try {
        const d = JSON.parse(antwort)
        // Nur der erste Satz; OpenWeatherMap hängt einen Verweis auf seine Hilfeseite an
        grund = String(d.reason || d.message || (d.error && d.error.message) || d.detail || "").split(". ")[0]
    } catch (e) {}
    // Bright Sky: keine Vorhersagestation des DWD im Umkreis von 50 km
    if (anbieter === "dwd" && status === 404)
        return T.t(sp, "Keine Vorhersagestation des DWD in der Nähe (bis 50 km). Bitte einen anderen Wetteranbieter wählen.")
    // Open-Meteo: das gewählte Modell rechnet für diesen Ort nicht (z. B. ICON-CH2 ausserhalb des Alpenraums)
    if (status === 400 && /no data is available for this location/i.test(grund))
        return T.t(sp, "Das gewählte Wettermodell deckt diesen Ort nicht ab. Bitte in den Einstellungen ein anderes Modell wählen.")
    if (status === 401)
        return T.t(sp, "API-Schlüssel für %1 ungültig oder noch nicht freigeschaltet", anbieterName(anbieter))
    // 403 heisst z.B. bei WeatherAPI.com auch „Kontingent aufgebraucht“; dann die Meldung des Anbieters zeigen
    if (status === 403)
        return T.t(sp, "%1 verweigert die Abfrage", anbieterName(anbieter)) + (grund ? ": " + grund : " " + T.t(sp, "(Schlüssel gesperrt?)"))
    return T.t(sp, "Keine Wetterdaten (Fehler %1)", status + (grund ? ": " + grund : ""))
}

// antworten: die gelesenen JSON-Antworten in der Reihenfolge von adressen()
function auswerten(anbieter, antworten) {
    switch (anbieter) {
    case "openweathermap": return ausOpenWeatherMap(antworten[0], antworten[1])
    case "weatherapi": return ausWeatherApi(antworten[0])
    case "metno": return ausMetNorway(antworten[0], antworten[1])
    case "dwd": return ausDwd(antworten[0], antworten[1])
    }
    return ausOpenMeteo(antworten[0])
}

function gerundet(wert) {
    return Math.round(wert || 0)
}

function oderNull(wert) {
    return wert === undefined || wert === null || isNaN(wert) ? null : wert
}

// Die Stunden, die die Tagesdetails zeigen
const TAGES_STUNDEN = [6, 9, 12, 15, 18, 21]

// Hat dieser Rechner jetzt denselben Zeitzonen-Versatz wie der Ort (Sekunden)? Dann liegt der Ort sehr
// wahrscheinlich in derselben Zeitzone, und die Systemzeit kennt auch die Zeitumstellungen.
function wieSystemzeit(versatzSek) {
    return -new Date().getTimezoneOffset() * 60 === versatzSek
}

// Böen der nächsten 24 Stunden ab jetzt (Liste [{ zeit, kmh }], ohne fehlende Werte)
function naechste24(liste, jetztMs) {
    return liste.filter(b => b.kmh !== null && b.kmh !== undefined && !isNaN(b.kmh)
                             && b.zeit >= jetztMs - 3600000 && b.zeit <= jetztMs + 24 * 3600000)
}

// ── Open-Meteo ──
// Einzelne Modelle reichen nicht immer 7 Tage weit; fehlende Werte kommen dann als null

function ausOpenMeteo(d) {
    const c = d.current
    const h = d.hourly
    const t = d.daily

    let start = h.time.indexOf(c.time.substring(0, 13) + ":00")
    if (start < 0)
        start = 0
    const stunden = []
    for (let i = start; i < h.time.length && stunden.length < 6; i++) {
        if (h.temperature_2m[i] === null || h.weather_code[i] === null)
            continue
        stunden.push({ zeit: h.time[i].substring(11, 16), temp: h.temperature_2m[i],
                       code: h.weather_code[i], tag: h.is_day[i] === 1 })
    }

    const tage = []
    for (let i = 1; i < t.time.length && tage.length < 5; i++) {
        if (t.temperature_2m_max[i] === null || t.temperature_2m_min[i] === null)
            continue
        // Stundenwerte des Tages für die Tagesdetails
        const tagesStunden = []
        for (const s of TAGES_STUNDEN) {
            const j = h.time.indexOf(t.time[i] + "T" + (s < 10 ? "0" : "") + s + ":00")
            if (j >= 0 && h.temperature_2m[j] !== null && h.weather_code[j] !== null)
                tagesStunden.push({ zeit: h.time[j].substring(11, 16), temp: h.temperature_2m[j],
                                    code: h.weather_code[j], tag: h.is_day[j] === 1 })
        }
        const verlauf = []
        for (let j = 0; j < h.time.length; j++)
            if (h.time[j].startsWith(t.time[i]) && h.temperature_2m[j] !== null)
                verlauf.push({ h: +h.time[j].substring(11, 13), temp: h.temperature_2m[j] })
        const feld = (name) => (t[name] ? oderNull(t[name][i]) : null)
        // Fehlt das Wetter eines Tages, ist „Bedeckt“ ehrlicher als eine Sonne
        tage.push({ name: W.kurzerTag(t.time[i]), datum: t.time[i], code: t.weather_code[i] !== null ? t.weather_code[i] : 3,
                    min: t.temperature_2m_min[i], max: t.temperature_2m_max[i], stunden: tagesStunden, verlauf: verlauf,
                    regen: feld("precipitation_probability_max"), menge: feld("precipitation_sum"), schnee: feld("snowfall_sum") })
    }

    // Fehlt einem Modell ein aktueller Wert oder ein Wert für heute, ersatzweise die Stundenwerte nehmen
    const erste = stunden[0]
    if (c.temperature_2m === null && !erste)
        throw new Error("keine Temperaturwerte")
    const temperatur = c.temperature_2m !== null ? c.temperature_2m : erste.temp
    const heuteWerte = []
    for (let i = 0; i < h.time.length; i++) {
        if (h.time[i].startsWith(t.time[0]) && h.temperature_2m[i] !== null)
            heuteWerte.push(h.temperature_2m[i])
    }
    if (!heuteWerte.length)
        heuteWerte.push(temperatur)

    // Open-Meteo liefert Ortszeiten ohne Versatz. utc_offset_seconds gilt nur jetzt; liegt der Ort in der
    // Zeitzone dieses Rechners, rechnet die Systemzeit samt Zeitumstellung, sonst der feste Versatz.
    const versatz = (d.utc_offset_seconds || 0) * 1000
    const wieSystem = wieSystemzeit(versatz / 1000)
    const zeitpunkt = s => wieSystem
        ? new Date(+s.substring(0, 4), +s.substring(5, 7) - 1, +s.substring(8, 10), +s.substring(11, 13), +s.substring(14, 16)).getTime()
        : Date.UTC(+s.substring(0, 4), +s.substring(5, 7) - 1, +s.substring(8, 10),
                   +s.substring(11, 13), +s.substring(14, 16)) - versatz
    const jetztMs = zeitpunkt(c.time)
    const boeen = [{ zeit: jetztMs, kmh: c.wind_gusts_10m }]
    if (h.wind_gusts_10m)
        for (let i = 0; i < h.time.length; i++)
            boeen.push({ zeit: zeitpunkt(h.time[i]), kmh: h.wind_gusts_10m[i] })

    const uhr = s => (s ? String(s).substring(11, 16) : "")
    return {
        temperatur: temperatur,
        gefuehlt: oderNull(c.apparent_temperature),
        windRichtung: oderNull(c.wind_direction_10m),
        sonnenAuf: t.sunrise ? uhr(t.sunrise[0]) : "",
        sonnenUnter: t.sunset ? uhr(t.sunset[0]) : "",
        uv: t.uv_index_max ? oderNull(t.uv_index_max[0]) : null,
        boeen: naechste24(boeen, jetztMs),
        code: c.weather_code !== null ? c.weather_code : (erste ? erste.code : 0),
        tag: c.is_day !== null ? c.is_day === 1 : (erste ? erste.tag : true),
        wind: c.wind_speed_10m || 0, feuchte: gerundet(c.relative_humidity_2m),
        niederschlag: gerundet(t.precipitation_probability_max[0]),
        heuteMax: t.temperature_2m_max[0] !== null ? t.temperature_2m_max[0] : Math.max(...heuteWerte),
        heuteMin: t.temperature_2m_min[0] !== null ? t.temperature_2m_min[0] : Math.min(...heuteWerte),
        heuteDatum: t.time[0], heuteAb: 0,
        stunden: stunden, tage: tage
    }
}

// ── OpenWeatherMap (kostenloser Zugang: aktuelles Wetter + 5 Tage in 3-Stunden-Schritten) ──

function wmoAusOpenWeatherMap(id) {
    if (id >= 200 && id < 300) return 95
    if (id === 300) return 51
    if (id === 301) return 53
    if (id === 302) return 55
    if (id >= 310 && id < 400) return id === 313 || id === 314 || id === 321 ? 80 : 53
    if (id === 500) return 61
    if (id === 501) return 63
    if (id >= 502 && id <= 504) return 65
    if (id === 511) return 66
    if (id === 520) return 80
    if (id === 521) return 81
    if (id === 522 || id === 531) return 82
    if (id === 600) return 71
    if (id === 601) return 73
    if (id === 602) return 75
    if (id >= 611 && id <= 616) return 66
    if (id === 620) return 85
    if (id === 621 || id === 622) return 86
    if (id >= 700 && id < 800) return 45
    if (id === 800) return 0
    if (id === 801) return 1
    if (id === 802) return 2
    return 3
}

// Ortszeit eines Zeitpunkts (Sekunden seit 1970). OpenWeatherMap meldet nur den Zeitzonen-Versatz,
// der jetzt gilt (Sekunden); über eine Sommerzeit-Umstellung hinweg wäre er eine Stunde falsch.
// wieSystem: Der Ort liegt in der Zeitzone dieses Rechners, dann rechnet die Systemzeit samt
// Sommerzeit-Regeln; sonst der feste Versatz.
function ortszeit(sekunden, versatz, wieSystem) {
    const d = new Date((wieSystem ? sekunden : sekunden + versatz) * 1000)
    const jahr = wieSystem ? d.getFullYear() : d.getUTCFullYear()
    const monat = wieSystem ? d.getMonth() : d.getUTCMonth()
    const tag = wieSystem ? d.getDate() : d.getUTCDate()
    const stunde = wieSystem ? d.getHours() : d.getUTCHours()
    const minute = wieSystem ? d.getMinutes() : d.getUTCMinutes()
    const zwei = n => (n < 10 ? "0" : "") + n
    return { datum: jahr + "-" + zwei(monat + 1) + "-" + zwei(tag), uhr: zwei(stunde) + ":" + zwei(minute), stunde: stunde }
}

function ausOpenWeatherMap(jetzt, vorhersage) {
    const versatz = vorhersage.city.timezone
    // Gleicher Versatz wie dieser Rechner jetzt: sehr wahrscheinlich dieselbe Zeitzone
    const wieSystem = -new Date(jetzt.dt * 1000).getTimezoneOffset() * 60 === versatz
    const ort = ortszeit(jetzt.dt, versatz, wieSystem)
    const heute = ort.datum
    const liste = vorhersage.list.map(e => ({
        zeit: ortszeit(e.dt, versatz, wieSystem),
        temp: e.main.temp,
        code: wmoAusOpenWeatherMap(e.weather[0].id),
        tag: e.weather[0].icon.endsWith("d"),
        regen: e.pop || 0,
        mm: ((e.rain && e.rain["3h"]) || 0) + ((e.snow && e.snow["3h"]) || 0),
        boe: e.wind && e.wind.gust !== undefined ? e.wind.gust * 3.6 : null,
        ms: e.dt * 1000
    }))

    // Heute: aktuelle Temperatur und die restlichen Vorhersagewerte des Tages. Tageswerte gibt es
    // im kostenlosen Zugang nicht, darum gilt die Spanne nur ab jetzt (heuteAb); main.qml führt sie
    // mit den früher am selben Tag gesehenen Werten zusammen.
    let heuteMax = jetzt.main.temp, heuteMin = jetzt.main.temp, regen = 0
    const nachTag = {}
    for (const e of liste) {
        if (e.zeit.datum === heute) {
            heuteMax = Math.max(heuteMax, e.temp)
            heuteMin = Math.min(heuteMin, e.temp)
            regen = Math.max(regen, e.regen)
        } else {
            (nachTag[e.zeit.datum] = nachTag[e.zeit.datum] || []).push(e)
        }
    }

    // Folgetage: Spanne aller Werte, Symbol vom Wert am nächsten an 12 Uhr. Die Vorhersage reicht
    // genau 5 × 24 Stunden weit, der letzte Tag ist darum meist nur angebrochen (z.B. nur bis 6 Uhr)
    // und hätte eine viel zu tiefe Höchsttemperatur; Tage mit weniger als 6 der 8 Werte fallen weg.
    const tage = Object.keys(nachTag).sort().filter(datum => nachTag[datum].length >= 6).slice(0, 5).map(datum => {
        const werte = nachTag[datum]
        const mittag = werte.reduce((a, b) => Math.abs(b.zeit.stunde - 12) < Math.abs(a.zeit.stunde - 12) ? b : a)
        // Tagesdetails: die Werte von 5 bis 23 Uhr (OpenWeatherMap rechnet in 3-Stunden-Schritten)
        const tagesStunden = werte.filter(e => e.zeit.stunde >= 5 && e.zeit.stunde <= 23).slice(0, 6)
                                  .map(e => ({ zeit: e.zeit.uhr, temp: e.temp, code: e.code, tag: e.tag }))
        return { name: W.kurzerTag(datum), datum: datum, code: mittag.code,
                 min: Math.min(...werte.map(e => e.temp)), max: Math.max(...werte.map(e => e.temp)),
                 stunden: tagesStunden, verlauf: werte.map(e => ({ h: e.zeit.stunde, temp: e.temp })),
                 regen: Math.round(Math.max(...werte.map(e => e.regen)) * 100),
                 menge: werte.reduce((s, e) => s + e.mm, 0), schnee: null }
    })

    const sonne = jetzt.sys || {}
    return {
        temperatur: jetzt.main.temp, code: wmoAusOpenWeatherMap(jetzt.weather[0].id),
        gefuehlt: oderNull(jetzt.main.feels_like),
        windRichtung: oderNull(jetzt.wind.deg),
        sonnenAuf: sonne.sunrise ? ortszeit(sonne.sunrise, versatz, wieSystem).uhr : "",
        sonnenUnter: sonne.sunset ? ortszeit(sonne.sunset, versatz, wieSystem).uhr : "",
        uv: null,   // nicht im kostenlosen Zugang; kommt aus den Zusatzdaten
        tag: jetzt.weather[0].icon.endsWith("d"),
        wind: (jetzt.wind.speed || 0) * 3.6, feuchte: gerundet(jetzt.main.humidity),
        boeen: naechste24([{ zeit: jetzt.dt * 1000, kmh: jetzt.wind.gust !== undefined ? jetzt.wind.gust * 3.6 : null }]
                          .concat(liste.map(e => ({ zeit: e.ms, kmh: e.boe }))), jetzt.dt * 1000),
        niederschlag: gerundet(regen * 100),
        heuteMax: heuteMax, heuteMin: heuteMin, heuteDatum: heute, heuteAb: ort.stunde,
        stunden: liste.slice(0, 6).map(e => ({ zeit: e.zeit.uhr, temp: e.temp, code: e.code, tag: e.tag })),
        tage: tage
    }
}

// ── WeatherAPI.com (kostenloser Zugang: 3 Tage Vorhersage) ──

const WMO_AUS_WEATHERAPI = {
    1000: 0, 1003: 2, 1006: 3, 1009: 3, 1030: 45, 1135: 45, 1147: 48,
    1063: 80, 1066: 85, 1069: 66, 1072: 56, 1087: 95, 1114: 73, 1117: 75,
    1150: 51, 1153: 53, 1168: 56, 1171: 57,
    1180: 61, 1183: 61, 1186: 63, 1189: 63, 1192: 65, 1195: 65, 1198: 66, 1201: 67, 1204: 66, 1207: 67,
    1210: 71, 1213: 71, 1216: 73, 1219: 73, 1222: 75, 1225: 75, 1237: 77,
    1240: 80, 1243: 81, 1246: 82, 1249: 85, 1252: 86, 1255: 85, 1258: 86, 1261: 77, 1264: 77,
    1273: 95, 1276: 95, 1279: 95, 1282: 95
}

function wmoAusWeatherApi(code) {
    const w = WMO_AUS_WEATHERAPI[code]
    return w === undefined ? 3 : w
}

// „07:46 AM“ → „07:46“, „06:05 PM“ → „18:05“
function uhrAus12(text) {
    const m = String(text || "").match(/(\d{1,2}):(\d{2})\s*([AP]M)/i)
    if (!m)
        return ""
    const h = (+m[1] % 12) + (m[3].toUpperCase() === "PM" ? 12 : 0)
    return (h < 10 ? "0" : "") + h + ":" + m[2]
}

function ausWeatherApi(d) {
    const c = d.current
    const tage = d.forecast.forecastday
    const heute = tage[0].day

    // Stundenwerte ab der laufenden Stunde, auch über Mitternacht hinaus
    const ab = d.location.localtime.substring(0, 13)
    const stunden = []
    for (const t of tage) {
        for (const h of t.hour) {
            if (stunden.length < 6 && h.time.substring(0, 13) >= ab)
                stunden.push({ zeit: h.time.substring(11, 16), temp: h.temp_c,
                               code: wmoAusWeatherApi(h.condition.code), tag: h.is_day === 1 })
        }
    }

    const astro = tage[0].astro || {}
    return {
        temperatur: c.temp_c, code: wmoAusWeatherApi(c.condition.code), tag: c.is_day === 1,
        gefuehlt: oderNull(c.feelslike_c),
        windRichtung: oderNull(c.wind_degree),
        sonnenAuf: uhrAus12(astro.sunrise),
        sonnenUnter: uhrAus12(astro.sunset),
        uv: oderNull(heute.uv),
        wind: c.wind_kph, feuchte: gerundet(c.humidity),
        boeen: naechste24([{ zeit: d.location.localtime_epoch * 1000, kmh: c.gust_kph }]
                          .concat([].concat(...tage.map(t => t.hour)).map(h => ({ zeit: h.time_epoch * 1000, kmh: h.gust_kph }))),
                          d.location.localtime_epoch * 1000),
        niederschlag: gerundet(Math.max(heute.daily_chance_of_rain || 0, heute.daily_chance_of_snow || 0)),
        heuteMax: heute.maxtemp_c, heuteMin: heute.mintemp_c, heuteDatum: tage[0].date, heuteAb: 0,
        stunden: stunden,
        tage: tage.slice(1, 6).map(t => ({ name: W.kurzerTag(t.date), datum: t.date, code: wmoAusWeatherApi(t.day.condition.code),
                                           min: t.day.mintemp_c, max: t.day.maxtemp_c,
                                           stunden: (t.hour || []).filter(h => TAGES_STUNDEN.indexOf(+h.time.substring(11, 13)) >= 0)
                                                    .map(h => ({ zeit: h.time.substring(11, 16), temp: h.temp_c,
                                                                 code: wmoAusWeatherApi(h.condition.code), tag: h.is_day === 1 })),
                                           verlauf: (t.hour || []).map(h => ({ h: +h.time.substring(11, 13), temp: h.temp_c })),
                                           regen: Math.max(t.day.daily_chance_of_rain || 0, t.day.daily_chance_of_snow || 0),
                                           menge: oderNull(t.day.totalprecip_mm),
                                           schnee: t.day.totalsnow_cm !== undefined ? oderNull(t.day.totalsnow_cm) : null }))
    }
}

// ── MET Norway (yr.no): kostenlos, ohne Schlüssel ──
// Stundenwerte für gut 2 Tage, danach alle 6 Stunden; Zeiten in UTC. Ausserhalb Skandinaviens fehlen
// Böen und Regenwahrscheinlichkeit. om: Antwort von Open-Meteo mit Zeitzone und Sonnenzeiten.

const WMO_AUS_MET = {
    clearsky: 0, fair: 1, partlycloudy: 2, cloudy: 3, fog: 45,
    lightrain: 61, rain: 63, heavyrain: 65, lightrainshowers: 80, rainshowers: 81, heavyrainshowers: 82,
    lightsleet: 68, sleet: 68, heavysleet: 68, lightsleetshowers: 68, sleetshowers: 68, heavysleetshowers: 68,
    lightsnow: 71, snow: 73, heavysnow: 75, lightsnowshowers: 85, snowshowers: 85, heavysnowshowers: 86
}

// "partlycloudy_day" → { code: 2, tag: true }; Gewitter-Varianten ("…andthunder") → 95
function wmoAusMet(symbol, tagSonst) {
    const s = String(symbol || "cloudy")
    const teile = s.split("_"), name = teile[0]
    const tag = teile[1] === "day" ? true : teile[1] === "night" ? false : tagSonst
    if (name.indexOf("thunder") >= 0)
        return { code: 95, tag: tag }
    const c = WMO_AUS_MET[name]
    return { code: c === undefined ? 3 : c, tag: tag }
}

// Werte für die Tagesdetails: die üblichen Stunden (6, 9 … 21 Uhr). MET liefert ab dem dritten Tag nur
// noch alle 6 Stunden (Ortszeit z. B. 1, 7, 13, 19 Uhr); dann die vorhandenen Werte ab 5 Uhr
function tagesWerte(werte) {
    const ueblich = werte.filter(e => TAGES_STUNDEN.indexOf(e.ort.stunde) >= 0)
    return ueblich.length >= 3 ? ueblich : werte.filter(e => e.ort.stunde >= 5).slice(0, 6)
}

// Ortszeit für Anbieter mit UTC-Zeiten (MET Norway, DWD): wie bei OpenWeatherMap die Systemzeit (mit
// Zeitumstellung), wenn der Ort in der Zeitzone dieses Rechners liegt, sonst der feste Versatz von jetzt.
// om: Antwort von Open-Meteo mit utc_offset_seconds. Liefert ms → { datum, uhr, stunde }
function ortszeitAus(om) {
    const versatz = (om && om.utc_offset_seconds) || 0
    const wieSystem = wieSystemzeit(versatz)
    return ms => {
        const z = n => (n < 10 ? "0" : "") + n
        if (wieSystem) {
            const d = new Date(ms)
            return { datum: d.getFullYear() + "-" + z(d.getMonth() + 1) + "-" + z(d.getDate()),
                     uhr: z(d.getHours()) + ":" + z(d.getMinutes()), stunde: d.getHours() }
        }
        const d = new Date(ms + versatz * 1000)
        return { datum: d.getUTCFullYear() + "-" + z(d.getUTCMonth() + 1) + "-" + z(d.getUTCDate()),
                 uhr: z(d.getUTCHours()) + ":" + z(d.getUTCMinutes()), stunde: d.getUTCHours() }
    }
}

// Sonnenauf- und -untergang von heute aus der Open-Meteo-Antwort ("HH:MM", "" = unbekannt)
function sonneAus(om) {
    return om && om.daily ? { auf: String(om.daily.sunrise[0] || "").substring(11, 16),
                              unter: String(om.daily.sunset[0] || "").substring(11, 16) } : { auf: "", unter: "" }
}

function ausMetNorway(met, om) {
    const ort = ortszeitAus(om)
    const sonne = sonneAus(om)
    // Tag oder Nacht für Zeitpunkte ohne _day/_night im Symbol: nach den Sonnenzeiten von heute
    const tagUm = uhr => !sonne.auf || (uhr >= sonne.auf && uhr < sonne.unter)
    const reihe = met.properties.timeseries.map((e, i, alle) => {
        const ms = Date.parse(e.time), o = ort(ms), d = e.data
        const naechste = i + 1 < alle.length ? Date.parse(alle[i + 1].time) - ms : 3600000
        const block = d.next_1_hours || d.next_6_hours || d.next_12_hours || {}
        const w = wmoAusMet(block.summary && block.summary.symbol_code, tagUm(o.uhr))
        // Niederschlag bis zum nächsten Zeitpunkt (stündlich bzw. 6-stündlich), ohne doppelt zu zählen
        const mmBlock = naechste <= 3600000 ? d.next_1_hours : d.next_6_hours
        return { ms: ms, ort: o, temp: d.instant.details.air_temperature, i: d.instant.details, code: w.code, tag: w.tag,
                 mm: mmBlock && mmBlock.details ? mmBlock.details.precipitation_amount || 0 : 0,
                 stuendlich: !!d.next_1_hours && naechste <= 3600000 }
    })
    const jetzt = reihe[0], heute = jetzt.ort.datum
    const heuteWerte = reihe.filter(e => e.ort.datum === heute)
    const nachTag = {}
    for (const e of reihe)
        if (e.ort.datum !== heute)
            (nachTag[e.ort.datum] = nachTag[e.ort.datum] || []).push(e)
    const tage = Object.keys(nachTag).sort().filter(d => nachTag[d].length >= 3).slice(0, 5).map(datum => {
        const werte = nachTag[datum]
        const mittag = werte.reduce((a, b) => (Math.abs(b.ort.stunde - 12) < Math.abs(a.ort.stunde - 12) ? b : a))
        return { name: W.kurzerTag(datum), datum: datum, code: mittag.code,
                 min: Math.min(...werte.map(e => e.temp)), max: Math.max(...werte.map(e => e.temp)),
                 stunden: tagesWerte(werte).map(e => ({ zeit: e.ort.uhr, temp: e.temp, code: e.code, tag: e.tag })),
                 verlauf: werte.map(e => ({ h: e.ort.stunde, temp: e.temp })),
                 regen: null, menge: werte.reduce((s, e) => s + e.mm, 0), schnee: null }
    })
    const uvWerte = heuteWerte.map(e => e.i.ultraviolet_index_clear_sky).filter(x => x !== undefined)
    return {
        temperatur: jetzt.temp, code: jetzt.code, tag: jetzt.tag,
        gefuehlt: oderNull(jetzt.i.apparent_air_temperature),
        windRichtung: oderNull(jetzt.i.wind_from_direction),
        wind: (jetzt.i.wind_speed || 0) * 3.6, feuchte: gerundet(jetzt.i.relative_humidity),
        sonnenAuf: sonne.auf, sonnenUnter: sonne.unter,
        uv: uvWerte.length ? Math.max(...uvWerte) : null,
        // Böen nur in Skandinavien (wind_speed_of_gust); sonst gibt es keine eigene Windwarnung
        boeen: naechste24(reihe.map(e => ({ zeit: e.ms, kmh: e.i.wind_speed_of_gust !== undefined ? e.i.wind_speed_of_gust * 3.6 : null })), jetzt.ms),
        niederschlag: -1,
        heuteMax: Math.max(...heuteWerte.map(e => e.temp)), heuteMin: Math.min(...heuteWerte.map(e => e.temp)),
        heuteDatum: heute, heuteAb: heuteWerte.length >= 20 ? 0 : jetzt.ort.stunde,
        stunden: reihe.filter(e => e.stuendlich || e === jetzt).slice(0, 6)
                      .map(e => ({ zeit: e.ort.uhr, temp: e.temp, code: e.code, tag: e.tag })),
        tage: tage
    }
}

// ── Deutscher Wetterdienst: Stationsvorhersage MOSMIX über Bright Sky ──
// Stündliche Werte der nächsten DWD-Vorhersagestation (weltweit gut 5000, dicht in Mitteleuropa), Zeiten
// in UTC, Wind und Böen in km/h, Niederschlag in mm je Stunde. Luftfeuchtigkeit und gefühlte Temperatur
// liefert MOSMIX nicht; sie werden aus Taupunkt und Wind berechnet. om wie bei MET Norway.

// Relative Feuchte in % aus Temperatur und Taupunkt (Magnus-Formel)
function feuchteAusTaupunkt(t, td) {
    if (t === null || td === null || t === undefined || td === undefined)
        return null
    const f = x => Math.exp(17.625 * x / (243.04 + x))
    return Math.max(0, Math.min(100, 100 * f(td) / f(t)))
}

// Gefühlte Temperatur wie bei Open-Meteo (Formel des australischen Wetterdienstes): Feuchte macht
// wärmer, Wind kälter. kmh: Windgeschwindigkeit in km/h
function gefuehltAus(t, feuchte, kmh) {
    if (t === null || t === undefined || feuchte === null)
        return null
    const dampf = feuchte / 100 * 6.105 * Math.exp(17.27 * t / (237.7 + t))
    return t + 0.33 * dampf - 0.70 * (kmh || 0) / 3.6 - 4.0
}

// Bright-Sky-Symbol ("rain", "partly-cloudy-day" …) → { code, tag }; die Stärke von Regen und Schnee
// nach der Menge der Stunde, weil das Symbol nur die Art kennt
function wmoAusDwd(e, tagSonst) {
    const icon = String(e.icon || ""), mm = e.precipitation || 0, wolken = e.cloud_cover
    const tag = icon.endsWith("-day") ? true : icon.endsWith("-night") ? false : tagSonst
    const art = icon.replace(/-(day|night)$/, "") || e.condition || ""
    let code
    switch (art) {
    case "thunderstorm": code = 95; break
    case "hail": code = 96; break
    case "snow": code = mm < 0.5 ? 71 : mm < 2 ? 73 : 75; break
    case "sleet": code = 68; break
    case "rain": code = mm < 0.5 ? 61 : mm < 2.5 ? 63 : 65; break
    case "fog": code = 45; break
    case "clear": code = wolken !== null && wolken !== undefined && wolken > 15 ? 1 : 0; break
    case "partly-cloudy": code = 2; break
    case "cloudy": case "dry": code = 3; break
    default:
        // "wind" oder ohne Symbol: nach der Bewölkung
        code = wolken === null || wolken === undefined ? 3 : wolken <= 15 ? 0 : wolken <= 40 ? 1 : wolken <= 75 ? 2 : 3
    }
    return { code: code, tag: tag }
}

function ausDwd(bs, om) {
    const ort = ortszeitAus(om)
    const sonne = sonneAus(om)
    const tagUm = uhr => !sonne.auf || (uhr >= sonne.auf && uhr < sonne.unter)
    const stundeJetzt = Math.floor(Date.now() / 3600000) * 3600000
    const alle = (bs.weather || []).filter(e => e.temperature !== null && e.temperature !== undefined).map(e => {
        const ms = Date.parse(e.timestamp), o = ort(ms), w = wmoAusDwd(e, tagUm(o.uhr))
        const feuchte = feuchteAusTaupunkt(e.temperature, e.dew_point)
        // Für das Tagessymbol zählt auch Niederschlag, den das Stundensymbol als zu schwach weglässt
        // (condition "snow", Symbol aber "cloudy")
        const art = ["rain", "snow", "sleet", "hail", "thunderstorm"].indexOf(e.condition) >= 0
                    ? wmoAusDwd({ icon: e.condition, precipitation: e.precipitation }, true).code : w.code
        return { ms: ms, ort: o, temp: e.temperature, code: w.code, tag: w.tag, e: e, feuchte: feuchte, art: art,
                 mm: e.precipitation || 0, schnee: e.condition === "snow" || e.icon === "snow" }
    })
    // Ab der laufenden Stunde; die Stunde davor nur, falls noch nichts Neueres da ist
    const reihe = alle.filter(e => e.ms >= stundeJetzt).length ? alle.filter(e => e.ms >= stundeJetzt) : alle
    if (!reihe.length)
        throw new Error("keine Vorhersagewerte")
    const jetzt = reihe[0], heute = jetzt.ort.datum
    const heuteWerte = reihe.filter(e => e.ort.datum === heute)
    const nachTag = {}
    for (const e of reihe)
        if (e.ort.datum !== heute)
            (nachTag[e.ort.datum] = nachTag[e.ort.datum] || []).push(e)
    const wahrscheinlich = werte => {
        const p = werte.map(e => e.e.precipitation_probability).filter(x => x !== null && x !== undefined)
        return p.length ? Math.max(...p) : null
    }
    const tage = Object.keys(nachTag).sort().filter(d => nachTag[d].length >= 12).slice(0, 5).map(datum => {
        const werte = nachTag[datum]
        // Symbol des Tages wie bei Open-Meteo das stärkste Wetter des Tages (Gewitter vor Schnee vor Regen,
        // bei gleicher Art die stärkste Stunde); Regen und Schnee aber erst ab 1 mm am Tag, sonst das
        // Symbol um die Mittagszeit
        const wichtig = c => c >= 95 ? 6 : c >= 71 && c <= 77 ? 5 : c >= 61 && c <= 68 ? 4 : 0
        const haupt = werte.reduce((a, b) => (wichtig(b.art) > wichtig(a.art)
                                              || wichtig(b.art) === wichtig(a.art) && b.art > a.art ? b : a))
        const mittag = werte.reduce((a, b) => (Math.abs(b.ort.stunde - 12) < Math.abs(a.ort.stunde - 12) ? b : a))
        const summe = werte.reduce((x, e) => x + e.mm, 0)
        const code = wichtig(haupt.art) === 6 || wichtig(haupt.art) >= 4 && summe >= 1 ? haupt.art : mittag.code
        return { name: W.kurzerTag(datum), datum: datum, code: code,
                 min: Math.min(...werte.map(e => e.temp)), max: Math.max(...werte.map(e => e.temp)),
                 stunden: werte.filter(e => TAGES_STUNDEN.indexOf(e.ort.stunde) >= 0)
                               .map(e => ({ zeit: e.ort.uhr, temp: e.temp, code: e.code, tag: e.tag })),
                 verlauf: werte.map(e => ({ h: e.ort.stunde, temp: e.temp })),
                 regen: wahrscheinlich(werte), menge: werte.reduce((s, e) => s + e.mm, 0),
                 // Neuschnee grob: 1 mm Wasser ≈ 1 cm Schnee
                 schnee: werte.reduce((s, e) => s + (e.schnee ? e.mm : 0), 0) }
    })
    const kmh = jetzt.e.wind_speed || 0
    const regenHeute = wahrscheinlich(heuteWerte)
    return {
        temperatur: jetzt.temp, code: jetzt.code, tag: jetzt.tag,
        gefuehlt: gefuehltAus(jetzt.temp, jetzt.feuchte, kmh),
        windRichtung: oderNull(jetzt.e.wind_direction),
        wind: kmh, feuchte: jetzt.feuchte === null ? 0 : gerundet(jetzt.feuchte),
        sonnenAuf: sonne.auf, sonnenUnter: sonne.unter,
        uv: null,
        boeen: naechste24(reihe.map(e => ({ zeit: e.ms, kmh: oderNull(e.e.wind_gust_speed) })), jetzt.ms),
        niederschlag: regenHeute === null ? -1 : regenHeute,
        heuteMax: Math.max(...heuteWerte.map(e => e.temp)), heuteMin: Math.min(...heuteWerte.map(e => e.temp)),
        heuteDatum: heute, heuteAb: heuteWerte.length >= 20 ? 0 : jetzt.ort.stunde,
        stunden: reihe.slice(0, 6).map(e => ({ zeit: e.ort.uhr, temp: e.temp, code: e.code, tag: e.tag })),
        tage: tage
    }
}
