<div align="center">

# Faculty Website — KT · CNTT · VHNT

**Official website of the Faculty** — news, announcements, admissions and department introductions.

[![WordPress](https://img.shields.io/badge/WordPress-latest-21759B?logo=wordpress&logoColor=white)](https://wordpress.org/)
[![PHP](https://img.shields.io/badge/PHP-8.5-777BB4?logo=php&logoColor=white)](#)
[![OpenLiteSpeed](https://img.shields.io/badge/OpenLiteSpeed-LSWS-0F91C4)](#)
[![Caddy](https://img.shields.io/badge/Caddy-2-1F88C0?logo=caddy&logoColor=white)](https://caddyserver.com/)
[![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?logo=docker&logoColor=white)](https://docs.docker.com/compose/)
[![MariaDB](https://img.shields.io/badge/MariaDB-latest-003545?logo=mariadb&logoColor=white)](https://mariadb.org/)
[![Redis](https://img.shields.io/badge/Redis-latest-DC382D?logo=redis&logoColor=white)](https://redis.io/)
[![License](https://img.shields.io/badge/license-GPL--3.0-blue)](LICENSE)

**English** · [Tiếng Việt](README.vi.md)

</div>

---

## Screenshots

| Home | Article detail |
|:--:|:--:|
| ![Home](screenshots/trangchu.jpg) | ![Article detail](screenshots/single-page.jpg) |

| News archive | Login | Loading screen |
|:--:|:--:|:--:|
| ![Archive](screenshots/archive.jpg) | ![Login](screenshots/login.jpg) | ![Loading](screenshots/loading-custom.jpg) |

---

## Overview

- News and announcement portal for the Faculty.
- Clean, responsive interface on phones and desktops.
- Admin dashboard to publish, edit and delete articles.
- The entire stack runs on Docker Compose — rebuild the whole environment with one command.

---

## Features

- Home page, news categories, announcements and admissions pages.
- Article detail page with search.
- Media block, class timetable, partner logos and view counters.
- Dedicated admin login (WordPress admin).
- Automatic HTTPS (Caddy issues and renews Let's Encrypt certificates).
- zstd / gzip compression at the proxy layer, object caching via Redis.

---

## Architecture

```text
            ┌──────────────┐   80 / 443    ┌─────────────────────────┐
  Internet ─┤    Caddy     ├──────────────►│  wordpress (OLS + PHP)  │
            │  reverse     │               │  OpenLiteSpeed + LSPHP  │
            │  proxy + TLS │               └───────┬─────────┬───────┘
            └──────────────┘                       │         │
                                              ┌────▼───┐ ┌───▼────┐
                                              │MariaDB │ │ Redis  │
                                              └────────┘ └────────┘
```

| Service | Image / Build | Role | Ports |
|:--|:--|:--|:--|
| `caddy` | `caddy:latest` | Reverse proxy, automatic HTTPS, compression, security headers | `80`, `443` |
| `wordpress` | built from `Dockerfile` | OpenLiteSpeed + LSPHP 8.5 running WordPress | internal `80` |
| `db` | `mariadb:latest` | Database | internal `3306` |
| `redis` | `redis:latest` | Object cache (64 MB, `allkeys-lru`, no disk persistence) | internal `6379` |

Only **Caddy** publishes ports to the host. The database and Redis are reachable only on the internal Docker network.

---

## Repository Structure

```text
.
├── Caddyfile             # Reverse proxy + HTTPS + security headers
├── docker-compose.yml    # db / redis / wordpress / caddy
├── Dockerfile            # OpenLiteSpeed + LSPHP 8.5 + PHP extensions
├── ols-entrypoint.sh     # Fix permissions, generate env file for PHP, then run the original entrypoint
├── uploads.ini           # Upload limits, memory, opcache
├── .env.example          # Environment template (copy to .env)
├── LICENSE               # GNU General Public License v3.0
├── wordpress/            # WordPress source (bind mount); only wp-config.php is committed
│   └── wp-config.php     # Reads configuration from environment variables
├── screenshots/          # Demo screenshots
└── data/                 # Runtime data: mysql, caddy certs (not committed)
```

---

## Requirements

- **Docker Engine** 24+ and **Docker Compose v2** (use the `docker compose` command, not `docker-compose`)
- A **domain name pointing to the server IP** (A / AAAA record) — required for Caddy to obtain an HTTPS certificate. Caddy must be reachable on ports `80` and `443` from the internet.
- Server: **1 vCPU / 1 GB RAM / 10 GB disk** recommended as a minimum
- `sudo` access (or membership of the `docker` group) to run containers

> Running locally? Use a `*.localhost` domain or configure Caddy to use internal certificates (see *Running Locally*).

---

## Installation

### 1. Clone and configure environment variables

```bash
git clone https://github.com/Namtran592005/WebKhoa.git
cd WebKhoa
cp .env.example .env
```

Open `.env` and replace **every** `change-me` value:

```dotenv
DB_NAME=wordpress
DB_USER=wordpress
DB_PASSWORD=<strong-password>
DB_ROOT_PASSWORD=<different-strong-root-password>
REDIS_PASSWORD=<strong-redis-password>
SITE_DOMAIN=khoa.example.edu.vn
```

Generate random passwords:

```bash
openssl rand -base64 32
```

> ⚠️ `.env` holds secrets and **must not be committed**. The bundled `.gitignore` already excludes it.

### 2. Prepare the WordPress directory

The repository only commits `wordpress/wp-config.php`. The WordPress core (`wp-admin/`, `wp-includes/`, ...) is **not tracked in Git** to keep the repository small. On a fresh clone the directory is therefore empty, and WordPress will fail with a missing `wp-load.php` error.

Pick one of the two options:

**Option A — Download the WordPress core (recommended for the latest release)**

```bash
docker compose build
docker compose run --rm --entrypoint sh wordpress -c \
  "cd /var/www/vhosts/localhost/html && \
   tar -xzf <(curl -fsSL https://wordpress.org/latest.tar.gz) --strip-components=1 && \
   ls wp-settings.php"
```

**Option B — Copy an existing WordPress installation**

Copy an entire WordPress directory into `wordpress/`, keeping the repository's `wp-config.php` (do not overwrite it).

### 3. Start the stack

```bash
docker compose up -d --build
docker compose ps
```

Check the logs to confirm Caddy obtained the certificate:

```bash
docker compose logs -f caddy
```

HTTPS is ready once you see a `certificate obtained successfully` message.

---

## First Run

Open `https://<SITE_DOMAIN>` in a browser. Because the database is empty, WordPress shows the **5-step installer**:

1. Choose a language (Vietnamese or English)
2. Fill in **Site Title**, **Username**, **Password** and **admin Email**
3. Click **Install WordPress**

You do **not** need to enter database details — `wp-config.php` reads them from environment variables.

Note: `DB_PASSWORD` / `DB_ROOT_PASSWORD` / `REDIS_PASSWORD` in `.env` are **container** credentials and are completely separate from the **WordPress** admin password you set in this step.

Log in to the admin panel at: `https://<SITE_DOMAIN>/wp-admin`

---

## WordPress Configuration After Install

`docker-compose.yml` injects the following constants through `WORDPRESS_CONFIG_EXTRA` (no manual editing needed):

| Constant | Value |
|:--|:--|
| `WP_HOME` / `WP_SITEURL` | `https://${SITE_DOMAIN}` |
| `FORCE_SSL_ADMIN` | `true` |
| `FS_METHOD` | `direct` (allows direct plugin/theme updates) |

In addition, `wp-config.php` detects the `X-Forwarded-Proto: https` header from Caddy so WordPress does not enter a redirect loop.

To enable Redis object caching: install the **Redis Object Cache** (or **LiteSpeed Cache**) plugin and point it to host `redis`, port `6379`, password `REDIS_PASSWORD`. The Redis container has persistence disabled, so it is cache-only; losing its data on restart is expected.

---

## Operations Notes

### Directory permissions

`ols-entrypoint.sh` runs `chmod -R 777` on the WordPress directory at **every container start**, so files created by the host bind mount do not cause write failures (uploads, plugins, cache). This is convenient for demo / learning environments but is **not a security best practice**. Before running in real production, replace it with a dedicated UID/GID for the web server.

### Passing environment variables to PHP

LSPHP does not inherit Docker environment variables, so the entrypoint generates `/usr/local/lsws/conf/wp-env.php` containing `putenv()` calls and loads it automatically through `auto_prepend_file`. This lets `wp-config.php` read the `WORDPRESS_*` variables exactly like the official `wordpress` image.

### Upload limits

`uploads.ini` sets `upload_max_filesize` / `post_max_size` to **400 MB**, `memory_limit` to **512 MB**, `max_execution_time` to **300 s**, and enables opcache with 10,000 files. For larger uploads, edit this file and run `docker compose up -d` again.

### Salts and secrets

`wordpress/wp-config.php` defaults all salts (`AUTH_KEY`, `NONCE_KEY`, ...) to `change-me`. Override them by adding `WORDPRESS_AUTH_KEY`, `WORDPRESS_NONCE_SALT`, ... to `.env`. Generate fresh values with:

```bash
curl -fsSL https://api.wordpress.org/secret-key/1.1/salt/
```

### Backup

All data lives under `data/` (not committed):

| Path | Contents |
|:--|:--|
| `data/mysql/` | MariaDB database |
| `data/caddy/` | Caddy certificates and state |
| `wordpress/wp-content/uploads/` | Images and media files |

Back these up regularly. Example database dump:

```bash
docker compose exec db sh -c 'exec mariadb-dump -uroot -p"$MARIADB_ROOT_PASSWORD" "$MARIADB_DATABASE"' > backup-$(date +%F).sql
```

---

## Common Commands

Run all commands from the repository root. On Linux, prefix `docker` with `sudo` if you hit a *permission denied* error.

```bash
docker compose up -d --build       # rebuild images and start in the background
docker compose ps                  # show service status
docker compose logs -f wordpress   # follow WordPress logs
docker compose logs -f caddy       # follow HTTPS / certificate logs
docker compose restart caddy       # reload Caddyfile (after editing it)
docker compose down                # stop and remove containers (keeps data)
docker compose down -v             # stop and remove anonymous volumes too
rm -rf data/                       # DELETE ALL DATA — use with care
```

Run WP-CLI:

```bash
docker compose run --rm -u www-data wordpress \
  -c "cd /var/www/vhosts/localhost/html && php wp-cli.phar plugin list"
```

---

## Running Locally

Caddy cannot issue a valid certificate for a domain that does not actually resolve to your machine. To test on your own computer:

1. Add an entry to your `hosts` file (`/etc/hosts` or `C:\Windows\System32\drivers\etc\hosts`):
   ```text
   127.0.0.1 khoa.localhost
   ```
2. Set `SITE_DOMAIN=khoa.localhost` in `.env`
3. Temporarily change the top of `Caddyfile` to:
   ```caddyfile
   {
       local_certs
   }

   khoa.localhost {
       reverse_proxy wordpress:80 { ... }
   }
   ```
4. `docker compose up -d --build`, then open `https://khoa.localhost`
   (Caddy installs its local CA; the browser may warn about the certificate the first time)

You can also browse over plain HTTP at `http://localhost:80`.

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|:--|:--|:--|
| `Error establishing a database connection` | Wrong password in `.env`, or the database has not finished starting | `docker compose logs db`; wait or run `docker compose restart wordpress` |
| Blank page / `Unable to open ... wp-load.php` | WordPress core missing from `wordpress/` | See **Step 2** of Installation |
| Caddy keeps logging `tls: ... no such host` | DNS does not point to the server, or ports 80/443 are blocked | Check `dig <SITE_DOMAIN>` and your firewall |
| Redirect loop to `/wp-admin/install.php` | Missing `X-Forwarded-Proto`, or wrong `WP_HOME` / `WP_SITEURL` | Verify `SITE_DOMAIN` in `.env`, then restart `wordpress` |
| Image upload fails with *file too large* | PHP / proxy limits | Raise the values in `uploads.ini`, then `docker compose up -d` |
| Cannot install plugins, FTP prompt shown | `FS_METHOD` not set | Check `WORDPRESS_CONFIG_EXTRA` in `docker-compose.yml` |
| Permission error when writing files | Bind mount owned by host `root` | `ols-entrypoint.sh` already chmods 777; if it still fails, `sudo chown -R 1000:1000 wordpress/` |

View all logs: `docker compose logs --tail=200`

---

## Security — Before Going to Production

- [ ] Replace **every** `change-me` value in `.env` with strong, random passwords
- [ ] Regenerate all WordPress salts (`AUTH_KEY`, `NONCE_KEY`, ...)
- [ ] Replace `chmod -R 777` in `ols-entrypoint.sh` with a proper UID/GID
- [ ] Keep `WORDPRESS_DEBUG=0` (disabled by default)
- [ ] Restrict access to `/wp-admin` (IP allowlist or Basic Auth at Caddy)
- [ ] Enable a firewall that only allows `22`, `80`, `443`
- [ ] Set up automated backups and **test a restore**
- [ ] Keep images up to date: `docker compose pull && docker compose up -d --build`

---

## License

This project is licensed under the [GNU General Public License v3.0](LICENSE) (GPL-3.0).

Copyright © 2026 Faculty of KT — CNTT — VHNT.

WordPress, OpenLiteSpeed, Caddy, MariaDB, Redis, and other third-party components remain under their own upstream licenses.
