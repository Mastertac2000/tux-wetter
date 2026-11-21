.pragma library

// SPDX-FileCopyrightText: 2026 R.Bruns
// SPDX-License-Identifier: GPL-3.0-or-later

// Sprachen des Widgets: Deutsch (die Texte im Code) und Englisch (dieses Wörterbuch).
// t(sp, text, …) liefert den Text in der Sprache sp ("de" oder "en"); %1, %2 … werden durch die
// weiteren Werte ersetzt. Fehlt eine Übersetzung, bleibt der deutsche Text.

const EN = {
    // ── Wetterlage ──
    "Sonnig": "Sunny", "Klar": "Clear", "Überwiegend sonnig": "Mostly sunny", "Überwiegend klar": "Mostly clear",
    "Teilweise bewölkt": "Partly cloudy", "Bedeckt": "Overcast", "Nebel": "Fog", "Nieselregen": "Drizzle",
    "Gefrierender Niesel": "Freezing drizzle", "Leichter Regen": "Light rain", "Regen": "Rain",
    "Starker Regen": "Heavy rain", "Gefrierender Regen": "Freezing rain", "Schneeregen": "Sleet", "Leichter Schneefall": "Light snow",
    "Schneefall": "Snow", "Starker Schneefall": "Heavy snow", "Schneegriesel": "Snow grains",
    "Leichte Regenschauer": "Light showers", "Regenschauer": "Showers", "Heftige Regenschauer": "Heavy showers",
    "Schneeschauer": "Snow showers", "Gewitter": "Thunderstorm", "Gewitter mit Hagel": "Thunderstorm with hail",
    "Unbekannt": "Unknown",

    // ── Tage und Himmelsrichtungen ──
    "So": "Sun", "Mo": "Mon", "Di": "Tue", "Mi": "Wed", "Do": "Thu", "Fr": "Fri", "Sa": "Sat",
    "Sonntag": "Sunday", "Montag": "Monday", "Dienstag": "Tuesday", "Mittwoch": "Wednesday",
    "Donnerstag": "Thursday", "Freitag": "Friday", "Samstag": "Saturday",
    "N": "N", "NO": "NE", "O": "E", "SO": "SE", "S": "S", "SW": "SW", "W": "W", "NW": "NW",
    "Nord": "north", "Nordost": "northeast", "Ost": "east", "Südost": "southeast", "Süd": "south",
    "Südwest": "southwest", "West": "west", "Nordwest": "northwest",

    // ── Warnungen ──
    "Wind": "Wind", "Starkregen": "Heavy rain", "Schnee": "Snow", "Glätte und Frost": "Ice and frost",
    "Hitze": "Heat", "Strassenglätte": "Slippery roads", "Frost": "Frost", "Gefahrenstufe": "danger level",
    "%1-Warnung": "%1 warning",
    "Windwarnung": "Wind warning", "Regenwarnung": "Rain warning", "Schneewarnung": "Snow warning",
    "Glatteiswarnung": "Black ice warning", "Gewitterwarnung": "Thunderstorm warning", "Hitzewarnung": "Heat warning",
    "Kältewarnung": "Cold warning",
    "Windböen": "Wind gusts", "Sturmböen": "Storm gusts", "Schwere Sturmböen": "Severe storm gusts",
    "Orkanartige Böen": "Violent storm gusts", "Orkanböen": "Hurricane-force gusts", "Extreme Orkanböen": "Extreme hurricane-force gusts",
    "Starkes Gewitter": "Strong thunderstorm", "Schweres Gewitter": "Severe thunderstorm",
    "Dauerregen": "Persistent rain", "Ergiebiger Dauerregen": "Heavy persistent rain", "Heftiger Starkregen": "Very heavy rain",
    "Extrem Ergiebiger Dauerregen": "Extremely heavy persistent rain", "Extrem Heftiger Starkregen": "Extremely heavy rain",
    "Schneeverwehung": "Snow drifts", "Starke Schneeverwehung": "Heavy snow drifts", "Extrem Starker Schneefall": "Extremely heavy snow",
    "Glätte": "Slippery roads", "Glatteis": "Black ice", "Strenger Frost": "Severe frost",
    "Starke Hitze": "Strong heat", "Extreme Hitze": "Extreme heat", "Tornado": "Tornado",
    "heute": "today", "morgen": "tomorrow", "bis %1": "until %1", "bis %1 km/h": "up to %1 km/h",
    "Amtliche Warnung (%1)": "Official warning (%1)", "Vorhersage": "Forecast",
    "Wetterwarnung (gelb)": "Weather warning (yellow)", "Wetterwarnung (orange)": "Weather warning (orange)",
    "Unwetterwarnung (rot)": "Severe weather warning (red)", "Extreme Unwetterwarnung (violett)": "Extreme weather warning (purple)",

    // ── Zusatzdaten ──
    "Birke": "Birch", "Gräser": "Grass", "Erle": "Alder", "Beifuss": "Mugwort", "Ambrosia": "Ragweed", "Olive": "Olive",
    "keine": "none", "gering": "low", "mässig": "moderate", "stark": "high", "sehr stark": "very high",
    "Pollen/m³": "pollen/m³",
    "gut": "good", "recht gut": "fair", "schlecht": "poor", "sehr schlecht": "very poor", "extrem schlecht": "extremely poor",
    "niedrig": "low", "hoch": "high", "sehr hoch": "very high", "extrem": "extreme",
    "Regen noch über 2 Std.": "Rain for 2+ hours", "Regen bis %1": "Rain until %1", "Kein Regen bis %1": "No rain until %1",
    "Regen ab %1": "Rain from %1", "ab %1": "from %1", "noch über 2 Std.": "for 2+ hours", "keiner bis %1": "none until %1", "Niederschlag je Viertelstunde (Open-Meteo)": "Precipitation per 15 minutes (Open-Meteo)",
    // ── Karte, Leiste und Meldungen ──
    "Lade Wetterdaten …": "Loading weather data …", "Jetzt aktualisieren": "Refresh now",
    "Nächster Ort": "Next location", "Vorheriger Ort": "Previous location", "Aktueller Standort": "Current location",
    "gefühlt %1°": "feels like %1°", "Wind aus %1 (%2°)": "Wind from the %1 (%2°)",
    "Höchst/Tiefst heute erst ab %1 Uhr bekannt": "Today's high/low only known from %1:00",
    "Höchst/Tiefst heute %1° / %2°, erst ab %3 Uhr bekannt": "Today's high/low %1° / %2°, only known from %3:00",
    "Stand %1": "As of %1", "Stand: %1": "As of: %1", "keine aktuellen Daten": "no current data",
    "Keine neuen Daten seit mehr als zwei Aktualisierungen": "No new data for more than two updates",
    "Sonnenaufgang %1 · Sonnenuntergang %2": "Sunrise %1 · sunset %2",
    "UV-Index heute höchstens %1 (%2)": "UV index today up to %1 (%2)", "Luft": "Air", "Pollen": "Pollen",
    "Europäischer Luftqualitätsindex %1 (%2)": "European Air Quality Index %1 (%2)",
    "Stundenwerte · zurück mit Klick auf den Tag": "Hourly values · click the day again to go back",
    "Bitte in den Einstellungen einen API-Schlüssel für %1 eintragen": "Please enter an API key for %1 in the settings",
    "Wetterdaten nicht lesbar: %1": "Weather data not readable: %1",
    "Wetterdaten von %1 nicht lesbar: %2": "Weather data from %1 not readable: %2",
    "Keine Wetterdaten (keine Verbindung)": "No weather data (no connection)",
    "Keine Wetterdaten (Fehler %1)": "No weather data (error %1)",
    "API-Schlüssel für %1 ungültig oder noch nicht freigeschaltet": "API key for %1 invalid or not activated yet",
    "%1 verweigert die Abfrage": "%1 refuses the request", "(Schlüssel gesperrt?)": "(key blocked?)",

    // ── Einstellungen ──
    "Ort": "Location", "Ort suchen:": "Search location:", "z.B. Luzern": "e.g. Lucerne", "Suchen": "Search",
    "Suche …": "Searching …", "Suche fehlgeschlagen (%1)": "Search failed (%1)", "Antwort nicht lesbar": "response not readable",
    "keine Verbindung": "no connection", "Kein Ort gefunden": "No location found",
    "Zur Ortsliste hinzufügen": "Add to location list", "Angezeigter Name:": "Displayed name:",
    "Hier änderst du nur die Beschriftung auf der Karte. Das Wetter kommt weiter von den Koordinaten unten. Für einen anderen Ort oben bei „Ort suchen“ suchen und einen Treffer anklicken.":
        "This only changes the label on the card. The weather still comes from the coordinates below. For a different location, use “Search location” above and click a result.",
    "Koordinaten:": "Coordinates:", "Ortsliste:": "Location list:", "Noch keine Orte gespeichert": "No locations saved yet",
    "Nach oben": "Move up", "Nach unten": "Move down", "Aus der Liste entfernen": "Remove from list",
    "Angezeigten Ort hinzufügen": "Add displayed location", "Standort:": "Your location:",
    "Automatisch bestimmen (über die IP-Adresse)": "Detect automatically (via IP address)",
    "Mehrere Orte: Auf der Karte mit ‹ › neben dem Ortsnamen, mit dem Mausrad oder im Kontextmenü umschalten. Der automatische Standort fragt den Dienst GeoJS nach dem ungefähren Ort deiner IP-Adresse (Stadt), höchstens alle 10 Minuten.":
        "Several locations: switch on the card with ‹ › next to the location name, with the mouse wheel or in the context menu. Automatic location asks the GeoJS service for the approximate location of your IP address (city), at most every 10 minutes.",
    "Wetterdaten": "Weather data", "Wetteranbieter:": "Weather provider:", "Wettermodell:": "Weather model:",
    "Automatisch (bestes Modell für den Ort)": "Automatic (best model for the location)",
    "MeteoSchweiz ICON-CH2 (Alpenraum, 4–5 Tage)": "MeteoSwiss ICON-CH2 (Alpine region, 4–5 days)", "Deutscher Wetterdienst ICON": "German Weather Service ICON",
    "ECMWF IFS (Europäisches Zentrum)": "ECMWF IFS (European Centre)", "NOAA GFS (USA)": "NOAA GFS (USA)",
    "Météo-France (3–4 Tage, ohne Regenwahrscheinlichkeit)": "Météo-France (3–4 days, no chance of rain)",
    "API-Schlüssel:": "API key:", "Schlüssel von %1": "Key from %1",
    "Kostenloser Zugang: Vorhersage in 3-Stunden-Schritten. Ein neuer Schlüssel kann bis zu 2 Stunden brauchen, bis er funktioniert.":
        "Free plan: forecast in 3-hour steps. A new key can take up to 2 hours to start working.",
    "Kostenloser Zugang: Vorhersage nur für 3 Tage, die 5-Tage-Liste zeigt dann 2 Tage.":
        "Free plan: forecast for 3 days only, so the 5-day list shows 2 days.",
    "Kostenlosen Schlüssel holen": "Get a free key", "Aktualisieren alle:": "Update every:",
    "Die Anbieter erneuern ihre Daten höchstens alle 15 Minuten, die Vorhersagen sogar nur alle 1–3 Stunden. Häufiger abzufragen bringt keine neueren Werte.":
        "Providers renew their data every 15 minutes at most, forecasts only every 1–3 hours. Querying more often brings no newer values.",
    "Anzeige": "Display", "Sprache:": "Language:", "Automatisch (Systemsprache)": "Automatic (system language)",
    "Einheit:": "Unit:", "Fahrenheit statt Celsius": "Fahrenheit instead of Celsius", "Animation:": "Animation:",
    "Wettersymbole animieren": "Animate weather icons", "Zusätzlich zeigen:": "Also show:",
    "Gefühlte Temperatur": "Feels-like temperature", "Infozeile: Sonnenauf- und -untergang, UV-Index": "Info line: sunrise and sunset, UV index",
    "Regen der nächsten 2 Stunden": "Rain in the next 2 hours", "Luftqualität und Pollen": "Air quality and pollen",
    "Regen, UV-Index, Luftqualität und Pollen kommen immer von Open-Meteo, auch bei einem anderen Wetteranbieter. Pollen gibt es nur für Europa. Ein Klick auf einen Tag der Vorschau zeigt dessen Stundenwerte.":
        "Rain, UV index, air quality and pollen always come from Open-Meteo, even with a different weather provider. Pollen is only available for Europe. Clicking a day in the forecast shows its hourly values.",
    "Warnungen": "Warnings", "Warnen vor:": "Warn about:", "Wind (ab Böen von 50 km/h, auch laut Vorhersage)": "Wind (gusts from 50 km/h, also from the forecast)",
    "Die amtlichen Warnungen von MeteoSchweiz kommen über MeteoAlarm, das Warnportal der europäischen Wetterdienste (EUMETNET). Das Widget lädt alle Schweizer Warnungen (etwa 1 MB, höchstens alle 20 Minuten) und prüft selbst, ob der Ort betroffen ist. Titel und Text bleiben im Wortlaut von MeteoSchweiz.":
        "The official MeteoSwiss warnings come via MeteoAlarm, the warning portal of the European weather services (EUMETNET). The widget loads all Swiss warnings (about 1 MB, at most every 20 minutes) and checks itself whether the location is affected. Title and text keep the wording of MeteoSwiss.",
    "Amtliche Warnungen:": "Official warnings:", "Schweiz (MeteoSchweiz)": "Switzerland (MeteoSwiss)",
    "Österreich (GeoSphere Austria)": "Austria (GeoSphere Austria)", "Deutschland (Deutscher Wetterdienst)": "Germany (German Weather Service)",
    "Benachrichtigung:": "Notification:", "Bei neuer Warnung ab": "For new warnings from",
    "Gelb": "Yellow", "Orange": "Orange", "Rot": "Red", "Violett": "Purple",
    "Gewarnt wird vor Wetter in den nächsten 24 Stunden. Wind wertet das Widget überall selbst aus der Vorhersage aus; alle Warnarten kommen in den angehakten Ländern als amtliche Warnung des Wetterdienstes. Dafür prüft das Widget einmal je Ort, in welchem Land er liegt (Schweiz: über swisstopo), und schickt danach die Koordinaten an den DWD bzw. GeoSphere, in der Schweiz die Postleitzahl an MeteoSchweiz. Jede Warnung wird nur einmal gemeldet, erneut nur, wenn sie stärker wird. Die Warnung ersetzt keine offizielle Unwetterwarnung.":
        "Warnings cover the next 24 hours. The widget evaluates wind itself everywhere from the forecast; all warning types come as official warnings from the weather service in the checked countries. For this, the widget checks once per location which country it is in (Switzerland: via swisstopo) and then sends the coordinates to the DWD or GeoSphere, in Switzerland the postal code to MeteoSwiss. Each warning is notified only once, again only if it gets stronger. These warnings do not replace official severe weather warnings.",
    "Aussehen": "Appearance", "Farbschema:": "Colour scheme:", "Vorschau:": "Preview:", "Eigene Farben:": "Custom colours:",
    "Violett (Standard)": "Purple (default)", "Blau": "Blue", "Grün": "Green", "Sonnenuntergang": "Sunset", "Nacht": "Night",
    "Eigene Farben": "Custom colours", "oben links": "top left", "unten rechts": "bottom right",
    "Farbe %1 wählen": "Choose colour %1", "Farbe für den Hintergrund wählen": "Choose background colour",
    "Diese Farben sind sehr hell: Die weisse Schrift ist darauf schlecht lesbar. Dunklere Farben wählen.":
        "These colours are very light: white text is hard to read on them. Choose darker colours.",
    "Glas-Effekt:": "Glass effect:", "Hintergrundbild verschwommen durchscheinen lassen": "Let the wallpaper shine through blurred",
    "Tönung Glas:": "Glass tint:", "Abdunklung Glas:": "Glass darkening:", "Deckkraft Hintergrund:": "Background opacity:",
    "Datenquellen und Lizenz": "Data sources and licence",
    "Wetterdaten: %1 · Ortssuche, Regen, UV, Luft: Open-Meteo.com (CC BY 4.0)": "Weather data: %1 · location search, rain, UV, air: Open-Meteo.com (CC BY 4.0)",
    "Mond: MET Norway (CC BY 4.0) · Messwerte: MeteoSchweiz, GeoSphere Austria (CC BY 4.0), Deutscher Wetterdienst über Bright Sky": "Moon: MET Norway (CC BY 4.0) · measurements: MeteoSwiss, GeoSphere Austria (CC BY 4.0), Deutscher Wetterdienst via Bright Sky",
    "Warnungen: GeoSphere Austria (CC BY 4.0), Deutscher Wetterdienst, MeteoSchweiz · Ortsprüfung: swisstopo · Standort: GeoJS": "Warnings: GeoSphere Austria (CC BY 4.0), Deutscher Wetterdienst, MeteoSwiss · location check: swisstopo · location: GeoJS",
    "Tux-Wetter ist freie Software unter der GPL-3.0-or-later.": "Tux-Wetter is free software under the GPL-3.0-or-later.",
    // ── Version 1.4 ──
    "MET Norway (yr.no)": "MET Norway (yr.no)", "gemessen": "measured",
    "Gemessen um %1 an der Station %2 (%3), %4 km entfernt": "Measured at %1 at station %2 (%3), %4 km away",
    "Vorhersagemodell: %1°": "Forecast model: %1°", "Wert des Vorhersagemodells": "Value from the forecast model",
    "Klicken öffnet die Warnseite von %1": "Click to open the warning page of %1",
    "Regenwahrscheinlichkeit %1 %": "Chance of rain %1 %", "Niederschlag %1 mm": "Precipitation %1 mm", "Neuschnee %1 cm": "New snow %1 cm",
    "%1 % beleuchtet": "%1 % illuminated", "Mondaufgang %1": "Moonrise %1", "Monduntergang %1": "Moonset %1",
    "Neumond": "New moon", "Zunehmende Sichel": "Waxing crescent", "Erstes Viertel": "First quarter",
    "Zunehmender Mond": "Waxing gibbous", "Vollmond": "Full moon", "Abnehmender Mond": "Waning gibbous",
    "Letztes Viertel": "Last quarter", "Abnehmende Sichel": "Waning crescent",
    "Helle Karte:": "Light card:", "Dunkle Schrift auf heller Karte (für helle Hintergrundbilder)": "Dark text on a light card (for light wallpapers)",
    "Infozeile: Sonnenauf- und -untergang, Mond, UV-Index": "Info line: sunrise and sunset, moon, UV index",
    "MET Norway: kostenlos und ohne Schlüssel, für Europa sehr gut. Böen und Regenwahrscheinlichkeit gibt es nur für Skandinavien; ohne Böen fehlt die eigene Windwarnung (amtliche Warnungen bleiben).":
        "MET Norway: free and without a key, very good for Europe. Gusts and chance of rain are only available for Scandinavia; without gusts there is no own wind warning (official warnings remain).",
    "Klicken zeigt %1": "Click to show %1", "auch für die anderen Orte der Ortsliste": "also for the other locations in the list",
    "Für die anderen Orte der Ortsliste holt das Widget die amtlichen Warnungen ebenfalls; ein Warndreieck neben ‹ › zeigt sie an.":
        "The widget also fetches official warnings for the other locations in the list; a warning triangle next to ‹ › shows them.",
    "Gemessene Temperatur (Schweiz, Österreich, Deutschland)": "Measured temperature (Switzerland, Austria, Germany)",
    "Die gemessene Temperatur stammt von der nächsten Station von MeteoSchweiz, GeoSphere Austria bzw. des DWD (bis 25 km, höchstens 300 m Höhenunterschied) und ersetzt den Modellwert. Mondauf- und -untergang kommen von MET Norway.":
        "The measured temperature comes from the nearest MeteoSwiss, GeoSphere Austria or DWD station (up to 25 km, at most 300 m difference in altitude) and replaces the model value. Moonrise and moonset come from MET Norway.",

    // ── Sicherung der Einstellungen ──
    "Frühere Einstellungen gefunden": "Earlier settings found",
    "Ein Tux-Wetter hat am %1 seine Einstellungen gesichert: %2.": "A Tux-Wetter widget saved its settings on %1: %2.",
    "1 Ort in der Ortsliste": "1 location in the list", "%1 Orte in der Ortsliste": "%1 locations in the list",
    "Diese Einstellungen übernehmen?": "Use these settings?", "Übernehmen": "Use them", "Nein, neu einrichten": "No, start fresh",
    "Sicherung": "Backup",
    "Wird das Widget vom Desktop entfernt, löscht Plasma seine Einstellungen. Tux-Wetter sichert sie darum selbst; ein neu hinzugefügtes Widget bietet an, sie zu übernehmen. Für einen anderen Rechner die Einstellungen in eine Datei sichern.":
        "When the widget is removed from the desktop, Plasma deletes its settings. Tux-Wetter therefore backs them up itself; a newly added widget offers to restore them. To move to another computer, save the settings to a file.",
    "Datei:": "File:", "In Datei sichern …": "Save to file …", "Aus Datei laden …": "Load from file …",
    "API-Schlüssel mitsichern": "Include API keys", "Automatisch gesichert:": "Automatic backups:", "Laden": "Load",
    "Einstellungen sichern": "Save settings", "Einstellungen laden": "Load settings",
    "Tux-Wetter-Einstellungen (*.json)": "Tux-Wetter settings (*.json)", "Alle Dateien (*)": "All files (*)",
    "Einstellungen gesichert in %1": "Settings saved to %1", "Sichern nicht möglich: %1": "Could not save: %1",
    "Datei nicht lesbar: %1": "Could not read file: %1",
    "Diese Datei enthält keine Einstellungen von Tux-Wetter.": "This file does not contain Tux-Wetter settings.",
    "Einstellungen geladen. Mit OK oder Anwenden übernehmen.": "Settings loaded. Press OK or Apply to use them.",

    // ── Deutscher Wetterdienst (MOSMIX) ──
    "über Bright Sky": "via Bright Sky",
    "%1 über %2": "%1 via %2",

    // ── Quellenangaben (anbieter.js quellenZeile/quellenListe) ──
    "Daten: %1": "Data: %1", "Datenbasis: %1": "Data basis: %1", "Wetterdaten: %1": "Weather data: %1", "über %1": "via %1",
    "Ortssuche, Regen, UV, Sonnenzeiten: %1": "Location search, rain, UV, sun times: %1",
    "Luft und Pollen: %1": "Air quality and pollen: %1",
    "Ortsnamen der Suche: %1": "Place names for the search: %1",
    "Enthält veränderte Informationen des %1 %2.": "Contains modified %1 information %2.",
    "Weder die Europäische Kommission noch das ECMWF sind für die Verwendung dieser Informationen verantwortlich.":
        "Neither the European Commission nor ECMWF is responsible for any use that may be made of the Copernicus information or data it contains.",
    "Mond: %1": "Moon: %1", "Messwerte: %1": "Measurements: %1", "Warnungen: %1": "Warnings: %1",
    "Ortsprüfung: %1 · Standort: %2": "Location check: %1 · Position: %2",
    "Die Daten werden vom Widget aufbereitet: umgerechnet, zusammengefasst und zum Teil daraus berechnet (z. B. Tageswerte, gefühlte Temperatur).":
        "The widget processes the data: converted, summarised and partly derived (e.g. daily values, feels-like temperature).",
    "Tux-Wetter ist freie Software unter der %1.": "Tux-Wetter is free software under the %1.",
    "Das gewählte Wettermodell deckt diesen Ort nicht ab. Bitte in den Einstellungen ein anderes Modell wählen.":
        "The selected weather model does not cover this location. Please choose another model in the settings.",
    "Keine Vorhersagestation des DWD in der Nähe (bis 50 km). Bitte einen anderen Wetteranbieter wählen.":
        "No DWD forecast station nearby (within 50 km). Please choose another weather provider.",
    "Deutscher Wetterdienst: kostenlos und ohne Schlüssel. Die Werte kommen von der nächsten Vorhersagestation des DWD (MOSMIX, abgerufen über Bright Sky): sehr dicht in Deutschland, Österreich und der Schweiz, weltweit gut 5000 Stationen. Ohne Station im Umkreis von 50 km gibt es keine Daten.":
        "Deutscher Wetterdienst (German weather service): free and without a key. The values come from the nearest DWD forecast station (MOSMIX, retrieved via Bright Sky): very dense in Germany, Austria and Switzerland, more than 5000 stations worldwide. Without a station within 50 km there is no data.",

    // ── Neue Versionen ──
    "Tux-Wetter %1 ist erschienen": "Tux-Wetter %1 is available",
    "Installiert ist %1. Die neue Version gibt es auf GitHub; das Widget lädt sie nicht selbst herunter.":
        "Installed is %1. The new version is available on GitHub; the widget does not download it by itself.",
    "Download-Seite öffnen": "Open download page",
    "Diese Version überspringen": "Skip this version",
    "Neue Versionen": "New versions", "Update-Hinweis:": "Update notice:",
    "Auf GitHub nach neuen Versionen suchen": "Check GitHub for new versions",
    "Einmal am Tag fragt das Widget bei GitHub nach der neuesten Version. Ist sie neuer, erscheint ein Hinweis mit einem Link zur Download-Seite. Das Widget lädt und installiert nichts selbst.":
        "Once a day the widget asks GitHub for the latest version. If it is newer, a notice with a link to the download page appears. The widget does not download or install anything by itself."
}

function t(sp, text) {
    let s = sp === "en" && EN[text] !== undefined ? EN[text] : text
    for (let i = 2; i < arguments.length; i++)
        s = s.split("%" + (i - 1)).join(String(arguments[i]))
    return s
}

// Gibt es eine englische Übersetzung?
function hat(text) {
    return EN[text] !== undefined
}

// Einstellung "auto", "de" oder "en" → Sprache; automatisch Deutsch bei deutscher Systemsprache,
// sonst Englisch
function aufloesen(einstellung, systemSprache) {
    if (einstellung === "de" || einstellung === "en")
        return einstellung
    return String(systemSprache).substring(0, 2) === "de" ? "de" : "en"
}
