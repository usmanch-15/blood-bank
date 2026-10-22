const {test} = require('node:test');
const assert = require('node:assert/strict');
const {validateBanner, visibleBanner} = require('../bannerPolicy');
const valid = () => ({en:{title:'Help nearby',description:'Review requests.',button:'Explore'},ur:{title:'مدد کریں',description:'درخواستیں دیکھیں',button:'دیکھیں'},action:'requests',active:true,priority:10,startAt:100,endAt:200});
test('campaigns require both languages, bounded priority, safe links and valid dates', () => {
  assert.equal(validateBanner(valid()).audience,'donor');
  for (const overrides of [{ur:{}},{priority:101},{startAt:200},{action:'external'},{imageUrl:'javascript:alert(1)'},{active:'true'}]) {
    assert.throws(() => validateBanner({...valid(),...overrides}));
  }
});
test('scheduled donor banners have inclusive start and exclusive expiry', () => {
  const b=validateBanner(valid());
  assert.equal(visibleBanner(b,99),false);
  assert.equal(visibleBanner(b,100),true);
  assert.equal(visibleBanner(b,199),true);
  assert.equal(visibleBanner(b,200),false);
  assert.equal(visibleBanner({...b,active:false},150),false);
  assert.equal(visibleBanner({...b,audience:'receiver'},150),false);
});
