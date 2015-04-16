var playerServices = angular.module('playerServices', []);

playerServices.factory('player', ['audio', '$rootScope', 'playlistService', 'Playlist', '$http', function(audio, $rootScope, playlistService, Playlist) {
    var player = {
        playlist_count: 0,
        current_track: 0,
        current: null,
        progress: 0,
        playing: false,
        title: "None",
        playlist_files: [],

        play: function(audiofile) {
            if(audiofile == null) {
                player.findFirst();
            }
            if (player.playing) {
                player.stop();
            }
            if ((!player.playing) && (player.current != null) && (player.current_track == audiofile.track_id)) {
                audio.play();
                player.playing = true;
            }

            if ((player.current == null && audiofile) || (audiofile && (player.current_track != audiofile.track_id))) {
                var url = audiofile.filepath;
                player.current = audiofile;
                audio.src = url;
                audio.play();
                player.current_track = audiofile.track_id;
                player.playing = true;
            }
        },
        pause: function() {
            if (player.playing) {
                audio.pause();
                player.playing = false;
            } else {
                audio.play();
                player.playing = true;
            }
        },
        stop: function() {
            if (player.playing) {
                audio.pause();
                player.playing = false;
                player.current = null;
            }
        },
        prev: function(){
            player.play(player.playlist_files[player.current_track - 2]);
        },
        next: function(){
            player.play(player.playlist_files[player.current_track]);
        },
        findFirst: function() {
            player.play(player.playlist_files[0]);
        },
        playerTime: function(timeline){
            var divisor_for_minutes = timeline % (60 * 60);
            var minutes = Math.floor(divisor_for_minutes / 60);

            var divisor_for_seconds = divisor_for_minutes % 60;
            var seconds = Math.ceil(divisor_for_seconds);

            if(seconds == 60) {
                minutes += 1;
                seconds = 0;
            }
            seconds += '';
            minutes += '';

            if (minutes.length < 2) {
                minutes = '0' + minutes;
            }
            if (seconds.length < 2) {
                seconds = '0' + seconds;
            }

            return {'seconds': seconds, 'minutes': minutes}
        },
        currentTime: function() {
            return audio.currentTime;
        },
        currentDuration: function() {
            return parseInt(audio.duration);
        }
    };
    audio.addEventListener('timeupdate', function(evt) {
        $rootScope.$apply(function() {
            player.progress = player.currentTime();
            player.progress_percent = (player.progress / player.currentDuration()) * 100;
        });
    });
    audio.addEventListener('ended', function() {
        $rootScope.$apply(player.stop());
    });
    audio.addEventListener('canplay', function() {
        $rootScope.$apply(function() {
            player.ready = true;
        });
    });
    return player;
}]);

playerServices.factory('audio', ['$document', function($document) {
    var audio = $document[0].createElement('audio');

    return audio;
}]);

playerServices.factory('Playlist', ['$resource', function($resource) {
    return $resource('/playlists/:id', {id: '@id'},{
        update: {
            method: 'PUT'
        }
    });
}]);

playerServices.service('playlistService', ['$http', '$q', function($http, $q) {
    var playlistFiles = function(playlist_id) {
        var deferred = $q.defer();
        $http({
            method: 'GET',
            url: '/playlists/' + playlist_id
        }).success(function (data) {
            deferred.resolve(data);
        });

        return deferred.promise;
    };

    var audiosList = function(){
        return $http({
            method: 'GET',
            url: '/audios'
        }).success(function (data) {
            return data;
        });
    };

    var audioData = function(collection) {
        var list = [];
        var id = 1;

        angular.forEach(collection, function(audio){
            list.push({
                track_id: id,
                filename: audio.filename,
                filepath: audio.filepath,
                title:audio.title,
                duration: audio.duration
            });
            id = id + 1
        });

        return list;
    };

    return {
        audioFiles: function() {return audiosList() },
        getAudioData: function(collection) { return audioData(collection) }
    };
}]);