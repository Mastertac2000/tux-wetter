.pragma library

// SPDX-FileCopyrightText: 2026 R.Bruns
// SPDX-License-Identifier: GPL-3.0-or-later

// Sicherung der Einstellungen: Plasma löscht die Einstellungen eines Widgets, sobald es vom Desktop
// entfernt wird. Das Widget legt sie darum zusätzlich im eigenen Speicher ab (main.qml) und kann sie
// als Datei sichern und laden (ConfigGeneral.qml). Hier steht, welche Einstellungen dazugehören und
// wie eine Sicherung aussieht.

const FORMAT = "tux-wetter-einstellungen"

// Einstellungen des Benutzers mit ihrem Standardwert (wie in config/main.xml). Nicht dabei sind die
// Werte, die das Widget selbst setzt (Warngebiete, gemerkte Grösse, gewählter Standort).
const STANDARD = {
    locationName: "Luzern", latitude: 47.0505, longitude: 8.3064,
    provider: "openmeteo", weatherModel: "best_match", owmApiKey: "", weatherApiKey: "",
    windWarning: true, thunderWarning: true, rainWarning: true, snowWarning: true, iceWarning: true, heatWarning: true,
    dwdWarnings: true, meteoSwissWarnings: true, geoSphereWarnings: true,
    colorScheme: "violett", customColorStart: "#2B2763", customColorEnd: "#5A3AD4",
    useFahrenheit: false, updateInterval: 15, animations: true,
    glassEffect: false, glassTint: 45, glassDarken: 18, backgroundOpacity: 94,
    language: "auto", showDetails: true, feelsLike: true, rainNowcast: true, airQuality: true,
    notifications: true, notifyLevel: 2, notifyAllPlaces: true,
    places: "[]", autoLocation: false, measuredTemp: true, lightCard: false, checkUpdates: true
}
const SCHLUESSEL = Object.keys(STANDARD)
// API-Schlüssel: in der automatischen Sicherung immer, in einer Datei nur auf Wunsch
const GEHEIM = ["owmApiKey", "weatherApiKey"]

function gleich(a, b) {
    return typeof a === "number" && typeof b === "number" ? Math.abs(a - b) < 1e-6 : String(a) === String(b)
}

// Wurde an den Einstellungen etwas geändert? Ein frisch hinzugefügtes Widget hat überall den Standardwert.
// lies(name) liefert den Wert (Plasmoid.configuration[name] oder seite["cfg_" + name]).
function eingerichtet(lies) {
    return SCHLUESSEL.some(k => !gleich(lies(k), STANDARD[k]))
}

// Die Einstellungen als Objekt { name: wert }
function auslesen(lies, mitGeheim) {
    const e = {}
    for (const k of SCHLUESSEL)
        if (mitGeheim || GEHEIM.indexOf(k) < 0)
            e[k] = lies(k)
    return e
}

// Inhalt einer Sicherungsdatei; Zeichen ausserhalb von ASCII als \uXXXX, damit die Datei in jeder
// Kodierung gleich gelesen wird
function datei(lies, mitGeheim, jetzt) {
    const inhalt = { format: FORMAT, version: 1, erstellt: new Date(jetzt).toISOString(), einstellungen: auslesen(lies, mitGeheim) }
    return JSON.stringify(inhalt, null, 2).replace(/[\u0080-￿]/g, c => "\\u" + ("000" + c.charCodeAt(0).toString(16)).slice(-4))
}

// Prüft eine Sicherung (Text einer Datei oder Objekt aus dem Speicher) und liefert nur die bekannten
// Einstellungen mit passendem Typ; null, wenn es keine Tux-Wetter-Sicherung ist
function pruefen(quelle) {
    let d = quelle
    if (typeof quelle === "string") {
        try {
            d = JSON.parse(quelle)
        } catch (e) {
            return null
        }
    }
    if (!d || typeof d !== "object" || d.format !== FORMAT || !d.einstellungen || typeof d.einstellungen !== "object")
        return null
    const e = {}
    for (const k of SCHLUESSEL) {
        const v = d.einstellungen[k]
        if (v === undefined || v === null || typeof v !== typeof STANDARD[k])
            continue
        if (typeof v === "number" && !isFinite(v))
            continue
        if (k === "places") {
            try {
                if (!Array.isArray(JSON.parse(v)))
                    continue
            } catch (x) {
                continue
            }
        }
        e[k] = v
    }
    if (typeof e.latitude === "number" && Math.abs(e.latitude) > 90 || typeof e.longitude === "number" && Math.abs(e.longitude) > 180) {
        delete e.latitude
        delete e.longitude
    }
    return Object.keys(e).length ? { erstellt: d.erstellt || "", einstellungen: e } : null
}

// Anzahl Orte in der Ortsliste einer Sicherung
function anzahlOrte(e) {
    try {
        const o = JSON.parse(e.places || "[]")
        return Array.isArray(o) ? o.length : 0
    } catch (x) {
        return 0
    }
}
