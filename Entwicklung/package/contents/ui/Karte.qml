// SPDX-FileCopyrightText: 2026 R.Bruns
// SPDX-License-Identifier: GPL-3.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import QtQuick.Effects
import QtQuick.Controls as QQC2
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PC3
import "wetter.js" as W
import "warnung.js" as Wa
import "farben.js" as Fa
import "zusatz.js" as Z
import "sicherung.js" as S
import "anbieter.js" as A

// Die Wetterkarte im Glas-Look. Alle Masse beziehen sich auf eine 700×545 grosse Vorlage
// und werden mit s skaliert; main.qml hält die Karte immer in diesem Seitenverhältnis.
Item {
    id: karte

    required property var wetter
    readonly property real s: Math.min(width / 700, height / 545)
    readonly property string sp: wetter.sprache
    // Text in der Anzeigesprache (siehe main.qml)
    function t(text) {
        return karte.wetter.t.apply(null, arguments)
    }
    // Tagesdetails: Index des angeklickten Vorschautags (-1 = die nächsten Stunden wie üblich)
    property int gewaehlterTag: -1
    readonly property var tagDetails: gewaehlterTag >= 0 && gewaehlterTag < wetter.tage.length ? wetter.tage[gewaehlterTag] : null
    readonly property bool details: Plasmoid.configuration.showDetails

    // Nach einer Minute ohne Klick wieder die nächsten Stunden zeigen
    Timer {
        running: karte.gewaehlterTag >= 0
        interval: 60000
        onTriggered: karte.gewaehlterTag = -1
    }
    Connections {
        target: karte.wetter
        function onTageChanged() { karte.gewaehlterTag = -1 }
    }

    // Mausrad über der Karte: zum nächsten oder vorherigen gespeicherten Ort
    WheelHandler {
        enabled: karte.wetter.mehrereOrte
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        property real summe: 0
        onWheel: event => {
            summe += event.angleDelta.y
            if (Math.abs(summe) >= 120) {
                karte.wetter.ortWechseln(summe > 0 ? -1 : 1)
                summe = 0
            }
        }
    }
    // Helle Karte (Einstellung): dunkle Schrift auf stark aufgehellten Farben des Schemas
    readonly property bool hellModus: Plasmoid.configuration.lightCard
    // Farbe von Schrift und Linien: weiss auf der dunklen, dunkelblau auf der hellen Karte
    readonly property color vorder: hellModus ? "#1B1F33" : "#FFFFFF"
    function farbe(deckkraft) {
        return Qt.alpha(vorder, deckkraft)
    }
    // Einfarbige Symbole gibt es weiss und (auf der hellen Karte) dunkel
    function symbolDatei(name) {
        return Qt.resolvedUrl("../icons/" + name + (hellModus ? "-dunkel" : "") + ".svg")
    }
    readonly property color hell: vorder
    function zahl(x) {
        const s = x < 1 && x > 0 ? x.toFixed(1) : String(Math.round(x))
        return sp === "en" ? s : s.replace(".", ",")
    }
    // Farben des gewählten Farbschemas (Einstellungen)
    readonly property var verlauf: (hellModus ? Fa.verlaufHell : Fa.verlauf)(Plasmoid.configuration.colorScheme,
                                   Plasmoid.configuration.customColorStart, Plasmoid.configuration.customColorEnd)
    readonly property color schimmer: Fa.schimmer(Plasmoid.configuration.colorScheme, Plasmoid.configuration.customColorStart)
    readonly property color gedimmt: karte.farbe(hellModus ? 0.62 : 0.55)
    readonly property string schrift: Kirigami.Theme.defaultFont.family

    // ── Glas-Effekt: das Hintergrundbild scheint verschwommen durch die Karte ──
    // Das Hintergrundbild liegt im selben Fenster wie das Widget und wird mit ShaderEffectSource
    // abgegriffen. In Leisten gibt es keins; dann bleibt die normale Karte.
    readonly property var hintergrund: {
        const c = Plasmoid.containment
        return c && c.wallpaperGraphicsObject ? sichtbaresElement(c.wallpaperGraphicsObject) : null
    }
    readonly property bool glas: Plasmoid.configuration.glassEffect && hintergrund !== null
    // Zusätzlich erfasster Rand, damit der Weichzeichner an den Kanten nicht ausfranst
    readonly property real glasRand: 48
    property rect ausschnitt: Qt.rect(0, 0, 0, 0)

    function sichtbaresElement(element) {
        if (!element)
            return null
        if (element.sourceComponent !== undefined && element.item !== undefined)
            return sichtbaresElement(element.item)
        if (element.width > 0 && element.height > 0)
            return element
        for (let i = 0; i < element.children.length; i++) {
            const kind = sichtbaresElement(element.children[i])
            if (kind)
                return kind
        }
        return null
    }

    function lageAktualisieren() {
        if (!glas)
            return
        const p = karte.mapToItem(hintergrund, 0, 0)
        if (p.x !== ausschnitt.x || p.y !== ausschnitt.y
                || width !== ausschnitt.width || height !== ausschnitt.height)
            ausschnitt = Qt.rect(p.x, p.y, width, height)
    }

    // Das Widget kann auf dem Desktop verschoben werden; dafür gibt es kein Signal
    Timer {
        interval: 150
        repeat: true
        triggeredOnStart: true
        running: karte.glas && karte.visible
        onTriggered: karte.lageAktualisieren()
    }

    ShaderEffectSource {
        id: hintergrundTextur
        visible: false
        width: karte.width + 2 * karte.glasRand
        height: karte.height + 2 * karte.glasRand
        // Viertel-Auflösung: verstärkt die Unschärfe und spart Rechenleistung
        textureSize: Qt.size(Math.max(1, width / 4), Math.max(1, height / 4))
        sourceItem: karte.glas ? karte.hintergrund : null
        sourceRect: Qt.rect(karte.ausschnitt.x - karte.glasRand, karte.ausschnitt.y - karte.glasRand,
                            karte.ausschnitt.width + 2 * karte.glasRand,
                            karte.ausschnitt.height + 2 * karte.glasRand)
    }

    Item {
        id: glasMaske
        visible: false
        layer.enabled: true
        width: hintergrundTextur.width
        height: hintergrundTextur.height

        Rectangle {
            x: karte.glasRand
            y: karte.glasRand
            width: karte.width
            height: karte.height
            radius: 22 * karte.s
            antialiasing: true
        }
    }

    MultiEffect {
        x: -karte.glasRand
        y: -karte.glasRand
        width: hintergrundTextur.width
        height: hintergrundTextur.height
        visible: karte.glas
        source: hintergrundTextur
        autoPaddingEnabled: false
        blurEnabled: true
        blur: 1.0
        blurMax: 64
        saturation: 0.25
        // Abgedunkelt, damit die weisse Schrift auch über hellen Bildstellen lesbar bleibt
        brightness: -Plasmoid.configuration.glassDarken / 100
        maskEnabled: true
        maskSource: glasMaske
    }

    // Hintergrund: Verlauf des Farbschemas (Standard violett) mit Schimmer unten links
    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        opacity: (karte.glas ? Plasmoid.configuration.glassTint : Plasmoid.configuration.backgroundOpacity) / 100

        ShapePath {
            strokeColor: "transparent"
            fillGradient: LinearGradient {
                x1: 0; y1: 0
                x2: karte.width; y2: karte.height
                GradientStop { position: 0.0; color: karte.verlauf[0] }
                GradientStop { position: 0.5; color: karte.verlauf[1] }
                GradientStop { position: 1.0; color: karte.verlauf[2] }
            }
            PathRectangle { width: karte.width; height: karte.height; radius: 22 * karte.s }
        }
        ShapePath {
            strokeColor: "transparent"
            fillGradient: RadialGradient {
                centerX: karte.width * 0.05; centerY: karte.height * 1.05
                focalX: centerX; focalY: centerY
                centerRadius: karte.width * 0.6
                GradientStop { position: 0.0; color: Qt.alpha(karte.schimmer, karte.hellModus ? 0.3 : 0.78) }
                GradientStop { position: 1.0; color: Qt.alpha(karte.schimmer, 0) }
            }
            PathRectangle { width: karte.width; height: karte.height; radius: 22 * karte.s }
        }
        ShapePath {
            fillColor: "transparent"
            strokeColor: karte.farbe(0.18)
            strokeWidth: 1
            PathRectangle { x: 0.5; y: 0.5; width: karte.width - 1; height: karte.height - 1; radius: 22 * karte.s }
        }
    }

    // Glanz und heller Rand für den Glas-Effekt; unabhängig von der Tönung immer sichtbar
    Shape {
        anchors.fill: parent
        visible: karte.glas
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: "transparent"
            fillGradient: LinearGradient {
                x1: 0; y1: 0
                x2: karte.width * 0.35; y2: karte.height
                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.16) }
                GradientStop { position: 0.45; color: Qt.rgba(1, 1, 1, 0.03) }
                GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0) }
            }
            PathRectangle { width: karte.width; height: karte.height; radius: 22 * karte.s }
        }
        ShapePath {
            fillColor: "transparent"
            strokeWidth: 1.2
            strokeColor: karte.farbe(0.38)
            PathRectangle { x: 0.6; y: 0.6; width: karte.width - 1.2; height: karte.height - 1.2; radius: 22 * karte.s }
        }
    }

    Text {
        visible: !karte.wetter.geladen
        anchors.centerIn: parent
        width: parent.width - 60 * karte.s
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
        text: karte.wetter.fehler || karte.t("Lade Wetterdaten …")
        color: karte.gedimmt
        font.family: karte.schrift
        font.pixelSize: 20 * karte.s
    }

    Item {
        anchors.fill: parent
        visible: karte.wetter.geladen

        // ── Kopfbereich links: Symbol, Ort, Temperatur ──
        WetterSymbol {
            // Auf der hellen Karte ein leichter Schatten, damit weisse Wolken sichtbar bleiben
            layer.enabled: karte.hellModus
            layer.effect: MultiEffect { shadowEnabled: true; shadowColor: "#803A4570"; shadowBlur: 0.5; shadowVerticalOffset: 1 }
            x: 26 * karte.s; y: 30 * karte.s
            width: 104 * karte.s; height: width
            code: karte.wetter.code
            tag: karte.wetter.tag
            zeit: karte.wetter.animationsZeit
        }

        Text {
            id: ort
            x: 146 * karte.s; y: 24 * karte.s
            // Volle Breite bis zum rechten Rand (bzw. zum Ortsumschalter); sehr lange Namen werden erst
            // kleiner, dann gekürzt
            width: Math.max(0, (ortWahl.visible ? ortWahl.x - 10 * karte.s : parent.width - 34 * karte.s) - x)
            height: 34 * karte.s
            verticalAlignment: Text.AlignVCenter
            fontSizeMode: Text.HorizontalFit
            minimumPixelSize: Math.round(18 * karte.s)
            elide: Text.ElideRight
            text: Plasmoid.configuration.locationName
            color: karte.hell
            font.family: karte.schrift
            font.pixelSize: 25 * karte.s
            font.weight: Font.Medium

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: karte.wetter.aktualisieren()
            }
        }

        // Umschalter für mehrere Orte: ‹ 2/3 ›
        Row {
            id: ortWahl
            visible: karte.wetter.mehrereOrte
            anchors.right: parent.right
            anchors.rightMargin: 30 * karte.s
            anchors.verticalCenter: ort.verticalCenter
            spacing: 2 * karte.s

            // Warnung an einem anderen Ort der Ortsliste: Dreieck in der Farbe der stärksten; Klick zeigt den Ort
            Canvas {
                id: andereWarnung
                readonly property var a: karte.wetter.andereWarnungen
                readonly property int stufe: a.length ? a[0].liste[0].stufe : 0
                visible: stufe > 0
                anchors.verticalCenter: parent.verticalCenter
                width: 20 * karte.s; height: width
                onStufeChanged: requestPaint()
                onWidthChanged: requestPaint()
                onPaint: {
                    const c = getContext("2d"), b = width
                    c.reset()
                    if (!stufe)
                        return
                    c.lineJoin = "round"
                    c.lineWidth = Math.max(1, b * 0.07)
                    c.strokeStyle = "#1A1A1A"
                    c.fillStyle = Wa.FARBEN[stufe]
                    c.beginPath(); c.moveTo(b / 2, b * 0.08); c.lineTo(b * 0.95, b * 0.9); c.lineTo(b * 0.05, b * 0.9); c.closePath()
                    c.fill(); c.stroke()
                    c.fillStyle = Wa.SCHRIFT[stufe]
                    c.fillRect(b * 0.45, b * 0.36, b * 0.1, b * 0.3)
                    c.fillRect(b * 0.45, b * 0.72, b * 0.1, b * 0.1)
                }
                HoverHandler {
                    id: andereMaus
                    cursorShape: Qt.PointingHandCursor
                }
                TapHandler { onTapped: karte.wetter.ortZeigen(andereWarnung.a[0].ort) }
                QQC2.ToolTip.visible: andereMaus.hovered
                QQC2.ToolTip.text: andereWarnung.a.map(x => x.ort.name + ": " + Wa.kurztext(x.liste[0], karte.wetter.jetzt, x.liste.length - 1, karte.sp)).join("\n")
                                   + "\n" + karte.t("Klicken zeigt %1", andereWarnung.a.length ? andereWarnung.a[0].ort.name : "")
            }
            Item { width: 4 * karte.s; height: 1; visible: andereWarnung.visible }

            Repeater {
                model: [-1, 0, 1]
                Text {
                    id: wahl
                    required property int modelData
                    anchors.verticalCenter: parent.verticalCenter
                    text: modelData < 0 ? "‹" : modelData > 0 ? "›"
                          : (karte.wetter.ortsIndex >= 0 ? (karte.wetter.ortsIndex + 1) + "/" + karte.wetter.ortsListe.length : "–")
                    color: modelData === 0 ? karte.gedimmt : (wahlMaus.containsMouse ? karte.hell : karte.farbe(0.75))
                    font.family: karte.schrift
                    font.pixelSize: (modelData === 0 ? 15 : 26) * karte.s
                    leftPadding: modelData === 0 ? 0 : 4 * karte.s
                    rightPadding: leftPadding
                    MouseArea {
                        id: wahlMaus
                        anchors.fill: parent
                        anchors.margins: -3 * karte.s
                        enabled: wahl.modelData !== 0
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: karte.wetter.ortWechseln(wahl.modelData)
                    }
                }
            }
        }

        Text {
            id: grossTemp
            x: 140 * karte.s; y: 44 * karte.s
            text: karte.wetter.grad(karte.wetter.anzeigeTemp)
            color: karte.hell
            // Woher die Temperatur stammt: Messstation oder Vorhersagemodell
            HoverHandler { id: tempMaus }
            QQC2.ToolTip.visible: tempMaus.hovered
            QQC2.ToolTip.text: karte.wetter.gemessen
                ? karte.t("Gemessen um %1 an der Station %2 (%3), %4 km entfernt", Qt.formatTime(new Date(karte.wetter.messung.zeit), "HH:mm"),
                          karte.wetter.messung.station, karte.wetter.messung.quelle, karte.wetter.messung.km.toFixed(0))
                  + "\n" + karte.t("Vorhersagemodell: %1°", karte.wetter.grad(karte.wetter.temperatur))
                : karte.t("Wert des Vorhersagemodells")
            font.family: karte.schrift
            // Dreistellige Werte (z.B. -12 oder 104 °F) etwas kleiner, damit °C/°F nicht an die
            // Werte rechts stösst; die Grundlinie bleibt dabei gleich
            font.pixelSize: 86 * karte.s * Math.min(1, Math.max(0, kopfWerte.x - 20 * karte.s - einheit.width - 8 * karte.s - x)
                                              / Math.max(1, grossMass.advanceWidth))
            font.weight: Font.Normal
            topPadding: grossSchrift.ascent * (1 - font.pixelSize / (86 * karte.s))
        }

        // Masse der Temperatur in voller Grösse: Breite des Textes und Oberlänge der Schrift
        TextMetrics {
            id: grossMass
            font: grossSchrift.font
            text: grossTemp.text
        }
        FontMetrics {
            id: grossSchrift
            font.family: karte.schrift
            font.pixelSize: 86 * karte.s
            font.weight: Font.Normal
        }

        Column {
            id: einheit
            anchors.left: grossTemp.right
            anchors.leftMargin: 8 * karte.s
            y: grossTemp.y + 18 * karte.s
            spacing: 14 * karte.s

            Repeater {
                model: [false, true]
                Text {
                    required property bool modelData
                    text: modelData ? "°F" : "°C"
                    color: karte.wetter.fahrenheit === modelData ? karte.hell : karte.farbe(0.4)
                    font.family: karte.schrift
                    font.pixelSize: 23 * karte.s

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -4 * karte.s
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Plasmoid.configuration.useFahrenheit = parent.modelData
                    }
                }
            }
        }

        // ── Kopfbereich rechts unter dem Ortsnamen: Wind, Regenwahrscheinlichkeit heute,
        //    Luftfeuchtigkeit, Beschreibung, Höchst/Tiefst ──
        Row {
            id: kopfWerte
            anchors.right: parent.right
            anchors.rightMargin: 34 * karte.s
            y: 72 * karte.s
            spacing: 8 * karte.s

            Image {
                anchors.verticalCenter: parent.verticalCenter
                width: 24 * karte.s; height: width
                source: karte.symbolDatei("wind")
                sourceSize: Qt.size(width * 2, height * 2)
                opacity: 0.85
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Math.round(karte.wetter.wind) + "<font size=\"1\" color=\"" + (karte.hellModus ? "#B31B1F33" : "#B3FFFFFF") + "\"> km/h</font>"
                textFormat: Text.StyledText
                // Bei einer Windwarnung in der Warnfarbe
                color: karte.wetter.windWarnung ? (karte.hellModus ? Wa.AUF_HELL : Wa.AUF_KARTE)[karte.wetter.windWarnung.stufe] : karte.hell
                font.family: karte.schrift
                font.pixelSize: 23 * karte.s
                font.weight: Font.Medium
            }
            // Windrichtung: Pfeil zeigt, wohin der Wind weht; Tooltip nennt, woher er kommt
            Canvas {
                id: windPfeil
                visible: karte.wetter.windRichtung !== null
                anchors.verticalCenter: parent.verticalCenter
                width: 18 * karte.s; height: width
                rotation: (karte.wetter.windRichtung || 0) + 180
                readonly property color f: karte.vorder
                onFChanged: requestPaint()
                onWidthChanged: requestPaint()
                onPaint: {
                    const c = getContext("2d"), b = width
                    c.reset()
                    c.fillStyle = f
                    c.beginPath(); c.moveTo(b / 2, b * 0.05); c.lineTo(b * 0.85, b * 0.92); c.lineTo(b / 2, b * 0.7); c.lineTo(b * 0.15, b * 0.92)
                    c.closePath(); c.fill()
                }
                HoverHandler { id: pfeilMaus }
                QQC2.ToolTip.visible: pfeilMaus.hovered
                QQC2.ToolTip.text: karte.wetter.windRichtung === null ? ""
                                   : karte.t("Wind aus %1 (%2°)", W.himmelsrichtung(karte.wetter.windRichtung, karte.sp, true),
                                             Math.round(karte.wetter.windRichtung))
            }
            Item { width: 14 * karte.s; height: 1 }
            Image {
                anchors.verticalCenter: parent.verticalCenter
                width: 27 * karte.s; height: width
                source: Qt.resolvedUrl("../icons/umbrella.svg")
                sourceSize: Qt.size(width * 2, height * 2)
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: (karte.wetter.niederschlag < 0 ? "–" : karte.wetter.niederschlag) + "%"
                color: karte.hell
                font.family: karte.schrift
                font.pixelSize: 23 * karte.s
                font.weight: Font.Medium
            }
            Item { width: 14 * karte.s; height: 1 }
            Image {
                anchors.verticalCenter: parent.verticalCenter
                width: 20 * karte.s; height: width
                source: Qt.resolvedUrl("../icons/drop.svg")
                sourceSize: Qt.size(width * 2, height * 2)
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: karte.wetter.feuchte + "%"
                color: karte.hell
                font.family: karte.schrift
                font.pixelSize: 23 * karte.s
                font.weight: Font.Medium
            }
        }

        Text {
            anchors.right: parent.right
            anchors.rightMargin: 34 * karte.s
            y: 112 * karte.s
            width: 300 * karte.s
            horizontalAlignment: Text.AlignRight
            elide: Text.ElideRight
            text: W.beschreibung(karte.wetter.code, karte.wetter.tag, karte.sp)
            color: karte.hell
            font.family: karte.schrift
            font.pixelSize: 20 * karte.s
        }

        Text {
            id: hochTief
            anchors.right: parent.right
            anchors.rightMargin: 34 * karte.s
            y: 148 * karte.s
            text: karte.wetter.grad(karte.wetter.heuteMax) + "° / " + karte.wetter.grad(karte.wetter.heuteMin) + "°"
            color: karte.hell
            font.family: karte.schrift
            font.pixelSize: 23 * karte.s

            // Ab wann die Spanne gilt (OpenWeatherMap ohne Werte vom Morgen), zeigt ein Tooltip beim
            // Überfahren. Der Plasma-Tooltip aus main.qml erscheint nur in der Leiste, nicht auf dem
            // Desktop; darum haben auch Warnband und „Stand …“ eigene Tooltips.
            HoverHandler {
                id: hochTiefMaus
                enabled: karte.wetter.heuteAb >= 9
            }
            QQC2.ToolTip.visible: hochTiefMaus.hovered
            QQC2.ToolTip.text: karte.t("Höchst/Tiefst heute erst ab %1 Uhr bekannt", karte.wetter.heuteAb)
        }

        // Gefühlte Temperatur links von Höchst/Tiefst
        Text {
            id: gefuehltText
            visible: Plasmoid.configuration.feelsLike && karte.wetter.gefuehlt !== null
            anchors.right: hochTief.left
            anchors.rightMargin: 16 * karte.s
            anchors.baseline: hochTief.baseline
            text: karte.t("gefühlt %1°", karte.wetter.grad(karte.wetter.gefuehlt || 0))
            color: karte.gedimmt
            font.family: karte.schrift
            font.pixelSize: 19 * karte.s
        }

        // ── Stundenwerte (in den Tagesdetails stattdessen die Temperaturkurve, siehe unten) ──
        Row {
            visible: karte.tagDetails === null
            x: 34 * karte.s
            // Gleicher Abstand unter „Höchst / Tiefst“ wie zwischen den Zeilen rechts oben
            y: 198 * karte.s
            width: parent.width - 68 * karte.s

            Repeater {
                model: karte.wetter.stunden
                Item {
                    id: stunde
                    required property var modelData
                    width: parent.width / 6
                    height: 120 * karte.s

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: stunde.modelData.zeit
                        color: karte.gedimmt
                        font.family: karte.schrift
                        font.pixelSize: 20 * karte.s
                    }
                    WetterSymbol {
                        // Auf der hellen Karte ein leichter Schatten, damit weisse Wolken sichtbar bleiben
                        layer.enabled: karte.hellModus
                        layer.effect: MultiEffect { shadowEnabled: true; shadowColor: "#803A4570"; shadowBlur: 0.5; shadowVerticalOffset: 1 }
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 30 * karte.s
                        width: 54 * karte.s; height: width
                        code: stunde.modelData.code
                        tag: stunde.modelData.tag
                        zeit: karte.wetter.animationsZeit
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 84 * karte.s
                        text: karte.wetter.grad(stunde.modelData.temp) + "°"
                        color: karte.hell
                        font.family: karte.schrift
                        font.pixelSize: 25 * karte.s
                        font.weight: Font.Medium
                    }
                }
            }
        }

        // ── Tagesdetails: Temperaturkurve über den Tag, darüber Uhrzeit und Symbol alle 3 Stunden ──
        Item {
            id: tagKurve
            visible: karte.tagDetails !== null
            x: 34 * karte.s
            y: 198 * karte.s
            width: parent.width - 68 * karte.s
            height: 120 * karte.s
            readonly property var punkte: karte.tagDetails && karte.tagDetails.verlauf && karte.tagDetails.verlauf.length
                                          ? karte.tagDetails.verlauf.slice().sort((a, b) => a.h - b.h)
                                          : (karte.tagDetails ? karte.tagDetails.stunden.map(x => ({ h: +x.zeit.substring(0, 2), temp: x.temp })) : [])
            readonly property real tiefst: punkte.length ? Math.min(...punkte.map(p => p.temp)) : 0
            readonly property real hoechst: punkte.length ? Math.max(...punkte.map(p => p.temp)) : 1
            // Kurvenbereich unten; die Beschriftungen stehen über den Punkten
            readonly property real oben: 80 * karte.s
            readonly property real unten: 114 * karte.s
            function xBei(h) { return (h + 0.5) / 24 * width }
            function yBei(temp) {
                return unten - (temp - tiefst) / Math.max(1, hoechst - tiefst) * (unten - oben)
            }
            // Temperatur zu einer Stunde, aus den Punkten der Kurve (für die Beschriftungen)
            function tempBei(h) {
                const p = punkte.find(x => x.h === h)
                return p ? p.temp : null
            }

            Canvas {
                id: kurvenBild
                anchors.fill: parent
                readonly property var p: tagKurve.punkte
                readonly property color f: karte.vorder
                onPChanged: requestPaint()
                onFChanged: requestPaint()
                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()
                onPaint: {
                    const c = getContext("2d")
                    c.reset()
                    if (p.length < 2)
                        return
                    // Fläche unter der Kurve, dann die Linie
                    c.beginPath()
                    c.moveTo(tagKurve.xBei(p[0].h), tagKurve.unten + 4 * karte.s)
                    for (const q of p) c.lineTo(tagKurve.xBei(q.h), tagKurve.yBei(q.temp))
                    c.lineTo(tagKurve.xBei(p[p.length - 1].h), tagKurve.unten + 4 * karte.s)
                    c.closePath()
                    c.fillStyle = Qt.alpha(f, 0.10)
                    c.fill()
                    c.beginPath()
                    p.forEach((q, i) => (i ? c.lineTo : c.moveTo).call(c, tagKurve.xBei(q.h), tagKurve.yBei(q.temp)))
                    c.lineWidth = Math.max(1.5, 2.2 * karte.s)
                    c.lineJoin = "round"
                    c.strokeStyle = Qt.alpha(f, 0.85)
                    c.stroke()
                }
            }

            Repeater {
                model: karte.tagDetails ? karte.tagDetails.stunden : []
                Item {
                    id: kurvenStunde
                    required property var modelData
                    readonly property int h: +modelData.zeit.substring(0, 2)
                    readonly property var temp: tagKurve.tempBei(h) !== null ? tagKurve.tempBei(h) : modelData.temp
                    x: tagKurve.xBei(h) - width / 2
                    width: 60 * karte.s
                    height: tagKurve.height
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: kurvenStunde.modelData.zeit
                        color: karte.gedimmt
                        font.family: karte.schrift
                        font.pixelSize: 17 * karte.s
                    }
                    WetterSymbol {
                        // Auf der hellen Karte ein leichter Schatten, damit weisse Wolken sichtbar bleiben
                        layer.enabled: karte.hellModus
                        layer.effect: MultiEffect { shadowEnabled: true; shadowColor: "#803A4570"; shadowBlur: 0.5; shadowVerticalOffset: 1 }
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 22 * karte.s
                        width: 34 * karte.s; height: width
                        code: kurvenStunde.modelData.code
                        tag: kurvenStunde.modelData.tag
                        zeit: karte.wetter.animationsZeit
                    }
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: tagKurve.yBei(kurvenStunde.temp) - height / 2
                        width: 7 * karte.s; height: width; radius: width / 2
                        color: karte.vorder
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: tagKurve.yBei(kurvenStunde.temp) - height - 3 * karte.s
                        text: karte.wetter.grad(kurvenStunde.temp) + "°"
                        color: karte.hell
                        font.family: karte.schrift
                        font.pixelSize: 16 * karte.s
                        font.weight: Font.Medium
                    }
                }
            }
        }

        Rectangle {
            id: trenner
            x: 36 * karte.s
            y: tagListe.y - 12 * karte.s - height
            width: parent.width - 72 * karte.s
            height: Math.max(1, karte.s)
            color: karte.farbe(0.16)
        }

        // ── Wetterwarnung als farbiges Band unter der grossen Temperatur (die stärkste; weitere im Tooltip) ──
        // Senkrecht mittig zwischen der Grundlinie der Temperatur und den Stundenwerten. Es beginnt unter
        // der Temperatur; ein langer Text rückt nach links, damit er nicht an „Höchst / Tiefst“ stösst.
        Rectangle {
            id: warnband
            readonly property var w: karte.wetter.warnung
            readonly property real rechtsFrei: (gefuehltText.visible ? gefuehltText.x : hochTief.x) - 16 * karte.s
            visible: w !== null
            x: Math.max(34 * karte.s, Math.min(grossTemp.x + 4 * karte.s, rechtsFrei - width))
            y: (grossTemp.y + grossTemp.baselineOffset + 198 * karte.s) / 2 - height / 2 + 2 * karte.s
            // Breite aus der natürlichen Textbreite (nicht aus der Zeile, sonst entsteht eine Bindungsschleife).
            // Aufgerundet mit 1 px Luft: fehlt dem Text auch nur ein Bruchteil eines Pixels, kürzt Qt ihn mit „…“
            width: Math.min(dreieck.width + 6 * karte.s + Math.ceil(warnText.implicitWidth) + 1 + 22 * karte.s, rechtsFrei - 34 * karte.s)
            height: 22 * karte.s
            radius: height / 2
            color: w ? Wa.FARBEN[w.stufe] : "transparent"

            // Alle Warnungen ausführlich (Böen nach Höhenlage, stärkere Böen laut Vorhersage) beim Überfahren
            readonly property string seite: Wa.warnSeite(w, karte.sp)
            HoverHandler {
                id: warnMaus
                cursorShape: warnband.seite ? Qt.PointingHandCursor : Qt.ArrowCursor
            }
            // Klick öffnet die amtliche Warnseite des Wetterdienstes im Browser
            TapHandler {
                enabled: warnband.seite !== ""
                onTapped: Qt.openUrlExternally(warnband.seite)
            }
            QQC2.ToolTip.visible: warnMaus.hovered && w !== null
            QQC2.ToolTip.text: karte.wetter.warnungen.map(x => Wa.langtext(x, karte.wetter.jetzt, karte.sp)).join("\n\n")
                               + (seite ? "\n\n" + karte.t("Klicken öffnet die Warnseite von %1", w.quelle) : "")

            Row {
                id: warnInhalt
                anchors.centerIn: parent
                spacing: 6 * karte.s
                // Warndreieck in der Schriftfarbe des Bands
                Canvas {
                    id: dreieck
                    anchors.verticalCenter: parent.verticalCenter
                    width: 13 * karte.s; height: width
                    readonly property color farbe: warnband.w ? Wa.SCHRIFT[warnband.w.stufe] : "white"
                    onFarbeChanged: requestPaint()
                    onWidthChanged: requestPaint()
                    onPaint: {
                        const c = getContext("2d"), b = width
                        c.reset()
                        c.fillStyle = farbe
                        c.beginPath(); c.moveTo(b / 2, b * 0.06); c.lineTo(b * 0.98, b * 0.92); c.lineTo(b * 0.02, b * 0.92); c.closePath(); c.fill()
                        c.fillStyle = warnband.color
                        c.fillRect(b * 0.44, b * 0.34, b * 0.12, b * 0.32)
                        c.fillRect(b * 0.44, b * 0.72, b * 0.12, b * 0.11)
                    }
                }
                Text {
                    id: warnText
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(Math.ceil(implicitWidth) + 1, warnband.width - 22 * karte.s - dreieck.width - 6 * karte.s)
                    elide: Text.ElideRight
                    text: warnband.w ? Wa.kurztext(warnband.w, karte.wetter.jetzt, karte.wetter.warnungen.length - 1, karte.sp) : ""
                    color: warnband.w ? Wa.SCHRIFT[warnband.w.stufe] : "white"
                    font.family: karte.schrift
                    font.pixelSize: 13.5 * karte.s
                    font.weight: Font.Medium
                }
            }
        }

        // ── Infozeile zwischen Stundenwerten und Vorschau: Sonne, UV, Luft, Pollen, Regen der nächsten
        //    2 Stunden. Sind Tagesdetails offen, steht hier stattdessen, welcher Tag gezeigt wird. ──
        Item {
            id: infoZeile
            x: 36 * karte.s
            y: 326 * karte.s
            width: parent.width - 72 * karte.s
            height: 26 * karte.s
            visible: karte.details || karte.tagDetails !== null
            // Ist die Zeile breiter als die Karte (lange Texte, Englisch), wird sie etwas kleiner gezeichnet
            readonly property real faktor: Math.min(1, width / Math.max(1, infoLinks.implicitWidth
                                                                     + (regenInfo.visible ? regenInfo.implicitWidth + 18 * karte.s : 0)))

            // Tagesdetails: „Montag, 27.10. · Stundenwerte“ und Schliessen
            Row {
                visible: karte.tagDetails !== null
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10 * karte.s
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: karte.tagDetails ? W.langerTag(karte.tagDetails.datum, karte.sp) : ""
                    color: karte.hell
                    font.family: karte.schrift
                    font.pixelSize: 16 * karte.s
                    font.weight: Font.Medium
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: karte.t("Stundenwerte · zurück mit Klick auf den Tag")
                    color: karte.gedimmt
                    font.family: karte.schrift
                    font.pixelSize: 15 * karte.s
                }
            }

            Row {
                id: infoLinks
                visible: karte.tagDetails === null
                anchors.verticalCenter: parent.verticalCenter
                scale: infoZeile.faktor
                transformOrigin: Item.Left
                spacing: 16 * karte.s

                // Sonnenaufgang und -untergang
                Row {
                    visible: karte.wetter.sonneAuf !== "" && karte.wetter.sonneUnter !== ""
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4 * karte.s
                    Image {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 20 * karte.s; height: width
                        source: karte.symbolDatei("sunrise")
                        sourceSize: Qt.size(width * 2, height * 2)
                        opacity: 0.85
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: karte.wetter.sonneAuf
                        color: karte.hell
                        font.family: karte.schrift
                        font.pixelSize: 16 * karte.s
                    }
                    Item { width: 6 * karte.s; height: 1 }
                    Image {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 20 * karte.s; height: width
                        source: karte.symbolDatei("sunset")
                        sourceSize: Qt.size(width * 2, height * 2)
                        opacity: 0.85
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: karte.wetter.sonneUnter
                        color: karte.hell
                        font.family: karte.schrift
                        font.pixelSize: 16 * karte.s
                    }
                    HoverHandler { id: sonneMaus }
                    QQC2.ToolTip.visible: sonneMaus.hovered
                    QQC2.ToolTip.text: karte.t("Sonnenaufgang %1 · Sonnenuntergang %2", karte.wetter.sonneAuf, karte.wetter.sonneUnter)
                }

                // Mondphase als kleine Scheibe; Auf- und Untergang im Tooltip
                Canvas {
                    id: mondBild
                    readonly property var m: karte.wetter.mond
                    visible: m !== null && m.phase !== null
                    anchors.verticalCenter: parent.verticalCenter
                    width: 18 * karte.s; height: width
                    readonly property real phase: m && m.phase !== null ? m.phase : 0
                    readonly property color f: karte.vorder
                    onPhaseChanged: requestPaint()
                    onFChanged: requestPaint()
                    onWidthChanged: requestPaint()
                    onPaint: {
                        const c = getContext("2d"), r = width / 2 - 1, mx = width / 2, my = height / 2
                        c.reset()
                        // dunkle Scheibe mit Rand
                        c.fillStyle = Qt.alpha(f, 0.18); c.strokeStyle = Qt.alpha(f, 0.55); c.lineWidth = 1
                        c.beginPath(); c.arc(mx, my, r, 0, 2 * Math.PI); c.fill(); c.stroke()
                        // beleuchteter Teil: Halbkreis plus Ellipse (zunehmend rechts, abnehmend links)
                        const p = ((phase % 360) + 360) % 360, zunehmend = p < 180
                        const k = Math.cos(p * Math.PI / 180)   // 1 = neu, -1 = voll
                        c.fillStyle = "#F4E7B0"
                        c.beginPath()
                        c.arc(mx, my, r, -Math.PI / 2, Math.PI / 2, !zunehmend)
                        c.save(); c.translate(mx, my); c.scale(Math.max(0.001, Math.abs(k)), 1)
                        c.arc(0, 0, r, Math.PI / 2, -Math.PI / 2, (k > 0) === zunehmend)
                        c.restore()
                        c.closePath(); c.fill()
                    }
                    HoverHandler { id: mondMaus }
                    QQC2.ToolTip.visible: mondMaus.hovered
                    QQC2.ToolTip.text: m ? Z.mondName(phase, karte.sp) + ", " + karte.t("%1 % beleuchtet", Z.mondLicht(phase))
                                           + (m.auf ? "\n" + karte.t("Mondaufgang %1", m.auf) : "")
                                           + (m.unter ? "\n" + karte.t("Monduntergang %1", m.unter) : "") : ""
                }

                // Beschriftung gedimmt, Wert hell, z. B. „UV 3“, „Luft gut“, „Pollen keine“
                Repeater {
                    model: [
                        { an: karte.wetter.uv !== null, name: "UV", wert: karte.wetter.uv !== null ? String(Math.round(karte.wetter.uv)) : "",
                          tipp: karte.wetter.uv !== null ? karte.t("UV-Index heute höchstens %1 (%2)", Math.round(karte.wetter.uv), Z.uvText(karte.wetter.uv, karte.sp)) : "" },
                        { an: karte.wetter.luft !== null && karte.wetter.luft.eaqi !== null, name: karte.t("Luft"),
                          wert: karte.wetter.luft && karte.wetter.luft.eaqi !== null ? Z.luftText(karte.wetter.luft.eaqi, karte.sp) : "",
                          tipp: karte.wetter.luft && karte.wetter.luft.eaqi !== null
                                ? karte.t("Europäischer Luftqualitätsindex %1 (%2)", Math.round(karte.wetter.luft.eaqi), Z.luftText(karte.wetter.luft.eaqi, karte.sp)) : "" },
                        { an: karte.wetter.luft !== null && karte.wetter.luft.pollen !== null, name: karte.t("Pollen"),
                          wert: karte.wetter.luft && karte.wetter.luft.pollen ? Z.pollenKurz(karte.wetter.luft.pollen, karte.sp) : "",
                          tipp: karte.wetter.luft && karte.wetter.luft.pollen ? Z.pollenLang(karte.wetter.luft.pollen, karte.sp) : "" }
                    ]
                    Row {
                        id: info
                        required property var modelData
                        visible: modelData.an
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 5 * karte.s
                        Text {
                            text: info.modelData.name + ":"
                            color: karte.gedimmt
                            font.family: karte.schrift
                            font.pixelSize: 16 * karte.s
                        }
                        Text {
                            text: info.modelData.wert
                            color: karte.hell
                            font.family: karte.schrift
                            font.pixelSize: 16 * karte.s
                        }
                        HoverHandler { id: infoMaus }
                        QQC2.ToolTip.visible: infoMaus.hovered
                        QQC2.ToolTip.text: info.modelData.tipp
                    }
                }
            }

            // Regen der nächsten 2 Stunden wie die anderen Werte: „Regen:“ gedimmt, der Wert hell;
            // die Mengen je Viertelstunde stehen im Tooltip
            Row {
                id: regenInfo
                readonly property var viertel: Z.naechsteZwei(karte.wetter.regen, karte.wetter.jetzt)
                visible: karte.tagDetails === null && karte.details && Plasmoid.configuration.rainNowcast && viertel.length > 0
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                scale: infoZeile.faktor
                transformOrigin: Item.Right
                spacing: 5 * karte.s

                Text {
                    text: karte.t("Regen") + ":"
                    color: karte.gedimmt
                    font.family: karte.schrift
                    font.pixelSize: 16 * karte.s
                }
                Text {
                    text: Z.regenKurz(karte.wetter.regen, karte.wetter.jetzt, karte.sp)
                    color: karte.hell
                    font.family: karte.schrift
                    font.pixelSize: 16 * karte.s
                }
                HoverHandler { id: regenMaus }
                QQC2.ToolTip.visible: regenMaus.hovered
                QQC2.ToolTip.text: Z.regenLang(karte.wetter.regen, karte.wetter.jetzt, karte.sp)
            }
        }

        // ── 5-Tage-Vorschau ──
        // Feste Lage für fünf Zeilen; liefert ein Anbieter weniger Tage, bleibt unten Platz frei
        Column {
            id: tagListe
            x: 36 * karte.s
            y: parent.height - 30 * karte.s - 5 * 27 * karte.s
            width: parent.width - 72 * karte.s

            Repeater {
                model: karte.wetter.tage
                Item {
                    id: tagZeile
                    required property var modelData
                    required property int index
                    // Tagesdetails gibt es, wenn der Anbieter Stundenwerte für diesen Tag liefert
                    readonly property bool mitDetails: !!(modelData.stunden && modelData.stunden.length)
                    readonly property real spanne: karte.wetter.bereichMax - karte.wetter.bereichMin
                    readonly property real von: (modelData.min - karte.wetter.bereichMin) / spanne
                    readonly property real bis: (modelData.max - karte.wetter.bereichMin) / spanne
                    width: parent.width
                    height: 27 * karte.s

                    // Hervorhebung: gewählter Tag bzw. Maus darüber
                    Rectangle {
                        x: -8 * karte.s
                        width: parent.width + 16 * karte.s
                        height: parent.height
                        radius: 6 * karte.s
                        color: karte.farbe(karte.gewaehlterTag === tagZeile.index ? 0.14 : tagMaus.containsMouse ? 0.07 : 0)
                    }
                    MouseArea {
                        id: tagMaus
                        anchors.fill: parent
                        enabled: tagZeile.mitDetails
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: karte.gewaehlterTag = karte.gewaehlterTag === tagZeile.index ? -1 : tagZeile.index
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: tagZeile.modelData.datum ? W.kurzerTag(tagZeile.modelData.datum, karte.sp) : tagZeile.modelData.name
                        color: karte.farbe(0.82)
                        font.family: karte.schrift
                        font.pixelSize: 18 * karte.s
                    }
                    WetterSymbol {
                        // Auf der hellen Karte ein leichter Schatten, damit weisse Wolken sichtbar bleiben
                        layer.enabled: karte.hellModus
                        layer.effect: MultiEffect { shadowEnabled: true; shadowColor: "#803A4570"; shadowBlur: 0.5; shadowVerticalOffset: 1 }
                        anchors.verticalCenter: parent.verticalCenter
                        x: 88 * karte.s
                        width: 26 * karte.s; height: width
                        code: tagZeile.modelData.code
                        zeit: karte.wetter.animationsZeit
                    }
                    // Regen des Tages: Wahrscheinlichkeit und Menge, bei Neuschnee in cm mit Flocke
                    Row {
                        id: tagRegen
                        readonly property var d: tagZeile.modelData
                        readonly property bool schnee: d.schnee !== null && d.schnee !== undefined && d.schnee >= 0.5
                        anchors.verticalCenter: parent.verticalCenter
                        x: 126 * karte.s
                        spacing: 3 * karte.s
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: [tagRegen.d.regen !== null && tagRegen.d.regen !== undefined ? tagRegen.d.regen + "%" : "",
                                   tagRegen.schnee ? karte.zahl(tagRegen.d.schnee) + " cm"
                                   : tagRegen.d.menge >= 0.1 ? karte.zahl(tagRegen.d.menge) + " mm" : ""].filter(x => x).join(" · ")
                            color: karte.hellModus ? "#1F6FB2" : "#8FD3FF"
                            font.family: karte.schrift
                            font.pixelSize: 15 * karte.s
                        }
                        Image {
                            visible: tagRegen.schnee
                            anchors.verticalCenter: parent.verticalCenter
                            width: 14 * karte.s; height: width
                            source: karte.symbolDatei("flocke")
                            sourceSize: Qt.size(width * 2, height * 2)
                        }
                        HoverHandler { id: tagRegenMaus }
                        QQC2.ToolTip.visible: tagRegenMaus.hovered
                        QQC2.ToolTip.text: [tagRegen.d.regen !== null && tagRegen.d.regen !== undefined ? karte.t("Regenwahrscheinlichkeit %1 %", tagRegen.d.regen) : "",
                                            tagRegen.d.menge !== null && tagRegen.d.menge !== undefined ? karte.t("Niederschlag %1 mm", karte.zahl(tagRegen.d.menge)) : "",
                                            tagRegen.schnee ? karte.t("Neuschnee %1 cm", karte.zahl(tagRegen.d.schnee)) : ""].filter(x => x).join("\n")
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: spur.left
                        anchors.rightMargin: 12 * karte.s
                        text: karte.wetter.grad(tagZeile.modelData.min) + "°"
                        color: karte.gedimmt
                        font.family: karte.schrift
                        font.pixelSize: 17 * karte.s
                    }
                    Rectangle {
                        id: spur
                        anchors.verticalCenter: parent.verticalCenter
                        x: 262 * karte.s
                        width: parent.width - 262 * karte.s - 58 * karte.s
                        height: 4 * karte.s
                        radius: height / 2
                        color: karte.farbe(0.14)

                        Rectangle {
                            x: tagZeile.von * spur.width
                            width: Math.max(spur.height, (tagZeile.bis - tagZeile.von) * spur.width)
                            height: spur.height
                            radius: height / 2
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: W.farbeBei(tagZeile.von) }
                                GradientStop { position: 0.5; color: W.farbeBei((tagZeile.von + tagZeile.bis) / 2) }
                                GradientStop { position: 1.0; color: W.farbeBei(tagZeile.bis) }
                            }
                        }
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        text: karte.wetter.grad(tagZeile.modelData.max) + "°"
                        color: karte.hell
                        font.family: karte.schrift
                        font.pixelSize: 18 * karte.s
                    }
                }
            }
        }

        // ── Unten links: Hinweis, wenn die Daten nicht mehr aktuell sind ──
        Item {
            visible: karte.wetter.veraltet
            anchors.left: parent.left
            anchors.leftMargin: 36 * karte.s
            anchors.right: quellen.left
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 5 * karte.s
            height: veraltetHinweis.implicitHeight

            Row {
                id: veraltetHinweis
                visible: karte.wetter.veraltet
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                spacing: 5 * karte.s

                // Warum die Daten nicht aktuell sind, beim Überfahren
                HoverHandler { id: standMaus }
                QQC2.ToolTip.visible: standMaus.hovered
                QQC2.ToolTip.text: karte.wetter.fehler || karte.t("Keine neuen Daten seit mehr als zwei Aktualisierungen")

                Kirigami.Icon {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 15 * karte.s; height: width
                    source: "dialog-warning"
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: karte.t("Stand %1", karte.wetter.standText()) + (karte.wetter.fehler ? " · " + karte.t("keine aktuellen Daten") : "")
                    color: karte.gedimmt
                    font.family: karte.schrift
                    font.pixelSize: 14 * karte.s
                }
            }
        }

        // ── Unten rechts: Quellenangabe, von den Anbietern verlangt (siehe anbieter.js QUELLEN) ──
        // Ein Klick auf einen Namen öffnet die Seite des Dienstes; beim Überfahren alle Quellen mit Lizenz
        Text {
            id: quellen
            anchors.right: parent.right
            anchors.rightMargin: 36 * karte.s
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 8 * karte.s
            textFormat: Text.StyledText
            text: A.quellenZeile(karte.wetter.anbieter, karte.sp)
            color: karte.farbe(karte.hellModus ? 0.55 : 0.45)
            linkColor: color
            font.family: karte.schrift
            font.pixelSize: 12 * karte.s
            onLinkActivated: link => Qt.openUrlExternally(link)

            HoverHandler {
                id: quellenMaus
                cursorShape: quellen.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
            }
            QQC2.ToolTip.visible: quellenMaus.hovered
            QQC2.ToolTip.text: A.quellenListe(karte.wetter.anbieter, karte.sp, false)
        }
    }

    // ── Angebot, die Einstellungen eines früheren Widgets zu übernehmen (main.qml angebot) ──
    Rectangle {
        id: angebotFlaeche
        readonly property var a: karte.wetter.angebot
        visible: a !== null
        anchors.fill: parent
        radius: 22 * karte.s
        color: karte.hellModus ? "#B3FFFFFF" : "#A6000000"

        // Klicks nicht an die Karte darunter weitergeben
        MouseArea { anchors.fill: parent; hoverEnabled: true; onWheel: wheel => wheel.accepted = true }

        Rectangle {
            anchors.centerIn: parent
            width: parent.width - 70 * karte.s
            height: angebotInhalt.implicitHeight + 44 * karte.s
            radius: 16 * karte.s
            color: karte.hellModus ? "#F2FFFFFF" : "#F21B1F33"
            border.color: karte.farbe(0.25)
            border.width: 1

            Column {
                id: angebotInhalt
                anchors.centerIn: parent
                width: parent.width - 48 * karte.s
                spacing: 12 * karte.s

                Text {
                    width: parent.width
                    wrapMode: Text.Wrap
                    text: karte.t("Frühere Einstellungen gefunden")
                    color: karte.vorder
                    font.family: karte.schrift
                    font.pixelSize: 24 * karte.s
                    font.weight: Font.DemiBold
                }
                Text {
                    width: parent.width
                    wrapMode: Text.Wrap
                    readonly property var e: angebotFlaeche.a ? angebotFlaeche.a.einstellungen : ({})
                    readonly property int orte: angebotFlaeche.a ? S.anzahlOrte(e) : 0
                    text: angebotFlaeche.a
                          ? karte.t("Ein Tux-Wetter hat am %1 seine Einstellungen gesichert: %2.",
                                    Qt.formatDateTime(new Date(angebotFlaeche.a.stand), karte.sp === "en" ? "yyyy-MM-dd HH:mm" : "dd.MM.yyyy HH:mm"),
                                    (e.locationName || "–") + (orte > 0 ? ", " + karte.t(orte === 1 ? "1 Ort in der Ortsliste" : "%1 Orte in der Ortsliste", orte) : ""))
                            + " " + karte.t("Diese Einstellungen übernehmen?")
                          : ""
                    color: karte.farbe(0.85)
                    font.family: karte.schrift
                    font.pixelSize: 17 * karte.s
                }
                Row {
                    spacing: 10 * karte.s
                    PC3.Button {
                        icon.name: "dialog-ok-apply"
                        text: karte.t("Übernehmen")
                        onClicked: karte.wetter.angebotAnnehmen()
                    }
                    PC3.Button {
                        icon.name: "dialog-cancel"
                        text: karte.t("Nein, neu einrichten")
                        onClicked: karte.wetter.angebotAblehnen()
                    }
                }
            }
        }
    }

    // ── Hinweis auf eine neue Version bei GitHub (main.qml neueVersion); heruntergeladen wird nichts ──
    Rectangle {
        id: updateFlaeche
        readonly property var v: karte.wetter.neueVersion
        // Das Angebot früherer Einstellungen geht vor
        visible: v !== null && karte.wetter.angebot === null
        anchors.fill: parent
        radius: 22 * karte.s
        color: karte.hellModus ? "#B3FFFFFF" : "#A6000000"

        // Klicks nicht an die Karte darunter weitergeben
        MouseArea { anchors.fill: parent; hoverEnabled: true; onWheel: wheel => wheel.accepted = true }

        Rectangle {
            anchors.centerIn: parent
            width: parent.width - 70 * karte.s
            height: Math.min(parent.height - 40 * karte.s, updateInhalt.implicitHeight + 44 * karte.s)
            radius: 16 * karte.s
            color: karte.hellModus ? "#F2FFFFFF" : "#F21B1F33"
            border.color: karte.farbe(0.25)
            border.width: 1
            clip: true

            Column {
                id: updateInhalt
                anchors.centerIn: parent
                width: parent.width - 48 * karte.s
                spacing: 12 * karte.s

                Text {
                    width: parent.width
                    wrapMode: Text.Wrap
                    text: updateFlaeche.v ? karte.t("Tux-Wetter %1 ist erschienen", updateFlaeche.v.version) : ""
                    color: karte.vorder
                    font.family: karte.schrift
                    font.pixelSize: 24 * karte.s
                    font.weight: Font.DemiBold
                }
                Text {
                    width: parent.width
                    wrapMode: Text.Wrap
                    text: updateFlaeche.v
                          ? karte.t("Installiert ist %1. Die neue Version gibt es auf GitHub; das Widget lädt sie nicht selbst herunter.",
                                    karte.wetter.eigeneVersion)
                          : ""
                    color: karte.farbe(0.85)
                    font.family: karte.schrift
                    font.pixelSize: 17 * karte.s
                }
                // Nebeneinander; nur wenn das Widget sehr schmal ist, rutscht der zweite Knopf darunter
                Flow {
                    width: parent.width
                    spacing: 10 * karte.s
                    PC3.Button {
                        icon.name: "internet-services"
                        text: karte.t("Download-Seite öffnen")
                        onClicked: karte.wetter.updateSeiteOeffnen()
                    }
                    PC3.Button {
                        icon.name: "dialog-cancel"
                        text: karte.t("Diese Version überspringen")
                        onClicked: karte.wetter.updateUeberspringen()
                    }
                }
            }
        }
    }
}
