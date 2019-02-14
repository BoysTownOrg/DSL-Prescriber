classdef File < handle
    properties (Access = private)
        fileID
    end
    
    methods
        function self = File(varargin)
            fileID = fopen(varargin{:});
            assert(fileID ~= -1, ['Unable to open ', varargin{1}]);
            self.fileID = fileID;
        end
        
        function result = fprintf(self, varargin)
            result = fprintf(self.fileID, varargin{:});
        end
        
        function line = fgetl(self, varargin)
            line = fgetl(self.fileID, varargin{:});
        end
        
        function result = textscan(self, varargin)
            result = textscan(self.fileID, varargin{:});
        end
        
        function delete(self)
            try
                fclose(self.fileID);
            catch
            end
        end
    end
end

