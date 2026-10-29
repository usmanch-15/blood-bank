import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { SOS_RADIUS_STEPS_KM, donationTimelineLabel } from '../src/workflows.js';

test('Worker schedules request expiry every 15 minutes', () => {
  const config = readFileSync(new URL('../wrangler.toml', import.meta.url), 'utf8');
  assert.match(config, /^\s*crons\s*=\s*\["\*\/15 \* \* \* \*"\]\s*$/m);
});

test('SOS matching tries only the configured radii in order', () => {
  assert.deepEqual(SOS_RADIUS_STEPS_KM, [5, 10, 25, 50]);
});

test('donation history labels preserve dispute and completion status', () => {
  assert.equal(donationTimelineLabel({ status: 'disputed' }), 'disputed');
  assert.equal(donationTimelineLabel({ disputed: true, status: 'completed' }), 'disputed');
  assert.equal(donationTimelineLabel({ status: 'cancelled' }), 'cancelled');
  assert.equal(donationTimelineLabel({ completedAt: {} }), 'completed');
  assert.equal(donationTimelineLabel({ status: 'accepted' }), 'accepted');
  assert.equal(donationTimelineLabel({}), 'proposed');
});
