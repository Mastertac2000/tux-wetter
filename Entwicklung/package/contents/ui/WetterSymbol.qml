// SPDX-FileCopyrightText: 2026 R.Bruns
// SPDX-License-Identifier: GPL-3.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import org.kde.plasma.plasmoid
import "wetter.js" as W

// Wettersymbol; bei Regen, Niesel, Schauern und Schnee fallen Tropfen bzw. Flocken animiert
// unter der Wolke hervor, bei Gewitter zuckt in unregelmässigen Abständen der Blitz, die
// Sonne dreht langsam ihre Strahlen, und der Mond leuchtet und wiegt sich (bei klarer Nacht
// funkeln dazu Sterne). Wolken treiben sanft hin und her.
// Alle Bewegungen werden aus zeit berechnet, die der gemeinsame Animationstakt in main.qml
// vorgibt; so zeichnet plasmashell nur in diesem Takt neu statt mit der Bildrate des Monitors.
// Koordinaten in Einheiten der 64×64 grossen SVG-Vorlage (e = 1 Einheit).
Item {
    id: symbol

    property int code
    property bool tag: true
    // Laufzeit in Sekunden
    property real zeit: 0

    readonly property string name: W.symbol(code, tag)
    readonly property string art: W.niederschlag(code)
    readonly property bool animiert: art !== "" && Plasmoid.configuration.animations
    readonly property bool schnee: art === "schnee"
    readonly property bool gewitter: code >= 95 && Plasmoid.configuration.animations
    // Mittelpunkt und Radius der Sonne in den Tagessymbolen (null = keine animierte Sonne)
    readonly property var sonne: Plasmoid.configuration.animations
        ? ({ "clear-day": [32, 32, 13], "partly-day": [25, 25, 10], "showers-day": [25, 20, 9] })[name] || null
        : null
    // Mondbild, Mittelpunkt und Radius der Sichel in den Nachtsymbolen (null = kein animierter Mond)
    readonly property var mond: Plasmoid.configuration.animations
        ? ({ "clear-night": ["moon-clear", 30, 29, 20], "partly-night": ["moon-partly", 22.9, 20.7, 17],
             "showers-night": ["moon-showers", 21.2, 14.2, 16] })[name] || null
        : null
    readonly property bool wolke: Plasmoid.configuration.animations && !name.startsWith("clear-")
    readonly property real e: width / 64

    // Datei des Grundbilds (siehe unten); "" = keins
    function grundbild(c, t, an) {
        const n = W.symbol(c, t)
        let datei = n
        if (an && ["clear-day", "partly-day", "showers-day", "clear-night", "partly-night", "showers-night"].indexOf(n) >= 0)
            datei = n.startsWith("clear-") ? "" : n + "-front"
        else if (an && n === "cloudy")
            datei = "cloudy-front"
        else if (an && (W.niederschlag(c) !== "" || c >= 95))
            datei = n + "-cloud"
        return datei ? Qt.resolvedUrl("../icons/" + datei + ".svg") : ""
    }

    // Sanftes Pendeln 0 → 1 → 0 mit der Periode p (Sekunden), wie eine InOutSine-Animation hin und zurück
    function pendel(p) {
        return (1 - Math.cos(2 * Math.PI * zeit / p)) / 2
    }

    // Wolkentakt 0…2π in 9 s, je Symbol zufällig versetzt, damit nicht alle Wolken gleich schwingen
    readonly property real wolkenVersatz: Math.random() * 2 * Math.PI
    readonly property real wolkenPhase: wolkenVersatz + 2 * Math.PI * zeit / 9
    // x-Positionen der Tropfen bzw. Flocken wie in den unbewegten Symbolen
    readonly property var spalten: ({ niesel: [24, 36], regen: [20, 31, 42],
                                      schauer: [24, 34, 44], schnee: [20, 32, 44] })[art] || []

    // Gemeinsamer Takt 0…1; jeder Tropfen läuft darin versetzt
    readonly property real takt: (zeit / (schnee ? 2.6 : art === "niesel" ? 1.3 : 0.9)) % 1

    // ── Sonne: Strahlen drehen sich langsam und werden sanft grösser und kleiner ──
    Item {
        anchors.fill: parent
        visible: symbol.sonne !== null

        Image {
            readonly property real r: symbol.sonne ? symbol.sonne[2] : 13
            width: (r + 10) * 2 * symbol.e
            height: width
            x: (symbol.sonne ? symbol.sonne[0] : 32) * symbol.e - width / 2
            y: (symbol.sonne ? symbol.sonne[1] : 32) * symbol.e - height / 2
            source: Qt.resolvedUrl("../icons/rays-" + r + ".svg")
            sourceSize: Qt.size(width * 2, height * 2)
            smooth: true
            rotation: parent.visible ? (symbol.zeit * 12) % 360 : 0
            scale: parent.visible ? 1 + 0.1 * symbol.pendel(3.6) : 1
        }
        Image {
            readonly property real r: symbol.sonne ? symbol.sonne[2] : 13
            width: 2 * r * symbol.e
            height: width
            x: (symbol.sonne ? symbol.sonne[0] : 32) * symbol.e - width / 2
            y: (symbol.sonne ? symbol.sonne[1] : 32) * symbol.e - height / 2
            source: Qt.resolvedUrl("../icons/sun-disc.svg")
            sourceSize: Qt.size(width * 2, height * 2)
        }
    }

    // ── Mond: Schein schwillt auf und ab, die Sichel wiegt sich leicht ──
    Item {
        id: mondEbene
        anchors.fill: parent
        visible: symbol.mond !== null

        readonly property real mx: (symbol.mond ? symbol.mond[1] : 32) * symbol.e
        readonly property real my: (symbol.mond ? symbol.mond[2] : 32) * symbol.e
        readonly property real mr: (symbol.mond ? symbol.mond[3] : 20) * symbol.e

        Image {
            width: parent.mr * 2.8
            height: width
            x: parent.mx - width / 2
            y: parent.my - height / 2
            source: Qt.resolvedUrl("../icons/moon-glow.svg")
            sourceSize: Qt.size(width * 2, height * 2)
            opacity: parent.visible ? 0.3 + 0.6 * symbol.pendel(5.2) : 0
        }
        Image {
            anchors.fill: parent
            source: symbol.mond ? Qt.resolvedUrl("../icons/" + symbol.mond[0] + ".svg") : ""
            sourceSize: Qt.size(width * 2, height * 2)
            transform: Rotation {
                origin.x: mondEbene.mx
                origin.y: mondEbene.my
                angle: mondEbene.visible ? -5 + 10 * symbol.pendel(7.6) : 0
            }
        }

        // Funkelnde Sterne nur bei klarer Nacht: [x, y, Grösse, Periode in s]
        Repeater {
            model: symbol.name === "clear-night" && symbol.mond !== null
                   ? [[50, 16, 7, 3.4], [57, 43, 5, 4.6], [14, 55, 4.5, 4]] : []

            Image {
                required property var modelData
                width: modelData[2] * symbol.e
                height: width
                x: modelData[0] * symbol.e - width / 2
                y: modelData[1] * symbol.e - height / 2
                source: Qt.resolvedUrl("../icons/star.svg")
                sourceSize: Qt.size(width * 2, height * 2)
                opacity: 1 - 0.85 * symbol.pendel(modelData[3])
            }
        }
    }

    // Hintere Wolke bei „Bedeckt“; treibt gegenläufig zur vorderen
    Image {
        anchors.fill: parent
        visible: symbol.wolke && symbol.name === "cloudy"
        source: visible ? Qt.resolvedUrl("../icons/cloudy-back.svg") : ""
        sourceSize: Qt.size(width * 2, height * 2)
        transform: Translate {
            x: -Math.sin(symbol.wolkenPhase) * 1.2 * symbol.e
            y: Math.sin(symbol.wolkenPhase * 2) * 0.4 * symbol.e
        }
    }

    // Grundbild; bei animierter Sonne oder animiertem Mond nur die Wolke davor (bei klarem Himmel
    // nichts), bei Niederschlag/Gewitter nur die Wolke, bei „Bedeckt“ nur die vordere Wolke
    Image {
        anchors.fill: parent
        // Direkt aus code berechnet: über name/animiert/sonne gelesen, konnte beim Wechsel des Codes
        // kurz ein veralteter Zwischenwert eine nicht vorhandene Datei verlangen (z. B. fog-cloud.svg)
        source: symbol.grundbild(symbol.code, symbol.tag, Plasmoid.configuration.animations)
        sourceSize: Qt.size(width * 2, height * 2)
        transform: Translate {
            x: symbol.wolke ? Math.sin(symbol.wolkenPhase) * 1.6 * symbol.e : 0
            y: symbol.wolke ? Math.sin(symbol.wolkenPhase * 2) * 0.6 * symbol.e : 0
        }
    }

    Repeater {
        model: symbol.animiert ? symbol.spalten : []

        Image {
            required property real modelData
            required property int index
            // Phase dieses Tropfens; Nachbarn sind gegeneinander versetzt
            readonly property real phase: (symbol.takt + index / symbol.spalten.length + (index % 2) * 0.17) % 1
            readonly property real groesse: (symbol.schnee ? 5.6 : 11.2) * symbol.e

            z: -1
            width: groesse
            height: groesse
            source: Qt.resolvedUrl("../icons/" + (symbol.schnee ? "flake" : "drop") + ".svg")
            sourceSize: Qt.size(width * 2, height * 2)
            x: (modelData + (symbol.schnee ? Math.sin(phase * Math.PI * 2) * 2.2 : 0)) * symbol.e - width / 2
            y: (44 + phase * (symbol.schnee ? 16 : 17)) * symbol.e - height / 2
            opacity: phase < 0.2 ? phase / 0.2 : phase > 0.7 ? (1 - phase) / 0.3 : 1
        }
    }

    // ── Gewitter: Schein und Blitz, die gemeinsam aufflackern ──
    // Zufällige Pause je Symbol, damit nicht alle Gewitter gleichzeitig blitzen
    readonly property real blitzPause: 1200 + Math.random() * 2800

    // Helligkeit des Blitzes ms Millisekunden nach dem Ende der Pause
    function blitzHelligkeit(ms) {
        if (ms < 0)
            return 0
        if (ms < 50)
            return ms / 50
        if (ms < 120)
            return 1 - 0.75 * (ms - 50) / 70
        if (ms < 170)
            return 0.25 + 0.75 * (ms - 120) / 50
        if (ms < 520)
            return 1
        const x = Math.min(1, (ms - 520) / 300)
        return 1 - x * x
    }

    Item {
        anchors.fill: parent
        visible: symbol.gewitter
        opacity: visible ? symbol.blitzHelligkeit((symbol.zeit * 1000) % (symbol.blitzPause + 820) - symbol.blitzPause) : 0

        Image {
            x: 14 * symbol.e; y: 32 * symbol.e
            width: 38 * symbol.e; height: width
            source: Qt.resolvedUrl("../icons/bolt-glow.svg")
            sourceSize: Qt.size(width * 2, height * 2)
        }
        Image {
            x: 24 * symbol.e; y: 39 * symbol.e
            width: 17 * symbol.e; height: 23 * symbol.e
            source: Qt.resolvedUrl("../icons/bolt.svg")
            sourceSize: Qt.size(width * 2, height * 2)
        }
    }
}
