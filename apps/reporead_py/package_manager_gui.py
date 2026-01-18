# package_manager_gui.py
import tkinter as tk
from tkinter import ttk, messagebox, scrolledtext
import subprocess
from pathlib import Path
import re
from datetime import datetime


class PackageManagerApp:
    def __init__(self, root):
        self.root = root
        self.root.title("📦 GLLB-Apps Package Manager")
        self.root.geometry("900x750")
        self.root.configure(bg="#1e1e1e")

        # Sök efter repo path automatiskt
        self.repo_path = self.find_repo_path()

        # Stil
        self.setup_style()

        # GUI
        self.create_widgets()

        # Auto-load vid start
        self.load_packages()

    def setup_style(self):
        """Konfigurera dark theme"""
        style = ttk.Style()
        style.theme_use("clam")

        bg_color = "#1e1e1e"
        fg_color = "#ffffff"
        select_bg = "#264f78"

        style.configure("TFrame", background=bg_color)
        style.configure("TLabel", background=bg_color, foreground=fg_color, font=("Segoe UI", 10))
        style.configure("Title.TLabel", font=("Segoe UI", 16, "bold"))
        style.configure("TButton", font=("Segoe UI", 10))
        style.configure(
            "Treeview",
            background="#252526",
            foreground=fg_color,
            fieldbackground="#252526",
            font=("Segoe UI", 9),
        )
        style.configure(
            "Treeview.Heading",
            background="#3e3e42",
            foreground=fg_color,
            font=("Segoe UI", 10, "bold"),
        )
        style.map("Treeview", background=[("selected", select_bg)])

    def find_repo_path(self):
        """Hitta repo path automatiskt"""
        cwd = Path.cwd()
        if (cwd / ".git").exists():
            return cwd

        possible_paths = [
            Path.home() / "Documents" / "dart-packages-handbook",
            Path.home() / "Projects" / "dart-packages-handbook",
            Path("D:/Programmering/Github-Dart-Handbook/dart-packages-handbook"),
            Path.cwd().parent / "dart-packages-handbook",
        ]

        for path in possible_paths:
            if path.exists() and (path / ".git").exists():
                return path

        return cwd

    def create_widgets(self):
        """Skapa GUI komponenter"""
        main_frame = ttk.Frame(self.root, padding="20")
        main_frame.grid(row=0, column=0, sticky=(tk.W, tk.E, tk.N, tk.S))

        # Title
        title = ttk.Label(main_frame, text="📦 GLLB-Apps Dart Package Manager", style="Title.TLabel")
        title.grid(row=0, column=0, columnspan=3, pady=(0, 20))

        # Repo path
        path_frame = ttk.Frame(main_frame)
        path_frame.grid(row=1, column=0, columnspan=3, sticky=(tk.W, tk.E), pady=(0, 10))

        ttk.Label(path_frame, text="Repo Path:").pack(side=tk.LEFT, padx=(0, 10))
        self.path_entry = ttk.Entry(path_frame, width=60)
        self.path_entry.pack(side=tk.LEFT, fill=tk.X, expand=True)
        self.path_entry.insert(0, str(self.repo_path))

        ttk.Button(path_frame, text="Browse", command=self.browse_repo).pack(side=tk.LEFT, padx=(10, 0))

        # Package list
        list_frame = ttk.LabelFrame(main_frame, text="Current Packages", padding="10")
        list_frame.grid(row=2, column=0, columnspan=3, sticky=(tk.W, tk.E, tk.N, tk.S), pady=(0, 10))

        # Treeview
        columns = ("Package", "Version", "Source")
        self.tree = ttk.Treeview(list_frame, columns=columns, show="headings", height=10)

        self.tree.heading("Package", text="Package Name")
        self.tree.heading("Version", text="Version")
        self.tree.heading("Source", text="Source")

        self.tree.column("Package", width=300)
        self.tree.column("Version", width=120)
        self.tree.column("Source", width=180)

        scrollbar = ttk.Scrollbar(list_frame, orient=tk.VERTICAL, command=self.tree.yview)
        self.tree.configure(yscroll=scrollbar.set)

        self.tree.grid(row=0, column=0, sticky=(tk.W, tk.E, tk.N, tk.S))
        scrollbar.grid(row=0, column=1, sticky=(tk.N, tk.S))

        # Buttons (fetch borttagen)
        btn_frame = ttk.Frame(main_frame)
        btn_frame.grid(row=3, column=0, columnspan=3, pady=(10, 10))

        ttk.Button(btn_frame, text="🔄 Refresh from README", command=self.load_packages).pack(side=tk.LEFT, padx=5)
        ttk.Button(btn_frame, text="➕ Add Package", command=self.add_package_dialog).pack(side=tk.LEFT, padx=5)
        ttk.Button(btn_frame, text="➖ Remove Selected", command=self.remove_package).pack(side=tk.LEFT, padx=5)

        # Update & Push section
        action_frame = ttk.LabelFrame(main_frame, text="Update & Push", padding="10")
        action_frame.grid(row=4, column=0, columnspan=3, sticky=(tk.W, tk.E), pady=(0, 10))

        ttk.Label(action_frame, text="Commit message:").grid(row=0, column=0, sticky=tk.W, pady=(0, 5))
        self.commit_entry = ttk.Entry(action_frame, width=60)
        self.commit_entry.grid(row=1, column=0, sticky=(tk.W, tk.E), pady=(0, 10))
        self.commit_entry.insert(0, "🤖 Update package list")

        btn_frame2 = ttk.Frame(action_frame)
        btn_frame2.grid(row=2, column=0, sticky=(tk.W, tk.E))

        ttk.Button(btn_frame2, text="⬇️ Pull Latest", command=self.pull_from_github).pack(side=tk.LEFT, padx=5)
        ttk.Button(btn_frame2, text="💾 Generate README", command=self.generate_readme).pack(side=tk.LEFT, padx=5)
        ttk.Button(btn_frame2, text="🚀 Generate & Force Push", command=self.generate_and_push).pack(
            side=tk.LEFT, padx=5
        )

        # Log
        log_frame = ttk.LabelFrame(main_frame, text="Log", padding="10")
        log_frame.grid(row=5, column=0, columnspan=3, sticky=(tk.W, tk.E, tk.N, tk.S))

        self.log_text = scrolledtext.ScrolledText(
            log_frame, height=8, bg="#1e1e1e", fg="#ffffff", font=("Consolas", 9)
        )
        self.log_text.pack(fill=tk.BOTH, expand=True)

        # Configure grid weights
        self.root.columnconfigure(0, weight=1)
        self.root.rowconfigure(0, weight=1)
        main_frame.columnconfigure(0, weight=1)
        main_frame.rowconfigure(2, weight=1)
        main_frame.rowconfigure(5, weight=1)
        list_frame.columnconfigure(0, weight=1)
        list_frame.rowconfigure(0, weight=1)
        action_frame.columnconfigure(0, weight=1)

        self.packages = []

    def log(self, message):
        """Logga meddelande"""
        timestamp = datetime.now().strftime("%H:%M:%S")
        self.log_text.insert(tk.END, f"[{timestamp}] {message}\n")
        self.log_text.see(tk.END)
        self.root.update()

    def browse_repo(self):
        """Välj repo directory"""
        from tkinter import filedialog

        path = filedialog.askdirectory(initialdir=self.path_entry.get())
        if path:
            self.path_entry.delete(0, tk.END)
            self.path_entry.insert(0, path)
            self.repo_path = Path(path)

    def load_packages(self):
        """Läs packages från README"""
        self.log("📖 Reading packages from README...")

        readme_path = Path(self.path_entry.get()) / "README.md"

        if not readme_path.exists():
            self.log(f"❌ README not found: {readme_path}")
            return

        try:
            content = readme_path.read_text(encoding="utf-8")

            # Extrahera packages från markdown table: | **name** |
            pattern = r"\|\s*\*\*([^*]+)\*\*\s*\|"
            matches = re.findall(pattern, content)

            self.packages = []
            for package_name in matches:
                self.packages.append(
                    {
                        "package": package_name.strip(),
                        "version": "Unknown",
                        "source": "README",
                    }
                )

            self.update_tree()
            self.log(f"✅ Loaded {len(self.packages)} packages from README")

        except Exception as e:
            self.log(f"❌ Error reading README: {e}")

    def add_package_dialog(self):
        """Dialog för att lägga till package manuellt + validering"""
        dialog = tk.Toplevel(self.root)
        dialog.title("Add Package")
        dialog.geometry("420x170")
        dialog.configure(bg="#1e1e1e")

        frame = ttk.Frame(dialog, padding="20")
        frame.pack(fill=tk.BOTH, expand=True)

        ttk.Label(frame, text="Package name (lowercase):").grid(row=0, column=0, sticky=tk.W, pady=5)
        entry = ttk.Entry(frame, width=40)
        entry.grid(row=1, column=0, sticky=(tk.W, tk.E), pady=5)
        entry.focus()

        help_lbl = ttk.Label(frame, text="Allowed: a-z, 0-9, underscore (_)")
        help_lbl.grid(row=2, column=0, sticky=tk.W, pady=(0, 10))

        def add():
            name = entry.get().strip().lower().replace(" ", "")

            if not name:
                messagebox.showwarning("Empty", "Please enter a package name.")
                return

            # Pub package names: lowercase + underscore
            if not re.match(r"^[a-z0-9_]+$", name):
                messagebox.showerror(
                    "Invalid name",
                    "Invalid package name.\n\nUse only: a-z, 0-9, underscore (_)\nLowercase only.",
                )
                return

            if name in [p["package"] for p in self.packages]:
                messagebox.showwarning("Duplicate", f"Package '{name}' already exists!")
                return

            self.packages.append({"package": name, "version": "Unknown", "source": "Manual"})
            self.update_tree()
            self.log(f"✅ Added package: {name}")
            dialog.destroy()

        btn_frame = ttk.Frame(frame)
        btn_frame.grid(row=3, column=0, pady=10, sticky=tk.W)

        ttk.Button(btn_frame, text="Add", command=add).pack(side=tk.LEFT, padx=5)
        ttk.Button(btn_frame, text="Cancel", command=dialog.destroy).pack(side=tk.LEFT, padx=5)

        entry.bind("<Return>", lambda e: add())

    def remove_package(self):
        """Ta bort vald package"""
        selection = self.tree.selection()
        if not selection:
            messagebox.showwarning("No Selection", "Please select a package to remove")
            return

        item = self.tree.item(selection[0])
        package_name = item["values"][0]

        if messagebox.askyesno("Confirm", f"Remove package '{package_name}'?"):
            self.packages = [p for p in self.packages if p["package"] != package_name]
            self.update_tree()
            self.log(f"🗑️ Removed package: {package_name}")

    def update_tree(self):
        """Uppdatera treeview"""
        for item in self.tree.get_children():
            self.tree.delete(item)

        for pkg in sorted(self.packages, key=lambda x: x["package"]):
            self.tree.insert("", tk.END, values=(pkg["package"], pkg["version"], pkg["source"]))

    # ---------------- Git helpers ----------------

    def pull_from_github(self):
        """Pull senaste ändringar från GitHub"""
        self.log("⬇️ Pulling from GitHub...")

        try:
            repo_path = Path(self.path_entry.get())

            result = subprocess.run(
                ["git", "pull", "--no-rebase", "-X", "ours"],
                cwd=repo_path,
                capture_output=True,
                text=True,
            )

            if result.returncode == 0:
                output = (result.stdout or "").strip()
                if output:
                    for line in output.split("\n"):
                        if line.strip():
                            self.log(f"  {line.strip()}")

                if "already up to date" in output.lower():
                    self.log("  ℹ️ Already up to date")
                else:
                    self.log("✅ Pull complete!")

                self.load_packages()
            else:
                err = (result.stderr or "").strip()
                self.log(f"  ❌ {err}")
                messagebox.showerror("Git Error", err or "Unknown git error")

        except Exception as e:
            self.log(f"❌ Error: {e}")
            messagebox.showerror("Error", f"Failed to pull:\n{e}")

    def generate_readme(self):
        """Generera ny README"""
        self.log("📝 Generating README...")

        try:
            timestamp = datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S")

            lines = [
                "# 📦 GLLB-Apps Dart Packages\n",
                "My published packages on pub.dev\n",
                "| Package | Version | Pub Points | Popularity | Link |",
                "|---------|---------|------------|------------|------|",
            ]

            for pkg in sorted(self.packages, key=lambda x: x["package"]):
                name = pkg["package"]
                lines.append(
                    f"| **{name}** | "
                    f"![version](https://img.shields.io/pub/v/{name}.svg?color=blue) | "
                    f"![points](https://img.shields.io/pub/points/{name}?color=green) | "
                    f"![popularity](https://img.shields.io/pub/popularity/{name}?color=orange) | "
                    f"[pub.dev](https://pub.dev/packages/{name}) |"
                )

            lines.extend(
                [
                    "\n---",
                    f"**Last updated:** `{timestamp} UTC` 🤖",
                    "\n*Auto-updated daily at 03:00 UTC via GitHub Actions*",
                ]
            )

            readme_path = Path(self.path_entry.get()) / "README.md"
            readme_path.write_text("\n".join(lines), encoding="utf-8")

            self.log(f"✅ README generated: {readme_path}")

        except Exception as e:
            self.log(f"❌ Error generating README: {e}")
            messagebox.showerror("Error", f"Failed to generate README:\n{e}")

    def generate_and_push(self):
        """Generera README och force-pusha till GitHub (alltid force push)"""
        repo_path = Path(self.path_entry.get())

        self.log(f"📂 Working in: {repo_path}")

        # 1) Generera README först
        self.generate_readme()

        # 2) Git add
        self.log("📝 git add README.md")
        try:
            subprocess.run(
                ["git", "add", "README.md"],
                cwd=repo_path,
                capture_output=True,
                text=True,
                check=True,
            )
        except Exception as e:
            self.log(f"❌ git add failed: {e}")
            messagebox.showerror("Error", f"git add failed:\n{e}")
            return

        # 3) Commit (OK om inget att committa)
        self.log("💾 git commit")
        commit_msg = (self.commit_entry.get() or "🤖 Update package list").strip()

        try:
            commit_result = subprocess.run(
                ["git", "commit", "-m", commit_msg],
                cwd=repo_path,
                capture_output=True,
                text=True,
            )

            combined = ((commit_result.stdout or "") + (commit_result.stderr or "")).lower()
            if "nothing to commit" in combined:
                self.log("  ℹ️ Nothing to commit (README unchanged)")
            else:
                if commit_result.stdout:
                    self.log(f"  {commit_result.stdout.strip()}")
                if commit_result.stderr:
                    self.log(f"  {commit_result.stderr.strip()}")

        except Exception as e:
            self.log(f"❌ Commit error: {e}")
            messagebox.showerror("Error", f"git commit failed:\n{e}")
            return

        # 4) ALWAYS force push (säkrast: force-with-lease)
        self.log("🚀 git push --force-with-lease")
        try:
            push_result = subprocess.run(
                ["git", "push", "--force-with-lease"],
                cwd=repo_path,
                capture_output=True,
                text=True,
            )

            if push_result.stdout:
                self.log(f"  {push_result.stdout.strip()}")
            if push_result.stderr:
                self.log(f"  {push_result.stderr.strip()}")

            if push_result.returncode == 0:
                self.log("✅ Force push complete!")
                messagebox.showinfo("Success", "Force push completed successfully! 🎉")
            else:
                self.log("❌ Force push failed!")
                messagebox.showerror("Error", push_result.stderr or "Force push failed")

        except Exception as e:
            self.log(f"❌ Push error: {e}")
            messagebox.showerror("Error", str(e))


def main():
    root = tk.Tk()
    app = PackageManagerApp(root)
    root.mainloop()


if __name__ == "__main__":
    main()
