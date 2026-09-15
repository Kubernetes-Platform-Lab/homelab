## Managing user quota for self-hosted ente

1. Download `ente-cli-bin` to be able to manage ente from an externally as you cannot do it from within pod
2. Create `~/.ente/config.yaml` file and insert:
```
endpoint:
    api: "https://api-ente.akna.one.pl"
```
or whatever your ente photos endpoint is
3. Run `ente account add` to authenticate to the endpoint

photos
~/.ente/
email_address_of_admin_account
password_of_admin_account

4. Run `ente-cli admin update-subscription -a <auth-email> -u <user-email-to-change-quota> --no-limit`

The CLI asks you for the amount of storage quota you want to assign to that user and it's expiry date


