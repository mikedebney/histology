clc
clear all

% Basic Image, Pixel & Voxel Info

original_x = 14.48; 
original_y = 11.64;

info = imfinfo('/Users/mike/Desktop/Histology/MI03_01/MI03_1_10.tif');
imdata = imread('/Users/mike/Desktop/Histology/MI03_01/MI03_1_10.tif');
img = im2double(imdata);

pixel_size = original_x/info.Width*1000;    % Pixel Size in Microns
voxel_size = 200;
block_size = round(voxel_size/pixel_size);


% Identify Background/Normal/Scar Colours

background_colour = [0.70 0.70 0.70]; 
scarlet_colour = [0.50, 0.30, 0.30];
anniline_colour = [0.30, 0.40, 0.60];


% MI14
% background_colour = [0.70 0.70 0.70]; tol 10
% scarlet_colour = [0.3, 0.20, 0.25]; tol 10
% anniline_colour = [0.30, 0.40, 0.60]; tol 10

% MI03
% background_colour = [0.70 0.70 0.70]; tol 10
% scarlet_colour = [0.50, 0.30, 0.30]; tol 15
% anniline_colour = [0.30, 0.40, 0.60]; tol 10

% Remove Background (White)

tolerance = 0.10;
background_mask =...
  img(:,:,1) >= background_colour(1) - tolerance & ...
  img(:,:,1) <= background_colour(1) + tolerance & ...
  img(:,:,2) >= background_colour(2) - tolerance & ...
  img(:,:,2) <= background_colour(2) + tolerance & ...
  img(:,:,3) >= background_colour(3) - tolerance & ...
  img(:,:,3) <= background_colour(3) + tolerance;
background_mask = ~ background_mask;            % Invert logical array

img2(:,:,1) = img(:,:,1).*background_mask;      % Apply mask to raw img data
img2(:,:,2) = img(:,:,2).*background_mask;
img2(:,:,3) = img(:,:,3).*background_mask;

% Identify Normal Myocardium (Biebrich Scarlet Stain)

tolerance = 0.10;
scarlet_mask =...
  img2(:,:,1) >= scarlet_colour(1) - tolerance & ...
  img2(:,:,1) <= scarlet_colour(1) + tolerance & ...
  img2(:,:,2) >= scarlet_colour(2) - tolerance & ...
  img2(:,:,2) <= scarlet_colour(2) + tolerance & ...
  img2(:,:,3) >= scarlet_colour(3) - tolerance & ...
  img2(:,:,3) <= scarlet_colour(3) + tolerance;

img_scarlet(:,:,1) = img2(:,:,1).*scarlet_mask;     % Apply scarlet mask
img_scarlet(:,:,2) = img2(:,:,2).*scarlet_mask;
img_scarlet(:,:,3) = img2(:,:,3).*scarlet_mask;
% figure,imshow(img_scarlet)

% Identify Scar (Anniline Blue Stain)

tolerance = 0.10;
anniline_mask =...
  img2(:,:,1) >= anniline_colour(1) - tolerance & ...
  img2(:,:,1) <= anniline_colour(1) + tolerance & ...
  img2(:,:,2) >= anniline_colour(2) - tolerance & ...
  img2(:,:,2) <= anniline_colour(2) + tolerance & ...
  img2(:,:,3) >= anniline_colour(3) - tolerance & ...
  img2(:,:,3) <= anniline_colour(3) + tolerance;

img_anniline(:,:,1) = img2(:,:,1).*anniline_mask;     % Apply anniline mask
img_anniline(:,:,2) = img2(:,:,2).*anniline_mask;
img_anniline(:,:,3) = img2(:,:,3).*anniline_mask;
% figure, imshow(img_anniline)

% View Masks (Comment once optimised)

% figure, imshow(img);
% impixelregion
% figure,imshow(background_mask);title('Masked')      % Show background mask
% figure,imshow(scarlet_mask);title('Scarlet Mask')   % Show scarlet mask
% figure,imshow(anniline_mask);title('Anniline Mask')  % Show anniline mask



img_sum(:,:,1) = img_scarlet(:,:,1) + img_anniline(:,:,1);
img_sum(:,:,2) = img_scarlet(:,:,2) + img_anniline(:,:,2);
img_sum(:,:,3) = img_scarlet(:,:,3) + img_anniline(:,:,3);
% imshow(img_sum)


%% Process Image in Blocks

% Block size calculated from (known) image size, voxel size of 200microns
% Takes each mask image (anniline, scarlet) and sums the number of pixels
% in each block
% Total number of pixels/block calculated by adding anniline & scarlet


fun = @(block_struct)...
    sum(block_struct.data(:));

block_anniline = blockproc(anniline_mask, [block_size block_size], fun);
block_scarlet = blockproc(scarlet_mask, [block_size block_size], fun);

block_anniline(block_anniline<20) = 0;          % Remove less than 20px
block_scarlet(block_scarlet<20) = 0;            % Remove less than 20px

block_sum = block_anniline + block_scarlet;     % Total number of pixels
block_sum(block_sum<20) = 0;

%% Derive Normal, Scar & IBZ

% For each block we assign whether it is scar, normal or IBZ
% Scar & Normal are defined as comprising >80% of pixels/block
% IBZ is defined as comprising between 20-80% of either normal/scar

perc_scarlet = block_scarlet./block_sum;        % Percentage of scarlet
perc_anniline = block_anniline./block_sum;      % Percentage of anniline

scar = perc_anniline;
normal = perc_scarlet;
IBZ = perc_scarlet;

scar(scar<0.8) = nan;           % >80% of pixels = scar
normal(normal<0.8) = nan;       % >80% of pixels = normal

IBZ(IBZ>0.8) = nan;             % Exclude > 80%
IBZ(IBZ<0.2) = nan;             % Exclude < 20%
IBZ(isnan(IBZ)) = 0;            % Convert NANs to zeroes
IBZ = logical(IBZ);             % Convert to logical array

figure, imshow(IBZ);
figure, imshow(scar);
figure, imshow(normal);


