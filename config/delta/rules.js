export default [
  {
    match: {
      subject: {},
    },
    callback: {
      url: "http://resource/.mu/delta",
      method: "POST",
    },
    options: {
      resourceFormat: "v0.0.1",
      gracePeriod: 1000,
      foldEffectiveChanges: true,
      ignoreFromSelf: true,
    },
  },
  {
    match: {
      // we expect the full body to be sent in this case
      object: { value: "http://mu.semte.ch/vocabularies/push/Update" },
    },
    callback: {
      url: "http://polling-push-update/delta",
      method: "POST",
    },
    options: {
      resourceFormat: "v0.0.1",
      gracePeriod: 100,
      foldEffectiveChanges: false,
      ignoreFromSelf: false,
    },
  },
  {
    match: {

    },
    callback: {
      url: "http://push-update-resource-monitor/.mu/delta",
      method: "POST",
    },
    options: {
      resourceFormat: "v0.0.1",
      gracePeriod: 100,
      foldEffectiveChanges: false,
      ignoreFromSelf: false,
    },
  }
];
