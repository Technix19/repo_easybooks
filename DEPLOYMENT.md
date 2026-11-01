# EasyBooks: Flutter Web deployment without Xcode

EasyBooks is a Flutter application whose browser build can run on Vercel.
The app's Flutter source is under `repo_easybooks/`, not at the repository root.

## How it works

1. GitHub Actions installs Flutter on a Linux runner, runs unit tests, and executes
   `flutter build web --release --base-href "/"` from `repo_easybooks/`.
2. The compiled files are uploaded as a GitHub Actions artifact.
3. When you manually approve a production deployment, a second GitHub Actions
   job downloads the same artifact, wraps it in Vercel Build Output API v3, and
   runs `vercel deploy --prebuilt --prod`.
4. Supabase hosts the database and email authentication. Vercel hosts **only the
   web frontend**. No Xcode or local iOS build is involved.

This workflow intentionally does **not** auto-publish pull requests or pushes
to `main`: a financial app should first pass authentication and RLS checks.

## 1. Verify the Flutter Web build in GitHub

Open **GitHub → Actions → Flutter Web CI and Vercel Deployment**.
The workflow runs automatically when you open a PR or push to `main`.

Check that **Test and build Flutter Web** succeeds and has an
`easybooks-flutter-web` downloadable artifact. This stage doesn't need Vercel
credentials.

For a local browser test if Flutter is already installed:

```bash
cd repo_easybooks
flutter pub get
flutter test
flutter build web --release --base-href "/"
```

The output is `repo_easybooks/build/web`.

## 2. Create or link a Vercel project

Use a Vercel project with the **Other** framework preset, intended for a
prebuilt static site. **Do not rely on a Vercel-side Flutter build**. This
repository's workflow handles compilation on GitHub's Ubuntu runner.

You can create/link a Vercel project through the Vercel CLI using a small
empty working directory (no Flutter or Xcode required):

```bash
npm install --global vercel
mkdir easybooks-vercel-link
cd easybooks-vercel-link
vercel login
vercel link
```

Select/create the Vercel project you want to deploy. Read the two IDs from
`.vercel/project.json`: `orgId` and `projectId`.

If you already have a Vercel project, choose it during `vercel link`.
Do not paste the personal access token into GitHub source files.

## 3. Configure GitHub Actions secrets

In the **repo_easybooks** GitHub repository, open **Settings → Secrets and
variables → Actions → New repository secret** and create:

| Secret | Value |
|---|---|
| `VERCEL_TOKEN` | Your Vercel personal access token (create from Vercel Account Settings → Tokens) |
| `VERCEL_ORG_ID` | `orgId` from `.vercel/project.json` |
| `VERCEL_PROJECT_ID` | `projectId` from `.vercel/project.json` |

The workflow will check these values before attempting a deployment.
GitHub Actions secrets are not committed to the repo.

**Important:** If you import the GitHub repo directly using Vercel Git
Integration, disable its automatic Vercel builds for this project so the
GitHub Actions prebuilt deploy pipeline remains the single source of truth.

## 4. Configure Supabase login redirects

Your Supabase project is `keprvxiclcxdvasdxpey` ("EasyBooks Web App").
Open **Supabase → Authentication → URL Configuration**.

After a preview or production domain is known, allow the URLs that the
Flutter code actually generates, such as:

- `https://YOUR-PROJECT.vercel.app/#/` (magic-link login)
- `https://YOUR-PROJECT.vercel.app/#/login` (email-confirmation redirect)

Supabase also needs the site origin. Configure the **Site URL** to the
production deployment origin when you are ready.

These must use your real Vercel domain, not `YOUR-PROJECT`.
Test both sign-in and new-user verification from a fresh browser session.

## 5. Verify financial data isolation

Before production, use two test accounts to confirm:

- Account A cannot view, update, or delete Account B's income, expenses,
  or profile.
- Daily graph/RPC totals include only the signed-in account's rows.
- Newly created income and expense rows receive the correct `user_id`.
- CSV export downloads only the signed-in user's records.
- Magic-link and signup redirects correctly return to EasyBooks.
- Desktop and mobile layout does not overflow.

Live table policies already use `user_id = auth.uid()`, but the isolation
and functional checks still need two real authenticated test sessions.
The app is intended for browser use; **not** a native iOS binary.

Security warnings seen in the current Supabase project include mutable
function `search_path` settings, GraphQL schema visibility, and disabled
leaked-password protection. Review these warnings separately in Supabase
Security Advisors before broad public release.

## 6. Deploy manually to Vercel production

Once the PR is merged, the build is green, credentials exist, and the
security checks pass:

1. Open **GitHub → Actions → Flutter Web CI and Vercel Deployment**.
2. Select **Run workflow** on the `main` branch.
3. Enable **deploy_production** and run it.
4. Review the deployment URL from the Vercel deploy step.

This upload uses the compiled web artifact in `.vercel/output/static` and
a minimal Build Output API configuration. It never attempts to build iOS.

## Useful links

- [Flutter Web deployment](https://docs.flutter.dev/deployment/web)
- [subosito/flutter-action](https://github.com/subosito/flutter-action)
- [Vercel Build Output API](https://vercel.com/docs/build-output-api)
- [Vercel CLI prebuilt deployments](https://vercel.com/docs/cli/deploy)
- [Supabase auth redirect URLs](https://supabase.com/docs/guides/auth/redirect-urls)
- [Supabase Row Level Security](https://supabase.com/docs/guides/database/postgres/row-level-security)
