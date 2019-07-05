function num = diplom(img_url, image_id)
% img_url = 'http://res.cloudinary.com/detextive/image/upload/v1560706511/r2vtrmmldpcjh8i28u5j.jpg';
% result_id = '24';

    THRESH_COEFF = 0.4;
    IM_HEIGHT = 512;
    IM_MAX_HEIGHT = 600;
    CAUCHY_SCALE_COEFF = 7 * 1.3; % 1.5

    % Get an image
    image = imread(img_url);
%     if size(image,1) > IM_MAX_HEIGHT || size(image,2) > IM_MAX_HEIGHT
%         image = imresize(image, [IM_HEIGHT NaN]); % Привести изображение в высоте IM_HEIGHT
%     end
    Im = image;
%     figure(2); imshow(Im);
    Im = rgb2gray(Im); % Перевести изображение в ч/б

    % Obtain the 2D CWT with the Gaus and Cauchy wavelets with fixed scale. 
    % Vector of angles goes from 0 to 15pi/8 with step pi/8.
    % (2D НВП с вейвлетами Гауса и Коши с фиксированным масштабом.
    % Вектор углов задан от 0 до 15pi/8 с шагом pi/8)
    wavelet = {'cauchy',{pi/6,4,4,1}};
    scales = 1:0.5:8;
    angles = 0:pi/8:pi-pi/8;
    cwt_res = cwtft2(Im, 'wavelet', wavelet, 'scales', scales, 'angles', angles);

    % String representation for visualization of each angle. 
    angz = {'0', 'pi/8', 'pi/4', '3*pi/8', 'pi/2', '5*pi/8', '3*pi/4', '7*pi/8'};

    % Filtering amd getting sum of all 2d-CWT coefficients for each angle
    % (Фильтрация и нахождение суммы всех коэффициентов 2d-НВП для каждого угла)
    abs_coeff = abs(cwt_res.cfs(:,:,:,:,:));
    thresh_abs_coeff = zeros(size(abs_coeff));
    processed = zeros(size(abs_coeff));

    for l=1:size(abs_coeff, 4) % for each scale
        for k=1:size(abs_coeff, 5) % for each angle
            current_image = abs_coeff(:,:,:,l,k);
            max_val_on_k_image = max(current_image, [], 'all');

            for i=1:size(current_image, 1)
                for j=1:size(current_image, 2)
                    if current_image(i,j) < max_val_on_k_image * THRESH_COEFF
                        current_image(i,j) = 0;
                    end
                end
            end

            thresh_abs_coeff(:,:,:,l,k) = current_image;

            alpha = angles(k);
            font_height = scales(l) * CAUCHY_SCALE_COEFF;
            processed(:,:,:,l,k) = process_coeff(current_image, font_height, alpha);
        end
    end

    masked = abs_coeff .* processed;
    sum_coeff = sum(masked(:,:,:,:,:), [1 2 3]);
    resulted_img = {};
    resulted_ang = zeros(length(scales), 1);
    resulted_scale = zeros(length(scales), 1);
    max_vals = zeros(length(scales), 1);

    % Поиск угла с макс откликом для каждого масштаба (после фильтарции
    % областей)
    for sc=1:length(scales) % for each scale
        [max_sum_value, max_angle_ind] = max(sum_coeff(:,:,:,sc,:));
        resulted_img{end+1} = processed(:,:,:,sc,max_angle_ind); % masked
        resulted_ang(sc) = angles(max_angle_ind);
        resulted_scale(sc) = sc;
        max_vals(sc) = max_sum_value;

