import Foundation

public enum YouTubePlayerBridgeMessage: Equatable, Sendable {
    case ready
    case segmentFinished(endTime: Double)
    case timeUpdate(currentTime: Double)
    case stateChange(state: Int)
    case unknown

    public init(dictionary: [String: Any]) {
        guard let type = dictionary["type"] as? String else {
            self = .unknown
            return
        }
        switch type {
        case "ready":
            self = .ready
        case "segmentFinished":
            let endTime = Self.parseDouble(dictionary["endTime"]) ?? 0.0
            self = .segmentFinished(endTime: endTime)
        case "timeUpdate":
            let currentTime = Self.parseDouble(dictionary["currentTime"]) ?? 0.0
            self = .timeUpdate(currentTime: currentTime)
        case "state":
            let state = Self.parseInt(dictionary["state"]) ?? -1
            self = .stateChange(state: state)
        default:
            self = .unknown
        }
    }

    private static func parseDouble(_ value: Any?) -> Double? {
        if let doubleVal = value as? Double {
            return doubleVal
        }
        if let intVal = value as? Int {
            return Double(intVal)
        }
        if let num = value as? NSNumber {
            return num.doubleValue
        }
        return nil
    }

    private static func parseInt(_ value: Any?) -> Int? {
        if let intVal = value as? Int {
            return intVal
        }
        if let num = value as? NSNumber {
            return num.intValue
        }
        return nil
    }
}

public enum YouTubePlayerBridgeScript {
    public static func htmlTemplate(videoId: String) -> String {
        """
        <!DOCTYPE html>
        <html>
        <head>
          <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
          <style>
            body, html { margin: 0; padding: 0; width: 100%; height: 100%; background: #000; overflow: hidden; }
            #player { width: 100%; height: 100%; pointer-events: none; }
          </style>
        </head>
        <body>
          <div id="player"></div>
          <script src="https://www.youtube.com/iframe_api"></script>
          <script>
            var player, targetEndTime = 0, isMonitoring = false, hasSeeked = false;
            function onYouTubeIframeAPIReady() {
              player = new YT.Player('player', {
                videoId: '\(videoId)',
                playerVars: {
                  'playsinline': 1,
                  'controls': 0,
                  'rel': 0,
                  'modestbranding': 1,
                  'disablekb': 1,
                  'fs': 0
                },
                events: {
                  'onReady': function() {
                    window.webkit.messageHandlers.shadowingBridge.postMessage({ type: 'ready' });
                  },
                  'onStateChange': function(e) {
                    window.webkit.messageHandlers.shadowingBridge.postMessage({ type: 'state', state: e.data });
                  }
                }
              });
            }

            function playSegment(start, end, rate) {
              targetEndTime = end;
              hasSeeked = false;
              if (!player) return;
              if (rate && player.setPlaybackRate) player.setPlaybackRate(rate);
              player.seekTo(start, true);
              player.playVideo();
              isMonitoring = true;
              requestAnimationFrame(checkTime);
            }

            function pauseVideo() {
              isMonitoring = false;
              if (player && player.pauseVideo) player.pauseVideo();
            }

            function replaySegment(start, end, rate) {
              playSegment(start, end, rate);
            }

            function checkTime() {
              if (!isMonitoring || !player || !player.getCurrentTime) return;
              var current = player.getCurrentTime();
              if (!hasSeeked) {
                if (current < targetEndTime) {
                  hasSeeked = true;
                }
              }
              if (hasSeeked && current >= targetEndTime) {
                player.pauseVideo();
                isMonitoring = false;
                window.webkit.messageHandlers.shadowingBridge.postMessage({
                  type: 'segmentFinished',
                  endTime: targetEndTime
                });
              } else {
                requestAnimationFrame(checkTime);
              }
            }
          </script>
        </body>
        </html>
        """
    }
}
