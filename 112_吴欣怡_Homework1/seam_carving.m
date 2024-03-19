%   Copyright © 2024, Renjie Chen @ USTC


%% read image
im = imread('peppers.png');
%% draw 2 copies of the image
fig=figure('Units', 'pixel', 'Position', [100,100,1000,700], 'toolbar', 'none');
subplot(121); imshow(im); title({'Input image'});
subplot(122); himg = imshow(im*0); title({'Resized Image', 'Use the blue button to resize the input image'});
hToolResize = uipushtool('CData', reshape(repmat([0 0 1], 100, 1), [10 10 3]), 'TooltipString', 'apply seam carving method to resize image', ...
                        'ClickedCallback', @(~, ~) set(himg, 'cdata', seam_carve_image(im, size(im,1:2)-[0 300])));

%% TODO: implement function: searm_carve_image
% check the title above the image for how to use the user-interface to resize the input image
function im = seam_carve_image(im, sz)
% im = imresize(im, sz);

costfunction = @(im) sum( imfilter(im, [.5 1 .5; 1 -6 1; .5 1 .5]).^2, 3 );
k = size(im,2) - sz(2);
for i = 1:k
    %%已经得到整个能量值矩阵
    G = costfunction(im);
    %% find a seam in G
    seam=find_min_seam(G,'VERTICAL');
    %% remove seam from im
    im = remove_VERTICAL(im, seam);
end

end

% 计算M矩阵的值
function seam = find_min_seam(G,seamdirection)
    [rows, cols] = size(G);
    M=zeros(rows,cols);
    
    if strcmp(seamdirection,'VERTICAL')
        M(1,:) = G(1,:);
        for x = 2:rows
            for y = 1:cols
                if y == 1
                    M(x,y) = G(x,y) + min([M(x-1,y),M(x-1,y+1)]);
                elseif y==cols
                    M(x,y) = G(x,y) + min([M(x-1,y-1),M(x-1,y)]);
                else 
                    M(x,y) = G(x,y) + min([M(x-1,y-1),M(x-1,y),M(x-1,y+1)]);
                end
            end
        end
        % 找到最后一行中能量最小的像素位置
        [~, last_pixel] = min(M(end, :));

        % 回溯找到整个最小能量路径
        seam = zeros(rows, 1);
        seam(end) = last_pixel;
        for i = rows-1:-1:1
            if last_pixel == 1
                [~, idx] = min([M(i, last_pixel), M(i, last_pixel+1)]);
                last_pixel = last_pixel + idx - 1;
            elseif last_pixel == cols
                [~, idx] = min([M(i, last_pixel-1), M(i, last_pixel)]);
                last_pixel = last_pixel - 2 + idx;
            else
                [~, idx] = min([M(i, last_pixel-1), M(i, last_pixel), M(i, last_pixel+1)]);
                last_pixel = last_pixel - 2 + idx;
            end
            seam(i) = last_pixel;
        end


    elseif strcmp(seamdirection,'HORIZONTAL')
        M(:,1) = G(:,1);
        for y = 2:cols
            for x = 1:rows
                if x == 1
                    M(x,y) = G(x,y) + min([M(x,y-1),M(x+1,y-1)]);
                elseif x==rows
                    M(x,y) = G(x,y) + min([M(x-1,y-1),M(x,y-1)]);
                else 
                    M(x,y) = G(x,y) + min([M(x-1,y-1),M(x,y-1),M(x+1,y-1)]);
                end
            end
        end
        % 找到最后一列中能量最小的像素位置
        [~, last_pixel] = min(M(:, end));
        % 回溯找到整个最小能量路径
        seam = zeros(cols, 1);
        seam(cols) = last_pixel;

        for i = cols-1:-1:1
            if last_pixel == 1
                [~, idx] = min([M(last_pixel, i), M(last_pixel+1, i)]);
                last_pixel = last_pixel + idx - 1;
            elseif last_pixel == rows
                [~, idx] = min([M(last_pixel-1, i), M(last_pixel, i)]);
                last_pixel = last_pixel - 2 + idx;
            else
                [~, idx] = min([M(last_pixel-1, i), M(last_pixel, i),  M(last_pixel+1, i)]);
                last_pixel = last_pixel - 2 + idx;
            end
            seam(i) = last_pixel;
        end


    else
        disp("SeamDirection error.")
        exit()
    end
end 

function im=remove_VERTICAL(im,seam)
    [rows, cols, ~] = size(im);
    im_new = zeros(rows, cols - 1, 3);
    % 删除路径对应的像素
    for i = 1:rows
        if seam(i) == 1
            im_new(i, :, 1) = im(i, 2:end, 1);
            im_new(i, :, 2) = im(i, 2:end, 2);
            im_new(i, :, 3) = im(i, 2:end, 3);
        elseif seam(i) == cols
            im_new(i, :, 1) = im(i, 1:end-1, 1);
            im_new(i, :, 2) = im(i, 1:end-1, 2);
            im_new(i, :, 3) = im(i, 1:end-1, 3);
        else
            im_new(i, :, 1) = [im(i, 1:seam(i)-1, 1), im(i, seam(i)+1:end, 1)];
            im_new(i, :, 2) = [im(i, 1:seam(i)-1, 2), im(i, seam(i)+1:end, 2)];
            im_new(i, :, 3) = [im(i, 1:seam(i)-1, 3), im(i, seam(i)+1:end, 3)];
        end
    end

    im = uint8(im_new);
end

function im=remove_HORIZONTAL(im,seam)
    [rows, cols, ~] = size(im);
    im_new = zeros(rows-1, cols, 3);
    % 删除路径对应的像素
    for i = 1:cols
        if seam(i) == 1
            im_new(:, i, 1) = im(2:end, i, 1);
            im_new(:, i, 2) = im(2:end, i, 2);
            im_new(:, i, 3) = im(2:end, i, 3);
        elseif seam(i) == rows
            im_new(:, i, 1) = im(1:end-1, i, 1);
            im_new(:, i, 2) = im(1:end-1, i, 2);
            im_new(:, i, 3) = im(1:end-1, i, 3);
        else
            im_new(:, i, 1) = cat(1, im(1:seam(i)-1, i, 1), im(seam(i)+1:end, i, 1));
            im_new(:, i, 2) = cat(1, im(1:seam(i)-1, i, 2), im(seam(i)+1:end, i, 2));
            im_new(:, i, 3) = cat(1, im(1:seam(i)-1, i, 3), im(seam(i)+1:end, i, 3));
        end
    end

    im = uint8(im_new);
end