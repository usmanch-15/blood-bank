// Legacy identifiers supplement missing entries, never override explicit revocation.
const activeStatuses = ['accepted', 'agreed', 'awaiting_confirmation'];
function assignments(r) {
  const result = {...(r.commitments || {})};
  const ids = [...(Array.isArray(r.acceptedDonorIds) ? r.acceptedDonorIds : []), r.acceptedDonorId];
  for (const id of ids) if (typeof id === 'string' && id && !Object.hasOwn(result, id)) {
    result[id] = {status:'accepted', name:'Assigned donor'};
  }
  return result;
}
function actionable(r) {
  const deadline = r?.requiredBy?.toMillis?.() ?? r?.requiredBy;
  return !!r && r.reviewStatus !== 'rejected' &&
    ['pending','accepted','partially_fulfilled'].includes(r.status) &&
    !(typeof deadline === 'number' && deadline > 0 && deadline <= Date.now());
}
function liveConversation(c, r, sender) {
  const ids = c?.participantIds;
  const donor = ids?.find(id => id !== r?.requesterId);
  return actionable(r) && Array.isArray(ids) && ids.length === 2 &&
    new Set(ids).size === 2 && ids.includes(sender) && ids.includes(r.requesterId) &&
    !(c.blockedUserIds || []).includes(sender) && activeStatuses.includes(assignments(r)[donor]?.status);
}
module.exports = {assignments, actionable, activeStatuses, liveConversation};
