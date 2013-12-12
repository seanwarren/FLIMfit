function [dim, data] = get_image_dimensions( file, session)

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

    if nargin ==1 
        session = [];       % session NA for files (OMERO only)
    end
    
    
    dim = [];    
    
     
     
     [~,name,ext] = fileparts(file)
     
     
     
     
     
     
     
     
     
     
  
     if ~isempty(strfind(ext,'tif'))
        dim.FLIM_type = 'widefield';
        
     else
        dim.FLIM_type = 'TCSPC';        
     end
        
     % Load first file/folder to get sizes etc. 
     
     
     [dim.delays,data,t_int] = load_flim_file(file); 
     data_size = size(data)
     
     dim.sizeX = data_size(end -1);
     dim.sizeY = data_size(end);
     
     dim.modulo = []; % NA for files
        
     
    
   
        
    end
    
    
                  
             

        
    
    
  