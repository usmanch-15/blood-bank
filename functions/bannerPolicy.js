const ACTIONS = ['requests', 'profile', 'history'];
function validateBanner(d) {
  const text = (v, max) => typeof v === 'string' && v.trim().length > 0 && v.trim().length <= max;
  for (const locale of ['en', 'ur']) {
    if (!text(d[locale]?.title, 80) || !text(d[locale]?.description, 240) || !text(d[locale]?.button, 40)) throw new Error('Both languages need a title, description and button label.');
  }
  if (!ACTIONS.includes(d.action) || typeof d.active !== 'boolean' || !Number.isInteger(d.priority) || d.priority < 0 || d.priority > 100) throw new Error('Invalid action, status or priority.');
  if (!Number.isFinite(d.startAt) || !Number.isFinite(d.endAt) || d.endAt <= d.startAt) throw new Error('End date must be after the start date.');
  if (d.imageUrl && (typeof d.imageUrl !== 'string' || d.imageUrl.length > 2048 || !/^https:\/\//.test(d.imageUrl))) throw new Error('Use an HTTPS image URL.');
  return {en: d.en, ur: d.ur, action: d.action, active: d.active, priority: d.priority, startAt: d.startAt, endAt: d.endAt, imageUrl: d.imageUrl || '', audience: 'donor'};
}
function visibleBanner(b, now) { return b.active === true && b.audience === 'donor' && b.startAt <= now && b.endAt > now; }
module.exports = {validateBanner, visibleBanner};
