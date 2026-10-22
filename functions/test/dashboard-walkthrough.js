const {chromium}=require('playwright');
const fs=require('node:fs');
const path=require('node:path');
const artifacts=path.resolve(__dirname,'../../audit-artifacts/dashboard');fs.mkdirSync(artifacts,{recursive:true});
async function main(){
  process.env.FIRESTORE_EMULATOR_HOST='127.0.0.1:8080';process.env.FIREBASE_AUTH_EMULATOR_HOST='127.0.0.1:9099';
  const admin=require('../firebaseAdmin');admin.initializeApp({projectId:'demo-blood-bank'});
  const db=admin.firestore();
  for(const role of ['donor','receiver','admin']){
    const uid=`preview-${role}`;
    try{await admin.auth().createUser({uid,email:`${uid}@example.test`,password:'Preview!12345',emailVerified:true});}catch(e){if(!['auth/uid-already-exists','auth/email-already-exists'].includes(e.code))throw e;}
    await admin.auth().updateUser(uid,{password:'Preview!12345'});
    await db.doc(`users/${uid}`).set({uid,email:`${uid}@example.test`,name:'Usman',role,status:'approved',bloodGroup:'O+',isDonor:role==='donor',isReceiver:role==='receiver',isAvailable:true,locationSharingEnabled:true,latitude:31,longitude:74,rewardPoints:50,isEligible:true,lastDonationDate:null,createdAt:admin.firestore.Timestamp.now()});
  }
  const base={requesterId:'preview-receiver',bloodGroup:'O+',quantity:2,remainingUnits:2,donatedUnits:0,hospitalName:'City Hospital',hospitalAddress:'Lahore',latitude:31.01,longitude:74.01,urgency:'urgent',status:'pending',requiredBy:admin.firestore.Timestamp.fromMillis(Date.now()+86400000),createdAt:admin.firestore.Timestamp.now(),reviewStatus:'approved'};
  await db.doc('blood_requests/preview-nearby').set(base);
  await db.doc('blood_requests/preview-invite').set({...base,hospitalName:'Community Hospital'});
  await db.doc('blood_requests/preview-invite/invites/preview-donor').set({donorId:'preview-donor',requesterId:'preview-receiver',status:'invited',createdAt:admin.firestore.Timestamp.now()});
  await db.doc('blood_requests/preview-active').set({...base,hospitalName:'General Hospital',status:'accepted',acceptedDonorIds:['preview-donor'],participantIds:['preview-receiver','preview-donor'],commitments:{'preview-donor':{status:'accepted',name:'Usman'}}});
  await db.doc('awareness_banners/preview-banner').set({en:{title:'Your next act of kindness',description:'Keep your availability up to date and explore requests near you.',button:'Explore requests'},ur:{title:'آپ کی مدد کا اگلا قدم',description:'اپنی دستیابی تازہ رکھیں اور قریبی درخواستیں دیکھیں۔',button:'درخواستیں دیکھیں'},action:'requests',audience:'donor',active:true,priority:10,startAt:Date.now()-10000,endAt:Date.now()+86400000,revision:1,updatedAt:admin.firestore.Timestamp.now()});
  const browser=await chromium.launch({channel:'chrome',headless:true,args:['--enable-unsafe-swiftshader']});
  try{
    for(const role of (process.argv[2] ? [process.argv[2]] : ['donor','receiver'])){
      if(!['donor','receiver','admin'].includes(role))throw Error('Invalid preview role');
      const context=await browser.newContext({viewport:{width:role==='admin' ? 1280 : 390,height:844}});
      await context.addInitScript(()=>localStorage.setItem('flutter.theme_mode',JSON.stringify('dark')));
      const page=await context.newPage();const errors=[];page.on('pageerror',e=>errors.push(e.message));
      await page.goto('http://127.0.0.1:7357',{waitUntil:'domcontentloaded'});
      await page.locator('flt-semantics-placeholder').evaluate(el=>el.click(),{timeout:60000}).catch(()=>{});
      await page.locator('input').first().waitFor({timeout:60000});
      await page.locator('input').nth(0).click({force:true});
      await page.keyboard.type(`preview-${role}@example.test`,{delay:25});
      await page.locator('input').nth(1).click({force:true});
      await page.keyboard.press('Control+A');
      await page.keyboard.type('Preview!12345',{delay:25});
      await page.waitForTimeout(500);
      if(await page.locator('input').nth(1).inputValue()!=='Preview!12345')throw Error('Password input did not settle');
      await page.getByRole('button',{name:'Login',exact:true}).click();
      await page.waitForTimeout(3000);
      console.log(role,'AFTER LOGIN',await page.locator('body').innerText());
      if(role==='admin'){
        await page.getByText('Awareness Banners',{exact:true}).click();
        await page.getByRole('button',{name:'Create banner',exact:true}).click();
        await page.waitForTimeout(1500);
        await page.addStyleTag({content:'.firebase-emulator-warning {display:none !important}'});
        await page.screenshot({path:path.join(artifacts,'admin-banner-editor.png')});
        if(errors.length)throw Error(errors.join('\n'));
        await context.close();continue;
      }
      const roleButton=page.getByRole('button',{name:role==='donor' ? /donor/i : /receiver/i});
      const ready=role==='donor' ? page.waitForResponse(r=>r.url().endsWith('/donorInvitations') && r.request().method()==='POST',{timeout:45000}) : Promise.resolve();
      await roleButton.first().waitFor({timeout:15000});
      await roleButton.first().click();
      await ready;
      await page.waitForTimeout(2000);
      await page.addStyleTag({content:'.firebase-emulator-warning {display:none !important}'});
      await page.screenshot({path:path.join(artifacts,`${role}-dark.png`)});
      console.log(role,'DASHBOARD',await page.locator('body').innerText());
      console.log(role,'ERRORS',errors);
      await page.mouse.move(200,600);await page.mouse.wheel(0,500);await page.waitForTimeout(6000);
      await page.screenshot({path:path.join(artifacts,`${role}-dark-lower.png`)});
      if(role==='donor'){
        await page.getByRole('button',{name:'Explore requests',exact:true}).click();
        await page.waitForTimeout(2000);
        await page.screenshot({path:path.join(artifacts,'blood-requests-tabs.png')});
        console.log('REQUEST TABS',await page.locator('body').innerText());
      }
      if(errors.length)throw Error(errors.join('\n'));
      await context.close();
    }
  }finally{await browser.close();await admin.app().delete();}
}
main().catch(e=>{console.error(e);process.exitCode=1;});
