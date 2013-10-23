function load_single(obj,file,polarisation_resolved,data_setting_file,channel)
    %> Load a single FLIM dataset
    
    % Copyright (C) 2013 Imperial College London.
    % All rights reserved.
    %
    % This program is free software; you can redistribute it and/or modify
    % it under the terms of the GNU General Public License as published by
    % the Free Software Foundation; either version 2 of the License, or
    % (at your option) any later version.
    %
    % This program is distributed in the hope that it will be useful,
    % but WITHOUT ANY WARRANTY; without even the implied warranty of
    % MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    % GNU General Public License for more details.
    %
    % You should have received a copy of the GNU General Public License along
    % with this program; if not, write to the Free Software Foundation, Inc.,
    % 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
    %
    % This software tool was developed with support from the UK 
    % Engineering and Physical Sciences Council 
    % through  a studentship from the Institute of Chemical Biology 
    % and The Wellcome Trust through a grant entitled 
    % "The Open Microscopy Environment: Image Informatics for Biological Sciences" (Ref: 095931).

    % Author : Sean Warren
    
   
    
    [path,name,ext] = fileparts(file);

    if strcmp(ext,'.raw')
        obj.load_raw_data(file);
        return;
    end
    
    if is64
        obj.use_memory_mapping = false;
    end
    
    if nargin < 3
        polarisation_resolved = false;
    end
    if nargin < 4
        data_setting_file = [];
    end
    if nargin < 5
        channel = [];
    end
    
    obj.root_path = ensure_trailing_slash(path);    
    
    % Determine which planes we need to load 
    [ZCT, block] = obj.request_planes(file, obj.polarisation_resolved, []);
    channel = ZCT{2};

   
    if length(channel) > 1
        obj.load_multiple_channels = true;
    end
        
   
    
    if ~strcmp(ext,'.raw')
        if strcmp(ext,'.sdt') || strcmp(ext,'.txt') ||  strcmp(ext,'.asc') || strcmp(ext,'.irf') || strcmp(file(end-7:end),'.ome.tif')
            obj.mode = 'TCSPC';
        else
            obj.mode = 'widefield';
        end
    end
    
    obj.file_names = {file};
    obj.channels = channel;
    
    if isempty(obj.names)
        % Set names from file names
        if strcmp(ext,'.sdt') || strcmp(ext,'.txt') || strcmp(ext,'.irf') 
            if isempty(obj.names)    
                obj.names{1} = name;
            end
        else
            path_parts = split(filesep,path);
            obj.names{1} = path_parts{end};
        end
    end
    
    obj.n_datasets = length(obj.names);
    
    obj.polarisation_resolved = polarisation_resolved;
    
    % open first file to get size etc
    [obj.t,data,obj.t_int] = load_flim_file(obj.file_names{1},channel,block);         
    
   
    data = obj.ensure_correct_dimensionality(data);
    obj.data_size = size(data);
    
    if obj.load_multiple_channels
        obj.data_size(5) = obj.data_size(2);
        obj.data_size(2) = 1;
    end
    
       
    obj.metadata = extract_metadata(obj.names);
    
    obj.load_selected_files();
        
    obj.init_dataset(data_setting_file);

end