import sys
from PySide6.QtCore import QUrl, QTimer, QSize
from PySide6.QtWidgets import QApplication
from PySide6.QtWebEngineWidgets import QWebEngineView
quelle, ziel, breite = sys.argv[1], sys.argv[2], int(sys.argv[3])
app = QApplication(sys.argv[:1] + ["--disable-gpu"])
v = QWebEngineView()
v.resize(breite, 900)
def fertig(ok):
    # Webfonts laden lassen, dann Höhe messen und auf volle Länge vergrössern
    QTimer.singleShot(2500, lambda: v.page().runJavaScript("document.documentElement.scrollHeight", hoehe))
def hoehe(h):
    v.resize(breite, int(h))
    QTimer.singleShot(1500, lambda: (v.grab().save(ziel), print("gespeichert", breite, "x", h), app.quit()))
v.loadFinished.connect(fertig)
v.load(QUrl.fromLocalFile(quelle))
v.show()
app.exec()
