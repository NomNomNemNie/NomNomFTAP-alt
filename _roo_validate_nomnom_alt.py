from pathlib import Path

ROOT = Path(__file__).resolve().parent
FILES = [ROOT / "Loader.lua", ROOT / "NomNom.lua"] + sorted((ROOT / "modules").glob("*.lua"))
DOCS = [ROOT / "README.md", ROOT / "STRONG_COMPARISON.md"]
BLOCKED = [
    "Load NoName Pack",
    "Load XOCO Pack",
    "Load NoName-Apple Pack",
    "SayMessageRequest",
    "TextChatService",
    "RBXGeneral",
    "E:/Projects",
    "E:\\Projects",
    ": and",
    ": or",
]

issues = []
for path in FILES + DOCS:
    text = path.read_text(encoding="utf-8", errors="ignore")
    for blocked in BLOCKED:
        if blocked in text:
            issues.append(f"{path.relative_to(ROOT)} contains blocked marker: {blocked}")
    balance = 0
    for index, char in enumerate(text):
        if char == "(":
            balance += 1
        elif char == ")":
            balance -= 1
        if balance < 0:
            issues.append(f"{path.relative_to(ROOT)} parenthesis underflow at byte {index}")
            break
    if balance != 0:
        issues.append(f"{path.relative_to(ROOT)} parenthesis balance ended at {balance}")

readme = (ROOT / "README.md").read_text(encoding="utf-8", errors="ignore")
comparison = (ROOT / "STRONG_COMPARISON.md").read_text(encoding="utf-8", errors="ignore")
if "The Wourld" not in readme or "canonical" not in readme.lower():
    issues.append("README.md missing The Wourld canonical wording")
if "The Wourld" not in comparison or "canonical base" not in comparison.lower():
    issues.append("STRONG_COMPARISON.md missing The Wourld canonical-base wording")

if issues:
    print("Validation failed:")
    for issue in issues:
        print("-", issue)
    raise SystemExit(1)

print(f"Validation passed: {len(FILES)} Lua files and {len(DOCS)} docs checked")
print("- no pack loader labels")
print("- no blocked public-chat APIs")
print("- no absolute local workspace paths")
print("- no ': and' / ': or' method-call patterns")
print("- The Wourld canonical wording present")
