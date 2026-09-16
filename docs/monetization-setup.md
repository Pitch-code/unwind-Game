# Monetization setup — a beginner's walkthrough

You don't need any of this to *play or test* the game: it already runs with
Google's **test ads** and the code for the paid upgrade is finished. This is
only about turning on **real money**. Take it slowly, one part at a time.

There are two separate Google systems:

- **AdMob** — pays you for showing ads. (Free to set up.)
- **Google Play Console** — where you publish the app and sell the one-time
  "Remove Ads + themes" upgrade. (One-time $25 signup.)

Use the **same Google account** that owns your Play Console for both. Your other
Gmail can be added later as a free "test buyer".

---

## Part A — AdMob (real ads). ~10 minutes, free.

Goal: come away with **two IDs** and send them to me.

1. Go to **admob.google.com** and sign in. Accept the terms — that creates your
   AdMob account.
2. Left menu → **Apps** → **Add app**.
   - Platform: **Android**.
   - "Is the app listed on Google Play?" → **No** (not yet).
   - Name it **Unwind** → Add.
3. You now have an **App ID**. It looks like `ca-app-pub-1234567890123456~1234567890`
   (note the **`~`**). Copy it.
4. With the app selected → **Ad units** → **Add ad unit** →
   choose **Interstitial** → name it `Unwind Interstitial` → **Create**.
5. You now have an **ad unit ID**. It looks like
   `ca-app-pub-1234567890123456/9876543210` (note the **`/`**). Copy it.
6. **Send me both IDs.** That's all — I plug them in at build time (they're
   already made configurable). ⚠️ Never tap a real ad in your own app; Google
   bans accounts for it. We keep test ads until the app is live.

---

## Part B — Google Play Console (the paid upgrade). Longer.

Goal: create the app and a product with the exact ID `unwind_premium`.

### B1. Developer account (once)
- Go to **play.google.com/console**. If you've never registered, sign up and
  pay the **one-time $25** fee. (If you already published PhoneProof, you're
  done — reuse it.)

### B2. Create the app
- **Create app** → name **Unwind**, pick language, **App or game: Game**,
  **Free**, tick the declarations → Create.

### B3. Create the upgrade product
- Left menu → **Monetize → Products → In-app products** → **Create product**.
  - **Product ID: `unwind_premium`** ← must be exactly this, it's baked into
    the app. You can't change an ID later, so type it carefully.
  - Name: **Remove Ads + all garden themes**.
  - Description: e.g. "Removes all ads and unlocks every garden theme. One-time
    purchase."
  - Price: your choice, ~**$3.99**.
  - **Save**, then **Activate**.
- Note: the product can only actually be *bought* once a build of the app that
  includes billing is uploaded to a testing track (next step).

### B4. Upload a build to Internal testing
- You need a **signed release `.aab`** built with your real ad IDs. Ask me and
  I'll walk through it, or follow `docs/RELEASE.md`. In short:
  `flutter build appbundle --release` with your signing key +
  `--dart-define=ADMOB_INTERSTITIAL_ID=...` and `ADMOB_APP_ID=...`.
- In Play Console → **Testing → Internal testing** → **Create new release** →
  upload the `.aab` → add your tester emails → **Save / Roll out**.
- Copy the **opt-in link**, open it on your test phone, and install from there.

### B5. Test without paying real money
- Play Console → **Setup → License testing** → add your tester Gmail
  (e.g. `labellens.dev@gmail.com`). Those accounts see **test purchases** and
  are never charged.
- On the test phone (signed in as that tester), open the game → **Remove ads**
  → you should see Google's purchase sheet marked as a test → confirm →
  ads disappear and themes unlock. Try **Restore** too.

---

## What I've already done for you (nothing to change in code)

- The purchase uses the product ID **`unwind_premium`** — just create it with
  that exact spelling.
- Ad IDs are configurable, so you never edit code: give me the two AdMob IDs, or
  pass them at build time (`ADMOB_APP_ID` env + `--dart-define=ADMOB_INTERSTITIAL_ID`).
- Debug builds keep Google's **test** ads, so development is always safe.

## Suggested order
1. **Part A (AdMob)** — quick and free. Send me the two IDs.
2. **Part B1–B3** — Play account + create `unwind_premium`.
3. Tell me, and I'll help produce the signed release build.
4. **B4–B5** — upload, add testers, test the purchase on your phone.
