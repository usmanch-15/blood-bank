const {test} = require('node:test');
const assert = require('node:assert/strict');
const {active,eligible,compatible,INTERVAL_MS,POINTS,distanceKm} = require('../donationPolicy');
test('only approved accounts are active',()=>{
  for(const status of ['pending','suspended','deleted','rejected',undefined]) assert.equal(active({status}),false);
  assert.equal(active({status:'approved'}),true);
});
test('eligibility enforces the exact 90 day boundary',()=>{
  const now=200*86400000;
  assert.equal(eligible({},now),true);
  assert.equal(eligible({lastDonationDate:{toMillis:()=>now-INTERVAL_MS+1}},now),false);
  assert.equal(eligible({lastDonationDate:{toMillis:()=>now-INTERVAL_MS}},now),true);
});
test('reward is fixed and compatible groups are validated',()=>{
  assert.equal(POINTS,50);
  assert.equal(compatible('O-','AB+'),true);
  assert.equal(compatible('AB+','O-'),false);
  assert.equal(compatible('X','A+'),false);
});
test('radius distinguishes 15 and 30 km and identical coordinates',()=>{
  assert.equal(distanceKm(31,74,31,74),0);
  const distance=distanceKm(31,74,31.18,74);
  assert.ok(distance>15 && distance<30);
});
const {isNotificationAllowed} = require('../notificationService');
require('node:test').test('notification aliases respect master, status and category preferences', () => {
  const assert = require('node:assert/strict');
  assert.equal(isNotificationAllowed({status:'approved',notificationPrefs:{rewardUpdates:false}},'donation_confirmed'),false);
  assert.equal(isNotificationAllowed({status:'approved',notificationPrefs:{sosAlerts:false}},'sos'),false);
  assert.equal(isNotificationAllowed({status:'approved',notificationsEnabled:false},'blood_request'),false);
  assert.equal(isNotificationAllowed({status:'suspended'},'general'),false);
  assert.equal(isNotificationAllowed({status:'approved'},'blood_request'),true);
});
