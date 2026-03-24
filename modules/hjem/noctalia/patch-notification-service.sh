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
/^  function trySaveToHistory\(data, notification\) \{$/ {
    print
    in_fn = 1
    next
}
in_fn && /^      return;$/ {
    print
    print "    const _allowed = (notificationAllowlistFile.text() || \"\")"
    print "      .toLowerCase().split(\"\\n\").map(a => a.trim()).filter(a => a !== \"\");"
    print "    if (_allowed.length > 0 && !_allowed.includes((data.appName || \"\").toLowerCase()))"
    print "      return;"
    in_fn = 0
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
