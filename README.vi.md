<div align="center">

# Website Khoa KT — CNTT — VHNT

**Website thông tin của Khoa** — tin tức, thông báo, tuyển sinh và giới thiệu bộ môn.

[![WordPress](https://img.shields.io/badge/WordPress-latest-21759B?logo=wordpress&logoColor=white)](https://wordpress.org/)
[![PHP](https://img.shields.io/badge/PHP-8.5-777BB4?logo=php&logoColor=white)](#)
[![OpenLiteSpeed](https://img.shields.io/badge/OpenLiteSpeed-LSWS-0F91C4)](#)
[![Caddy](https://img.shields.io/badge/Caddy-2-1F88C0?logo=caddy&logoColor=white)](https://caddyserver.com/)
[![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?logo=docker&logoColor=white)](https://docs.docker.com/compose/)
[![MariaDB](https://img.shields.io/badge/MariaDB-latest-003545?logo=mariadb&logoColor=white)](https://mariadb.org/)
[![Redis](https://img.shields.io/badge/Redis-latest-DC382D?logo=redis&logoColor=white)](https://redis.io/)

[English](README.md) · **Tiếng Việt**

</div>

---

## Ảnh demo

| Trang chủ | Chi tiết bài viết |
|:--:|:--:|
| ![Trang chủ](screenshots/trangchu.jpg) | ![Chi tiết bài viết](screenshots/single-page.jpg) |

| Danh sách tin | Đăng nhập | Màn hình chờ |
|:--:|:--:|:--:|
| ![Danh sách tin](screenshots/archive.jpg) | ![Đăng nhập](screenshots/login.jpg) | ![Loading](screenshots/loading-custom.jpg) |

---

## Giới thiệu

- Cổng thông tin tin tức, thông báo của Khoa.
- Giao diện đơn giản, responsive trên điện thoại và máy tính.
- Có trang quản trị để đăng / sửa / xóa bài viết.
- Toàn bộ hạ tầng chạy bằng Docker Compose: dựng lại môi trường chỉ với 1 lệnh.

---

## Tính năng

- Trang chủ, chuyên mục tin tức, thông báo, tuyển sinh.
- Trang chi tiết bài viết kèm tìm kiếm.
- Khối Media, thời khóa biểu, đối tác và thống kê lượt xem.
- Trang đăng nhập quản trị riêng (WordPress admin).
- HTTPS tự động (Caddy cấp và gia hạn chứng chỉ Let's Encrypt).
- Nén zstd / gzip ở tầng proxy, cache object qua Redis.

---

## Kiến trúc

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

| Service | Image / Build | Vai trò | Cổng |
|:--|:--|:--|:--|
| `caddy` | `caddy:latest` | Reverse proxy, tự động HTTPS, nén, security headers | `80`, `443` |
| `wordpress` | build từ `Dockerfile` | OpenLiteSpeed + LSPHP 8.5, chạy WordPress | nội bộ `80` |
| `db` | `mariadb:latest` | Cơ sở dữ liệu | nội bộ `3306` |
| `redis` | `redis:latest` | Object cache (64 MB, `allkeys-lru`, không lưu xuống đĩa) | nội bộ `6379` |

Chỉ **Caddy** được publish cổng ra ngoài. DB và Redis chỉ truy cập trong mạng Docker nội bộ.

---

## Cấu trúc repo

```text
.
├── Caddyfile             # Cấu hình reverse proxy + HTTPS + security headers
├── docker-compose.yml    # db / redis / wordpress / caddy
├── Dockerfile            # OpenLiteSpeed + LSPHP 8.5 + extension PHP
├── ols-entrypoint.sh     # Fix quyền + sinh file env cho PHP, rồi gọi entrypoint gốc
├── uploads.ini           # Giới hạn upload, memory, opcache
├── .env.example          # Mẫu biến môi trường (copy thành .env)
├── wordpress/            # Source WordPress (bind mount), chỉ commit wp-config.php
│   └── wp-config.php     # Đọc cấu hình từ biến môi trường
├── screenshots/          # Ảnh demo
└── data/                 # Dữ liệu runtime: mysql, caddy certs (không commit)
```

---

## Yêu cầu

- **Docker Engine** 24+ và **Docker Compose v2** (dùng lệnh `docker compose`, không phải `docker-compose`)
- Một **tên miền trỏ về IP server** (bản ghi A / AAAA) — cần cho Caddy lấy chứng chỉ HTTPS. Caddy phải truy cập được cổng `80` và `443` từ Internet.
- Server: khuyến nghị tối thiểu **1 vCPU / 1 GB RAM / 10 GB ổ đĩa**
- Có quyền `sudo` (hoặc thuộc group `docker`) để chạy container

> Chạy trên máy local? Dùng một domain dạng `*.localhost` hoặc cấu hình Caddy dùng certificate nội bộ (xem phần *Chạy local*).

---

## Cài đặt

### 1. Clone và cấu hình biến môi trường

```bash
git clone https://github.com/Namtran592005/WebKhoa.git
cd WebKhoa
cp .env.example .env
```

Mở `.env` và thay **toàn bộ** giá trị `change-me`:

```dotenv
DB_NAME=wordpress
DB_USER=wordpress
DB_PASSWORD=<mật-khẩu-mạnh>
DB_ROOT_PASSWORD=<mật-khẩu-root-mạnh-khác>
REDIS_PASSWORD=<mật-khẩu-redis-mạnh>
SITE_DOMAIN=khoa.example.edu.vn
```

Tạo mật khẩu ngẫu nhiên:

```bash
openssl rand -base64 32
```

> ⚠️ `.env` chứa mật khẩu nên **không được commit**. Repo đã có `.gitignore` chặn file này.

### 2. Chuẩn bị thư mục WordPress

Repo chỉ commit `wordpress/wp-config.php`, còn phần lõi WordPress (`wp-admin/`, `wp-includes/`, ...) **không nằm trong Git** để giữ repo gọn. Vì vậy, lần chạy đầu tiên WordPress sẽ trống hoàn toàn và báo lỗi thiếu `wp-load.php`.

Chọn một trong hai cách:

**Cách A — Tự tải WordPress core (khuyến nghị cho bản mới)**

```bash
docker compose build
docker compose run --rm --entrypoint sh wordpress -c \
  "cd /var/www/vhosts/localhost/html && \
   tar -xzf <(curl -fsSL https://wordpress.org/latest.tar.gz) --strip-components=1 && \
   ls wp-settings.php"
```

**Cách B — Chép source từ một WordPress sẵn có**

Chép toàn bộ thư mục WordPress vào `wordpress/`, giữ lại `wp-config.php` của repo (đừng ghi đè).

### 3. Khởi động

```bash
docker compose up -d --build
docker compose ps
```

Xem log để chắc chắn Caddy đã cấp chứng chỉ thành công:

```bash
docker compose logs -f caddy
```

Khi thấy dòng có `certificate obtained successfully` là HTTPS đã sẵn sàng.

---

## Lần chạy đầu tiên

Mở `https://<SITE_DOMAIN>` trên trình duyệt. Vì database trống, WordPress sẽ hiện **trình cài đặt 5 bước**:

1. Chọn ngôn ngữ (Tiếng Việt hoặc English)
2. Điền **Tên trang**, **Tên người dùng**, **Mật khẩu**, **Email admin**
3. Bấm **Install WordPress**

Thông tin kết nối database **không cần nhập** — `wp-config.php` đã đọc từ biến môi trường.

Lưu ý: mật khẩu `DB_PASSWORD` / `DB_ROOT_PASSWORD` / `REDIS_PASSWORD` trong `.env` là cho **container**, khác hoàn toàn với mật khẩu admin **WordPress** bạn đặt ở bước này.

Đăng nhập quản trị tại: `https://<SITE_DOMAIN>/wp-admin`

---

## Cấu hình WordPress sau khi cài

`docker-compose.yml` tự bơm các hằng số sau qua `WORDPRESS_CONFIG_EXTRA` (không cần sửa tay):

| Hằng số | Giá trị |
|:--|:--|
| `WP_HOME` / `WP_SITEURL` | `https://${SITE_DOMAIN}` |
| `FORCE_SSL_ADMIN` | `true` |
| `FS_METHOD` | `direct` (cho phép cập nhật plugin/theme trực tiếp) |

Ngoài ra `wp-config.php` tự nhận diện `X-Forwarded-Proto: https` từ Caddy để WordPress không bị redirect loop.

Muốn bật object cache Redis: cài plugin **Redis Object Cache** (hoặc **LiteSpeed Cache**), trỏ tới host `redis`, cổng `6379`, mật khẩu `REDIS_PASSWORD`. Container Redis đã tắt persistence nên chỉ dùng để cache, dữ liệu mất khi restart là bình thường.

---

## Ghi chú vận hành

### Quyền thư mục

`ols-entrypoint.sh` chạy `chmod -R 777` lên thư mục WordPress ở **mỗi lần container khởi động**, để bind mount từ host không bị lỗi ghi file (uploads, plugin, cache). Cách này tiện cho môi trường demo / học tập nhưng **không phải best practice bảo mật**. Trước khi chạy production thật, nên thay bằng một UID/GID cụ thể dành riêng cho web server.

### Truyền biến môi trường vào PHP

LSPHP không tự nhận biến từ Docker, nên entrypoint sinh ra file `/usr/local/lsws/conf/wp-env.php` chứa các lệnh `putenv()` và nạp tự động qua `auto_prepend_file`. Nhờ vậy `wp-config.php` đọc được `WORDPRESS_*` giống image `wordpress` chính chủ.

### Giới hạn upload

`uploads.ini` đặt `upload_max_filesize` / `post_max_size` = **400 MB**, `memory_limit` = **512 MB**, `max_execution_time` = **300 s**, opcache bật với 10.000 file. Nếu cần upload file lớn hơn, sửa file này và chạy lại `docker compose up -d`.

### Mã hoá / khoá bí mật

`wordpress/wp-config.php` để mặc định các salt (`AUTH_KEY`, `NONCE_KEY`, ...) là `change-me`. Có thể ghi đè bằng cách thêm `WORDPRESS_AUTH_KEY`, `WORDPRESS_NONCE_SALT`... vào `.env`. Sinh bằng:

```bash
curl -fsSL https://api.wordpress.org/secret-key/1.1/salt/
```

### Backup

Toàn bộ dữ liệu nằm trong `data/` (không commit):

| Đường dẫn | Nội dung |
|:--|:--|
| `data/mysql/` | Database MariaDB |
| `data/caddy/` | Chứng chỉ và trạng thái Caddy |
| `wordpress/wp-content/uploads/` | Ảnh và file media |

Nên backup định kỳ. Ví dụ dump database:

```bash
docker compose exec db sh -c 'exec mariadb-dump -uroot -p"$MARIADB_ROOT_PASSWORD" "$MARIADB_DATABASE"' > backup-$(date +%F).sql
```

---

## Lệnh thường dùng

Toàn bộ lệnh chạy trong thư mục gốc repo. Trên Linux, nếu gặp lỗi `permission denied` khi Docker tạo file, thêm `sudo` trước lệnh `docker`.

```bash
docker compose up -d --build       # build lại image và chạy nền
docker compose ps                  # xem trạng thái các service
docker compose logs -f wordpress   # theo dõi log WordPress
docker compose logs -f caddy       # theo dõi log HTTPS / chứng chỉ
docker compose restart caddy       # nạp lại Caddyfile (sau khi sửa)
docker compose down                # dừng và xoá container (giữ dữ liệu)
docker compose down -v             # dừng và xoá cả volume ẩn danh
rm -rf data/                       # XOÁ TOÀN BỘ dữ liệu — cẩn thận
```

Chạy WP-CLI:

```bash
docker compose run --rm -u www-data wordpress \
  -c "cd /var/www/vhosts/localhost/html && php wp-cli.phar plugin list"
```

---

## Chạy local (không có tên miền thật)

Caddy sẽ không cấp được chứng chỉ hợp lệ cho một domain không trỏ thật về máy. Để test trên máy cá nhân:

1. Thêm vào file `hosts` (`/etc/hosts` hoặc `C:\Windows\System32\drivers\etc\hosts`):
   ```text
   127.0.0.1 khoa.localhost
   ```
2. Đặt `SITE_DOMAIN=khoa.localhost` trong `.env`
3. Trong `Caddyfile`, tạm đổi phần đầu thành:
   ```caddyfile
   {
       local_certs
   }

   khoa.localhost {
       reverse_proxy wordpress:80 { ... }
   }
   ```
4. `docker compose up -d --build`, sau đó mở `https://khoa.localhost`
   (Caddy sẽ cài CA nội bộ vào máy; lần đầu trình duyệt có thể cảnh báo chứng chỉ)

Ngoài ra có thể truy cập tạm qua HTTP tại `http://localhost:80`.

---

## Xử lý sự cố

| Triệu chứng | Nguyên nhân thường gặp | Cách khắc phục |
|:--|:--|:--|
| `Error establishing a database connection` | Sai mật khẩu trong `.env`, hoặc DB khởi động chưa xong | `docker compose logs db`; đợi hoặc `docker compose restart wordpress` |
| Màn hình trắng / `Unable to open ... wp-load.php` | Chưa có WordPress core trong `wordpress/` | Xem **Bước 2** phần Cài đặt |
| Caddy lặp lại lỗi `tls: ... no such host` | DNS chưa trỏ về server, hoặc cổng 80/443 bị chặn | Kiểm tra `dig <SITE_DOMAIN>` và firewall |
| Redirect loop về `/wp-admin/install.php` | Thiếu `X-Forwarded-Proto` hoặc `WP_HOME`/`WP_SITEURL` sai | Kiểm tra `SITE_DOMAIN` trong `.env`, restart lại `wordpress` |
| Upload ảnh báo *file too large* | Giới hạn PHP / proxy | Tăng `uploads.ini`, `docker compose up -d` |
| Không cài được plugin, đòi FTP | `FS_METHOD` không được set | Kiểm tra `WORDPRESS_CONFIG_EXTRA` trong `docker-compose.yml` |
| Permissions error khi ghi file | Bind mount ghi quyền host `root` | `ols-entrypoint.sh` đã chmod 777; nếu vẫn lỗi, `sudo chown -R 1000:1000 wordpress/` |

Xem toàn bộ log: `docker compose logs --tail=200`

---

## Bảo mật — trước khi lên production

- [ ] Thay **tất cả** giá trị `change-me` trong `.env` bằng mật khẩu mạnh, ngẫu nhiên
- [ ] Sinh mới toàn bộ salt WordPress (`AUTH_KEY`, `NONCE_KEY`, ...)
- [ ] Thay `chmod -R 777` trong `ols-entrypoint.sh` bằng UID/GID phù hợp
- [ ] Đặt `WORDPRESS_DEBUG=0` (mặc định đã tắt)
- [ ] Giới hạn quyền truy cập `/wp-admin` (IP allowlist hoặc Basic Auth ở Caddy)
- [ ] Bật firewall chỉ mở `22`, `80`, `443`
- [ ] Cấu hình backup tự động và **diễn tập khôi phục**
- [ ] Cập nhật image: `docker compose pull && docker compose up -d --build`

---

## Giấy phép

© 2026 Khoa KT — CNTT — VHNT. Dùng cho mục đích đào tạo.
