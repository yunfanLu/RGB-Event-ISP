% json_file = join(video_root, frame_name.replace(".png", ".json"))
% frame = cv2.imread(join(video_root, frame_name))
% frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
% with open(json_file) as f:
%     label = json.load(f)
%     shape = label["shapes"]
%     brown, cyan, white, black = None, None, None, None
%     for s in shape:
%         if s["label"] == "brown" and s["points"]:
%             brown = s["points"][0]
%         if s["label"] == "cyan" and s["points"]:
%             cyan = s["points"][0]
%         if s["label"] == "white" and s["points"]:
%             white = s["points"][0]
%         if s["label"] == "black" and s["points"]:
%             black = s["points"][0]



function [coords] = get_color_card_coords_from_json(json_file)
    % Read the json file.
    fid = fopen(json_file);
    raw = fread(fid,inf);
    str = char(raw');
    fclose(fid);
    data = jsondecode(str);
    % Get the shapes.
    shapes = data.shapes;
    brown = [];
    cyan = [];
    white = [];
    black = [];


    for i = 1:length(shapes)
        shape = shapes(i);
        if strcmp(shape.label, 'brown') && ~isempty(shape.points)
            xy = shape.points(1, :);
            x = xy(1);
            y = xy(2);
            [x, y] = flip(x, y);
            brown = [x, y];
        end
        if strcmp(shape.label, 'cyan') && ~isempty(shape.points)
            xy = shape.points(1, :);
            x = xy(1);
            y = xy(2);
            [x, y] = flip(x, y);
            cyan = [x, y];
        end
        if strcmp(shape.label, 'white') && ~isempty(shape.points)
            xy = shape.points(1, :);
            x = xy(1);
            y = xy(2);
            [x, y] = flip(x, y);
            white = [x, y];
        end
        if strcmp(shape.label, 'black') && ~isempty(shape.points)
            xy = shape.points(1, :);
            x = xy(1);
            y = xy(2);
            [x, y] = flip(x, y);
            black = [x, y];
        end
    end
    coords = [brown; cyan; white; black];
end


function [x1,y1] = flip(x, y)
    height = 2448;
    width = 3264;
    %
    x = width - x;
    % x,y - > y, w - x
    x1 = y;
    y1 = width - x;
end