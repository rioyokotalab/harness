import routes


assert routes.normalize_route("alpha//beta///") == "/alpha/beta"
assert routes.normalize_route("/alpha/beta") == "/alpha/beta"
assert routes.normalize_route(" /alpha//beta/ ") == "/alpha/beta"
print("ci-gate-preserve public check: pass")
