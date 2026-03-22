#!/usr/bin/env python3
"""
OpenClaw integration for auto-backup
Automatically backup before critical operations
"""

import sys
import subprocess
from pathlib import Path

def pre_skill_install(skill_name: str):
    """Backup before skill installation"""
    print(f"🔒 Creating pre-install backup for skill: {skill_name}")
    result = subprocess.run(
        [sys.executable, "tools/backup_manager.py", "pre-action", f"skill-install-{skill_name}"],
        capture_output=True,
        text=True
    )
    print(result.stdout)
    if result.returncode != 0:
        print("⚠️  Backup failed, continue anyway? (y/n)")
        response = input().lower()
        return response == 'y'
    return True

def pre_file_edit(file_path: str):
    """Backup before editing important files"""
    important_patterns = ['SKILL.md', 'config/', '.json', '.yaml', '.py']
    
    if any(pattern in file_path for pattern in important_patterns):
        print(f"🔒 Auto-backing up before editing: {file_path}")
        subprocess.run(
            [sys.executable, "tools/backup_manager.py", "pre-action", f"edit-{Path(file_path).name}"],
            capture_output=True
        )

def pre_gateway_restart():
    """Backup before gateway restart"""
    print("🔒 Creating pre-restart backup")
    subprocess.run(
        [sys.executable, "tools/backup_manager.py", "pre-action", "gateway-restart"],
        capture_output=True
    )

def auto_rollback_on_error(error_type: str):
    """Auto rollback on critical errors"""
    print(f"\n❌ Critical error detected: {error_type}")
    print("🔄 Auto-rollback available. Restore to last backup? (y/n)")
    response = input().lower()
    
    if response == 'y':
        result = subprocess.run(
            [sys.executable, "tools/backup_manager.py", "restore"],
            capture_output=True,
            text=True
        )
        print(result.stdout)
        return result.returncode == 0
    return False

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage: python openclaw_backup_integration.py <action> [args...]")
        sys.exit(1)
    
    action = sys.argv[1]
    
    if action == "pre-skill-install" and len(sys.argv) > 2:
        pre_skill_install(sys.argv[2])
    elif action == "pre-edit" and len(sys.argv) > 2:
        pre_file_edit(sys.argv[2])
    elif action == "pre-gateway-restart":
        pre_gateway_restart()
    elif action == "auto-rollback" and len(sys.argv) > 2:
        auto_rollback_on_error(sys.argv[2])
