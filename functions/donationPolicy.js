const GROUPS = {
  'A+': ['A+', 'A-', 'O+', 'O-'], 'A-': ['A-', 'O-'],
  'B+': ['B+', 'B-', 'O+', 'O-'], 'B-': ['B-', 'O-'],
  'AB+': ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'],
  'AB-': ['A-', 'B-', 'AB-', 'O-'], 'O+': ['O+', 'O-'], 'O-': ['O-'],
};
const INTERVAL_MS = 90 * 86400000;
const POINTS = 50;
const active = user => user?.status === 'approved';
const eligible = (donor, now) => !donor.lastDonationDate ||
  now - donor.lastDonationDate.toMillis() >= INTERVAL_MS;
const compatible = (donorGroup, recipientGroup) =>
  (GROUPS[recipientGroup] || []).includes(donorGroup);
function distanceKm(a, b, c, d) {
  const rad = x => x * Math.PI / 180;
  const h = Math.sin(rad(c-a)/2)**2 + Math.cos(rad(a))*Math.cos(rad(c))*Math.sin(rad(d-b)/2)**2;
  return 6371 * 2 * Math.asin(Math.sqrt(Math.min(1, h)));
}
module.exports = { GROUPS, INTERVAL_MS, POINTS, active, eligible, compatible, distanceKm };
