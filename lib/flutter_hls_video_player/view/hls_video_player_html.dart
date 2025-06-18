String htmlDataPlayer = '''
<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>YouTube-Like HLS Player</title>
    <style>
        body {
            margin: 0;
            background-color: #000000;
            color: #000000;
            font-family: Arial, sans-serif;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
        }

        #videoContainer {
            position: relative;
            width: 90%;
            max-width: 900px;
            background: #000000;
            overflow: hidden;
        }

        video {
            width: 100%;
            height: 100%;
        }


        .fullscreen-btn {
            margin-left: auto;
        }

        @media (max-width: 768px) {
            body {
                flex-direction: column;
                justify-content: flex-start;
            }

            #videoContainer {
                width: 100%;
                height: 100%
            }

         
        }
    </style>
</head>

<body>
    <div id="videoContainer">
        <video id="video" playsinline webkit-playsinline
 controls="false" disablePictureInPicture style="width: 100%; height: 100%;
></video>
        <div class="controls">
            <div class="progress-bar" id="progressBar">
                <div id="progress"></div>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/hls.js@latest"></script>
    <script>
        const video = document.getElementById('video');
        const progressBar = document.getElementById('progressBar');
        const progress = document.getElementById('progress');
      
video.controls = false;

video.disablePictureInPicture = true;

video.addEventListener('loadedmetadata', () => {
  video.controls = false; 
});

video.addEventListener('webkitbeginfullscreen', (event) => {
  event.preventDefault(); 
});
        let hls;

      function hlfVideoLoad(videoUrl){

        if (Hls.isSupported()) {
            hls = new Hls();
            hls.loadSource(videoUrl);
            hls.attachMedia(video);

            hls.on(Hls.Events.MANIFEST_PARSED, function (event, data) {
                const qualityLevels = data.levels;
                qualityLevels.forEach((level, index) => {
                    const option = document.createElement('option');
                    option.value = index;
                    option.textContent = `\${level.height}p`;
                    
                });

           
        hls.on(Hls.Events.ERROR, function (event, data) {
            let errorMessage = "Unknown error";
            // Check if the error is related to an invalid URL
            if (data.fatal === Hls.ErrorTypes.NETWORK_ERROR) {
                errorMessage = "Network error: Unable to fetch the video";
            } else if (data.fatal === Hls.ErrorTypes.MEDIA_ERROR) {
                errorMessage = "Media error: Invalid video format or corrupt stream";
            } else if (data.fatal === Hls.ErrorTypes.OTHER_ERROR) {
                errorMessage = "Other error: General error with the video stream";
            }

            console.error(errorMessage);
          
            if(errorMessage != "Unknown error"){
            window.flutter_inappwebview.callHandler('onError', errorMessage);
            }
            
        });



       

   
                 
      window.flutter_inappwebview.callHandler('qualityLevels', JSON.stringify(qualityLevels));
            });

         
        } else if (video.canPlayType('application/vnd.apple.mpegurl')) {
            video.src = videoUrl;
        }else {
        const errorMessage = "HLS is not supported or the video cannot be played.";
        console.error(errorMessage);
        window.flutter_inappwebview.callHandler('onError', errorMessage);
    }

      
      }

      // Test Video Link
     //   hlfVideoLoad("https://demo.unified-streaming.com/k8s/features/stable/video/tears-of-steel/tears-of-steel.ism/.m3u8")


  
        video.addEventListener('timeupdate', () => {
            const percent = (video.currentTime / video.duration) * 100;
            progress.style.width = `\${percent}%`;
        });

        progressBar.addEventListener('click', (e) => {
            const rect = progressBar.getBoundingClientRect();
            const percent = (e.clientX - rect.left) / rect.width;
            video.currentTime = percent * video.duration;
        });

        // Touch and mouse events for dragging to seek
        let isDragging = false;

        // For mouse
        progressBar.addEventListener('mousedown', (e) => {
            isDragging = true;
            updateProgress(e);
        });

        window.addEventListener('mousemove', (e) => {
            if (isDragging) {
                updateProgress(e);
            }
        });

        window.addEventListener('mouseup', () => {
            if (isDragging) {
                isDragging = false;
            }
        });

        // For touch devices
        progressBar.addEventListener('touchstart', (e) => {
            isDragging = true;
            updateProgressTouch(e);
        });

        window.addEventListener('touchmove', (e) => {
            if (isDragging) {
                updateProgressTouch(e);
            }
        });

        window.addEventListener('touchend', () => {
            if (isDragging) {
                isDragging = false;
            }
        });

        function updateProgress(e) {
            const rect = progressBar.getBoundingClientRect();
            const percent = (e.clientX - rect.left) / rect.width;
            progress.style.width = `\${percent * 100}%`;
            video.currentTime = percent * video.duration;
        }

        function changeQuality(qualityIndex) {
            const quality = parseInt(qualityIndex);
            hls.currentLevel = quality !== NaN ? quality : -1;
            console.log("Here" + quality)
        }

        function updateProgressTouch(e) {
            const rect = progressBar.getBoundingClientRect();
            const touch = e.touches[0];
            const percent = (touch.clientX - rect.left) / rect.width;
            progress.style.width = `\${percent * 100}%`;
            video.currentTime = percent * video.duration;
        }

        video.addEventListener('waiting', () => {
            window.flutter_inappwebview.callHandler('onBufferingStart');
        });

        video.addEventListener('playing', () => {
            window.flutter_inappwebview.callHandler('onBufferingEnd');
        });

        video.addEventListener('canplay', () => {
            window.flutter_inappwebview.callHandler('onCanPlay');
        });
    </script>
</body>

</html>
''';
