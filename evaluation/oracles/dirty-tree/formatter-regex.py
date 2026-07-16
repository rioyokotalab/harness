import re


def normalize_title(text):
    return re.sub(r"\s+", " ", text).strip()
