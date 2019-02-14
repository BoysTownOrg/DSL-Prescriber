classdef PresenterFacade < handle
    properties (Access = private)
        presenter
    end
    
    methods
        function self = PresenterFacade(...
                audiogram, ...
                model, ...
                levels...
            )
            if nargin < 3
                levels = 0;
            end
            if nargin < 2
                model = dslprescriber.test.ModelStub();
            end
            self.presenter = dslprescriber.Presenter(audiogram, model, levels);
        end
        
        function run(self)
            self.presenter.run();
        end
        
        function presenter = get(self)
            presenter = self.presenter;
        end
    end
end

