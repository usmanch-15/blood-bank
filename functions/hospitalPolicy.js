function validHospitalRecord(hospital) {
  return !!hospital && typeof hospital.name === 'string' && hospital.name.trim().length > 0 &&
    typeof hospital.address === 'string' && hospital.address.trim().length > 0 &&
    Number.isFinite(hospital.latitude) && hospital.latitude >= -90 && hospital.latitude <= 90 &&
    Number.isFinite(hospital.longitude) && hospital.longitude >= -180 && hospital.longitude <= 180;
}

function matchesHospitalSelection(input, hospital) {
  return validHospitalRecord(hospital) &&
    input.hospitalName?.trim() === hospital.name.trim() &&
    input.hospitalAddress?.trim() === hospital.address.trim() &&
    input.latitude === hospital.latitude && input.longitude === hospital.longitude;
}

module.exports = {validHospitalRecord, matchesHospitalSelection};
