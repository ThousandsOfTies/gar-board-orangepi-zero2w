import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]

class BoardProfiles(unittest.TestCase):
    def test_profiles_are_self_contained_and_resources_are_consistent(self):
        board = json.loads((ROOT / 'board.json').read_text())
        self.assertEqual(1, board['schema_version'])
        for relative in board['profiles'].values():
            profile = json.loads((ROOT / relative).read_text())
            self.assertEqual(board['id'], profile['board'])
            self.assertEqual(profile['architecture'], profile['identity']['architecture'])
            self.assertIn(profile['startup']['init'], ('busybox', 'systemd'))
            for gpio in profile['gpio']:
                self.assertEqual(set(gpio['lines']), {int(line) for line in gpio['line_pins']})
                self.assertEqual(len(gpio['lines']), len(set(gpio['line_pins'].values())))
            for spi in profile['spi']:
                self.assertEqual(spi['device'], f"/dev/spidev{spi['bus']}.{spi['chip_select']}")
                self.assertGreater(spi['max_speed_hz'], 0)
            overlay = profile['preparation'].get('overlay')
            if overlay: self.assertTrue((ROOT / overlay).is_file())

    def test_optional_i2c_routing_does_not_claim_existing_gpio_or_spi_pins(self):
        board=json.loads((ROOT/'board.json').read_text())
        for relative in board['profiles'].values():
            profile=json.loads((ROOT/relative).read_text())
            used={pin for gpio in profile['gpio'] for pin in gpio['line_pins'].values()}
            used.update(pin for spi in profile['spi'] for pin in spi['pins'].values())
            for bus in profile.get('i2c',[]):
                self.assertTrue(used.isdisjoint(bus['pins'].values()))
                self.assertEqual(bus['device'],f"/dev/i2c-{bus['bus']}")
            for resource in profile['preparation'].get('resource_overlays',[]):
                self.assertTrue((ROOT/resource['overlay']).is_file())

if __name__ == '__main__': unittest.main()
