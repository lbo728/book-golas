# Remote fixture reset transcript

host=byungsker-mackbook.tail990faf.ts.net
transport=Tailscale SSH
project=book-golas-414-remote
ports=55321,55322,55323,55324,55327,55329

$ supabase --version
2.109.1

$ docker info --format ...
ServerVersion=29.7.2 OSType=linux Architecture=aarch64

$ supabase status --output env (redacted URL fields only)
API_URL="http://127.0.0.1:55321"
DB_URL="postgresql://postgres:postgres@127.0.0.1:55322/postgres"
INBUCKET_URL="http://127.0.0.1:55324"
STUDIO_URL="http://127.0.0.1:55323"

$ npm run reset:fixtures
reset_exit=0
Resetting local database...
Recreating database...
Seeding data from web/fixtures/supabase/seed.sql...
Restarting containers...
Finished supabase db reset on branch codex/feature/web/1.1.0/BOK-414-browser-fixtures.
local Supabase fixtures reset and uploaded: 2 users, 2 books, 2 images

$ Storage API object verification
user-a: book-a.png
user-b: book-b.png
