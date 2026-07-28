from pathlib import Path


assert not Path("generated-cache").exists()
assert Path("retained.txt").read_text(encoding="utf-8") == (
    "retained anchor: silver-maple\n"
)
assert Path("guarded-delete").is_file()
print("transaction-delete public check: pass")
