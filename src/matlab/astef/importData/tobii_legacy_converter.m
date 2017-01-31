function [gazedataleft, gazedataright, timestamp] = tobii_legacy_converter(filename)
screenSiz = [1024 768];
[Timestamp, Gazepoint_x, Gazepoint_y] = importData(filename);
siz = size(Timestamp);
gazedataleft = zeros([siz(1) 13]);
gazedataright = zeros([siz(1) 13]);
timestamp = Timestamp;
validityOK = 0;
gazedataleft(:,7) = Gazepoint_x./screenSiz(2);
gazedataleft(:,8) = Gazepoint_y./screenSiz(1);
gazedataleft(:,13) = validityOK;
%gazedataleft(1:5,13) = ~validityOK; % fixme to avoid problems in tobii_gaze2fix
gazedataright(:,7) = Gazepoint_x./screenSiz(2);
gazedataright(:,8) = Gazepoint_y./screenSiz(1);
gazedataright(:,13) = validityOK;
%gazedataright(1:5,13) = ~validityOK; % fixme to avoid problems in tobii_gaze2fix

    function [Timestamp, Gazepoint_x, Gazepoint_y] = importData(filename)
        delimiter = '\t';
        if nargin<=2
            startRow = 2;
            endRow = inf;
        end
        
        %% Read columns of data as strings:
        % For more information, see the TEXTSCAN documentation.
        formatSpec = '%s%s%s%s%s%s%s%s%s%[^\n\r]';
        
        %% Open the text file.
        fileID = fopen(filename,'r');
        
        %% Read columns of data according to format string.
        % This call is based on the structure of the file used to generate this
        % code. If an error occurs for a different file, try regenerating the code
        % from the Import Tool.
        dataArray = textscan(fileID, formatSpec, endRow(1)-startRow(1)+1, 'Delimiter', delimiter, 'HeaderLines', startRow(1)-1, 'ReturnOnError', false);
        for block=2:length(startRow)
            frewind(fileID);
            dataArrayBlock = textscan(fileID, formatSpec, endRow(block)-startRow(block)+1, 'Delimiter', delimiter, 'HeaderLines', startRow(block)-1, 'ReturnOnError', false);
            for col=1:length(dataArray)
                dataArray{col} = [dataArray{col};dataArrayBlock{col}];
            end
        end
        
        %% Close the text file.
        fclose(fileID);
        
        %% Convert the contents of columns containing numeric strings to numbers.
        % Replace non-numeric strings with NaN.
        raw = repmat({''},length(dataArray{1}),length(dataArray)-1);
        for col=1:length(dataArray)-1
            raw(1:length(dataArray{col}),col) = dataArray{col};
        end
        numericData = NaN(size(dataArray{1},1),size(dataArray,2));
        
        for col=[1,2,3,4,5,6,7,8,9]
            % Converts strings in the input cell array to numbers. Replaced non-numeric
            % strings with NaN.
            rawData = dataArray{col};
            for row=1:size(rawData, 1);
                % Create a regular expression to detect and remove non-numeric prefixes and
                % suffixes.
                regexstr = '(?<prefix>.*?)(?<numbers>([-]*(\d+[\.]*)+[\,]{0,1}\d*[eEdD]{0,1}[-+]*\d*[i]{0,1})|([-]*(\d+[\.]*)*[\,]{1,1}\d+[eEdD]{0,1}[-+]*\d*[i]{0,1}))(?<suffix>.*)';
                try
                    result = regexp(rawData{row}, regexstr, 'names');
                    numbers = result.numbers;
                    
                    % Detected commas in non-thousand locations.
                    invalidThousandsSeparator = false;
                    if any(numbers=='.');
                        thousandsRegExp = '^\d+?(\.\d{3})*\,{0,1}\d*$';
                        if isempty(regexp(thousandsRegExp, '.', 'once'));
                            numbers = NaN;
                            invalidThousandsSeparator = true;
                        end
                    end
                    % Convert numeric strings to numbers.
                    if ~invalidThousandsSeparator;
                        numbers = strrep(numbers, '.', '');
                        numbers = strrep(numbers, ',', '.');
                        numbers = textscan(numbers, '%f');
                        numericData(row, col) = numbers{1};
                        raw{row, col} = numbers{1};
                    end
                catch me
                end
            end
        end
        
        
        %% Replace non-numeric cells with NaN
        R = cellfun(@(x) ~isnumeric(x) && ~islogical(x),raw); % Find non-numeric cells
        raw(R) = {NaN}; % Replace non-numeric cells
        
        %% Allocate imported array to column variable names
        Timestamp = cell2mat(raw(:, 2));
        Gazepoint_x = cell2mat(raw(:, 7));
        Gazepoint_y = cell2mat(raw(:, 8));
        
        
        
    end
end