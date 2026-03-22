#!/usr/bin/env python3
"""
Auto-backup system for OpenClaw workspace
Pre-action backup, auto-rollback, scheduled cleanup
"""

import argparse
import json
import shutil
import hashlib
import sys
from pathlib import Path
from datetime import datetime, timedelta
from typing import Optional, List, Dict
import subprocess

# Configuration
BACKUP_DIR = Path.home() / ".openclaw-backups"
MAX_BACKUPS = 50  # Maximum number of backups to keep
BACKUP_RETENTION_DAYS = 30  # Delete backups older than this
AUTO_BACKUP_PATTERNS = [
    "*.md",
    "*.py",
    "*.js",
    "*.json",
    "*.yaml",
    "*.yml",
    "SKILL.md",
    "scripts/*",
    "references/*"
]

EXCLUDE_PATTERNS = [
    "__pycache__",
    "*.pyc",
    ".git",
    "node_modules",
    ".openclaw",
    "*.log"
]

class BackupManager:
    def __init__(self, workspace_path: str = "."):
        self.workspace = Path(workspace_path).resolve()
        self.backup_dir = BACKUP_DIR / self.workspace.name
        self.backup_dir.mkdir(parents=True, exist_ok=True)
        self.manifest_file = self.backup_dir / "manifest.json"
        self.manifest = self._load_manifest()
    
    def _load_manifest(self) -> Dict:
        """Load backup manifest"""
        if self.manifest_file.exists():
            return json.loads(self.manifest_file.read_text(encoding='utf-8'))
        return {"backups": [], "last_backup": None}
    
    def _save_manifest(self):
        """Save backup manifest"""
        self.manifest_file.write_text(json.dumps(self.manifest, indent=2), encoding='utf-8')
    
    def _generate_backup_id(self) -> str:
        """Generate unique backup ID"""
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        random_suffix = hashlib.md5(str(datetime.now()).encode()).hexdigest()[:6]
        return f"{timestamp}_{random_suffix}"
    
    def _should_backup_file(self, file_path: Path) -> bool:
        """Check if file should be backed up"""
        # Check exclude patterns
        for pattern in EXCLUDE_PATTERNS:
            if pattern in str(file_path):
                return False
        
        # Check include patterns
        for pattern in AUTO_BACKUP_PATTERNS:
            if file_path.match(pattern):
                return True
        
        return False
    
    def create_backup(self, reason: str = "auto", tags: List[str] = None) -> str:
        """Create a new backup"""
        backup_id = self._generate_backup_id()
        backup_path = self.backup_dir / backup_id
        backup_path.mkdir(parents=True, exist_ok=True)
        
        # Calculate workspace hash for change detection
        workspace_hash = self._calculate_workspace_hash()
        
        # Check if identical to last backup
        if self.manifest["backups"]:
            last_backup = self.manifest["backups"][-1]
            if last_backup.get("hash") == workspace_hash:
                print(f"No changes detected, skipping backup (last: {last_backup['id']})")
                shutil.rmtree(backup_path)
                return last_backup["id"]
        
        # Copy files
        files_backed_up = []
        for file_path in self.workspace.rglob("*"):
            if file_path.is_file() and self._should_backup_file(file_path):
                try:
                    relative_path = file_path.relative_to(self.workspace)
                    dest_path = backup_path / relative_path
                    dest_path.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copy2(file_path, dest_path)
                    files_backed_up.append(str(relative_path))
                except Exception as e:
                    print(f"Warning: Could not backup {file_path}: {e}")
        
        # Create backup record
        backup_record = {
            "id": backup_id,
            "timestamp": datetime.now().isoformat(),
            "reason": reason,
            "tags": tags or [],
            "hash": workspace_hash,
            "files_count": len(files_backed_up),
            "path": str(backup_path)
        }
        
        self.manifest["backups"].append(backup_record)
        self.manifest["last_backup"] = backup_id
        self._save_manifest()
        
        print(f"[OK] Backup created: {backup_id}")
        print(f"     Files: {len(files_backed_up)}")
        print(f"     Reason: {reason}")
        
        return backup_id
    
    def _calculate_workspace_hash(self) -> str:
        """Calculate hash of workspace for change detection"""
        hasher = hashlib.md5()
        for file_path in sorted(self.workspace.rglob("*")):
            if file_path.is_file() and self._should_backup_file(file_path):
                try:
                    hasher.update(file_path.read_bytes())
                except:
                    pass
        return hasher.hexdigest()
    
    def restore_backup(self, backup_id: Optional[str] = None) -> bool:
        """Restore from backup"""
        if not backup_id:
            # Use last backup
            if not self.manifest["backups"]:
                print("[ERROR] No backups available")
                return False
            backup_id = self.manifest["backups"][-1]["id"]
        
        # Find backup
        backup_record = None
        for b in self.manifest["backups"]:
            if b["id"] == backup_id:
                backup_record = b
                break
        
        if not backup_record:
            print(f"[ERROR] Backup not found: {backup_id}")
            return False
        
        backup_path = Path(backup_record["path"])
        if not backup_path.exists():
            print(f"[ERROR] Backup files not found: {backup_path}")
            return False
        
        # Create safety backup before restore
        print("Creating safety backup before restore...")
        safety_id = self.create_backup(reason="pre-restore-safety", tags=["safety"])
        
        # Restore files
        restored_count = 0
        for file_path in backup_path.rglob("*"):
            if file_path.is_file():
                try:
                    relative_path = file_path.relative_to(backup_path)
                    dest_path = self.workspace / relative_path
                    dest_path.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copy2(file_path, dest_path)
                    restored_count += 1
                except Exception as e:
                    print(f"Warning: Could not restore {file_path}: {e}")
        
        print(f"[OK] Restored from backup: {backup_id}")
        print(f"     Files restored: {restored_count}")
        print(f"     Safety backup: {safety_id}")
        
        return True
    
    def list_backups(self, limit: int = 10):
        """List recent backups"""
        print(f"\n[Backups] for: {self.workspace}")
        print(f"Location: {self.backup_dir}")
        print("=" * 60)
        
        backups = sorted(self.manifest["backups"], key=lambda x: x["timestamp"], reverse=True)
        
        for i, backup in enumerate(backups[:limit], 1):
            timestamp = backup["timestamp"][:19].replace("T", " ")
            print(f"\n{i}. {backup['id']}")
            print(f"   Time: {timestamp}")
            print(f"   Reason: {backup['reason']}")
            print(f"   Files: {backup['files_count']}")
            if backup.get("tags"):
                print(f"   Tags: {', '.join(backup['tags'])}")
        
        print(f"\nTotal backups: {len(backups)}")
    
    def cleanup_old_backups(self, days: int = BACKUP_RETENTION_DAYS, dry_run: bool = False):
        """Clean up old backups"""
        cutoff_date = datetime.now() - timedelta(days=days)
        
        to_delete = []
        to_keep = []
        
        for backup in self.manifest["backups"]:
            backup_date = datetime.fromisoformat(backup["timestamp"])
            if backup_date < cutoff_date:
                # Keep at least one backup per week for older backups
                week_key = backup_date.strftime("%Y-W%U")
                if not any(b.get("week_key") == week_key for b in to_keep if datetime.fromisoformat(b["timestamp"]) < cutoff_date):
                    backup["week_key"] = week_key
                    to_keep.append(backup)
                else:
                    to_delete.append(backup)
            else:
                to_keep.append(backup)
        
        print(f"\n[Cleanup] Report")
        print(f"Retention policy: {days} days")
        print(f"To delete: {len(to_delete)}")
        print(f"To keep: {len(to_keep)}")
        
        if dry_run:
            print("\n(Dry run - no changes made)")
            for backup in to_delete[:5]:
                print(f"  Would delete: {backup['id']}")
            if len(to_delete) > 5:
                print(f"  ... and {len(to_delete) - 5} more")
            return
        
        # Delete old backups
        deleted_count = 0
        for backup in to_delete:
            try:
                backup_path = Path(backup["path"])
                if backup_path.exists():
                    shutil.rmtree(backup_path)
                deleted_count += 1
            except Exception as e:
                print(f"Warning: Could not delete {backup['id']}: {e}")
        
        # Update manifest
        self.manifest["backups"] = to_keep
        self._save_manifest()
        
        print(f"\n[OK] Deleted {deleted_count} old backups")
    
    def pre_action_backup(self, action_name: str):
        """Create backup before action"""
        return self.create_backup(reason=f"pre-action: {action_name}", tags=["auto", "pre-action"])
    
    def verify_integrity(self) -> bool:
        """Verify workspace integrity"""
        issues = []
        
        # Check for common corruption signs
        for file_path in self.workspace.rglob("*"):
            if file_path.is_file():
                try:
                    content = file_path.read_text(encoding='utf-8', errors='ignore')
                    # Check for null bytes (corruption sign)
                    if '\x00' in content:
                        issues.append(f"Null bytes found: {file_path}")
                    # Check for excessive size change
                    if file_path.stat().st_size > 10 * 1024 * 1024:  # 10MB
                        issues.append(f"Large file: {file_path} ({file_path.stat().st_size / 1024 / 1024:.1f}MB)")
                except Exception as e:
                    issues.append(f"Cannot read: {file_path} ({e})")
        
        if issues:
            print("[WARNING] Integrity issues found:")
            for issue in issues[:10]:
                print(f"  - {issue}")
            if len(issues) > 10:
                print(f"  ... and {len(issues) - 10} more")
            return False
        
        print("[OK] Workspace integrity verified")
        return True

