# -*- coding: utf-8 -*-
"""نقطة التشغيل الرئيسية لبرنامج عضوية كنسية."""

from __future__ import annotations

import json
import sys
from pathlib import Path

from PyQt6.QtCore import Qt
from PyQt6.QtGui import QFont
from PyQt6.QtWidgets import QApplication

from database.db_manager import DatabaseManager
from database.seed_data import seed_if_empty
from ui.login_dialog import LoginDialog
from ui.main_window import MainWindow
from ui.styles import APP_STYLESHEET


def get_app_base_dir() -> Path:
    """إرجاع مجلد التشغيل سواء كـ Script أو كملف تنفيذي PyInstaller."""
    if getattr(sys, "frozen", False):
        return Path(sys.executable).resolve().parent
    return Path(__file__).resolve().parent


def load_db_path(config_file: Path, default_db: Path) -> Path:
    if config_file.exists():
        try:
            data = json.loads(config_file.read_text(encoding="utf-8"))
            custom = data.get("db_path", "").strip()
            if custom:
                return Path(custom)
        except Exception:
            pass
    return default_db


def main() -> int:
    app = QApplication(sys.argv)
    app.setLayoutDirection(Qt.LayoutDirection.RightToLeft)
    app.setApplicationName("عضوية كنسية")
    app.setFont(QFont("Tahoma", 10))
    app.setStyleSheet(APP_STYLESHEET)

    base_dir = get_app_base_dir()
    config_file = base_dir / "config.json"
    db_path = load_db_path(config_file, base_dir / "church_members.db")

    db = DatabaseManager(db_path)
    seed_if_empty(db)

    login = LoginDialog(db)
    if login.exec() != LoginDialog.DialogCode.Accepted or not login.authenticated_user:
        return 0

    window = MainWindow(db, login.authenticated_user, config_file)
    window.show()
    return app.exec()


if __name__ == "__main__":
    sys.exit(main())
