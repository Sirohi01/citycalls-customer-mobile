#!/bin/sh
# Runs the app against the local citycalls-api on this Mac's CURRENT Wi-Fi IP,
# so changing networks never leaves the app pointing at a stale address (which
# is what silently stops login OTPs). Extra args go to `flutter run`.
#
#   ./scripts/run-local.sh            # default device
#   ./scripts/run-local.sh -d <id>    # a specific device
IP=$(ipconfig getifaddr en0 || ipconfig getifaddr en1)
if [ -z "$IP" ]; then
  echo "No Wi-Fi IP found — is this Mac connected to a network?" >&2
  exit 1
fi
URL="http://$IP:4000/api/v1"
if ! curl -s -m 5 -o /dev/null "$URL/health"; then
  echo "Local API is not answering at $URL — start citycalls-api (npm run dev) first." >&2
  exit 1
fi
echo "Using local API: $URL"
exec flutter run --dart-define=API_BASE_URL="$URL" "$@"
