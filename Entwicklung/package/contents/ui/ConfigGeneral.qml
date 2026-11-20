// SPDX-FileCopyrightText: 2026 R.Bruns
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import "anbieter.js" as A
import "farben.js" as Fa
import "sprache.js" as T
import QtQuick.Dialogs as Dialoge
import QtQuick.LocalStorage as Speicher
import QtCore
import org.kde.plasma.plasma5support as P5
import "sicherung.js" as S

KCM.SimpleKCM {
    id: seite

    property string cfg_locationName
    property real cfg_latitude
    property real cfg_longitude
    property string cfg_provider
    property string cfg_weatherModel
    property string cfg_owmApiKey
    property string cfg_weatherApiKey
    property bool cfg_windWarning
    property bool cfg_thunderWarning
    property bool cfg_rainWarning
    property bool cfg_snowWarning
    property bool cfg_iceWarning
    property bool cfg_heatWarning
    property bool cfg_dwdWarnings
    property bool cfg_meteoSwissWarnings
    property bool cfg_geoSphereWarnings
    property string cfg_warnArea
    property string cfg_colorScheme
    property string cfg_customColorStart
    property string cfg_customColorEnd
    property bool cfg_useFahrenheit
    property int cfg_updateInterval
    property bool cfg_animations
    property bool cfg_glassEffect
    property int cfg_glassTint
    property int cfg_glassDarken
    property int cfg_backgroundOpacity
    property string cfg_language
    property bool cfg_showDetails
    property bool cfg_feelsLike
    property bool cfg_rainNowcast
    property bool cfg_airQuality
    property bool cfg_notifications
    property int cfg_notifyLevel
    property string cfg_places
    property bool cfg_autoLocation
    property bool cfg_autoActive
    property string cfg_autoPlace
    property bool cfg_measuredTemp
    property bool cfg_lightCard
    property string cfg_warnAreas
    // Vom Widget selbst gesetzt (gemerkte Grösse auf der Arbeitsfläche), nicht im Dialog
    property int cfg_lastWidth
    property int cfg_lastHeight
    property bool cfg_notifyAllPlaces
    property bool cfg_restoreChecked

    // Plasma übergibt zu jeder Einstellung auch den Standardwert; ohne diese Eigenschaften
    // schreibt es beim Öffnen der Einstellungen für jede eine Warnung ins Log
    property var cfg_locationNameDefault
    property var cfg_latitudeDefault
    property var cfg_longitudeDefault
    property var cfg_providerDefault
    property var cfg_weatherModelDefault
    property var cfg_owmApiKeyDefault
    property var cfg_weatherApiKeyDefault
    property var cfg_windWarningDefault
    property var cfg_thunderWarningDefault
    property var cfg_rainWarningDefault
    property var cfg_snowWarningDefault
    property var cfg_iceWarningDefault
    property var cfg_heatWarningDefault
    property var cfg_dwdWarningsDefault
    property var cfg_meteoSwissWarningsDefault
    property var cfg_geoSphereWarningsDefault
    property var cfg_warnAreaDefault
    property var cfg_colorSchemeDefault
    property var cfg_customColorStartDefault
    property var cfg_customColorEndDefault
    property var cfg_useFahrenheitDefault
    property var cfg_updateIntervalDefault
    property var cfg_animationsDefault
    property var cfg_glassEffectDefault
    property var cfg_glassTintDefault
    property var cfg_glassDarkenDefault
    property var cfg_backgroundOpacityDefault
    property var cfg_languageDefault
    property var cfg_showDetailsDefault
    property var cfg_feelsLikeDefault
    property var cfg_rainNowcastDefault
    property var cfg_airQualityDefault
    property var cfg_notificationsDefault
    property var cfg_notifyLevelDefault
    property var cfg_placesDefault
    property var cfg_autoLocationDefault
    property var cfg_autoActiveDefault
    property var cfg_autoPlaceDefault
    property var cfg_measuredTempDefault
    property var cfg_lightCardDefault
    property var cfg_warnAreasDefault
    property var cfg_lastWidthDefault
    property var cfg_lastHeightDefault
    property var cfg_notifyAllPlacesDefault
    property var cfg_restoreCheckedDefault

    // Sprache der Seite: wie gewählt, sonst nach der Systemsprache
    readonly property string uiSprache: T.aufloesen(cfg_language, Qt.locale().name)
    function t(text) {
        return T.t.apply(null, [uiSprache].concat(Array.prototype.slice.call(arguments)))
    }

    // Ist mindestens eine Warnart eingeschaltet? Sonst braucht es keine amtlichen Warnungen
    readonly property bool warnungenAn: cfg_windWarning || cfg_thunderWarning || cfg_rainWarning
                                        || cfg_snowWarning || cfg_iceWarning || cfg_heatWarning

    // Verlauf und Schimmer des gewählten Farbschemas für die Vorschau, und der schlechteste Kontrast
    // der weissen Schrift darauf
    readonly property var verlauf: Fa.verlauf(cfg_colorScheme, cfg_customColorStart, cfg_customColorEnd)
    readonly property color schimmer: Fa.schimmer(cfg_colorScheme, cfg_customColorStart)
    readonly property real kontrast: Math.min(...verlauf.map(f => Fa.kontrastWeiss(f)))

    // ── Sicherung der Einstellungen: Datei und automatische Sicherungen (siehe sicherung.js) ──
    property string sicherungMeldung: ""
    property int sicherungArt: Kirigami.MessageType.Positive
    function sicherungMelden(text, fehler) {
        sicherungArt = fehler ? Kirigami.MessageType.Error : Kirigami.MessageType.Positive
        sicherungMeldung = text
    }
    // Einstellungen einer Sicherung in die Seite übernehmen; gespeichert wird erst mit OK/Anwenden
    function einstellungenSetzen(e) {
        for (const n in e)
            if (!S.gleich(seite["cfg_" + n], e[n]))
                seite["cfg_" + n] = e[n]
        nameVonHand = false
    }
    // Text für die Shell in einfachen Anführungszeichen (ein ' wird zu '\'')
    function shellText(text) {
        return "'" + String(text).replace(/'/g, "'\\''") + "'"
    }
    function shellPfad(url) {
        return shellText(decodeURIComponent(String(url).replace(/^file:\/\//, "")))
    }
    // Automatische Sicherungen aus dem Speicher, neueste zuerst: [{ stand, einstellungen, text }]
    property var autoSicherungen: []
    function autoSicherungenLesen() {
        const liste = []
        try {
            Speicher.LocalStorage.openDatabaseSync("TuxWetter", "", "Letzte Wetterdaten", 100000).transaction(function (tx) {
                tx.executeSql("CREATE TABLE IF NOT EXISTS einstellungen (widget TEXT PRIMARY KEY, stand REAL, inhalt TEXT)")
                const r = tx.executeSql("SELECT stand, inhalt FROM einstellungen ORDER BY stand DESC")
                for (let i = 0; i < r.rows.length; i++) {
                    const z = r.rows.item(i), s = S.pruefen(z.inhalt)
                    if (!s)
                        continue
                    const n = S.anzahlOrte(s.einstellungen)
                    liste.push({ stand: z.stand, einstellungen: s.einstellungen,
                                 text: Qt.formatDateTime(new Date(z.stand), uiSprache === "en" ? "yyyy-MM-dd HH:mm" : "dd.MM.yyyy HH:mm")
                                       + " · " + (s.einstellungen.locationName || "–")
                                       + (n > 0 ? " · " + t(n === 1 ? "1 Ort in der Ortsliste" : "%1 Orte in der Ortsliste", n) : "") })
                }
            })
        } catch (e) {
            console.warn("TuX-Wetter: Sicherungen nicht lesbar:", e)
        }
        autoSicherungen = liste
    }
    Component.onCompleted: autoSicherungenLesen()

    // Dateien schreiben und lesen über die Shell (QML selbst darf keine Dateien schreiben)
    property var befehlFertig: ({})
    P5.DataSource {
        id: shell
        engine: "executable"
        onNewData: (quelle, daten) => {
            const fertig = seite.befehlFertig[quelle]
            delete seite.befehlFertig[quelle]
            disconnectSource(quelle)
            if (fertig)
                fertig(daten["exit code"], daten.stdout || "", daten.stderr || "")
        }
    }
    function ausfuehren(befehl, fertig) {
        befehlFertig[befehl] = fertig
        shell.connectSource(befehl)
    }

    function inDateiSichern(url) {
        const inhalt = S.datei(n => seite["cfg_" + n], mitSchluesseln.checked, Date.now())
        ausfuehren("printf '%s' " + shellText(inhalt) + " > " + shellPfad(url), (code, aus, fehler) => {
            if (code === 0)
                sicherungMelden(t("Einstellungen gesichert in %1", decodeURIComponent(String(url).replace(/^file:\/\//, ""))), false)
            else
                sicherungMelden(t("Sichern nicht möglich: %1", fehler.trim() || code), true)
        })
    }

    function ausDateiLaden(url) {
        ausfuehren("head -c 1000000 " + shellPfad(url), (code, aus, fehler) => {
            if (code !== 0)
                return sicherungMelden(t("Datei nicht lesbar: %1", fehler.trim() || code), true)
            const s = S.pruefen(aus)
            if (!s)
                return sicherungMelden(t("Diese Datei enthält keine Einstellungen von TuX-Wetter."), true)
            einstellungenSetzen(s.einstellungen)
            sicherungMelden(t("Einstellungen geladen. Mit OK oder Anwenden übernehmen."), false)
        })
    }

    readonly property var anbieter: A.ANBIETER.find(a => a.id === cfg_provider) || A.ANBIETER[0]

    // ── Ortsliste (JSON in cfg_places) ──
    readonly property var orte: {
        try {
            const o = JSON.parse(cfg_places || "[]")
            return Array.isArray(o) ? o : []
        } catch (e) {
            return []
        }
    }
    function orteSetzen(liste) {
        cfg_places = JSON.stringify(liste)
    }
    function ortHinzufuegen(name, b, l) {
        if (orte.some(o => Math.abs(o.lat - b) < 1e-4 && Math.abs(o.lon - l) < 1e-4))
            return
        orteSetzen(orte.concat([{ name: name, lat: b, lon: l }]))
    }
    function ortVerschieben(i, schritt) {
        const j = i + schritt
        if (j < 0 || j >= orte.length)
            return
        const neu = orte.slice()
        const x = neu[i]; neu[i] = neu[j]; neu[j] = x
        orteSetzen(neu)
    }

    property var treffer: []
    property string suchMeldung: ""
    // Wurde der angezeigte Name von Hand geändert (nicht über die Suche)? Dann bleibt der Ort derselbe
    property bool nameVonHand: false

    // „Schondra (DE)“ oder „Schondra, DE“ → Name „Schondra“ und Länderkürzel „DE“
    function suchbegriff(eingabe) {
        const m = eingabe.match(/^(.*?)\s*(?:\(([A-Za-z]{2})\)|,\s*([A-Za-z]{2}))$/)
        return m && m[1] ? { name: m[1], land: (m[2] || m[3]).toUpperCase() } : { name: eingabe, land: "" }
    }

    property int suchNr: 0   // nur die Antworten der letzten Suche zählen

    // Name zum Vergleichen: klein, Umlaute als ae/oe/ue, ß als ss, ohne Akzente („Genève“ = „geneve“)
    function vergleichsName(s) {
        return String(s).toLowerCase().replace(/ä/g, "ae").replace(/ö/g, "oe").replace(/ü/g, "ue").replace(/ß/g, "ss")
                        .normalize("NFD").replace(/[\u0300-\u036f]/g, "").trim()
    }

    // „Zuerich“ → „Zürich“; nur als zusätzliche Suche, denn manche Namen schreiben sich mit oe (Soest)
    function mitUmlauten(s) {
        return s.replace(/ae/g, "ä").replace(/oe/g, "ö").replace(/ue/g, "ü")
                .replace(/Ae/g, "Ä").replace(/Oe/g, "Ö").replace(/Ue/g, "Ü")
    }

    // Eine Anfrage an die Ortssuche; antwort(status, treffer) mit status 200 oder Fehlercode/0
    function ortsAnfrage(name, sprache, antwort) {
        const xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return
            if (xhr.status !== 200)
                return antwort(xhr.status || 0, [])
            try {
                antwort(200, JSON.parse(xhr.responseText).results || [])
            } catch (e) {
                antwort(-1, [])
            }
        }
        xhr.open("GET", "https://geocoding-api.open-meteo.com/v1/search?count=10&language=" + sprache
                 + "&name=" + encodeURIComponent(name))
        xhr.send()
    }

    // Sucht gleichzeitig auf Deutsch und Englisch („New York“ findet die Stadt nur auf Englisch, „Neuchâtel“
    // heisst auf Deutsch „Neuenburg“) und mit Umlauten statt ae/oe/ue („Zuerich“). Ein Ort zählt als genauer
    // Treffer, wenn einer seiner Namen passt; genaue Treffer kommen zuerst, grosse vor kleinen. Angezeigt wird
    // der Name in der Anzeigesprache.
    function suchen() {
        const begriff = suchbegriff(suchFeld.text.trim())
        const name = begriff.name
        if (!name)
            return
        const nr = ++suchNr
        const anfragen = [[name, uiSprache]]
        if (mitUmlauten(name) !== name)
            anfragen.push([mitUmlauten(name), uiSprache])
        anfragen.push([name, uiSprache === "de" ? "en" : "de"])
        const ergebnisse = [], status = []
        let offen = anfragen.length
        suchMeldung = t("Suche …")
        treffer = []
        anfragen.forEach((anfrage, i) => ortsAnfrage(anfrage[0], anfrage[1], function (s, liste) {
            if (nr !== suchNr)
                return
            ergebnisse[i] = liste
            status[i] = s
            if (--offen > 0)
                return
            if (status.every(x => x !== 200)) {
                const s0 = status[0]
                suchMeldung = t("Suche fehlgeschlagen (%1)", s0 > 0 ? s0 : s0 < 0 ? t("Antwort nicht lesbar") : t("keine Verbindung"))
                return
            }
            trefferZeigen(ergebnisse, vergleichsName(name), begriff.land)
        }))
    }

    // ergebnisse: Trefferlisten der Anfragen in fester Reihenfolge (Anzeigesprache zuerst)
    function trefferZeigen(ergebnisse, gesucht, land) {
        const orte = {}, reihe = []
        ergebnisse.forEach(liste => (liste || []).forEach(t => {
            if (!orte[t.id]) {
                orte[t.id] = { t: t, genau: false, nr: reihe.length }
                reihe.push(orte[t.id])
            }
            if (vergleichsName(t.name) === gesucht)
                orte[t.id].genau = true
        }))
        let r = reihe
        // Mit Länderkürzel nur Orte in diesem Land, sofern es dort welche gibt
        const imLand = r.filter(o => String(o.t.country_code || "").toUpperCase() === land)
        if (imLand.length)
            r = imLand
        r = r.slice().sort((a, b) => (b.genau - a.genau)
                                     || (a.genau && b.genau ? (b.t.population || 0) - (a.t.population || 0) : 0)
                                     || a.nr - b.nr)
             .slice(0, 10).map(o => o.t)
        treffer = r.map(t => ({
            name: t.name,
            text: t.name + [t.admin1, t.country].filter(x => x).map(x => ", " + x).join(""),
            lat: t.latitude,
            lon: t.longitude
        }))
        suchMeldung = treffer.length ? "" : t("Kein Ort gefunden")
    }

    Kirigami.FormLayout {

        // ════ Ort ════
        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: seite.t("Ort")
        }

        RowLayout {
            Kirigami.FormData.label: seite.t("Ort suchen:")
            QQC2.TextField {
                id: suchFeld
                placeholderText: seite.t("z.B. Luzern")
                onAccepted: seite.suchen()
            }
            QQC2.Button {
                text: seite.t("Suchen")
                icon.name: "search"
                onClicked: seite.suchen()
            }
        }

        QQC2.Label {
            visible: seite.suchMeldung !== ""
            text: seite.suchMeldung
        }

        // Treffer in einem eigenen Behälter: Kirigamis FormLayout kommt mit Einträgen, die ein Repeater
        // erst nach einer Suche erzeugt, nicht zurecht (sie erscheinen nicht, im Log stehen TypeErrors)
        ColumnLayout {
            visible: seite.treffer.length > 0
            spacing: 0
            Repeater {
                model: seite.treffer
                RowLayout {
                    id: trefferZeile
                    required property var modelData
                    spacing: 0
                    QQC2.Button {
                        text: trefferZeile.modelData.text
                        flat: true
                        icon.name: "mark-location"
                        onClicked: {
                            seite.cfg_locationName = trefferZeile.modelData.name
                            seite.cfg_latitude = trefferZeile.modelData.lat
                            seite.cfg_longitude = trefferZeile.modelData.lon
                            // Ein fest gewählter Ort ersetzt den automatischen Standort
                            seite.cfg_autoActive = false
                            seite.nameVonHand = false
                            // Zuletzt: Das Leeren der Liste löscht auch diesen Knopf samt seinem Kontext
                            seite.treffer = []
                        }
                    }
                    QQC2.ToolButton {
                        icon.name: "list-add"
                        QQC2.ToolTip.visible: hovered
                        QQC2.ToolTip.text: seite.t("Zur Ortsliste hinzufügen")
                        onClicked: seite.ortHinzufuegen(trefferZeile.modelData.name, trefferZeile.modelData.lat,
                                                        trefferZeile.modelData.lon)
                    }
                }
            }
        }

        QQC2.TextField {
            Kirigami.FormData.label: seite.t("Angezeigter Name:")
            text: seite.cfg_locationName
            onTextEdited: {
                seite.cfg_locationName = text
                seite.nameVonHand = true
            }
        }

        Kirigami.InlineMessage {
            Layout.preferredWidth: Kirigami.Units.gridUnit * 22
            visible: seite.nameVonHand
            type: Kirigami.MessageType.Information
            text: seite.t("Hier änderst du nur die Beschriftung auf der Karte. Das Wetter kommt weiter von den "
                          + "Koordinaten unten. Für einen anderen Ort oben bei „Ort suchen“ suchen und einen Treffer anklicken.")
        }

        QQC2.Label {
            Kirigami.FormData.label: seite.t("Koordinaten:")
            text: seite.cfg_latitude.toFixed(4) + " / " + seite.cfg_longitude.toFixed(4)
        }

        // Gespeicherte Orte: auf der Karte mit ‹ › oder dem Mausrad umschalten
        ColumnLayout {
            Kirigami.FormData.label: seite.t("Ortsliste:")
            spacing: 0
            QQC2.Label {
                visible: seite.orte.length === 0
                text: seite.t("Noch keine Orte gespeichert")
                opacity: 0.7
            }
            Repeater {
                model: seite.orte
                RowLayout {
                    id: ortZeile
                    required property var modelData
                    required property int index
                    spacing: 0
                    QQC2.Label {
                        Layout.minimumWidth: Kirigami.Units.gridUnit * 10
                        text: ortZeile.modelData.name
                        font.bold: !seite.cfg_autoActive && Math.abs(ortZeile.modelData.lat - seite.cfg_latitude) < 1e-4
                                   && Math.abs(ortZeile.modelData.lon - seite.cfg_longitude) < 1e-4
                    }
                    QQC2.ToolButton {
                        icon.name: "go-up"
                        enabled: ortZeile.index > 0
                        QQC2.ToolTip.visible: hovered
                        QQC2.ToolTip.text: seite.t("Nach oben")
                        onClicked: seite.ortVerschieben(ortZeile.index, -1)
                    }
                    QQC2.ToolButton {
                        icon.name: "go-down"
                        enabled: ortZeile.index < seite.orte.length - 1
                        QQC2.ToolTip.visible: hovered
                        QQC2.ToolTip.text: seite.t("Nach unten")
                        onClicked: seite.ortVerschieben(ortZeile.index, 1)
                    }
                    QQC2.ToolButton {
                        icon.name: "list-remove"
                        QQC2.ToolTip.visible: hovered
                        QQC2.ToolTip.text: seite.t("Aus der Liste entfernen")
                        onClicked: seite.orteSetzen(seite.orte.filter((o, i) => i !== ortZeile.index))
                    }
                }
            }
            QQC2.Button {
                text: seite.t("Angezeigten Ort hinzufügen")
                icon.name: "list-add"
                enabled: !seite.orte.some(o => Math.abs(o.lat - seite.cfg_latitude) < 1e-4
                                               && Math.abs(o.lon - seite.cfg_longitude) < 1e-4)
                onClicked: seite.ortHinzufuegen(seite.cfg_locationName, seite.cfg_latitude, seite.cfg_longitude)
            }
        }

        QQC2.CheckBox {
            Kirigami.FormData.label: seite.t("Standort:")
            text: seite.t("Automatisch bestimmen (über die IP-Adresse)")
            checked: seite.cfg_autoLocation
            onToggled: {
                seite.cfg_autoLocation = checked
                seite.cfg_autoActive = checked
            }
        }

        QQC2.Label {
            Layout.maximumWidth: Kirigami.Units.gridUnit * 22
            wrapMode: Text.WordWrap
            opacity: 0.7
            text: seite.t("Mehrere Orte: Auf der Karte mit ‹ › neben dem Ortsnamen, mit dem Mausrad oder im Kontextmenü "
                          + "umschalten. Der automatische Standort fragt den Dienst GeoJS nach dem ungefähren Ort deiner "
                          + "IP-Adresse (Stadt), höchstens alle 10 Minuten.")
        }

        // ════ Wetterdaten ════
        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: seite.t("Wetterdaten")
        }

        QQC2.ComboBox {
            Kirigami.FormData.label: seite.t("Wetteranbieter:")
            implicitContentWidthPolicy: QQC2.ComboBox.WidestText
            model: A.ANBIETER
            textRole: "name"
            valueRole: "id"
            // Als Bindung, damit eine geladene Sicherung auch die Auswahl umstellt
            currentIndex: Math.max(0, A.ANBIETER.findIndex(a => a.id === seite.cfg_provider))
            onActivated: seite.cfg_provider = currentValue
        }

        QQC2.ComboBox {
            Kirigami.FormData.label: seite.t("Wettermodell:")
            implicitContentWidthPolicy: QQC2.ComboBox.WidestText
            visible: seite.cfg_provider === "openmeteo"
            model: A.MODELLE.map(m => seite.t(m.name))
            // Die Einträge hängen an der Sprache: Wechselt sie, setzt die Liste ihre Auswahl auf den ersten
            // Eintrag zurück. Danach die Bindung an die Einstellung wiederherstellen.
            readonly property int soll: Math.max(0, A.MODELLE.findIndex(m => m.id === seite.cfg_weatherModel))
            currentIndex: soll
            onModelChanged: Qt.callLater(() => currentIndex = Qt.binding(() => soll))
            onActivated: index => seite.cfg_weatherModel = A.MODELLE[index].id
        }

        Kirigami.PasswordField {
            Kirigami.FormData.label: seite.t("API-Schlüssel:")
            visible: seite.anbieter.schluessel
            placeholderText: seite.t("Schlüssel von %1", seite.anbieter.name)
            text: seite.cfg_provider === "openweathermap" ? seite.cfg_owmApiKey : seite.cfg_weatherApiKey
            onTextEdited: {
                if (seite.cfg_provider === "openweathermap")
                    seite.cfg_owmApiKey = text
                else
                    seite.cfg_weatherApiKey = text
            }
        }

        QQC2.Label {
            visible: seite.anbieter.schluessel
            Layout.maximumWidth: Kirigami.Units.gridUnit * 22
            wrapMode: Text.WordWrap
            text: (seite.cfg_provider === "openweathermap"
                   ? seite.t("Kostenloser Zugang: Vorhersage in 3-Stunden-Schritten. Ein neuer Schlüssel kann bis zu "
                             + "2 Stunden brauchen, bis er funktioniert.")
                   : seite.t("Kostenloser Zugang: Vorhersage nur für 3 Tage, die 5-Tage-Liste zeigt dann 2 Tage."))
                  + " <a href=\"" + seite.anbieter.seite + "\">" + seite.t("Kostenlosen Schlüssel holen") + "</a>"
            textFormat: Text.StyledText
            onLinkActivated: link => Qt.openUrlExternally(link)
            HoverHandler { cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor }
        }

        QQC2.Label {
            visible: seite.cfg_provider === "metno"
            Layout.maximumWidth: Kirigami.Units.gridUnit * 22
            wrapMode: Text.WordWrap
            opacity: 0.7
            text: seite.t("MET Norway: kostenlos und ohne Schlüssel, für Europa sehr gut. Böen und Regenwahrscheinlichkeit gibt es nur für Skandinavien; ohne Böen fehlt die eigene Windwarnung (amtliche Warnungen bleiben).")
        }

        QQC2.Label {
            visible: seite.cfg_provider === "dwd"
            Layout.maximumWidth: Kirigami.Units.gridUnit * 22
            wrapMode: Text.WordWrap
            opacity: 0.7
            text: seite.t("Deutscher Wetterdienst: kostenlos und ohne Schlüssel. Die Werte kommen von der nächsten Vorhersagestation des DWD (MOSMIX, abgerufen über Bright Sky): sehr dicht in Deutschland, Österreich und der Schweiz, weltweit gut 5000 Stationen. Ohne Station im Umkreis von 50 km gibt es keine Daten.")
        }

        QQC2.SpinBox {
            Kirigami.FormData.label: seite.t("Aktualisieren alle:")
            from: 10
            to: 180
            value: seite.cfg_updateInterval
            onValueModified: seite.cfg_updateInterval = value
            textFromValue: (v) => v + " min"
            valueFromText: (t) => parseInt(t)
        }

        QQC2.Label {
            Layout.maximumWidth: Kirigami.Units.gridUnit * 22
            wrapMode: Text.WordWrap
            opacity: 0.7
            text: seite.t("Die Anbieter erneuern ihre Daten höchstens alle 15 Minuten, die Vorhersagen "
                          + "sogar nur alle 1–3 Stunden. Häufiger abzufragen bringt keine neueren Werte.")
        }

        // ════ Anzeige ════
        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: seite.t("Anzeige")
        }

        QQC2.ComboBox {
            Kirigami.FormData.label: seite.t("Sprache:")
            implicitContentWidthPolicy: QQC2.ComboBox.WidestText
            readonly property var werte: ["auto", "de", "en"]
            model: [seite.t("Automatisch (Systemsprache)"), "Deutsch", "English"]
            // Die Einträge hängen an der Sprache: Wechselt sie, setzt die Liste ihre Auswahl auf den ersten
            // Eintrag zurück. Danach die Bindung an die Einstellung wiederherstellen.
            readonly property int soll: Math.max(0, werte.indexOf(seite.cfg_language))
            currentIndex: soll
            onModelChanged: Qt.callLater(() => currentIndex = Qt.binding(() => soll))
            onActivated: index => seite.cfg_language = werte[index]
        }

        QQC2.CheckBox {
            Kirigami.FormData.label: seite.t("Einheit:")
            text: seite.t("Fahrenheit statt Celsius")
            checked: seite.cfg_useFahrenheit
            onToggled: seite.cfg_useFahrenheit = checked
        }

        QQC2.CheckBox {
            Kirigami.FormData.label: seite.t("Animation:")
            text: seite.t("Wettersymbole animieren")
            checked: seite.cfg_animations
            onToggled: seite.cfg_animations = checked
        }

        QQC2.CheckBox {
            Kirigami.FormData.label: seite.t("Zusätzlich zeigen:")
            text: seite.t("Gefühlte Temperatur")
            checked: seite.cfg_feelsLike
            onToggled: seite.cfg_feelsLike = checked
        }
        QQC2.CheckBox {
            text: seite.t("Gemessene Temperatur (Schweiz, Österreich, Deutschland)")
            checked: seite.cfg_measuredTemp
            onToggled: seite.cfg_measuredTemp = checked
        }
        QQC2.CheckBox {
            text: seite.t("Infozeile: Sonnenauf- und -untergang, Mond, UV-Index")
            checked: seite.cfg_showDetails
            onToggled: seite.cfg_showDetails = checked
        }
        QQC2.CheckBox {
            enabled: seite.cfg_showDetails
            text: seite.t("Regen der nächsten 2 Stunden")
            checked: seite.cfg_rainNowcast
            onToggled: seite.cfg_rainNowcast = checked
        }
        QQC2.CheckBox {
            enabled: seite.cfg_showDetails
            text: seite.t("Luftqualität und Pollen")
            checked: seite.cfg_airQuality
            onToggled: seite.cfg_airQuality = checked
        }

        QQC2.Label {
            Layout.maximumWidth: Kirigami.Units.gridUnit * 22
            wrapMode: Text.WordWrap
            opacity: 0.7
            text: seite.t("Regen, UV-Index, Luftqualität und Pollen kommen immer von Open-Meteo, auch bei einem anderen "
                          + "Wetteranbieter. Pollen gibt es nur für Europa. Ein Klick auf einen Tag der Vorschau zeigt "
                          + "dessen Stundenwerte.") + " "
                  + seite.t("Die gemessene Temperatur stammt von der nächsten Station von MeteoSchweiz, GeoSphere Austria bzw. des DWD (bis 25 km, höchstens 300 m Höhenunterschied) und ersetzt den Modellwert. Mondauf- und -untergang kommen von MET Norway.")
        }

        // ════ Warnungen ════
        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: seite.t("Warnungen")
        }

        QQC2.CheckBox {
            Kirigami.FormData.label: seite.t("Warnen vor:")
            text: seite.t("Wind (ab Böen von 50 km/h, auch laut Vorhersage)")
            checked: seite.cfg_windWarning
            onToggled: seite.cfg_windWarning = checked
        }
        QQC2.CheckBox {
            text: seite.t("Gewitter")
            checked: seite.cfg_thunderWarning
            onToggled: seite.cfg_thunderWarning = checked
        }
        QQC2.CheckBox {
            text: seite.t("Starkregen")
            checked: seite.cfg_rainWarning
            onToggled: seite.cfg_rainWarning = checked
        }
        QQC2.CheckBox {
            text: seite.t("Schnee")
            checked: seite.cfg_snowWarning
            onToggled: seite.cfg_snowWarning = checked
        }
        QQC2.CheckBox {
            text: seite.t("Glätte und Frost")
            checked: seite.cfg_iceWarning
            onToggled: seite.cfg_iceWarning = checked
        }
        QQC2.CheckBox {
            text: seite.t("Hitze")
            checked: seite.cfg_heatWarning
            onToggled: seite.cfg_heatWarning = checked
        }
        QQC2.CheckBox {
            Kirigami.FormData.label: seite.t("Amtliche Warnungen:")
            enabled: seite.warnungenAn
            text: seite.t("Schweiz (MeteoSchweiz)")
            checked: seite.cfg_meteoSwissWarnings
            onToggled: seite.cfg_meteoSwissWarnings = checked
        }
        QQC2.Label {
            Layout.fillWidth: true
            Layout.maximumWidth: Kirigami.Units.gridUnit * 26
            wrapMode: Text.WordWrap
            opacity: 0.7
            font: Kirigami.Theme.smallFont
            text: seite.t("Die amtlichen Warnungen von MeteoSchweiz kommen über MeteoAlarm, das Warnportal der europäischen Wetterdienste (EUMETNET). Das Widget lädt alle Schweizer Warnungen (etwa 1 MB, höchstens alle 20 Minuten) und prüft selbst, ob der Ort betroffen ist. Titel und Text bleiben im Wortlaut von MeteoSchweiz.")
        }
        QQC2.CheckBox {
            enabled: seite.warnungenAn
            text: seite.t("Österreich (GeoSphere Austria)")
            checked: seite.cfg_geoSphereWarnings
            onToggled: seite.cfg_geoSphereWarnings = checked
        }
        QQC2.CheckBox {
            enabled: seite.warnungenAn
            text: seite.t("Deutschland (Deutscher Wetterdienst)")
            checked: seite.cfg_dwdWarnings
            onToggled: seite.cfg_dwdWarnings = checked
        }

        RowLayout {
            Kirigami.FormData.label: seite.t("Benachrichtigung:")
            enabled: seite.warnungenAn
            QQC2.CheckBox {
                text: seite.t("Bei neuer Warnung ab")
                checked: seite.cfg_notifications
                onToggled: seite.cfg_notifications = checked
            }
            QQC2.ComboBox {
                enabled: seite.cfg_notifications
                model: [seite.t("Gelb"), seite.t("Orange"), seite.t("Rot"), seite.t("Violett")]
                // Die Einträge hängen an der Sprache: Wechselt sie, setzt die Liste ihre Auswahl auf den ersten
                // Eintrag zurück. Danach die Bindung an die Einstellung wiederherstellen.
                readonly property int soll: Math.max(0, Math.min(3, seite.cfg_notifyLevel - 1))
                currentIndex: soll
                onModelChanged: Qt.callLater(() => currentIndex = Qt.binding(() => soll))
                onActivated: index => seite.cfg_notifyLevel = index + 1
            }
        }
        QQC2.CheckBox {
            enabled: seite.warnungenAn && seite.cfg_notifications
            text: seite.t("auch für die anderen Orte der Ortsliste")
            checked: seite.cfg_notifyAllPlaces
            onToggled: seite.cfg_notifyAllPlaces = checked
        }

        QQC2.Label {
            Layout.maximumWidth: Kirigami.Units.gridUnit * 22
            wrapMode: Text.WordWrap
            opacity: 0.7
            text: seite.t("Gewarnt wird vor Wetter in den nächsten 24 Stunden. Wind wertet das Widget überall selbst "
                          + "aus der Vorhersage aus; alle Warnarten kommen in den angehakten Ländern als amtliche "
                          + "Warnung des Wetterdienstes. Dafür prüft das Widget einmal je Ort, in welchem Land er liegt "
                          + "(Schweiz: über swisstopo), und schickt danach die Koordinaten an den DWD bzw. GeoSphere, in "
                          + "der Schweiz die Postleitzahl an MeteoSchweiz. Jede Warnung wird nur einmal gemeldet, erneut "
                          + "nur, wenn sie stärker wird. Die Warnung ersetzt keine offizielle Unwetterwarnung.") + " "
                  + seite.t("Für die anderen Orte der Ortsliste holt das Widget die amtlichen Warnungen ebenfalls; ein Warndreieck neben ‹ › zeigt sie an.")
        }

        // ════ Aussehen ════
        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: seite.t("Aussehen")
        }
        QQC2.ComboBox {
            Kirigami.FormData.label: seite.t("Farbschema:")
            implicitContentWidthPolicy: QQC2.ComboBox.WidestText
            model: Fa.SCHEMEN.map(f => seite.t(f.name))
            // Die Einträge hängen an der Sprache: Wechselt sie, setzt die Liste ihre Auswahl auf den ersten
            // Eintrag zurück. Danach die Bindung an die Einstellung wiederherstellen.
            readonly property int soll: Math.max(0, Fa.SCHEMEN.findIndex(f => f.id === seite.cfg_colorScheme))
            currentIndex: soll
            onModelChanged: Qt.callLater(() => currentIndex = Qt.binding(() => soll))
            onActivated: index => seite.cfg_colorScheme = Fa.SCHEMEN[index].id
        }
        // Vorschau: Verlauf mit Schimmer unten links wie auf der Karte
        Rectangle {
            Kirigami.FormData.label: seite.t("Vorschau:")
            // Grösse direkt vorgeben: das Formular-Layout beachtet hier nur die implizite Grösse
            implicitWidth: Kirigami.Units.gridUnit * 14
            implicitHeight: Kirigami.Units.gridUnit * 2.6
            radius: Kirigami.Units.cornerRadius * 2
            clip: true
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: seite.verlauf[0] }
                GradientStop { position: 0.5; color: seite.verlauf[1] }
                GradientStop { position: 1.0; color: seite.verlauf[2] }
            }
            Rectangle {
                x: -width / 2; y: parent.height - height / 2
                width: parent.width * 0.9; height: width
                radius: width / 2
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: Qt.alpha(seite.schimmer, 0) }
                    GradientStop { position: 0.5; color: Qt.alpha(seite.schimmer, 0.55) }
                    GradientStop { position: 1.0; color: Qt.alpha(seite.schimmer, 0) }
                }
                opacity: 0.8
            }
            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                color: "transparent"
                border.color: Qt.rgba(1, 1, 1, 0.25)
            }
            Text {
                anchors.centerIn: parent
                text: "17 °C  ·  " + seite.t("Überwiegend sonnig")
                color: "white"
                font.pixelSize: Kirigami.Units.gridUnit * 0.95
                font.weight: Font.Medium
            }
        }
        RowLayout {
            Kirigami.FormData.label: seite.t("Eigene Farben:")
            visible: seite.cfg_colorScheme === "eigen"
            spacing: Kirigami.Units.largeSpacing
            // Anklickbare Farbfelder statt Knöpfe: Der Plasma-Stil zeichnet bei Knöpfen den Text selbst
            // und hätte ihn doppelt gezeigt
            Repeater {
                model: [[seite.t("oben links"), "cfg_customColorStart"], [seite.t("unten rechts"), "cfg_customColorEnd"]]
                RowLayout {
                    id: farbFeld
                    required property var modelData
                    spacing: Kirigami.Units.smallSpacing
                    Rectangle {
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 2
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 1.4
                        radius: Kirigami.Units.cornerRadius
                        color: seite[farbFeld.modelData[1]]
                        border.width: feldMaus.containsMouse ? 2 : 1
                        border.color: feldMaus.containsMouse ? Kirigami.Theme.highlightColor : Qt.rgba(0.5, 0.5, 0.5, 0.7)
                        MouseArea {
                            id: feldMaus
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                farbWahl.ziel = farbFeld.modelData[1]
                                farbWahl.selectedColor = seite[farbFeld.modelData[1]]
                                farbWahl.open()
                            }
                        }
                        QQC2.ToolTip.visible: feldMaus.containsMouse
                        QQC2.ToolTip.text: seite.t("Farbe %1 wählen", farbFeld.modelData[0])
                    }
                    QQC2.Label { text: farbFeld.modelData[0] }
                }
            }
        }
        Kirigami.InlineMessage {
            Layout.preferredWidth: Kirigami.Units.gridUnit * 22
            // Schwelle 3: Kontrast für grosse Schrift nach WCAG; alle fertigen Schemen liegen darüber
            visible: seite.kontrast < 3
            type: Kirigami.MessageType.Warning
            text: seite.t("Diese Farben sind sehr hell: Die weisse Schrift ist darauf schlecht lesbar. Dunklere Farben wählen.")
        }
        Dialoge.ColorDialog {
            id: farbWahl
            property string ziel: ""
            title: seite.t("Farbe für den Hintergrund wählen")
            onAccepted: seite[ziel] = selectedColor.toString().toUpperCase()
        }

        Item { Kirigami.FormData.isSection: true }

        QQC2.CheckBox {
            Kirigami.FormData.label: seite.t("Helle Karte:")
            text: seite.t("Dunkle Schrift auf heller Karte (für helle Hintergrundbilder)")
            checked: seite.cfg_lightCard
            onToggled: seite.cfg_lightCard = checked
        }

        QQC2.CheckBox {
            Kirigami.FormData.label: seite.t("Glas-Effekt:")
            text: seite.t("Hintergrundbild verschwommen durchscheinen lassen")
            checked: seite.cfg_glassEffect
            onToggled: seite.cfg_glassEffect = checked
        }

        RowLayout {
            Kirigami.FormData.label: seite.t("Tönung Glas:")
            visible: seite.cfg_glassEffect
            QQC2.Slider {
                from: 0
                to: 100
                stepSize: 1
                value: seite.cfg_glassTint
                onMoved: seite.cfg_glassTint = value
            }
            QQC2.Label {
                text: seite.cfg_glassTint + " %"
            }
        }

        RowLayout {
            Kirigami.FormData.label: seite.t("Abdunklung Glas:")
            visible: seite.cfg_glassEffect
            QQC2.Slider {
                from: 0
                to: 60
                stepSize: 1
                value: seite.cfg_glassDarken
                onMoved: seite.cfg_glassDarken = value
            }
            QQC2.Label {
                text: seite.cfg_glassDarken + " %"
            }
        }

        RowLayout {
            Kirigami.FormData.label: seite.t("Deckkraft Hintergrund:")
            visible: !seite.cfg_glassEffect
            QQC2.Slider {
                from: 20
                to: 100
                stepSize: 1
                value: seite.cfg_backgroundOpacity
                onMoved: seite.cfg_backgroundOpacity = value
            }
            QQC2.Label {
                text: seite.cfg_backgroundOpacity + " %"
            }
        }

        // ── Sicherung: Plasma löscht die Einstellungen mit dem Widget ──
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: seite.t("Sicherung")
        }
        QQC2.Label {
            Layout.fillWidth: true
            Layout.maximumWidth: Kirigami.Units.gridUnit * 26
            wrapMode: Text.WordWrap
            opacity: 0.7
            font: Kirigami.Theme.smallFont
            text: seite.t("Wird das Widget vom Desktop entfernt, löscht Plasma seine Einstellungen. TuX-Wetter sichert sie darum selbst; ein neu hinzugefügtes Widget bietet an, sie zu übernehmen. Für einen anderen Rechner die Einstellungen in eine Datei sichern.")
        }
        ColumnLayout {
            Kirigami.FormData.label: seite.t("Datei:")
            RowLayout {
                QQC2.Button {
                    icon.name: "document-save"
                    text: seite.t("In Datei sichern …")
                    onClicked: {
                        dateiSichern.selectedFile = StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/Tux-Wetter-Einstellungen.json"
                        dateiSichern.open()
                    }
                }
                QQC2.Button {
                    icon.name: "document-open"
                    text: seite.t("Aus Datei laden …")
                    onClicked: dateiLaden.open()
                }
            }
            QQC2.CheckBox {
                id: mitSchluesseln
                text: seite.t("API-Schlüssel mitsichern")
                checked: false
            }
        }
        RowLayout {
            Kirigami.FormData.label: seite.t("Automatisch gesichert:")
            visible: seite.autoSicherungen.length > 0
            QQC2.ComboBox {
                id: autoWahl
                Layout.preferredWidth: Kirigami.Units.gridUnit * 18
                model: seite.autoSicherungen.map(a => a.text)
            }
            QQC2.Button {
                icon.name: "edit-undo"
                text: seite.t("Laden")
                enabled: autoWahl.currentIndex >= 0
                onClicked: {
                    seite.einstellungenSetzen(seite.autoSicherungen[autoWahl.currentIndex].einstellungen)
                    seite.sicherungMelden(seite.t("Einstellungen geladen. Mit OK oder Anwenden übernehmen."), false)
                }
            }
        }
        Kirigami.InlineMessage {
            Layout.preferredWidth: Kirigami.Units.gridUnit * 22
            visible: seite.sicherungMeldung !== ""
            type: seite.sicherungArt
            text: seite.sicherungMeldung
            showCloseButton: true
            onVisibleChanged: if (!visible) seite.sicherungMeldung = ""
        }
        Dialoge.FileDialog {
            id: dateiSichern
            title: seite.t("Einstellungen sichern")
            fileMode: Dialoge.FileDialog.SaveFile
            defaultSuffix: "json"
            nameFilters: [seite.t("TuX-Wetter-Einstellungen (*.json)"), seite.t("Alle Dateien (*)")]
            onAccepted: seite.inDateiSichern(selectedFile)
        }
        Dialoge.FileDialog {
            id: dateiLaden
            title: seite.t("Einstellungen laden")
            fileMode: Dialoge.FileDialog.OpenFile
            currentFolder: StandardPaths.writableLocation(StandardPaths.HomeLocation)
            nameFilters: [seite.t("TuX-Wetter-Einstellungen (*.json)"), seite.t("Alle Dateien (*)")]
            onAccepted: seite.ausDateiLaden(selectedFile)
        }

        // Quellen und Lizenz (Nennung verlangt u. a. von CC BY 4.0)
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: seite.t("Datenquellen und Lizenz")
        }
        QQC2.Label {
            Layout.fillWidth: true
            Layout.maximumWidth: Kirigami.Units.gridUnit * 26
            wrapMode: Text.WordWrap
            opacity: 0.7
            font: Kirigami.Theme.smallFont
            // Dieselben Angaben wie im Tooltip der Quellenzeile auf der Karte, hier mit Links
            textFormat: Text.StyledText
            text: A.quellenListe(seite.cfg_provider, seite.uiSprache, true)
                  + "<br>" + seite.t("TuX-Wetter ist freie Software unter der %1.", A.verweis("GPL-3.0-or-later", "https://www.gnu.org/licenses/gpl-3.0.html"))
            onLinkActivated: link => Qt.openUrlExternally(link)
            HoverHandler { cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor }
        }
    }
}
