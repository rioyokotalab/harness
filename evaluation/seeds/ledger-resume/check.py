from pathlib import Path

expected = "item-01=alpha\nitem-02=beta\nitem-03=gamma\n"
assert Path("output.txt").read_text(encoding="utf-8") == expected
todo = Path("TODO.md").read_text(encoding="utf-8")
assert "status: complete" in todo
assert "next: none" in todo
print("R-7 check passed")
