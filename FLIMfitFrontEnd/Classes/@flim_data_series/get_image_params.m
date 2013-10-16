function ret = get_image_params( file, session,)

% find the image size & type from a file


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


    
    ret = [];    
    
     s = [];
     
     
     % find no of channels
     [n_chan, chan_info] = get_channels(file);
     
     [~,name,ext] = fileparts(file);
    
     
     if isempty(strfind(ext,'tif'))
        ret.FLIM_type = 'widefield';
     else
        ret.FLIM_type = 'TCSPC';        
     end
        
     % Load first folder to get sizes etc. 
     %(Inneficient! TBD find a better way)
     
     [ret.delays,data,t_int] = load_flim_file(file); 
     data_size = size(data);
     
     ret.sizeX = data_size(2);
     ret.sizeY = data_size(3);
     
     ret.modulo = []; % NA for files
        
     
    
   
        
    end
    
    
                  
             

        
    
    
  