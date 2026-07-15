# Security Policy

## Supported state

myCloset is currently a local functional prototype (`0.1.x`) and is not approved for production user data or App Store distribution. Security fixes apply to the latest `main` branch until formal release branches exist.

## Reporting a vulnerability

Do not disclose suspected vulnerabilities, private-data exposure, credentials, or exploit details in a public issue.

Use GitHub's private vulnerability reporting feature for this repository when available. If it is not enabled, contact the repository owner privately through the contact method listed on the owner's GitHub profile and include:

- affected commit or version;
- component and reproduction conditions;
- realistic impact;
- proof of concept with personal data removed;
- suggested mitigation, if known.

The project owner should acknowledge a report within five business days, triage severity, provide a remediation plan, and coordinate disclosure after a fix is available. This is a target, not a contractual service-level agreement.

## Security boundaries

The prototype:

- stores closet/profile/outfit content in the app's local container;
- performs no account authentication;
- has no production server or cloud media store;
- makes optional foreground weather requests;
- must not be used with real production secrets.

Future phases must add the controls specified in `SRS.md`, including server-side authorization, short-lived private media access, token validation/revocation, role-based administration, audit logging, deletion, rate limiting, upload validation, privacy reviews, and incident response.

## Secrets and sensitive files

Never commit:

- API keys or OAuth client secrets;
- `.env` files containing real values;
- Apple signing certificates or private keys;
- provisioning profiles;
- production exports, logs, images, or database snapshots;
- unredacted vulnerability reports.

Repository CI and review should block secret exposure. If a secret is committed, revoke and rotate it immediately; deleting it from a later commit is insufficient.
