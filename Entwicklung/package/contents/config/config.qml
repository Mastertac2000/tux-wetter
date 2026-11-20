// SPDX-FileCopyrightText: 2026 R.Bruns
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory {
        // Die Einstellungsseite selbst folgt der gewählten Sprache; der Name hier der Systemsprache
        name: Qt.locale().name.substring(0, 2) === "de" ? "Allgemein" : "General"
        icon: "weather-few-clouds"
        source: "ConfigGeneral.qml"
    }
}
