function ProcessImage(filename)
%% Reading the image
rgb_image = (imread(filename));
imshow(rgb_image);
fileInfo = dir(filename);
Orginal_fileSize = fileInfo.bytes
tic
%Convert to YCbCr Color Space which will allow us to separate the
%illuminance and chrominance
% Fix image for any size
%% Compressing
rgb_image = imresize(rgb_image,[ceil(size(rgb_image,1)/8)*8,ceil(size(rgb_image,2)/8)*8]);
ycbcrmap = rgb2ycbcr(rgb_image);
%Possible down sampling in the chrominance
% Divide the ycbcr map into its parts
illuminance = uint8(ycbcrmap(:,:,1));
CB = uint8(ycbcrmap(:,:,2));
CR = uint8(ycbcrmap(:,:,3));
% get the image size
[image_height image_width] = size(illuminance);
image_width = image_width /8 ;
% Block process the data with 8x8 window. Processing includes, normalizing 
% data, dct2, quantization data, then converts from square2line
processed_illuminance = BlockProcess(illuminance,0);
processed_CB = BlockProcess(CB,1);
processed_CR = BlockProcess(CR,1);
% Huffman encoding on the string
processed_illuminance(length(processed_illuminance)+1) = 127;
processed_CB(length(processed_CB)+1) = 127;
processed_CR(length(processed_CR)+1) = 127;
stream = [processed_illuminance;processed_CB;processed_CR];


[comp, dict] = HuffEncode(stream);

%% Transmit 
%after = length(compY);
%before = (length(illuminance))^2 *8;
%((before - after) / before)*100;
%% Save as image file format

%% Decompressing
dsig = huffmandeco(comp,dict);
index = 1;
counter = 1;
for x=1:1:length(dsig) 
    if dsig(x) == 127
        index = index + 1;
        x = x + 1; 
        counter = 1;
    else
        com(counter,index) = dsig(x);
    end
   counter = counter + 1;
   end





dsigY = com(:,1);
dsigCB = com(:,2);
dsigCR = com(:,3);


% Block De Process takes the data and width then, line2square, applies
% inverse quant, inverse dct2, unnormalize for each 8x8 square
outputY = BlockDeProcess(dsigY,image_width,0);
outputCB = BlockDeProcess(dsigCB,image_width,1);
outputCR = BlockDeProcess(dsigCR,image_width,1);
% put back together
decomImage(:,:,1) = uint8(round(outputY));
decomImage(:,:,2) = uint8(round(outputCB));
decomImage(:,:,3) = uint8(round(outputCR));

rgbOutput = ycbcr2rgb(decomImage);
figure(2);
imshow(rgbOutput);
imwrite(rgbOutput,'Output.png');
fileInfo = dir('Output.png');
Decompressed_fileSize = fileInfo.bytes
difference_imageSize = (Orginal_fileSize-Decompressed_fileSize)
toc
end

