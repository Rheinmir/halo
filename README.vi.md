# Halo

**Giữ ⌥, rê về phía app, thả tay.** Launcher dạng vòng cho macOS.

<p align="center"><img src="docs/vi/ring-hover.png" width="560" alt="Vòng Halo"></p>

<p align="center"><b>TL;DR</b> · <a href="GUIDE.vi.md">Hướng dẫn đầy đủ</a> · <a href="docs/devlog/README.md">Devlog</a> · <a href="README.md">English</a></p>

## Cài

Nhờ coding agent (Claude Code, Codex, Cursor…):

```text
Cài Halo từ https://github.com/Rheinmir/halo theo hướng dẫn trong AGENTS.md của repo.
```

Hoặc cài tay:

```bash
git clone https://github.com/Rheinmir/halo.git ~/halo && cd ~/halo && ./build.sh && open Halo.app
```

Sau đó bật **Halo** trong System Settings → Privacy & Security → **Accessibility**.

## Dùng

| Làm | Kết quả |
|---|---|
| Giữ ⌥ một mình → rê về phía app → thả | Mở / chuyển sang app đó |
| Rê tiếp ra ngoài mép vòng | Chọn một cửa sổ của app |
| ⌥ + **Space** | Về app trước đó |
| ⌥ + **1–9** | Mở ô số đó |
| Thả ở giữa vòng, hoặc **Esc** | Huỷ |
| Biểu tượng menu bar → **Settings…** | Kéo app vào vòng, đổi phím, độ trễ, ngôn ngữ |

## Cần biết

macOS 13+ · cần quyền Accessibility · build từ source (chưa có bản tải) · tối đa 10 app · danh sách cửa sổ chỉ thấy Space hiện tại · không truy cập mạng · Apache 2.0

## Đọc thêm

- [Hướng dẫn đầy đủ](GUIDE.vi.md): vì sao cần Halo, từng tính năng kèm ảnh, xử lý sự cố, phát triển
- [Devlog](docs/devlog/README.md) (tiếng Anh): các vấn đề đã gặp và lý do của từng quyết định
- [Issues](https://github.com/Rheinmir/halo/issues/25): mục lục docs, devlog và việc còn mở

## Cho agent

Dữ kiện cài, cập nhật và sửa code nằm trong [AGENTS.md](AGENTS.md), file mà coding agent tự tìm đọc.
