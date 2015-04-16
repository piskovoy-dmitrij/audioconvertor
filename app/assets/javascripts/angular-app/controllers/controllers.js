var audioControllers = angular.module('audioControllers', []);

audioControllers.controller('PlayerController', ['$scope', '$http', 'player', 'playlistService', 'Playlist', function($scope, $http, player, playlistService, Playlist) {
    $scope.playlists = Playlist.query();
    $scope.player = player;

    Playlist.query(function(result){
        //$scope.player = player;
        $scope.playlistData = result[0];
        $scope.playlist_files = result[0].files;
        player.playlist_files = playlistService.getAudioData(result[0].files);
        player.playlist_count = result[0].files.length;
    });

    $scope.play = function(id) {
        Playlist.get({id: id}, function(result){
            player.playlist_files = playlistService.getAudioData(result.files);
            player.playlist_count = result.files.length;
            player.play($scope.player.playlist_files[0]);
        });
    };

    $scope.delete = function(model) {
        $scope.player.stop();
        $scope.player.playlist_files = [];
        model.$delete();
    };
}]);

audioControllers.controller('PlaylistController', ['$scope', '$http', 'playlistService', 'Playlist', function($scope, $http, playlistService, Playlist){
    $scope.new_list = [];
    $scope.playlists = Playlist.query();

    var files = playlistService.audioFiles();
    files.then(function(result){
        $scope.audio_files = result.data;
    });

    $scope.submit = function(name) {
        Playlist.save({name: name, files: $scope.new_list});
        $scope.playlists = Playlist.query();
        $scope.new_list = [];
        $scope.name = "";
    };

    $scope.update = function(model) {
        console.log("playlist: ", model);
        console.log("updated: ", $scope.update_list);
    };

    $scope.delete = function(model) {
        model.$delete();
    };

    $scope.play = function(model) {

    }
}]);
