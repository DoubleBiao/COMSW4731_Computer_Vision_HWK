function output_img = recognizeObjects(orig_img, labeled_img, obj_db)
feature_std = feature_extra(obj_db);
[db,out_img] = compute2DProperties(orig_img,labeled_img);
feature_test = feature_extra(db);
matchpair = [];
for i = 1:size(feature_std,1)
    for j = 1:size(feature_test,1)
        if feature_compare(feature_std(i,:),feature_test(j,:)) == 1
            matchpair = [matchpair;[i,j]];
        end
    end
end

fh1 = figure();
imshow(orig_img);

hold on
for i = 1:size(matchpair,1)
    object_indx = matchpair(i,2);
    x_mean = db(object_indx,3);
    y_mean = db(object_indx,2);
    theata_1 = db(object_indx,5);
    plot(ceil(x_mean),ceil(y_mean),'*');
    line_point_x1 = ceil(x_mean + cos(theata_1) * 40);line_point_y1 = ceil(y_mean + sin(theata_1) * 40);
    line_point_x2 = ceil(x_mean - cos(theata_1) * 40);line_point_y2 = ceil(y_mean - sin(theata_1) * 40);
   
    line([line_point_x1,line_point_x2],[line_point_y1,line_point_y2],'LineWidth',2);
end
hold off
output_img = saveAnnotatedImg(fh1);
end

function feature = feature_extra(obj_db)
feature = obj_db(:,[1,end-2:end]); %feature of a object : [label| roundness | area/perimeter^2 | Eulernumber]
feature(:,3) = feature(:,3)/(pi/(2*pi)^2);  %normalization, the largest area and perimeter square ratio is that of circle : pi / (2*pi)^2  
end

function match = feature_compare(feature1, feature2)
threshold = 0.0548;

if feature1(4) ~= feature2(4) % if the Eulernumber is not equal, the object is unlikely to match
    match = 0;
    return 
end

distance = norm(feature1(2:3)-feature2(2:3));
match = distance < threshold;

end

function annotated_img = saveAnnotatedImg(fh)
figure(fh); % Shift the focus back to the figure fh

% The figure needs to be undocked
set(fh, 'WindowStyle', 'normal');

% The following two lines just to make the figure true size to the
% displayed image. The reason will become clear later.
img = getimage(fh);
truesize(fh, [size(img, 1), size(img, 2)]);

% getframe does a screen capture of the figure window, as a result, the
% displayed figure has to be in true size. 
frame = getframe(fh);
frame = getframe(fh);
pause(0.5); 
% Because getframe tries to perform a screen capture. it somehow 
% has some platform depend issues. we should calling
% getframe twice in a row and adding a pause afterwards make getframe work
% as expected. This is just a walkaround. 
annotated_img = frame.cdata;
end