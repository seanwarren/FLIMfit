classdef checkable_list < handle
   
    properties
        
    end
    
    properties(Access=private)
        scroll_panel;
        check_layout;
        slider;
        checkboxes;
        top_position;
        fig;
        abs_position;
    end
    
    methods

        function obj = checkable_list(parent,options)
        
            panel = uipanel('Parent',parent,'BorderType','none');
            sub_layout = uix.HBox('Parent',panel,'Padding',5);
            obj.scroll_panel = uipanel('Parent',sub_layout,'BackgroundColor','w','BorderType','none','Units','pixels');
            obj.check_layout = uix.VBox('Parent',obj.scroll_panel,'Padding',5,'BackgroundColor','w','Units','pixels');
            obj.slider = uicontrol('Style','slider','Parent',sub_layout,'Callback',@obj.update_position);
            for i=1:length(options)
                obj.checkboxes(i) = uicontrol('Style','check','String',num2str(options(i)),'Parent',obj.check_layout,'BackgroundColor','w');
            end
            obj.check_layout.Heights = [20*ones(1,length(options))];
            sub_layout.Widths = [-1 20];

            obj.setup_slider(true);
            obj.scroll_panel.ResizeFcn = @(~,~) obj.setup_slider(false);

            % Get figure containing this list
            obj.fig = parent;
            while ~isa(obj.fig,'matlab.ui.Figure')
                obj.fig = obj.fig.Parent;
            end                      
                
            last_fcn = obj.fig.WindowScrollWheelFcn;
            obj.fig.WindowScrollWheelFcn = @(src,evt) obj.mouse_scroll(src,evt,last_fcn);
            
        end
        
        
        function mouse_scroll(obj,src,evt,last_fcn)
            
            mouse_pos = obj.fig.CurrentPoint - obj.abs_position;
            obj.scroll_panel.Position(3:4);
            if all(mouse_pos > 0) && all(obj.scroll_panel.Position(3:4) - mouse_pos > 0)
                v = obj.slider.Value - obj.slider.SliderStep(1) * evt.VerticalScrollCount * obj.slider.Max;
                if v < obj.slider.Min
                    v = obj.slider.Min;
                end
                if v > obj.slider.Max
                    v = obj.slider.Max;
                end
                obj.slider.Value = v;
                obj.update_position(obj.slider);
            end
            
            if ~isempty(last_fcn)
                last_fcn(src,evt);
            else
            end
        end
        
        function setup_slider(obj,first)

            % Get absolute position in figure
            f = obj.scroll_panel;
            obj.abs_position = 0;
            while ~isa(f,'matlab.ui.Figure')
                obj.abs_position = obj.abs_position + f.Position(1:2);
                f = f.Parent;
            end                      
            
            p = obj.scroll_panel.Position;

            h =  sum(obj.check_layout.Heights) + 2*obj.check_layout.Padding;

            % stay where we are when resizing
            if first
                p_h = p(4)-h;
            else
                p_h = obj.check_layout.Position(2);
                p_h = p_h - obj.top_position + obj.scroll_panel.Position(4);
            end
            obj.top_position = obj.scroll_panel.Position(4);
            
            pc = [0 p_h p(3) h];

            obj.check_layout.Position = pc;

            mx = max(1,h-p(4));

            obj.slider.Min = 0; 
            obj.slider.Max = mx;
            obj.slider.Value = mx;


            if (mx == 1)
                obj.slider.Enable = 'off';
            else 
                obj.slider.Enable = 'on';
            end

            if (obj.slider.Max > 20)
                obj.slider.SliderStep = [20 20] / obj.slider.Max;
            else
                obj.slider.SliderStep = [1 1];
            end
        end

        function update_position(obj,src,evt)
            %# slider value
            offset = src.Value;
            p = obj.check_layout.Position;
            obj.check_layout.Position = [p(1) -offset p(3) p(4)];
        end
        
        function v = get_check(obj)
            v = 1;
            
%            n = 1:length(obj.checkboxes);
%            v = logical([obj.checkboxes.Value]);
%            v = n(v);
        end
    end
    
end