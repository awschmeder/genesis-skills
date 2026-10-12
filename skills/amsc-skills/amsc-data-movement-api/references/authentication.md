# Authentication

AmSC API authentication is Ping Identity: get a personal access token (PAT) from the Personal Access Tokens page of the myAmSC dashboard (https://my.amsc.energy.gov/dashboard); a PAT is tied to the project selected when it is generated. Export it as `AMSC_TOKEN` and send it as `Authorization: Bearer $AMSC_TOKEN` (see `../examples/curl-examples.md`).

The Globus resource server, scope, `UserApp` client and login flow below describe the bundled client's legacy AmSC login and are unverified against Ping auth; prefer the PAT. The Globus `data_access` consent for transfer source collections was observed with the legacy Globus login and has not been verified with a PAT.

## Base URL and scope

```text
Base URL: https://api.american-science-cloud.org/api/current
Resource server: 35bf38d3-4b30-42c8-ac9f-e39cec6516bf
Primary scope: https://auth.globus.org/scopes/35bf38d3-4b30-42c8-ac9f-e39cec6516bf/amsc
```

## Legacy client

The Python client in this skill uses the legacy Globus login (unverified against Ping auth; prefer the PAT):

```bash
python3 .claude/skills/amsc-data-movement-api/scripts/amsc_service_client.py --transfers
```

The client uses a Globus `UserApp` and stores tokens next to the client script:

```text
.claude/skills/amsc-data-movement-api/scripts/tokens.json
```

## Interactive login flow

When no valid cached token is available, the client prints a Globus authorization URL and waits for an authorization code.

Agent workflow:

1. Start the client command.
2. If a login URL is printed, allow the user to login with it
3. Wait for the user to complete the browser flow and provide the authorization code.
4. Send the code back to the waiting client process.

## Consent-required behavior

Transfer creation can require additional Globus `data_access` consent for the source collection.

For the tutorial source collection, the server has requested this composite scope during live testing:

```text
https://auth.globus.org/scopes/35bf38d3-4b30-42c8-ac9f-e39cec6516bf/amsc[urn:globus:auth:scope:transfer.api.globus.org:all[*https://auth.globus.org/scopes/6c54cade-bde5-45c1-bdea-f4bd71dba2cc/data_access]]
```

If the client prints a consent URL, treat it the same way as the initial login URL and write it to `login.tmp`.

## Notes

- Keep tokens and authorization codes out of committed files.
- The default API host for this skill is `https://api.american-science-cloud.org/api/current`.
