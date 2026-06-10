// ══════════════════════════════════════════════════════
// desktopParser.js
// Parser .desktop files (Desktop Entry Specification)
// Used by launcher module of quickshell-d77
// ══════════════════════════════════════════════════════
.pragma library

// Inserted delimiter with DesktopDirScanner between each archive
var FILE_DELIM = "===DESKTOP_FILE_START==="

// ──────────────────────────────────────────────────────
// Remove the "field codes" (%f %u %U ...) of Exec field.
// .desktop uses those codes for archives/URLs, but for a
// simple launcher those codes must be ignored.
// ──────────────────────────────────────────────────────
function cleanExec(exec) {
    if (!exec) return ""
    return exec
        .replace(/%[fFuUdDnNickvm]/g, "")
        .replace(/\s+/g, " ")
        .trim()
}

// ──────────────────────────────────────────────────────
// Converts textual "true"/"false" into boolean.
// ──────────────────────────────────────────────────────
function toBool(val) {
    return String(val).trim().toLowerCase() === "true"
}

// ──────────────────────────────────────────────────────
// Parse the corresponding text block of .desktop file into
//  on single file. Returns an object or null.
// [Desktop Entry] section is the only considered.
// ──────────────────────────────────────────────────────
function parseOne(content) {
    var lines = content.split("\n")
    var inEntry = false
    var app = {
        name:       "",
        exec:       "",
        icon:       "",
        comment:    "",
        categories: "",
        terminal:   false,
        noDisplay:  false,
        hidden:     false,
        isApp:      true
    }

    for (var i = 0; i < lines.length; i++) {
        var line = lines[i].trim()
        if (line === "" || line.charAt(0) === "#")
            continue

        // Section header, ex: [Desktop Entry] or [Desktop Action ...]
        if (line.charAt(0) === "[") {
            inEntry = (line === "[Desktop Entry]")
            continue
        }
        if (!inEntry)
            continue

        var eq = line.indexOf("=")
        if (eq < 0)
            continue

        var key = line.substring(0, eq).trim()
        var val = line.substring(eq + 1).trim()

        // Ignore local keys, ex: Name[pt_BR]=...
        // Only keep the "pure" keys.
        switch (key) {
            case "Name":       app.name       = val;              break
            case "Exec":       app.exec       = cleanExec(val);   break
            case "Icon":       app.icon       = val;              break
            case "Comment":    app.comment    = val;              break
            case "Categories": app.categories = val;              break
            case "Terminal":   app.terminal   = toBool(val);      break
            case "NoDisplay":  app.noDisplay  = toBool(val);      break
            case "Hidden":     app.hidden     = toBool(val);      break
            case "Type":       app.isApp      = (val === "Application"); break
        }
    }

    return app
}

// ──────────────────────────────────────────────────────
// It parses all the concatenated output from the scanner.
// Returns the array of valid applications already alphabetically
// sorted by name.
// ──────────────────────────────────────────────────────
function parseEntries(raw) {
    if (!raw) return []

    var blocks = raw.split(FILE_DELIM)
    var apps = []
    var seen = ({})

    for (var i = 0; i < blocks.length; i++) {
        var block = blocks[i]
        if (!block || block.trim() === "")
            continue

        var app = parseOne(block)

        // Filter invalid entries.
        if (!app.isApp)        continue
        if (app.noDisplay)     continue
        if (app.hidden)        continue
        if (app.name === "")   continue
        if (app.exec === "")   continue

        // Avoid duplicates (same name + exec).
        var dedupKey = app.name + "\u0000" + app.exec
        if (seen[dedupKey]) continue
        seen[dedupKey] = true

        apps.push(app)
    }

    apps.sort(function (a, b) {
        var an = a.name.toLowerCase()
        var bn = b.name.toLowerCase()
        return an < bn ? -1 : (an > bn ? 1 : 0)
    })

    return apps
}

// ──────────────────────────────────────────────────────
// Filters a list of apps based on query (case-insensitive).
// Name, comment or category.
// ──────────────────────────────────────────────────────
function filterApps(apps, query) {
    if (!query || query.trim() === "")
        return apps

    var q = query.trim().toLowerCase()
    return apps.filter(function (a) {
        return a.name.toLowerCase().indexOf(q) >= 0
            || (a.comment    && a.comment.toLowerCase().indexOf(q)    >= 0)
            || (a.categories && a.categories.toLowerCase().indexOf(q) >= 0)
    })
}
