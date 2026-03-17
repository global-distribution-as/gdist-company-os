---
title: SOP — Opprett leverandørbruker i systemet
type: SOP
audience: Daniel (only) — Martin requests, Daniel executes
updated: 2026-03-16
status: GJELDENDE — gjelder inntil P0-2 er bygget (se 09_Tech/BACKLOG.md)
---

# SOP: Opprett ny leverandørbruker

> **Hvem gjør dette:** Daniel
> **Hvem ber om det:** Martin (sender en WhatsApp med: navn, e-post, firmanavn)
> **Tid det tar:** 5 minutter
> **Hvorfor Daniel:** AdminSettings invitasjonsfunksjonen er ødelagt (se BACKLOG.md P0-2). Inntil det er fikset, gjøres dette manuelt i Supabase.

---

## Hva Martin sender til Daniel

Martin sender én WhatsApp/e-post med:
```
Ny leverandør:
Navn: [FORNAVN ETTERNAVN]
E-post: [e-post@firma.no]
Firma: [FIRMANAVN]
```

---

## Daniel gjør dette (5 steg)

### Steg 1 — Inviter bruker i Supabase Auth
1. Gå til https://supabase.com → logg inn → velg prosjektet `orsjlztclkiqntxznnyo`
2. Gå til **Authentication** → **Users** → klikk **"Invite user"**
3. Skriv inn leverandørens e-postadresse → klikk **"Send invite"**
4. Supabase sender en e-post med en magic link (gyldig i 24 timer)
5. **Kopier brukerens UUID** fra Users-listen (vises etter at invitasjonen er sendt)

### Steg 2 — Tildel rolle i `user_roles`
1. Gå til **Table Editor** → velg tabellen `user_roles`
2. Klikk **"Insert row"** og fyll inn:
   - `user_id`: [UUID kopiert fra steg 1]
   - `role`: `supplier`
3. Lagre.

### Steg 3 — Opprett leverandørprofil i `suppliers`
1. Gå til **Table Editor** → velg tabellen `suppliers`
2. Klikk **"Insert row"** og fyll inn:
   - `name`: [FIRMANAVN]
   - `contact_name`: [NAVN]
   - `email`: [E-POST]
   - `user_id`: [UUID]
   - `active`: `true`
   - (Øvrige felter kan leverandøren fylle inn selv via SupplierProfile når den er ferdigbygd)
3. Lagre.

### Steg 4 — Bekreft til Martin
Send en WhatsApp til Martin:
```
Leverandørbruker opprettet for [NAVN] / [FIRMA].
Innloggingslink er sendt til [E-POST].
Linken gjelder 24 timer. Gi beskjed hvis de ikke får den.
```

### Steg 5 — Martin sender velkomst-e-post
Martin sender velkomst-e-posten fra `_Templates/leverandor-velkomst-epost.md`.

---

## Vanlige feil

**"Invitasjonen kom aldri frem"**
→ Sjekk Resend-loggen (resend.com → Emails). Ble den sendt? Ble den avvist (spam)?
→ Alternativ: reset passordet via Auth → Users → [bruker] → "Send Password Recovery"

**"Leverandøren kan ikke logge inn etter å ha klikket linken"**
→ Magic link har utløpt (>24 timer). Send passord-tilbakestilling i stedet.
→ Auth → Users → [bruker] → "Send Password Recovery"

**"Produktene vises ikke etter opplasting"**
→ Produkter har status "pending" og må godkjennes av admin.
→ Gå til AdminDashboard (https://gdist.no/admin/dashboard) → "Pending Uploads" → godkjenn.

---

## Når P0-2 er bygget
Denne SOPen erstattes av den innebygde invitasjonsfunksjonen i AdminSettings.
Martin vil da kunne gjøre dette uten å kontakte Daniel.
