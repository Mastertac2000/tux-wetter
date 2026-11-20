.pragma library

// SPDX-FileCopyrightText: 2026 R.Bruns
// SPDX-License-Identifier: GPL-3.0-or-later

// Farbschemen für den Hintergrund der Karte (wie bei Tux Kalender): Verlauf von oben links über die
// Mitte nach unten rechts, dazu ein Schimmer unten links. "eigen" nimmt zwei frei gewählte Farben;
// die Mitte liegt dann genau dazwischen, der Schimmer ist eine aufgehellte Startfarbe.

const SCHEMEN = [
    { id: "violett", name: "Violett (Standard)", farben: ["#2B2763", "#4434B6", "#5A3AD4"], schimmer: "#2F6CE8" },
    { id: "blau", name: "Blau", farben: ["#353A97", "#3442A8", "#2C4CB8"], schimmer: "#2FA0E8" },
    { id: "petrol", name: "Petrol", farben: ["#1F5A73", "#1E6E80", "#1B8290"], schimmer: "#2FC8C0" },
    { id: "gruen", name: "Grün", farben: ["#1F5E4A", "#22704F", "#2B8457"], schimmer: "#3FBF7F" },
    { id: "bordeaux", name: "Bordeaux", farben: ["#6B1F3A", "#7E2747", "#8E2F4F"], schimmer: "#D04870" },
    { id: "sonnenuntergang", name: "Sonnenuntergang", farben: ["#8A3A6E", "#A6435C", "#B8553E"], schimmer: "#E07A3C" },
    { id: "graphit", name: "Graphit", farben: ["#3A3F4B", "#454B58", "#515866"], schimmer: "#6A7A94" },
    { id: "nacht", name: "Nacht", farben: ["#141A33", "#1B2240", "#222B4F"], schimmer: "#2E3F8A" },
    { id: "eigen", name: "Eigene Farben", farben: [], schimmer: "" }
]

function hexZuRgb(hex) {
    const h = String(hex).replace("#", "")
    const s = h.length === 3 ? h.split("").map(c => c + c).join("") : h.slice(-6)
    return [parseInt(s.substring(0, 2), 16), parseInt(s.substring(2, 4), 16), parseInt(s.substring(4, 6), 16)]
}

function rgbZuHex(rgb) {
    return "#" + rgb.map(v => Math.round(Math.max(0, Math.min(255, v))).toString(16).padStart(2, "0")).join("").toUpperCase()
}

function mischen(a, b, anteil) {
    const x = hexZuRgb(a), y = hexZuRgb(b)
    return rgbZuHex([0, 1, 2].map(i => x[i] + (y[i] - x[i]) * anteil))
}

function schema(id) {
    return SCHEMEN.find(x => x.id === id) || SCHEMEN[0]
}

// Die drei Verlaufsfarben des gewählten Schemas
// Eigene Farben nur, wenn sie lesbar sind (#RGB, #RRGGBB oder #AARRGGBB); sonst das Standardschema
function gueltig(hex) {
    return /^#?([0-9a-f]{3}|[0-9a-f]{6}|[0-9a-f]{8})$/i.test(String(hex).trim())
}
function verlauf(id, eigenStart, eigenEnde) {
    if (id === "eigen" && gueltig(eigenStart) && gueltig(eigenEnde))
        return [eigenStart, mischen(eigenStart, eigenEnde, 0.5), eigenEnde]
    return schema(id === "eigen" ? "" : id).farben
}

// Farbe des Schimmers unten links
function schimmer(id, eigenStart) {
    return id === "eigen" && gueltig(eigenStart) ? mischen(eigenStart, "#FFFFFF", 0.35) : schema(id === "eigen" ? "" : id).schimmer
}

// Relative Helligkeit nach WCAG (0 = schwarz, 1 = weiss)
function helligkeit(hex) {
    const lin = hexZuRgb(hex).map(v => {
        const c = v / 255
        return c <= 0.03928 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4)
    })
    return 0.2126 * lin[0] + 0.7152 * lin[1] + 0.0722 * lin[2]
}

// Kontrast von weisser Schrift auf der Farbe (WCAG: ab 4,5 gut lesbar, ab 3 für grosse Schrift)
function kontrastWeiss(hex) {
    return 1.05 / (helligkeit(hex) + 0.05)
}

// Helle Karte: die Farben des Schemas stark aufgehellt, so dass dunkle Schrift gut lesbar ist
function verlaufHell(id, eigenStart, eigenEnde) {
    return verlauf(id, eigenStart, eigenEnde).map(f => mischen(f, "#FFFFFF", 0.84))
}
