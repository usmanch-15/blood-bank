// Read-only inventory. Never enables APIs, billing, secrets or deployment.
const fs = require('node:fs');
const path = require('node:path');
async function main() {
  const args=process.argv.slice(2), at=args.indexOf('--project');
  const project=at>=0?args[at+1]:'demo-blood-bank';
  if(!/^[a-z][a-z0-9-]{4,62}$/.test(project || '')) throw Error('Invalid project ID');
  process.env.GCLOUD_PROJECT=project;
  const source=require('../index');
  const exported=Object.keys(source).sort();
  const lib=path.resolve(__dirname,'../../lib');
  const calls=new Set();
  function scan(dir){for(const entry of fs.readdirSync(dir,{withFileTypes:true})){
    const file=path.join(dir,entry.name);
    if(entry.isDirectory()) scan(file);
    else if(file.endsWith('.dart')) for(const m of fs.readFileSync(file,'utf8').matchAll(/(?:WorkflowService\.call|httpsCallable|_call)\(\s*['"]([^'"]+)['"]/g)) calls.add(m[1]);
  }}
  scan(lib);
  const dynamic=['participantRequests','donorInvitations','discoverRequests','getRequest','acceptDonation','declineRequest','updateAssignment','closeRequest','confirmDonation'];
  dynamic.forEach(name=>calls.add(name));
  const missing=[...calls].filter(name=>!exported.includes(name));
  console.log(JSON.stringify({project,region:'us-central1',runtime:process.version,declaredRuntime:'22',exported,clientCalls:[...calls].sort(),missing,
    secretBindings:exported.filter(k=>source[k].__endpoint?.secretEnvironmentVariables?.length).map(k=>({function:k,secrets:source[k].__endpoint.secretEnvironmentVariables.map(s=>s.key)}))},null,2));
  if(missing.length) process.exitCode=1;
  if(!args.includes('--live')) return;
  const cli='../node_modules/firebase-tools/lib/';
  const account=require(cli+'auth').getGlobalDefaultAccount();
  await require(cli+'requireAuth').requireAuth({...account,project,nonInteractive:true});
  const {Client}=require(cli+'apiv2');
  const blockers=[];
  async function read(label,origin,url,projectBody){
    try {const result=await new Client({urlPrefix:origin}).get(url,{skipLog:{resBody:true}});
      const summary=projectBody(result.body);
      if(summary.billingEnabled===false || (summary.state && summary.state!=='ENABLED') || summary.enabledVersions===0 || summary.nextPage) blockers.push(label);
      console.log(JSON.stringify({check:label,...summary}));
    } catch(e) {blockers.push(label);console.log(JSON.stringify({check:label,errorStatus:e.status || e.context?.response?.statusCode || e.context?.body?.error?.status || 'unavailable'}));}
  }
  await read('billing','https://cloudbilling.googleapis.com',`/v1/projects/${project}/billingInfo`,b=>({billingEnabled:b.billingEnabled===true}));
  await read('functions-v2','https://cloudfunctions.googleapis.com',`/v2/projects/${project}/locations/-/functions`,b=>({functions:(b.functions||[]).map(f=>f.name.split('/').slice(-3).join('/')),nextPage:!!b.nextPageToken}));
  await read('functions-v1','https://cloudfunctions.googleapis.com',`/v1/projects/${project}/locations/-/functions`,b=>({functions:(b.functions||[]).map(f=>f.name.split('/').slice(-3).join('/')),nextPage:!!b.nextPageToken}));
  for(const service of ['cloudfunctions','run','cloudbuild','artifactregistry','eventarc','pubsub','cloudscheduler','secretmanager','firestore','identitytoolkit','fcm','storage','firebasestorage']){
    await read(service,'https://serviceusage.googleapis.com',`/v1/projects/${project}/services/${service}.googleapis.com`,b=>({state:b.state}));
  }
  for(const secret of ['AGORA_APP_CERTIFICATE','TWILIO_AUTH_TOKEN']){
    await read(secret+'-metadata','https://secretmanager.googleapis.com',`/v1/projects/${project}/secrets/${secret}/versions`,b=>({enabledVersions:(b.versions||[]).filter(v=>v.state==='ENABLED').length}));
  }
  console.log(JSON.stringify({readiness:blockers.length?'blocked-or-unverified':'metadata-prerequisites-available',blockers}));
  if(blockers.length) process.exitCode=2;
}
main().catch(()=>{console.error('Preflight failed. Check local Firebase authentication/project access; no resources were changed.');process.exitCode=1;});
