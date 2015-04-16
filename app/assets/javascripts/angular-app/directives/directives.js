var playerDirectives = angular.module('playerDirectives', []);

playerDirectives.directive('audioLink', function() {
    return {
        restrict: 'EA',
        require: ['^ngModel'],
        replace: true,
        scope: {
            ngModel: '=',
            player: '='
        },
        templateUrl: 'audioListItem.html',
        link: function(scope) {
            scope.duration = 30;
        }
    }
});

playerDirectives.directive('playerView', ['audio', function(audio){
    return {
        restrict: 'EA',
        require: ['^ngModel'],
        scope: {
            ngModel: '='
        },
        templateUrl: 'playerView.html',
        link: function(scope) {
            scope.playlist_count = 0;
            scope.$watch('ngModel.current', function(newVal) {
                if (newVal) {
                    scope.playing = true;
                    scope.duration = parseInt(scope.ngModel.current.duration);
                    scope.title = scope.ngModel.current.title;
                    scope.secondsProgress = 0;
                    scope.percentComplete = 0;
                    scope.current_track = scope.ngModel.current_track;
                    scope.playlist_count = scope.ngModel.playlist_count;
                    scope.playing = scope.ngModel.playing;

                    var updateClock = function() {
                        if (scope.secondsProgress >= scope.duration || !scope.playing) {
                            scope.playing = false;
                            clearInterval(timer);
                        } else {

                            var currentTime = scope.ngModel.playerTime(scope.secondsProgress);
                            var durationTime = scope.ngModel.playerTime(scope.duration);

                            scope.secondsProgress = scope.ngModel.currentTime();
                            scope.percentComplete = scope.secondsProgress / scope.duration;

                            scope.minutesCurrent = currentTime['minutes'];
                            scope.secondsCurrent = currentTime['seconds'];
                            scope.minutesDuration = durationTime['minutes'];
                            scope.secondsDuration = durationTime['seconds'];
                        }
                    };
                    var timer = setInterval(function() { scope.$apply(updateClock); }, 500);
                    updateClock();
                }
            });
            scope.play = function(){
                scope.ngModel.play(scope.ngModel.current);
            };
            scope.pause = function(){
                scope.ngModel.pause();
            };
            scope.stop = function() {
                scope.ngModel.stop();
                scope.ngModel.current = null;
                scope.playing = false;
                scope.secondsProgress = 0;
                scope.title = "None";
            };
            scope.next = function() {
                scope.ngModel.next();
            };
            scope.prev = function() {
                scope.ngModel.prev();
            };
            scope.playing = false;
            scope.audio = audio;

            scope.minutesCurrent = '00';
            scope.secondsCurrent = '00';
            scope.minutesDuration = '00';
            scope.secondsDuration = '00';
        }
    };
}]);