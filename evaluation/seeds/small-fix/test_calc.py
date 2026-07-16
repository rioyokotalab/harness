import unittest

from calc import clamp


class ClampTests(unittest.TestCase):
    def test_inside(self):
        self.assertEqual(clamp(0.4), 0.4)

    def test_bounds(self):
        self.assertEqual(clamp(-2.0), 0.0)
        self.assertEqual(clamp(3.0), 1.0)

    def test_custom_bounds(self):
        self.assertEqual(clamp(7, 5, 6), 6)


if __name__ == "__main__":
    unittest.main()
