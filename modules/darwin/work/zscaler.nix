{ pkgs, ... }: {
  system.activationScripts.zscalerCaBundle = {
    # Run before the Nix daemon is restarted so the new bundle is in place.
    text = ''
      BUNDLE=/etc/ssl/certs/ca-bundle-with-zscaler.crt
      echo "Setting up Zscaler CA bundle at $BUNDLE..."

      # Start from the standard Mozilla bundle (provided by nixpkgs cacert).
      cat ${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt > "$BUNDLE"

      # Append every cert from the System Keychain whose subject contains
      # "Zscaler" (case-insensitive). Use Python to avoid awk/openssl piping
      # complexity across macOS/Nix path differences.
      /usr/bin/python3 - <<'PYEOF'
import subprocess, sys

result = subprocess.run(
    ["security", "find-certificate", "-a", "-p", "/Library/Keychains/System.keychain"],
    capture_output=True, text=True
)

certs = []
current = []
for line in result.stdout.splitlines():
    if "-----BEGIN CERTIFICATE-----" in line:
        current = [line]
    elif "-----END CERTIFICATE-----" in line:
        current.append(line)
        certs.append("\n".join(current))
        current = []
    elif current:
        current.append(line)

zscaler_certs = []
for cert in certs:
    subj = subprocess.run(
        ["openssl", "x509", "-noout", "-subject"],
        input=cert, capture_output=True, text=True
    )
    if "zscaler" in subj.stdout.lower():
        zscaler_certs.append(cert)

# Write the named bundle (used by the Nix daemon via nix.settings.ssl-cert-file).
bundle_path = "/etc/ssl/certs/ca-bundle-with-zscaler.crt"
with open(bundle_path, "a") as f:
    for cert in zscaler_certs:
        f.write("\n# Zscaler Root CA (from macOS System Keychain)\n")
        f.write(cert + "\n")

# Also patch /etc/ssl/cert.pem - this is the fallback used by libcurl (and
# therefore zellij's plugin downloader) when no SSL_CERT_FILE env var is set.
# Only append if not already present (idempotent).
cert_pem_path = "/etc/ssl/cert.pem"
existing = open(cert_pem_path).read()
appended = 0
with open(cert_pem_path, "a") as f:
    for cert in zscaler_certs:
        # Use the first line of the cert as a fingerprint to avoid duplicates.
        if cert.splitlines()[1] not in existing:
            f.write("\n# Zscaler Root CA (from macOS System Keychain)\n")
            f.write(cert + "\n")
            appended += 1

print(f"Added {len(zscaler_certs)} Zscaler cert(s) to {bundle_path}, {appended} new cert(s) appended to {cert_pem_path}", file=sys.stderr)
PYEOF
    '';
  };

  nix.settings.ssl-cert-file = "/etc/ssl/certs/ca-bundle-with-zscaler.crt";

  launchd.daemons.nix-daemon.serviceConfig.EnvironmentVariables = {
    NIX_SSL_CERT_FILE = "/etc/ssl/certs/ca-bundle-with-zscaler.crt";
    NIX_GIT_SSL_CAINFO = "/etc/ssl/certs/ca-bundle-with-zscaler.crt";
  };

  environment.variables = {
    NIX_SSL_CERT_FILE = "/etc/ssl/certs/ca-bundle-with-zscaler.crt";
    NIX_GIT_SSL_CAINFO = "/etc/ssl/certs/ca-bundle-with-zscaler.crt";
    SSL_CERT_FILE = "/etc/ssl/certs/ca-bundle-with-zscaler.crt";
  };
}