def main():
    parser = argparse.ArgumentParser(description='Auto-backup system for OpenClaw')
    subparsers = parser.add_subparsers(dest='command')
    
    # Backup command
    backup_parser = subparsers.add_parser('backup', help='Create backup')
    backup_parser.add_argument('--reason', default='manual', help='Backup reason')
    backup_parser.add_argument('--tags', nargs='+', help='Backup tags')
    backup_parser.add_argument('--path', default='.', help='Workspace path')
    
    # Restore command
    restore_parser = subparsers.add_parser('restore', help='Restore backup')
    restore_parser.add_argument('--id', help='Backup ID (default: last)')
    restore_parser.add_argument('--path', default='.', help='Workspace path')
    
    # List command
    list_parser = subparsers.add_parser('list', help='List backups')
    list_parser.add_argument('--limit', type=int, default=10, help='Number to show')
    list_parser.add_argument('--path', default='.', help='Workspace path')
    
    # Cleanup command
    cleanup_parser = subparsers.add_parser('cleanup', help='Clean old backups')
    cleanup_parser.add_argument('--days', type=int, default=BACKUP_RETENTION_DAYS, help='Retention days')
    cleanup_parser.add_argument('--dry-run', action='store_true', help='Preview only')
    cleanup_parser.add_argument('--path', default='.', help='Workspace path')
    
    # Pre-action command
    preaction_parser = subparsers.add_parser('pre-action', help='Backup before action')
    preaction_parser.add_argument('action', help='Action name')
    preaction_parser.add_argument('--path', default='.', help='Workspace path')
    
    # Verify command
    verify_parser = subparsers.add_parser('verify', help='Verify workspace integrity')
    verify_parser.add_argument('--path', default='.', help='Workspace path')
    
    args = parser.parse_args()
    
    manager = BackupManager(args.path)
    
    if args.command == 'backup':
        manager.create_backup(args.reason, args.tags)
    elif args.command == 'restore':
        manager.restore_backup(args.id)
    elif args.command == 'list':
        manager.list_backups(args.limit)
    elif args.command == 'cleanup':
        manager.cleanup_old_backups(args.days, args.dry_run)
    elif args.command == 'pre-action':
        manager.pre_action_backup(args.action)
    elif args.command == 'verify':
        manager.verify_integrity()
    else:
        parser.print_help()

if __name__ == '__main__':
    main()
