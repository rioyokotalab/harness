import unittest

from formatter import normalize_title


class FormatterTests(unittest.TestCase):
    def test_whitespace_and_case(self):
        self.assertEqual(normalize_title("  My\tTitle\nHere "), "My Title Here")


if __name__ == "__main__":
    unittest.main()
