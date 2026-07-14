import hashlib

payload = b"harness-llm-hpc-smoke"
assert hashlib.sha256(payload).hexdigest() == (
    "176123ce3e2bbde7a3933c7e02fd512485965a0e24f5dac15da173092256c1bd"
)
print("python_stdlib=pass")
