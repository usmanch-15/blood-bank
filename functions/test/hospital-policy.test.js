const test = require('node:test');
const assert = require('node:assert/strict');
const {validHospitalRecord, matchesHospitalSelection} = require('../hospitalPolicy');

const hospital = {name: 'Verified Hospital', address: 'Main Area', latitude: 31.52, longitude: 74.35};
const input = {...hospital, hospitalId: 'h1', hospitalName: hospital.name, hospitalAddress: hospital.address};

test('accepts a complete hospital record', () => assert.equal(validHospitalRecord(hospital), true));
test('rejects missing address or coordinates', () => {
  assert.equal(validHospitalRecord({...hospital, address: ''}), false);
  assert.equal(validHospitalRecord({...hospital, latitude: null}), false);
  assert.equal(validHospitalRecord({...hospital, longitude: 181}), false);
});
test('accepts only an exact identity and location match', () => {
  assert.equal(matchesHospitalSelection(input, hospital), true);
  assert.equal(matchesHospitalSelection({...input, hospitalName: 'Other Hospital'}, hospital), false);
  assert.equal(matchesHospitalSelection({...input, latitude: 31.53}, hospital), false);
  assert.equal(matchesHospitalSelection({...input, hospitalAddress: 'Other Area'}, hospital), false);
});
