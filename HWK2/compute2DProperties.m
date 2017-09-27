function [db, out_img] = compute2DProperties(orig_img, labeled_img)

num_obj = max(labeled_img(:));
db = [];

fh1 = figure();
imshow(orig_img);

hold on
for indx_obj = 1:num_obj
    [objects, x_mean, y_mean,a,b,c] = object_segmentting_and_cal(labeled_img,indx_obj);
    theata_1 = atan2(b,a-c)/2;
    theata_2 = theata_1 + pi/2;
    
    E_min = a * sin(theata_1)^2 - b * sin(theata_1) * cos(theata_1) + c * cos(theata_1)^2; 
    E_max = a * sin(theata_2)^2 - b * sin(theata_2) * cos(theata_2) + c * cos(theata_2)^2; 
    roundness = E_min/E_max;
    
    [perimeter,Eulernum] = comp_perimeter(objects);
    Area = sum(objects(:));
    db = [db;double(indx_obj), y_mean,x_mean, E_min,theata_1,roundness,Area/perimeter^2,Eulernum];
    
    plot(ceil(x_mean),ceil(y_mean),'*');
    line_point_x1 = ceil(x_mean + cos(theata_1) * 40);line_point_y1 = ceil(y_mean + sin(theata_1) * 40);
    line_point_x2 = ceil(x_mean - cos(theata_1) * 40);line_point_y2 = ceil(y_mean - sin(theata_1) * 40);
   
    line([line_point_x1,line_point_x2],[line_point_y1,line_point_y2],'LineWidth',2);
    
    
end
hold off
out_img = saveAnnotatedImg(fh1);

end

function [objects, x_mean, y_mean,a,b,c] = object_segmentting_and_cal(labeled_img, indx_obj)
%segment a single object from the image and compute some properties of this
%object including row and column position of the center and a,b,c

[raw, col] = find(labeled_img == indx_obj);

raw_up = min(raw); raw_down = max(raw);
col_left = min(col); col_right = max(col);

objects = labeled_img(raw_up:raw_down, col_left:col_right);
objects(objects ~= 0 & objects ~= indx_obj) = 0;
objects(objects == indx_obj) = 1;
objects = boolean(objects);


y_mean = mean(raw);
x_mean = mean(col);

raw = raw - y_mean;
col = col - x_mean;

a = sum(col.^2);
b = 2 * sum(raw.*col);  
c = sum(raw.^2); 

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

function [perimeter, Eulernum] = comp_perimeter(object)


perimeter = 0;
%boarden the object image
[obj_r,obj_c] = size(object);
boarden_len = 5;
object = [zeros(obj_r,boarden_len),object,zeros(obj_r,boarden_len)];
object = [zeros(boarden_len,obj_c + 2*boarden_len);object;zeros(boarden_len,obj_c + 2*boarden_len)];

chaincode = get_chaincode(object);
perimeter = perimeter + count_perimeter(chaincode);

object = xor(object,1);
holes = bwlabel(object,8);
num_holes = max(holes(:));

single_hole = holes;
for indx_holes = 2:num_holes
    single_hole(holes == indx_holes) = 1;
    single_hole(holes ~= indx_holes) = 0;
    chaincode = get_chaincode(single_hole);
    perimeter = perimeter + count_perimeter(chaincode);
end

Eulernum = 1 - (num_holes -1); % the number of body is 1 and the first 'hole' is actually the background

end

function chaincode = get_chaincode(object)

% n stores the 8 neighbors of a given pixel (x,y)
%     4   5   6 
%      \  |  /   
%    3 -(x,y)- 7                                               
%      /  |  \                                                                                                              
%     2   1   8                                                       
n=[0 1;-1 1;-1 0;-1 -1;0 -1;1 -1;1 0;1 1];
object = boolean(object);

chaincode=[];
[current_x,current_y]=find(object==1);
current_y=min(current_y);
im_y=object(:,current_y);
current_x=find(im_y==1, 1 );
start_point=[current_x, current_y];
dir=7;

while (1)
    neighbors=zeros(1,8);
    newdir=mod(dir+7-mod(dir,2),8);
    for i=0:7
        j=mod(newdir+i,8)+1;
        neighbors(i+1)=object(current_x+n(j,1),current_y+n(j,2));
    end
    d=find(neighbors==1, 1 );   %find the a connected pixel in the neighbor
    dir=mod(newdir+d-1,8);
    chaincode=[chaincode,dir];  % store the direction to the found pixel
    current_x=current_x+n(dir+1,1);current_y=current_y+n(dir+1,2);
    %revisit the starting point, which means the end of computation
    if current_x==start_point(1)&&current_y==start_point(2)
        break;
    end
end
end

function perimeter = count_perimeter(chaincode)
perimeter = 0;
sum1 = 0; sum2 = 0;
for k=1:length(chaincode)
    if chaincode(k)==0 ||chaincode(k)==2 ||chaincode(k)==4 ||chaincode(k)==6
        sum1=sum1+1;
    else
        sum2=sum2+1;
    end
end
perimeter=perimeter + sum1+sum2*sqrt(2);
end