%         cc = bwconncomp(processed(:,:,:,sc,max_angle_ind)); 
%         stats = regionprops(cc, 'ConvexHull'); 
% 
%         for i=1:length(stats)
%             hull = stats(i).ConvexHull;
%             hold on;
%             plot(hull(:,1), hull(:,2), 'r-');
%         end
    end

    resulted = table(resulted_ang, resulted_scale, resulted_img',...
                     'VariableNames', {'Angle', 'Scale', 'Img'});

    % Для каждого найденного уникального "максимального" угла объединяем 
    % результаты (ищем наложения)
    unique_angz = unique(resulted_ang);
    output_angz = {};
    output_imgs = {};

    for ang=1:length(unique_angz)
        curr_ang_results = resulted(resulted.Angle == unique_angz(ang), :);
        curr_sum_masked = 0;

        for k=1:height(curr_ang_results)
            curr_sum_masked = curr_sum_masked + curr_ang_results.Img{k};
        end

        max_val_res = max(curr_sum_masked, [], 'all');
        for i=1:size(curr_sum_masked, 1)
            for j=1:size(curr_sum_masked, 2)
                if curr_sum_masked(i,j) < 3 % max_val_res * 0.2
                    curr_sum_masked(i,j) = 0;
                end
            end
        end

        if sum(curr_sum_masked, 'all') > 0
            se = strel('disk', 5);
            curr_sum_masked = imopen(curr_sum_masked, se);
            
            output_angz{end+1} = unique_angz(ang);
            output_imgs{end+1} = curr_sum_masked;

%             figure(); colormap(jet); imagesc(curr_sum_masked);
%             figure(); imshow(Im); title(['Angle: ', num2str(unique_angz(ang)*180/pi)]);
%     
%             cc_r = bwconncomp(curr_sum_masked); 
%             stats_r = regionprops(cc_r, 'ConvexHull'); 
%             for i=1:length(stats_r)
%                 hull = stats_r(i).ConvexHull;
%                 hold on;
%                 plot(hull(:,1), hull(:,2), 'g-');
%             end
        end
    end

    % GET OUTPUT
    total_res = table(output_angz', output_imgs', 'VariableNames', {'Angle', 'Img'});
    words = {};
    angs = {};
    bbox1 = {};
    bbox2 = {};
    bbox3 = {};
    bbox4 = {};
    for i=1:height(total_res)
        alpha = total_res.Angle{i} * 180/pi;
        if alpha > 90, alpha = alpha - 180; end

%         Im_rot = imrotate(total_res.Img{i}, -alpha);
        Im_init_rot = imrotate(image, -alpha);

        cc = bwconncomp(total_res.Img{i}); 
        stats = regionprops(cc,'ConvexHull','Centroid'); 

%         figure(100+i); imshow(image); 
        title(['Angle is about ', num2str(alpha), ' degrees']);
        for j=1:length(stats)
%             hold on; figure(100+i);
        
            % Развернуть convexhull параллельно оси х (по точке центра)
            hull = stats(j).ConvexHull;
            polyin = polyshape(hull(:,1),hull(:,2),'Simplify',false);
            polyout = simplify(polyin);
            poly = rotate(polyout, alpha, stats(j).Centroid);
%             hold on; plot(poly);
            
            % Построить bbox
            [xlim,ylim] = boundingbox(poly);
            bb = round([xlim(1) ylim(1) xlim(2)-xlim(1) ylim(2)-ylim(1)], 0);
            points = bbox2points(bb);
            % Развернуть обратно
            polyinb = polyshape(points(:,1),points(:,2));
            polyb = rotate(polyinb, -alpha, stats(j).Centroid);
            vert = round(polyb.Vertices, 0);
            
%             hold on; plot(polyb,'LineStyle','-','EdgeColor','g','LineWidth',1,'FaceAlpha',0);
            
            croppedImage = imcrop(Im_init_rot, bb);

            % Perform OCR.
            ocr_text = ocr(croppedImage);
            disp(ocr_text.Text);
            
            words{end+1} = replace(ocr_text.Text, newline, ' ');
            angs{end+1} = alpha;
            bbox1{end+1} = bb(1); % X-coord
            bbox2{end+1} = bb(2); % Y-coord
            bbox3{end+1} = bb(3); % width
            bbox4{end+1} = bb(4); % height
        end
    end
    
    output = table(angs', bbox1', bbox2', bbox3', bbox4', words',...
                   'VariableNames', {'Angle', 'X', 'Y', 'W', 'H', 'Word'});
    writetable(output,sprintf("%s.csv", image_id),'Delimiter',';','Encoding','UTF-8');
    num = height(output);
end

