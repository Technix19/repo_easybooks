# EasyBooks — Xcode-free Flutter Web preview on Vercel

EasyBooks builds on GitHub Actions (Ubuntu, no Xcode). Vercel hosts **only**
the compiled Flutter Web files. The Flutter application lives in
`repo_easybooks/` inside this GitHub repository.

## Current status

- GitHub Actions has already **successfully built Flutter Web**.
- Vercel project **easybooks** exists in the **Codely** team:
  https://vercel.com/codely4/easybooks
- The Vercel project is intentionally **not Git-connected**. GitHub Actions
  builds Flutter first, then uploads a prebuilt site to Vercel.
- GitHub Actions deploys a **preview only**, with an explicit checkbox.
  No production deployment is configured until authentication and data
  isolation have been verified.

## Step 1. Create a Vercel token

1. Sign in to Vercel: https://vercel.com/account/tokens
2. Generate a personal access token with access to the **Codely** team.
3. Open https://github.com/Technix19/repo_easybooks/settings/secrets/actions
4. Add a **repository secret** named `VERCEL_TOKEN`. Paste its value
   directly into the GitHub form. **Never paste the token in chat or commit it.**

Vercel team/project IDs are non-secret identifiers and are already configured
in `.github/workflows/flutter-web.yml`:

- `VERCEL_ORG_ID=team_Vh6aHxefF7vYCxIl0brubyDU`
- `VERCEL_PROJECT_ID=prj_8w6vIiQaubQXbbgsSs2WusQF3Rzn`

You **do not need** to add these two IDs as GitHub secrets.

## Step 2. Run the preview

After merging the PR that contains the preview workflow:

1. Visit https://github.com/Technix19/repo_easybooks/actions
2. Open **Flutter Web CI and Vercel Deployment**.
3. Select **Run workflow**.
4. Select the `main` branch and check **deploy_preview**.
5. Start the workflow. It installs Flutter, runs tests, compiles the app
   and deploys the **same tested artifact** to Vercel.
6. Find the new preview URL in the **Deploy prebuilt Flutter Web preview
   to Vercel** job summary.

The job runs only as a manual workflow on `main`. Pull requests and normal
pushes run Flutter tests/build without Vercel authentication or deployment.

A preview might be protected by Vercel Authentication; sign in to your
authorized Vercel account to access it. Do not disable that protection
just to get a public screenshot.

## Step 3. Configure Supabase URLs for testing

Supabase project: `keprvxiclcxdvasdxpey` ("EasyBooks Web App").

Open https://supabase.com/dashboard/project/keprvxiclcxdvasdxpey/auth/url-configuration

Add the **actual preview deployment's URL** to Supabase Auth's redirect
allow list. The app's login and signup flows generate hash-based paths:

- `https://YOUR-ACTUAL-PREVIEW.vercel.app/#/` (magic-link login)
- `https://YOUR-ACTUAL-PREVIEW.vercel.app/#/login` (signup email confirmation)

Keep existing URLs in place so other app installations are not disrupted.
Do not change the production Site URL until the production domain is known
and verified. Preview URLs can change between builds; add the new exact URL
when running a fresh login test.

## Step 4. Test the real browser app

1. Visit the preview with a desktop browser.
2. Sign up or sign in and confirm the email redirect lands on EasyBooks.
3. Test login/logout and returning to the app after refreshing the page.
4. Create income and expense entries and inspect charts and tax reports.
5. Download a CSV and confirm its rows match the signed-in user's data.
6. Test both desktop and narrow/mobile viewport widths.
7. Use **two distinct test accounts**, A and B. Confirm that account A
   cannot view, modify, delete, or export B's financial records, and
   vice versa. Verify aggregation RPCs don't mix accounts.

A read-only audit found live RLS enabled on `income`, `expense`,
and `profile`, with ownership checks `user_id = auth.uid()`.
Both daily aggregate RPCs run with invoker permissions. These are good
initial checks, but they do not replace a two-account browser test.

Supabase Security Advisors also flagged:
- Mutable search paths on two reporting RPCs.
- Some objects visible in the GraphQL schema.
- Leaked-password protection disabled.

Review those findings before wider public release.

## Production deployment

Not configured yet. Keep the preview behind Vercel Authentication and
review functional/security tests first. Production can be added as
a separate manually approved GitHub Actions job after the preview
has passed review.

## Technical references

- [Flutter Web deployment](https://docs.flutter.dev/deployment/web)
- [Vercel Build Output API](https://vercel.com/docs/build-output-api)
- [Prebuilt Vercel deployment](https://vercel.com/docs/cli/deploy)
- [Supabase redirect URLs](https://supabase.com/docs/guides/auth/redirect-urls)
