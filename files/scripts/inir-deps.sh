#!/usr/bin/env bash
# files/scripts/inir-deps.sh
set -o pipefail

export REPO_ROOT=/tmp/inir SCRIPT_DIR=/tmp/inir INVOKED_FROM=/tmp/inir

mkdir -p /tmp/shim
cat > /tmp/shim/sudo <<'EOF'
#!/bin/sh
while [ "${1#-}" != "$1" ]; do shift; done   # drop flags like -n / -E
exec "$@"
EOF
chmod +x /tmp/shim/sudo
export PATH=/tmp/shim:$PATH

git clone --depth 1 --branch v3.1.1 https://github.com/snowarch/inir.git /tmp/inir
cd /tmp/inir

export HOME=/root TMPDIR=/tmp
ask=false; quiet=true; assume_yes=true
SKIP_SYSUPDATE=true
INSTALL_AUDIO=true INSTALL_TOOLKIT=true INSTALL_SCREENCAPTURE=true INSTALL_FONTS=true

# the same libraries ./setup loads before it hands over to the dist scripts
source ./sdata/lib/environment-variables.sh
source ./sdata/lib/functions.sh
source ./sdata/lib/tui.sh
source ./sdata/lib/package-installers.sh
source ./sdata/lib/dist-determine.sh
source ./sdata/lib/conflicts.sh
source ./sdata/lib/versioning.sh
source ./scripts/lib/config-path.sh
source ./sdata/lib/robust-update.sh
source ./sdata/lib/extras.sh
source ./sdata/lib/doctor.sh
source ./sdata/lib/snapshots.sh
source ./sdata/lib/uninstall.sh
source ./sdata/lib/user-modifications.sh
source ./sdata/lib/cli-binary.sh
source ./sdata/lib/hub-plugins.sh
source ./sdata/lib/prebuilt.sh

detect_distro
source ./sdata/subcmd-install/1.deps-router.sh || { echo "iNiR deps failed"; exit 1; }

# /usr/local is /var on ostree and doesn't ship in the image: move what landed there
if [ -d /usr/local/bin ]; then
  cp -a /usr/local/bin/. /usr/bin/ 2>/dev/null || true
fi

# the providers only warn on failure, so check that the essentials really arrived
for bin in niri qs awww cliphist; do
  command -v "$bin" >/dev/null || { echo "missing: $bin"; exit 1; }
done

mkdir -p /usr/lib/systemd/user
ln -sf /usr/lib/systemd/system/ydotool.service /usr/lib/systemd/user/ydotool.service

rm -rf /tmp/inir