%-----------------------------------------------------------------------
function res = process_coeff(thresh_coeff, font_height, alpha)
    BIN_THRESH = 0.2;
    H_TO_W = 1.5; % h/w for arbitrary font
    
    % Graduation of the results above to the scale of 0..1 - transfer to b/w
    % (Градуирование полученных выше результатов к шкале 0..1 - перевод в ч/б)
    grad_abs_coeff = mat2gray(thresh_coeff);

    % Binarization of b/w images
    % (Бинаризация полученных ч/б изображений)
    imb_coeff = imbinarize(grad_abs_coeff, BIN_THRESH);

    filt_imb = filter_with_regionprops(imb_coeff, font_height, alpha);
    alpha_d = alpha * 180/pi;
    
    % Создание структурных элементов для дилатации результатов бинаризации
    % (представляют собой "отрезки" под углом angle). Дилатация
    SE_dil = strel('line', font_height * H_TO_W, alpha_d);
    imb_coeff_dil = imdilate(filt_imb, SE_dil);
    SE_op = strel('line', font_height / 5, alpha_d - 90);
    imb_coeff_dil = imdilate(imb_coeff_dil, SE_op); % Поменять морф. операцию

    res = filter_w_to_h(imb_coeff_dil, font_height, alpha);
end

%-----------------------------------------------------------------------
function res = filter_with_regionprops(imgb, font_height, alpha)
    SPARE_HEIGHT_COEFF = 1.5;
    
    % Фильтрация по высоте шрифта
    cc = bwconncomp(imgb); 
    stats = regionprops(cc, 'Area','ConvexHull'); 
    idx = [];

    for i=1:length(stats)
        if stats(i).Area > font_height
            hull = stats(i).ConvexHull;
            x = hull(:,1);
            y = hull(:,2);
            x_n = round(x*cos(alpha) - y*sin(alpha), 0);
            y_n = round(x*sin(alpha) + y*cos(alpha), 0);
            w = max(x_n) - min(x_n);
            h = max(y_n) - min(y_n);
            
%             if (font_height == 59.15) && (alpha == 5*pi/8)
%                 disp(['W: ', num2str(w), '; H: ', num2str(h)])
%                 hold on;
%                 plot(hull(:,1), hull(:,2), 'r-');
%                 plot(x_n, y_n, 'g-');
%                 pause(2);
%             end
            
            if (h < font_height * SPARE_HEIGHT_COEFF)
                idx(end+1) = i;
            end
        end
    end
    res = ismember(labelmatrix(cc), idx); 
    
    % Ещё одна фильтрация (по ширине и кол-ву соседей)
    cc = bwconncomp(res); 
    stats = regionprops(cc, 'Area','ConvexHull','Centroid'); 
    idx = [];
    dist = squareform(pdist(cell2mat({stats(:).Centroid}')));

    for i=1:length(stats)
        if stats(i).Area > font_height
            hull = stats(i).ConvexHull;
            x = hull(:,1);
            y = hull(:,2);
            x_n = round(x*cos(alpha) - y*sin(alpha), 0);
            y_n = round(x*sin(alpha) + y*cos(alpha), 0);
            w = max(x_n) - min(x_n);
            h = max(y_n) - min(y_n);
            
            if ~isempty(dist)
                neighbors_num = nnz(dist(i ,:) <= font_height*2) - 1;
            else
                neighbors_num = 0;
            end
            
            if (w > font_height) || (neighbors_num > 0)
                idx(end+1) = i;
            end
        end
    end
    res = ismember(labelmatrix(cc), idx); 
end

%-----------------------------------------------------------------------
% Отфильтровать слишком высокие компоненты после дилатации (w / h = 0.67)
function res = filter_w_to_h(imgb, font_height, alpha)
    cc = bwconncomp(imgb); 
    stats = regionprops(cc, 'Area','ConvexHull'); 
    idx = [];

    for i=1:length(stats)
        if stats(i).Area > font_height^2
            hull = stats(i).ConvexHull;
            x = hull(:,1);
            y = hull(:,2);
            x_n = round(x*cos(alpha) - y*sin(alpha), 0);
            y_n = round(x*sin(alpha) + y*cos(alpha), 0);
            w = max(x_n) - min(x_n);
            h = max(y_n) - min(y_n);
            
            % Experimantally picked coeffs
            if (w / h >= 1.5) && (h >= font_height/1.3) && (h < font_height*2)
                idx(end+1) = i;
%                 hold on;
%                 plot(x, y, 'r-');
            end
        end
    end
    res = ismember(labelmatrix(cc), idx); 
end