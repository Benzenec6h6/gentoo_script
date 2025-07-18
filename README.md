# Gentoo Auto Installer

このプロジェクトは、Gentoo Linux のインストールをステップごとに自動化するスクリプト集です。最小構成の Openbox デスクトップ環境までセットアップします。

---

## 🔧 ディレクトリ構成

```bash
.
├── install.sh               # 全体実行用スクリプト
├── 00-env.sh                # 環境変数定義
├── 01-disk-select.sh        # ディスク選択
├── 02-network-select.sh     # ネットワークツール選択
├── 03-bootloader-select.sh  # ブートローダ選択
├── 04-stage3.sh             # Stage3 tarball ダウンロード＆展開
├── 05-make-conf.sh          # make.conf の配置
├── 06-mount.sh              # マウント処理
├── 07-chroot-prepare.sh     # chroot 環境準備
├── 08-chroot-exec.sh        # chroot スクリプト実行
├── 09-users.sh              # ユーザー追加
├── 10-bootloader.sh         # GRUB または systemd-boot セットアップ
├── 11-cleanup.sh            # アンマウントと終了処理
├── 12-postinstall.sh        # Openbox などの最低限の GUI 環境
│
├── assets/
│   ├── make.conf            # 初期 make.conf テンプレート
│   └── fstab.template       # fstab テンプレート
│
├── chroot/
│   └── chroot-setup.sh      # chroot 内初期セットアップ
│
└── profile/
    ├── openrc/
    │   └── make.conf         # OpenRC 向け make.conf
    ├── systemd/
    │   └── make.conf         # systemd 向け make.conf
    ├── package.use
    ├── package.accept_keywords
    └── kernel.sh            # カーネルビルド用スクリプト
```

---

## 🚀 使用方法

> **前提:**
> - UEFI または BIOS 環境
> - インストール対象ディスクに既存データが上書きされます
> - 有線 LAN 推奨

1. 必要な依存関係を満たした Gentoo LiveCD または適当な Linux 環境を用意
2. このリポジトリを取得（USB・git clone・wgetなど）
3. スクリプトに実行権限を与える：

   ```bash
   chmod +x *.sh chroot/*.sh profile/*.sh
   ```

4. インストール開始：

   ```bash
   sudo ./install.sh
   ```

---

## 🔑 カスタマイズ

- `00-env.sh` にインストール設定（ユーザー名、init、loaderなど）を記述
- `profile/` 内に必要な USE フラグやキーワードを追加可能
- デスクトップ環境を変更したい場合は `12-postinstall.sh` を編集

### make.conf の動作について

init に応じて以下の make.conf を自動で適用します：

- OpenRC: `profile/openrc/make.conf`
- systemd: `profile/systemd/make.conf`

`assets/make.conf` はデフォルトの比較・参考用テンプレートです。

---

## ⚠️ 注意

- このスクリプトは学習・個人利用を目的としています。
- 使用前にスクリプト内容をよく確認してください。

---

## ✅ TODO / 今後の改善案

- LUKS + LVM 対応
- Wayland 環境対応
- GUI ブートテーマ
- install.log への出力

---

ご意見・修正提案歓迎です！
