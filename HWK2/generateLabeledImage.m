function labeled_img = generateLabeledImage(gray_img, threshold)

b_img = im2bw(gray_img, threshold);
labeled_img = bwlabel(b_img,8);

end


