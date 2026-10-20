const MIN_RADIUS_KM = 5;
const MAX_RADIUS_KM = 1000;
function radiusKm(value) {
  if (value == null) return MIN_RADIUS_KM;
  if (typeof value !== 'number' || !Number.isFinite(value)) throw new TypeError('Invalid radius.');
  return Math.min(MAX_RADIUS_KM, Math.max(MIN_RADIUS_KM, value));
}
const inPakistan = (lat, lng) => Number.isFinite(lat) && Number.isFinite(lng) &&
  lat >= 23.5 && lat <= 37.1 && lng >= 60.8 && lng <= 77.9;
module.exports = {MIN_RADIUS_KM, MAX_RADIUS_KM, radiusKm, inPakistan};
