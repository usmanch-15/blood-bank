// Run only against the local Flutter web-server and demo Firebase emulators.
const {chromium} = require('playwright');
const fs = require('node:fs');
const path = require('node:path');
const artifacts = path.resolve(__dirname, '../../audit-artifacts');
fs.mkdirSync(artifacts, {recursive:true});
async function run() {
  process.env.FIRESTORE_EMULATOR_HOST='127.0.0.1:8080';
  process.env.FIREBASE_AUTH_EMULATOR_HOST='127.0.0.1:9099';
  process.env.FIREBASE_STORAGE_EMULATOR_HOST='127.0.0.1:9199';
  const admin = require('../firebaseAdmin');
  admin.initializeApp({projectId:'demo-blood-bank',storageBucket:'demo-blood-bank.appspot.com'});
  const role = process.argv[2] || 'donor';
  if (!['donor','receiver','admin'].includes(role)) throw Error('Invalid demo role');
  for (const type of ['donor','receiver','admin']) {
    const uid=`browser-${type}`, email=`${uid}@example.test`;
    try { await admin.auth().createUser({uid,email,password:'DemoAudit!123',emailVerified:true}); }
    catch (e) { if (e.code !== 'auth/uid-already-exists' && e.code !== 'auth/email-already-exists') throw e; }
    await admin.firestore().doc(`users/${uid}`).set({uid,email,name:`Audit ${type}`,role:type,
      status:'approved',bloodGroup:'O+',isDonor:type==='donor',isReceiver:type==='receiver',
      isAvailable:type==='donor',locationSharingEnabled:type==='donor',latitude:type==='donor'?31:null,
      longitude:type==='donor'?74:null,location:'Audit area',rewardPoints:0,isEligible:true,
      lastDonationDate:null,createdAt:admin.firestore.Timestamp.now(),profileImageUrl:null});
    await admin.firestore().doc(`users/${uid}/private/contact`).set({phoneNumber:'+923001234567'});
  }
  const browser = await chromium.launch({channel:'chrome',headless:true,args:['--enable-unsafe-swiftshader']});
  try {
    const page = await browser.newPage({viewport:{width:390,height:844}});
    const errors = [];
    page.on('pageerror',error=>errors.push(error.message));
    page.on('requestfailed',request=>errors.push(`${request.url().split('?')[0]}: ${request.failure()?.errorText}`));
    page.on('console',message=> { if(message.type()==='error') errors.push(message.text()); });
    const url = process.argv[3] || 'http://localhost:7357';
    if (!['localhost','127.0.0.1'].includes(new URL(url).hostname)) throw Error('Use only the local audit web server.');
    await page.goto(url, {waitUntil:'domcontentloaded'});
    try {
      await page.locator('flt-semantics-placeholder').waitFor({timeout:45000});
      await page.locator('flt-semantics-placeholder').evaluate(element=>element.click());
    } catch (_) {
      console.log('Startup DOM', await page.locator('body').innerText());
      console.log('Startup errors', JSON.stringify(errors));
      console.log('Startup markup', (await page.locator('body').innerHTML()).slice(0,2500));
      await page.screenshot({path:path.join(artifacts,`startup-${role}.png`)});
    }
    await page.waitForTimeout(5000);
    await page.locator('input').nth(0).click({force:true});
    await page.keyboard.type(`browser-${role}@example.test`,{delay:15});
    await page.keyboard.press('Tab');
    await page.keyboard.type('DemoAudit!123',{delay:15});
    await page.getByRole('button',{name:'Login',exact:true}).click();
    await page.waitForTimeout(4000);
    await page.screenshot({path:path.join(artifacts,'login.png')});
    console.log('TEXT',await page.locator('body').innerText());
    console.log('INPUTS',await page.locator('input').evaluateAll(elements=>elements.map(e=>({placeholder:e.placeholder,label:e.getAttribute('aria-label'),type:e.type}))));
    fs.writeFileSync(path.join(artifacts,'browser-errors.json'),JSON.stringify(errors,null,2));
    console.log('ERRORS',JSON.stringify(errors));
  } finally { await browser.close(); }
}
run().catch(error=>{console.error(error);process.exitCode=1;});
