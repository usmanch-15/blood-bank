const {test} = require('node:test');
const assert = require('node:assert/strict');
const {active,eligible,compatible,INTERVAL_MS,POINTS,distanceKm,matchScore} = require('../donationPolicy');
test('matching rank is transparent: urgency outranks distance within documented score',()=>{
  assert.equal(matchScore('critical',10),390);
  assert.ok(matchScore('urgent',1) > matchScore('normal',1));
  assert.ok(matchScore('normal',1) > matchScore('normal',20));
});
const {radiusKm,inPakistan} = require('../searchPolicy');
test('all 64 blood compatibility pairs have the expected server policy',()=>{
  const expected = {'O-':['O-'], 'O+':['O-','O+'], 'A-':['O-','A-'],
    'A+':['O-','O+','A-','A+'], 'B-':['O-','B-'], 'B+':['O-','O+','B-','B+'],
    'AB-':['O-','A-','B-','AB-'], 'AB+':['O-','O+','A-','A+','B-','B+','AB-','AB+']};
  for(const recipient of Object.keys(expected)) for(const donor of Object.keys(expected)) {
    assert.equal(compatible(donor,recipient),expected[recipient].includes(donor),`${donor} -> ${recipient}`);
  }
});
test('search range defaults, clamps, rejects malformed input and Pakistan bounds',()=>{
  assert.equal(radiusKm(),5);
  for(const value of [5,10,25,50,100,250,500,1000]) assert.equal(radiusKm(value),value);
  assert.equal(radiusKm(2000),1000); assert.equal(radiusKm(1),5);
  for(const value of [NaN,Infinity,'100',{},[]]) assert.throws(()=>radiusKm(value));
  assert.ok(inPakistan(23.5,60.8)); assert.ok(inPakistan(37.1,77.9));
  for(const pair of [[23.49,74],[37.11,74],[31,60.79],[31,77.91],[NaN,74]]) assert.equal(inPakistan(...pair),false);
});
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
