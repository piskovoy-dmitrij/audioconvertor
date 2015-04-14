AConverter.Router.map(function() {
    this.route('/demo');
});

AConverter.PlaylistsRoute = Ember.Route.extend({
    model: function() {
        var playlistObjects = [];
        Ember.$.getJSON('http://localhost:3000/playlists', function(artists) {
            artists.forEach(function(data) {
                playlistObjects.pushObject(AConverter.Playlist.createRecord(data));
            });
        });
        return playlistObjects;
    }
});