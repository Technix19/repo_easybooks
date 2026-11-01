# Password login for EasyBooks

EasyBooks uses **email + password** for regular sign-ins via Supabase Auth.
This avoids sending a magic-link email each time someone logs in.

## Current behavior

- **Log in:** Enter email and password. No email is sent.
- **Sign up:** Choose a password (at least 8 characters); Supabase may send **one confirmation email**, depending on your project's email-confirmation settings.
- **Forgot password:** Sends an email **only when requested**. The user clicks the recovery link, enters a new password, and signs in again.
- **Previously registered users:** Existing signups already provided passwords; use that original password. If forgotten, use **Forgot password** once. Existing accounts and financial records are not recreated or migrated.

## One-time Supabase redirect configuration

Open the [EasyBooks Supabase Authentication URL Configuration](https://supabase.com/dashboard/project/keprvxiclcxdvasdxpey/auth/url-configuration).

Add the actual deployment host followed by **`/?recovery=1`** to **Redirect URLs**.
For the currently verified deployment:

```
https://easybooks-i78mkfxum-codely4.vercel.app/?recovery=1
```

If you use a different or new preview URL, add that host's exact URL too.
Keep existing sign-up confirmation redirects (such as `/#/login`) allowed.
Do not remove existing URLs used by other app installations.
Do not change the production Site URL merely for this test.

The app intentionally uses a query marker instead of a hash-route marker:
Supabase can place recovery session tokens in the URL fragment, and Flutter
recognizes the recovery marker, consumes the session, removes URL tokens,
then opens `/#/reset-password`.

If a reset link is expired or already used, return to the login screen and
request a fresh one. **Password resets still use Supabase's outbound email
quota.** Daily use shouldn't.

## Verify in the browser

1. Create a test account and verify its email once if confirmation is enabled.
2. Log out and sign in with the original email/password; **no mail** should arrive.
3. Refresh the website while logged in, and check session persistence.
4. Use **Forgot password** once. Confirm you can open its link and set a new password.
5. Check the old password fails and the new password works.
6. Verify the app still displays the same financial records for the signed-in user.
7. Repeat with a second account to confirm RLS data isolation.

## Security and limitations

- Passwords are sent to Supabase Auth over HTTPS for verification and are
  never stored in EasyBooks' application tables or committed to GitHub.
- Keep email confirmation enabled if you depend on verified email ownership.
  Disabling it isn't necessary to reduce login email volume.
- Consider setting the minimum password length to 8+ in the Supabase Email
  provider settings. The client validates length, and the server should
  enforce an appropriate policy independently.
- Supabase free-plan email rate limits may still affect new-account
  confirmations and password resets; consider a custom SMTP service if the
  volume grows.
- Existing project security advisories and account-isolation checks still
  need to be resolved before wide public release.

## Source files

- `repo_easybooks/lib/login_page.dart` — password login form
- `repo_easybooks/lib/auth/auth_service.dart` — Supabase auth methods
- `repo_easybooks/lib/signup_page.dart` — registration validation
- `repo_easybooks/lib/forgot_pass.dart` — reset email request
- `repo_easybooks/lib/reset_password_page.dart` — new password form
- `repo_easybooks/lib/main.dart` — recovery callback routing
