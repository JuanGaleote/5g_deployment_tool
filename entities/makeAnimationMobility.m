function [] = makeAnimationMobility(steps,siteviewer,connection)

% https://es.mathworks.com/help/matlab/import_export/convert-between-image-sequences-and-video.html

% Animation generation.
if connection
    % Video file initialization.
    outputVideo = VideoWriter(fullfile(pwd,'RxTxData.avi'));
    outputVideo.FrameRate = 0.3;
    open(outputVideo);

    % Frame source.
    imageNames = dir(fullfile(pwd,'Scenes','*.jpg'));
    [~,index] = sortrows({imageNames.date}.'); imageNames = imageNames(index); clear index;
    imageNames = {imageNames.name}';
    imageNames = imageNames((length(imageNames)-steps):length(imageNames));

    % Video creation.
    for i = 1:length(imageNames) 
       img = imread(fullfile(pwd,'Scenes',imageNames{i}));
       writeVideo(outputVideo,img);
    end
    close(outputVideo);
end
if siteviewer
    % Video file initialization.
    outputVideo2 = VideoWriter(fullfile(pwd,'SiteViewer.avi'));
    outputVideo2.FrameRate = 1;
    open(outputVideo2);

    % Frame source.
    imageNames2 = dir(fullfile(pwd,'SiteViewer','*.jpg'));
    [~,index] = sortrows({imageNames2.date}.'); imageNames2 = imageNames2(index); clear index;
    imageNames2 = {imageNames2.name}';
    imageNames2 = imageNames2((length(imageNames2)-steps):length(imageNames2));

    % Video creation.
    for i = 1:length(imageNames2)   
       img2 = imread(fullfile(pwd,'SiteViewer',imageNames2{i}));
       writeVideo(outputVideo2,img2)
    end
    close(outputVideo2);
end
end