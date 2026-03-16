#!/usr/bin/env bash
set -euo pipefail

FILE="Services/System/NotificationService.qml"

awk '
/^  \/\/ State$/ {
    print
    print "  FileView {"
    print "    id: notificationAllowlistFile"
    print "    path: Settings.configDir + \"notification-allowlist\""
    print "    watchChanges: true"
    print "  }"
    print ""
    next
}
{ print }
' "$FILE" >"$FILE.tmp" && mv "$FILE.tmp" "$FILE"

awk '
/^      if \(shouldSave\) \{$/ {
    print "      if (shouldSave) {"
    print "        const _allowed = (notificationAllowlistFile.text() || \"\")"
    print "          .toLowerCase().split(\"\\n\").map(a => a.trim()).filter(a => a !== \"\");"
    print "        if (_allowed.length === 0 || _allowed.includes((data.appName || \"\").toLowerCase())) {"
    print "          addToHistory(data);"
    print "        }"
    in_block = 1
    next
}
in_block {
    if (/^      }$/) { in_block = 0; print }
    next
}
{ print }
' "$FILE" >"$FILE.tmp" && mv "$FILE.tmp" "$FILE"

grep -q "notificationAllowlistFile" "$FILE" ||
    {
        echo "patch-notification-service: FileView not inserted into $FILE" >&2
        exit 1
    }
grep -q "_allowed" "$FILE" ||
    {
        echo "patch-notification-service: allowlist gate not applied in $FILE" >&2
        exit 1
    }
