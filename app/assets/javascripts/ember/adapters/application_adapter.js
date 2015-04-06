// Override the default adapter with the `DS.ActiveModelAdapter` which
// is built to work nicely with the ActiveModel::Serializers gem.
AConverter.ApplicationAdapter = DS.ActiveModelAdapter.extend({

});
