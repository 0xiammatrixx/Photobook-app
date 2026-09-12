Good news first: the backend **has now added ID-token verification** — this error is coming from `google-auth-library`, which means the verify step is running. What's left is a one-line audience mismatch.

## The problem

Your ID token's `aud` (audience) claim is the **iOS client ID**, but the backend is checking against the **web client ID**.

- Token `aud` = `841792367578-t91482k7so8d5tac3qot43es2cumab47` (your iOS client)
- Backend `audience` = `841792367578-3dnk4at4nbm0pvtpeh0aakeqlefcm8ba` (your web client)

On iOS, native Google Sign-In issues the ID token against the **iOS client** (`GIDClientID`); on Android it's the **web client** (`serverClientId`). So a single `audience` string can't match both.

## The fix (tell the backend dev)

Pass an **array** of accepted audiences instead of one string:

```js
const ticket = await client.verifyIdToken({
  idToken: req.body.idToken,
  audience: [
    process.env.GOOGLE_CLIENT_ID,      // web (serverClientId) — Android
    process.env.GOOGLE_IOS_CLIENT_ID,  // iOS GIDClientID
  ],
});
```

And add to his env:

```
GOOGLE_CLIENT_ID=841792367578-3dnk4at4nbm0pvtpeh0aakeqlefcm8ba.apps.googleusercontent.com
GOOGLE_IOS_CLIENT_ID=841792367578-t91482k7so8d5tac3qot43es2cumab47.apps.googleusercontent.com
```

`verifyIdToken` accepts an array, and the token passes if its `aud` matches **any** entry — so iOS hits the second one and Android hits the first.

(If he later adds a dedicated Android OAuth client, add that client ID to the array too.)

No app change needed — you're already sending the correct token; it's purely the backend's `audience` being too strict.