// Gokapi: deutsche Oberfläche für alle öffentlichen Seiten (Upload-Anfrage, Download, Fehlerseite).
// Gokapi v2.2.4 hat keine Übersetzungen; diese Datei lädt Gokapi als /custom/public.js.
// Pflege: Nach einem Gokapi-Update bleiben geänderte Texte englisch — dann EXACT/PATTERNS ergänzen.
// Quelle der Texte: templates/html_public_upload.tmpl, html_error.tmpl, html_download*.tmpl, html_footer.tmpl,
// static/js/public_upload.js (Stand v2.2.4, erfaßt 26.10.2026).
(function () {
    'use strict';

    const EXACT = {
        // Upload-Seite
        'Upload Files': 'Dateien hochladen',
        'Note': 'Hinweis',
        'Upload restrictions': 'Bedingungen',
        'Upload possible until:': 'Hochladen möglich bis:',
        'Maximum file size:': 'Höchstgröße pro Datei:',
        'Maximum number of files:': 'Noch erlaubte Dateien:',
        'Drag & drop files here': 'Dateien hierher ziehen',
        'or paste or click to select': 'oder hier klicken und Dateien auswählen',
        'Unable to upload': 'Hochladen nicht möglich',
        'Continue': 'Weiter',
        'Success': 'Fertig',
        'All files have been successfully uploaded. No further files can be uploaded anymore. You can close this page now.':
            'Alle Dateien sind angekommen. Weitere Dateien sind nicht mehr möglich. Sie können diese Seite jetzt schließen.',
        // Fortschritt und Meldungen je Datei
        'Ready': 'Bereit',
        'Remove': 'Entfernen',
        'Reserving...': 'Wird vorbereitet …',
        'Cancel Upload': 'Hochladen abbrechen',
        'Waiting for upload slot...': 'Wartet …',
        'Completed': 'Fertig ✓',
        'Cancelled': 'Abgebrochen',
        'Upload failed': 'Hochladen fehlgeschlagen',
        'Remove from list': 'Aus der Liste entfernen',
        'Server Error': 'Serverfehler',
        'File size limit exceeded': 'Datei ist zu groß',
        'Upload request has expired': 'Der Link ist abgelaufen',
        'Maximum file count reached': 'Keine weiteren Dateien möglich',
        'Too many requests, please try again later': 'Gerade zu viele Anfragen, bitte später noch einmal versuchen',
        'Unknown upload error': 'Unbekannter Fehler beim Hochladen',
        'Too many files are selected for upload. Please only select 1 file.':
            'Zu viele Dateien ausgewählt. Bitte nur 1 Datei auswählen.',
        'Some files could not be uploaded because the server rejected the request. This likely occurred because another user was uploading files at the same time and the maximum file limit was reached.':
            'Einige Dateien konnten nicht hochgeladen werden, weil die erlaubte Anzahl inzwischen erreicht ist.',
        'The upload request exceeded the permitted time limit, and uploading additional files is no longer possible.':
            'Der Link ist abgelaufen. Weitere Dateien können nicht mehr hochgeladen werden.',
        // Fehlerseite
        'File not found': 'Datei nicht gefunden',
        'The link may have expired or the file has been downloaded too many times.':
            'Der Link ist vermutlich abgelaufen, oder die Datei wurde zu oft heruntergeladen.',
        'Unable to upload files': 'Hochladen nicht möglich',
        'This can happen for one of the following reasons:': 'Mögliche Gründe:',
        '- The upload request has expired (time limit reached)': '– Der Link ist abgelaufen.',
        '- The file limit for this upload request has been reached': '– Die erlaubte Anzahl Dateien ist erreicht.',
        '- An invalid upload URL was submitted': '– Der Link ist unvollständig oder falsch.',
        // Download-Seite
        'Size': 'Größe',
        'Download': 'Herunterladen',
        'Download File': 'Datei herunterladen',
        'Password required': 'Passwort erforderlich',
        'Enter password': 'Passwort eingeben',
        'Incorrect password!': 'Falsches Passwort!',
        // Fußzeile
        'Powered by': 'Bereitgestellt mit',
    };

    const PATTERNS = [
        [/^The file "(.+)" exceeds the maximum allowed size of (.+)\.$/s,
            (m, name, size) => `Die Datei „${name}“ ist zu groß. Erlaubt sind höchstens ${size}.`],
        [/^Too many files are selected for upload\. Please only select (\d+) files or fewer\.$/,
            (m, n) => `Zu viele Dateien ausgewählt. Bitte höchstens ${n} Dateien auswählen.`],
        // "Retry 2/3: Server Error (3.1 MB/s)" — die Geschwindigkeit hängt Gokapi an, sie bleibt stehen.
        [/^Retry (\d+)\/(\d+): (.*?)( \([\d.]+ [KMG]?B\/s\))?$/s,
            (m, a, b, rest, speed) => `Neuer Versuch ${a}/${b}: ${translate(rest)}${speed || ''}`],
        // Reine Größen- und Fortschrittsangaben: nur das Dezimalkomma
        [/^\d+(\.\d+)? [KMG]?B$/, (m) => m],
        [/^\d+%( \([\d.]+ [KMG]?B\/s\))?$/, (m) => m],
        // Ablaufdatum aus formatUnixTimestamp(): "2026-11-02 20:15" -> "02.11.2026, 20:15 Uhr"
        [/^(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2})$/,
            (m, y, mo, d, h, mi) => `${d}.${mo}.${y}, ${h}:${mi} Uhr`],
    ];

    // "200.0 MB" -> "200,0 MB"; greift nur bei Zahl + Einheit, nicht in Datumsangaben
    function decimalComma(s) {
        return s.replace(/(\d)\.(\d+)(?= ?[KMG]?B\b)/g, '$1,$2');
    }

    function translate(text) {
        const key = text.trim();
        if (!key) return text;
        if (Object.prototype.hasOwnProperty.call(EXACT, key)) {
            return text.replace(key, EXACT[key]);
        }
        for (const [re, fn] of PATTERNS) {
            const m = key.match(re);
            if (m) return text.replace(key, decimalComma(fn(...m)));
        }
        return text;
    }

    function translateNode(node) {
        if (node.nodeType === Node.TEXT_NODE) {
            const t = translate(node.nodeValue);
            if (t !== node.nodeValue) node.nodeValue = t;
            return;
        }
        if (node.nodeType !== Node.ELEMENT_NODE) return;
        if (node.tagName === 'SCRIPT' || node.tagName === 'STYLE') return;
        for (const attr of ['title', 'placeholder', 'aria-label']) {
            const v = node.getAttribute(attr);
            if (v) {
                const t = translate(v);
                if (t !== v) node.setAttribute(attr, t);
            }
        }
        node.childNodes.forEach(translateNode);
    }

    function start() {
        document.documentElement.lang = 'de';
        translateNode(document.body);
        new MutationObserver((mutations) => {
            for (const mu of mutations) {
                if (mu.type === 'characterData') translateNode(mu.target);
                else if (mu.type === 'attributes') translateNode(mu.target);
                else mu.addedNodes.forEach(translateNode);
            }
        }).observe(document.body, {
            childList: true, characterData: true, subtree: true,
            attributes: true, attributeFilter: ['title', 'placeholder', 'aria-label'],
        });
    }

    if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', start);
    else start();
})();
