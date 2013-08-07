function ic_importer()

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

%
addpath_global_analysis;              
%
settings = [];
%
if exist('ic_importer_settings.xml','file') 
    [ settings, ~ ] = xml_read ('ic_importer_settings.xml');    
    logon = settings.logon;
else
    logon = OMERO_logon();
end
%
data = createData();
    gui = createInterface(data);    
        updateInterface();    
%
%-------------------------------------------------------------------------%
    function data = createData()
        %
        if ~isempty(settings)
            data.DefaultDataDirectory = settings.DefaultDataDirectory;        
            data.image_annotation_file_extension = settings.image_annotation_file_extension;        
            data.load_dataset_annotations = settings.load_dataset_annotations;
            data.modulo = settings.modulo;
        else
            data.DefaultDataDirectory = 'c:\';        
            data.image_annotation_file_extension = 'none';        
            data.load_dataset_annotations = false;
            data.modulo = 'ModuloAlongT';
        end                    
        %
        data.client  = [];
        data.session  = [];            
        data.Destination = [];            
        %
        data.Source = [];
        data.DestinationName = [];
        %
        data.extension = '???';
        data.LoadMode = '???';  
        data.SingleFileMeaningLabel = '???';
        %
        %        
        data.dirlist = []; % list of directories to import for well plate
        data.dataset_annotations = [];                          
        %
        data.SourceList = [];
        data.BatchFileName = [];
        
    end % createData
%-------------------------------------------------------------------------%
    function gui = createInterface( data )
        %
        bckg_color = [.8 .8 .8];
        %
        gui = struct();
        % Open a window and add some menus
        gui.Window = figure( ...
            'Name', 'Imperial College Omero Importer', ...
            'NumberTitle', 'off', ...
            'MenuBar', 'none', ... % 
            'Position', [0 0 970 120], ... % ??? 'Position', [680 678 560 420], ...
            'Toolbar', 'none', ...
            'DockControls', 'off', ...
            'Resize', 'off', ...
            'Color',bckg_color, ...
            'HandleVisibility', 'off' );
        %
        set(gui.Window,'CloseRequestFcn',@onExit);
        %                
        % + File menu
        gui.menu_file = uimenu( gui.Window, 'Label', 'File' );
        uimenu( gui.menu_file, 'Label','Set data directory', 'Callback', @onSetDirectory );
        
% BATCH
uimenu( gui.menu_file, 'Label','Set list of data directories', 'Callback', @onSetDirectoryList );
        
        gui.menu_file_set_single = uimenu(gui.menu_file,'Label','Set image');
        gui.handles.menu_file_single_irf = uimenu(gui.menu_file_set_single,'Label','irf', 'Callback', @onSetFile);
        gui.handles.menu_file_single_bckg = uimenu(gui.menu_file_set_single,'Label','background', 'Callback', @onSetFile);        
        gui.handles.menu_file_single_tbckg = uimenu(gui.menu_file_set_single,'Label','time_varying_background', 'Callback', @onSetFile);        
        gui.handles.menu_file_single_intref = uimenu(gui.menu_file_set_single,'Label','intensity_reference', 'Callback', @onSetFile);        
        gui.handles.menu_file_single_Gfctr = uimenu(gui.menu_file_set_single,'Label','g_factor', 'Callback', @onSetFile);        
        gui.handles.menu_file_single_Gfctr = uimenu(gui.menu_file_set_single,'Label','sample', 'Callback', @onSetFile);        
        gui.handles.menu_file_single_Gfctr = uimenu(gui.menu_file_set_single,'Label','from image stack directory', 'Callback', @onSetFile);                
                      
        uimenu( gui.menu_file, 'Label', 'Exit', 'Callback', @onExit );        
        % + Omero menu
        gui.menu_omero = uimenu( gui.Window, 'Label', 'Omero' );
        gui.menu_logon = uimenu( gui.menu_omero, 'Label', 'Set logon default', 'Callback', @onLogon );        
        gui.menu_logon = uimenu( gui.menu_omero, 'Label', 'Restore logon', 'Callback', @onRestoreLogon );        
        gui.menu_setproject = uimenu( gui.menu_omero, 'Label','Set Project', 'Callback', @onSetDestination,'Separator','on' );
        gui.menu_setdataset = uimenu( gui.menu_omero, 'Label','Set Dataset', 'Callback', @onSetDestination );
        gui.menu_setproject = uimenu( gui.menu_omero, 'Label','Set Screen', 'Callback', @onSetDestination );        
        % + Upload menu
        %gui.menu_upload      = uimenu(gui.Window,'Label','Upload');
        %uimenu(gui.menu_upload,'Label','Go','Accelerator','G','Callback', @onGo);                                
        
        gui.menu_upload      = uimenu(gui.Window,'Label',data.modulo);
        uimenu(gui.menu_upload,'Label','ModuloAlongC','Callback', @onSetModuloAlong);                                
        uimenu(gui.menu_upload,'Label','ModuloAlongT','Callback', @onSetModuloAlong);                                
        uimenu(gui.menu_upload,'Label','ModuloAlongZ','Callback', @onSetModuloAlong);                                                        
        %
        % CONTROLS
        gui.ProjectNamePanel = uicontrol( 'Style', 'text','Parent',gui.Window,'String',data.DestinationName,'FontSize',10,'Position',[20 80 800 20],'BackgroundColor',bckg_color);          
        %
        gui.DirectoryNamePanel = uicontrol( 'Style', 'text', 'Parent',gui.Window,'String',data.Source,'FontSize',10,'Position',[20 60 800 20],'BackgroundColor',bckg_color);
        %
        gui.GoButton = uicontrol('Style', 'PushButton','Parent',gui.Window,'String','Go',...
             'Position',[20 20 100 20 ],'Callback', @onGo,'FontSize',10);
        %                          
        gui.Indicator = uicontrol('Style','text','Parent',gui.Window, 'BackgroundColor','red','Position',[150 20 100 20],'String',data.extension,'FontSize',10);
        %
        gui.ImageAnnotationFileExtensionPrompt = uicontrol( 'Style', 'text', ...
            'Parent',gui.Window, ...
            'String','Image annotation file extension', ...
            'BackgroundColor',bckg_color, ...
            'FontSize',10, ...
            'Position',[270 20 350 20]);
        %    
        gui.ImageAnnotationFileExtensionPopup = uicontrol('Parent',gui.Window,'Style', 'popup',...
            'String', 'none|xml|txt|xls|csv',...
            'FontSize',10, ...
            'Position', [540 20 70 24],...
            'BackgroundColor',bckg_color, ...           
            'Callback', @SetImageAnnotationFileExtension);
        %

        
        gui.DatasetAnnotationsCheckboxPrompt = uicontrol( 'Style', 'text', ...
            'Parent',gui.Window, ...
            'String','load common files as Dataset annotations', ...
            'BackgroundColor',bckg_color, ...
            'FontSize',10, ...
            'Position',[640 20 350 20]);
        %    
        gui.DatasetAnnotationsCheckbox = uicontrol('Parent',gui.Window,'Style', 'Checkbox',...
            'FontSize',10, ...
            'Position', [940 20 70 24],...
            'BackgroundColor',bckg_color, ...           
            'Callback', @SetDatasetAnnotationsCheckbox);
        %
                               
    end % createInterface
%-------------------------------------------------------------------------%
    function updateInterface()
        %
        if isempty(data.client)
            load_omero();      
                   if isempty(data.client)
                       onExit();
                       return;
                   end;
        end;        
        %
        % indicator panel
        Color = 'red';
        if ~isempty(data.Source) && ~isempty(data.DestinationName) && ~strcmp('???',data.extension)          
                Color = 'green';
        end
        %
        set(gui.ProjectNamePanel,'String',data.DestinationName);
        %        
        if ~isempty(data.SourceList) 
            set(gui.Indicator,'BackgroundColor',Color,'String','BATCH'); 
            set(gui.DirectoryNamePanel,'String',data.BatchFileName);                                            
        else
            set(gui.Indicator,'BackgroundColor',Color,'String',data.extension);
            set(gui.DirectoryNamePanel,'String',data.Source);                                
        end;        
        %                        
        if strcmp(data.image_annotation_file_extension,'none')
            set(gui.ImageAnnotationFileExtensionPopup,'Value',1);
        elseif strcmp(data.image_annotation_file_extension,'xml')
            set(gui.ImageAnnotationFileExtensionPopup,'Value',2);
        elseif strcmp(data.image_annotation_file_extension,'txt')
            set(gui.ImageAnnotationFileExtensionPopup,'Value',3);
        elseif strcmp(data.image_annotation_file_extension,'xls')
            set(gui.ImageAnnotationFileExtensionPopup,'Value',4);
        elseif strcmp(data.image_annotation_file_extension,'csv')
            set(gui.ImageAnnotationFileExtensionPopup,'Value',5);
        end                                                
        %
        %checkbox
        if data.load_dataset_annotations 
            set(gui.DatasetAnnotationsCheckbox,'Value',1);
        else
            set(gui.DatasetAnnotationsCheckbox,'Value',0);
        end
        %
        multiple_data_controls_visibility = 'on';
        %
        if strcmp('single file',data.LoadMode)
            multiple_data_controls_visibility = 'off';
        end
        %
        set(gui.ImageAnnotationFileExtensionPrompt, 'Visible', multiple_data_controls_visibility);
        set(gui.ImageAnnotationFileExtensionPopup, 'Visible', multiple_data_controls_visibility);
        set(gui.DatasetAnnotationsCheckboxPrompt, 'Visible', multiple_data_controls_visibility);
        set(gui.DatasetAnnotationsCheckbox, 'Visible', multiple_data_controls_visibility);
        %            
    end % updateInterface
%-------------------------------------------------------------------------%
    function onExit(~,~)
        %        
        if ~isempty(data.client)
            disp('Closing OMERO session');                
            data.client.closeSession();                
                save_settings();
        end        
        %
        delete(gui.Window);
            clear('gui');                 
                clear('data');                             
                    unloadOmero();                        
    end % onExit
%-------------------------------------------------------------------------%
    function onSetDirectory(~,~)     
        %
        data.SourceList = [];
        data.BatchFileName = [];
        
        data.Source = uigetdir(data.DefaultDataDirectory,'Select the folder containing the data');     
        %
        if 0 ~= data.Source
            %
            data.DefaultDataDirectory = data.Source;            
            set_directory_info();            
            updateInterface();
            %            
             if isempty(data.Destination) || strcmp(whos_Object(data.session,data.Destination.getId().getValue()),'Dataset')
                %
                prjct = select_Project(data.session,[],'Select Project');
                if ~isempty(prjct)
                    data.Destination = prjct;
                    data.DestinationName = char(java.lang.String(data.Destination.getName().getValue()));
                else
                    clear_settings();
                    return;
                end;
            end
            %                        
            updateInterface();
        end        
    end % onSetDirectory
%-------------------------------------------------------------------------%
    function onLogon(~,~)  
        %
        logon = OMERO_logon;
        data.client.closeSession();                        
        delete(gui.Window);
            clear('gui');                 
                clear('data');                             
        %
        load_omero();
        %
        if ~isempty(data.client)
            data = createData();
                gui = createInterface(data);        
                    updateInterface();
        end;
    end % onLogon
%-------------------------------------------------------------------------%
    function onRestoreLogon(~,~)  
        load_omero();
    end
%-------------------------------------------------------------------------%
    function onSetDestination(hObj,~,~)
                
        label = get(hObj,'Label');
        
        if strcmp(label,'Set Screen')        
            scrn = select_Screen(data.session,[],'Select screen');
            if ~isempty(scrn)
                data.Destination = scrn; 
                data.DestinationName = char(java.lang.String(data.Destination.getName().getValue()));                
            else
                return;
            end
            %
            if isempty(data.Source) || ~isdir(data.Source)
                onSetDirectory();
            end                    
                
        elseif strcmp(label,'Set Project')
            
            prjct = select_Project(data.session,[],'Select Project');             
            if ~isempty(prjct)
                data.Destination = prjct; 
                data.DestinationName = char(java.lang.String(data.Destination.getName().getValue()));                
            else
                return;
            end
            %
            if isempty(data.Source) || ~isdir(data.Source)
                onSetDirectory();
            end
            %
        else % need to set Dataset

            if isdir(data.Source)
                errordlg('please first choose an image you want to upload');
                return;
            end
                        
            [ dtst, ~ ] = select_Dataset(data.session,[],'Select Dataset');
            
            if ~isempty(dtst)
                data.Destination = dtst; % in  reality, dataset not project;
                data.DestinationName = char(java.lang.String(data.Destination.getName().getValue()));
            else
                return;
            end;           
            %                        
        end                   
        %
        updateInterface();

    end % onSetProject
%-------------------------------------------------------------------------%
    function onGo(~,~)                
        %
        if ~isempty(data.SourceList)
            % go through list                                    
            for d = 1:numel(data.SourceList)
                data.Source = char(data.SourceList{d});             
                set_directory_info();            
                updateInterface();                                
                import_directory();                
            end;                                             
            data.SourceList = [];
            data.BatchFileName = [];
            clear_settings;
            updateInterface;                                            
        else
            import_directory();             
        end        
        %
    end
%-------------------------------------------------------------------------%
    function import_directory()
        %
        if isempty(data.Source) || isempty(data.Destination)
            errordlg('either directory or project not set properly - can not continue');
            return;
        end
        %           
        whos_destination = whos_Object(data.session,data.Destination.getId().getValue());
        %        
        set(gui.Indicator,'String','..uploading..');
        %
        if (strcmp(data.extension,'tif') || strcmp(data.extension,'tiff') || strcmp(data.extension,'sdt') || strcmp(data.extension,'txt'))  && strcmp(data.LoadMode,'general')
            %
            if strcmp(whos_destination,'Project')
                
                new_dataset_id = upload_dir_as_Dataset(data.session,data.Destination,data.Source,data.extension,data.modulo);
                mydatasets = getDatasets(data.session,new_dataset_id); 
                new_dataset = mydatasets(1);                         
                %                        
                % IMAGE ANNOTATIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% (this is ugly)
                if ~strcmp(data.image_annotation_file_extension,'none')
                    proxy = data.session.getContainerService();
                    %Set the options
                    param = omero.sys.ParametersI();
                    %
                    param.leaves();
                    %
                    userId = data.session.getAdminService().getEventContext().userId; %id of the user.
                    param.exp(omero.rtypes.rlong(userId));
                    projectsList = proxy.loadContainerHierarchy('omero.model.Project', [], param);
                    %
                    for j = 0:projectsList.size()-1,
                        p = projectsList.get(j);
                        pid = java.lang.Long(p.getId().getValue());                
                        datasetsList = p.linkedDatasetList;
                        for i = 0:datasetsList.size()-1,                     
                             d = datasetsList.get(i);
                             did = java.lang.Long(d.getId().getValue());
                             imageList = d.linkedImageList;
                             for k = 0:imageList.size()-1,                       
                                 img = imageList.get(k);                         
                                 if pid == data.Destination.getId().getValue() && did == new_dataset_id
                                    attach_file_with_same_name_if_in_the_directory(img,data.image_annotation_file_extension,data.Source); 
                                 end
                             end 
                        end;
                    end;                                    
                end;
                
            elseif strcmp(whos_destination,'Dataset') % that means - one needs to upload dir as Omero Image to that Dataset
                        if strcmp(data.modulo,'ModuloAlongC'), errordlg('ModuloAlongC presetnly not supported'), return, end;
                        imgid = upload_dir_as_Omero_Image(data.session, data.Destination, data.Source,'tif',data.modulo,[]);
                        new_dataset = get_Object_by_Id(data.session,[],imgid);                
            end
                
            % IMAGE ANNOTATIONS - ENDS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
            %
        elseif strcmp(data.LoadMode,'well plate')
            
            new_dataset_id = upload_PlateReader_dir(data.session, data.Destination, data.Source, data.modulo);
            userId = data.session.getAdminService().getEventContext().userId;
            new_dataset = get_Object_by_Id(data.session,userId,new_dataset_id);            
            % myplates = getPlates(data.session,new_dataset_id); new_dataset = myplates(1);                         
            
        elseif strcmp(data.LoadMode,'single file')

                        if is_OME_tif(data.Source)
                            upload_Image_OME_tif(data.session,data.Destination,data.Source,' ');  
                        elseif  strcmp('txt',data.extension)                              
                            upload_Image_singlePix(data.session,data.Destination,data.Source,data.modulo);                                    
                        elseif strcmp('sdt',data.extension)
                            upload_Image_BH(data.session, data.Destination, data.Source, data.SingleFileMeaningLabel, data.modulo);
                        else
                            U = imread(data.Source,data.extension);
                            %
                            pixeltype = get_num_type(U);
                            %                                             
                            %str = split(filesep,data.Source);
                            strings1 = strrep(data.Source,filesep,'/');
                            str = split('/',strings1);                            
                            file_name = str(length(str));
                            %
                            % rearrange planes
                            [w,h,Nch] = size(U);
                            Z = zeros(Nch,h,w);
                            for c = 1:Nch,
                                Z(c,:,:) = squeeze(U(:,:,c))';
                            end;
                            img_description = ' ';
                            imageId = mat2omeroImage(data.session, Z, pixeltype, file_name,  img_description, [],'ModuloAlongC');
                            link = omero.model.DatasetImageLinkI;
                            link.setChild(omero.model.ImageI(imageId, false));
                            link.setParent(omero.model.DatasetI(data.Destination.getId().getValue(), false)); % in this case, "project" is Dataset
                            data.session.getUpdateService().saveAndReturnObject(link); 
                            %
                            % OME ANNOTATION
                            flimXMLmetadata.Image.Pixels.ATTRIBUTE.BigEndian = 'true';
                            flimXMLmetadata.Image.Pixels.ATTRIBUTE.DimensionOrder = 'XYCTZ'; % does not matter
                            flimXMLmetadata.Image.Pixels.ATTRIBUTE.ID = '?????';
                            flimXMLmetadata.Image.Pixels.ATTRIBUTE.PixelType = pixeltype;
                            flimXMLmetadata.Image.Pixels.ATTRIBUTE.SizeX = h; % :)
                            flimXMLmetadata.Image.Pixels.ATTRIBUTE.SizeY = w;
                            flimXMLmetadata.Image.Pixels.ATTRIBUTE.SizeZ = 1;
                            flimXMLmetadata.Image.Pixels.ATTRIBUTE.SizeC = Nch;
                            flimXMLmetadata.Image.Pixels.ATTRIBUTE.SizeT = 1;
                            %
                            flimXMLmetadata.Image.ContentsType = cellstr(data.SingleFileMeaningLabel);
                            %
                            xmlFileName = [tempdir 'metadata.xml'];
                            xml_write(xmlFileName,flimXMLmetadata);
                            %
                            namespace = 'IC_PHOTONICS';
                            description = ' ';
                            %
                            sha1 = char('pending');
                            file_mime_type = char('application/octet-stream');
                            %
                            myimages = getImages(data.session,imageId); image = myimages(1);
                            %
                            add_Annotation(data.session, [], ...
                                            image, ...
                                            sha1, ...
                                            file_mime_type, ...
                                            xmlFileName, ...
                                            description, ...
                                            namespace);    
                            %
                            delete(xmlFileName);
                            %                            
                        end                        
        elseif strcmp(data.LoadMode,'image from stack')                        
                        if strcmp(data.modulo,'ModuloAlongC'), errordlg('ModuloAlongC presetnly not supported'), return, end;
                        imgid = upload_dir_as_Omero_Image(data.session, data.Destination, data.Source,'tif',data.modulo,[]);
                        new_dataset = get_Object_by_Id(data.session,[],imgid);
        end % strcmp(data.LoadMode,'single file')
        %      
        if data.load_dataset_annotations
            for k=1:numel(data.dataset_annotations)
                    %
                    namespace = 'IC_PHOTONICS';
                    description = ' ';
                    %
                    sha1 = char('pending');
                    file_mime_type = char('application/octet-stream');
                    %
                    add_Annotation(data.session, [], ...
                        new_dataset, ... % not always "Dataset" :)
                        sha1, ...
                        file_mime_type, ...
                        data.dataset_annotations{k}, ...
                        description, ...
                        namespace);    
            end        
        end % if data.load_dataset_annotations
        %        
        clear_settings;
        updateInterface;        
    end % onGo
%-------------------------------------------------------------------------%
    function load_omero()
        try
            data.client = loadOmero(logon{1});
            data.session = data.client.createSession(logon{2},logon{3});
        catch
            data.client = [];
            data.session = [];
            errordlg('Error creating OMERO session');        
        end
    end % load_omero
%-------------------------------------------------------------------------%           
    function set_directory_info()
        % annotations first
        annotations = [];
        % check dataset annotations..
        annotations_extensions = {'xml' 'txt' 'csv' 'rtf' 'doc' 'docx' 'ppt' 'pdf' 'xls' 'xlsx' 'm' 'irf'};
        for k=1:numel(annotations_extensions)
            files = dir([data.Source filesep '*.' annotations_extensions{k}]);
            num_files = length(files);
                if 0 ~= num_files
                    annotations = [annotations; files];
                end
        end                        
        % fill the list of annotations
        data.dataset_annotations = [];
        for k=1:numel(annotations)
            data.dataset_annotations{k} = [data.Source filesep annotations(k).name]; %full name
            % disp(data.dataset_annotations{k});
        end                
        %
        data.extension = '???';
        data.LoadMode = '???';        
        extensions = {'tif' 'tiff' 'sdt' 'txt'};
        for k=1:numel(extensions)
            files = dir([data.Source filesep '*.' extensions{k}]);
            num_files = length(files);
                if 0 ~= num_files
                    data.extension = extensions{k};
                    data.LoadMode = 'general';   
                    return;
                end
        end              
        %                        
        % presume it is well-plate data...        
        data.dirlist = [];
        totlist = dir(data.Source);
        z = 0;
        for k=3:length(totlist)
            if 1==totlist(k).isdir
                z=z+1;
                data.dirlist{z}=[data.Source filesep totlist(k).name];
            end
        end   
        %
        data.extension = 'tif'; % this is bad
        data.LoadMode = 'well plate'; 
        %
    end % set_directory_info
%-------------------------------------------------------------------------%
    function clear_settings()
        data.Source = [];
        
        if isempty(data.SourceList)
            data.DestinationName = [];
            data.Destination = [];        
        end
                
        %
        data.extension = '???';
        data.LoadMode = '???';        
        data.SingleFileMeaningLabel = '???';
        %
        data.dirlist = []; % list of directories to import for well plate
        data.dataset_annotations = [];                 
    end % clear_settings
%-------------------------------------------------------------------------%  
    function save_settings()        
        ic_importer_settings = [];
        ic_importer_settings.logon = logon;
        ic_importer_settings.DefaultDataDirectory = data.DefaultDataDirectory;        
        ic_importer_settings.image_annotation_file_extension = data.image_annotation_file_extension;
        ic_importer_settings.load_dataset_annotations = data.load_dataset_annotations;
        ic_importer_settings.modulo = data.modulo;
        xml_write('ic_importer_settings.xml', ic_importer_settings);
    end % save_settings
%-------------------------------------------------------------------------%  
    function attach_file_with_same_name_if_in_the_directory(obj,extension,directory)
        %disp(obj.getName().getValue());
        filename_with_extension = char(java.lang.String(obj.getName().getValue()));
        str = split('.',filename_with_extension);
        filename = [char(directory) filesep char(str(1)) '.' extension];
        if exist(filename,'file')
            disp(filename);            
                %
                namespace = 'IC_PHOTONICS';
                description = ' ';
                %
                sha1 = char('pending');
                file_mime_type = char('application/octet-stream');
                %
                add_Annotation(data.session, [], ...
                    obj, ...
                    sha1, ...
                    file_mime_type, ...
                    filename, ...
                    description, ...
                    namespace);                                        
        end        
    end
%-------------------------------------------------------------------------%  
    function SetImageAnnotationFileExtension(hObj,~)
        val = get(hObj,'Value'); % 'none|xml|txt|xls|csv'
        if val ==1
          data.image_annotation_file_extension = 'none';  
        elseif val == 2
            data.image_annotation_file_extension = 'xml'; 
        elseif val == 3
            data.image_annotation_file_extension = 'txt';  
        elseif val == 4
            data.image_annotation_file_extension = 'xls';  
        elseif val == 5
            data.image_annotation_file_extension = 'csv'; 
        end        
    end
%-------------------------------------------------------------------------%  
    function SetDatasetAnnotationsCheckbox(hObj,~,~)
        if (get(hObj,'Value') == get(hObj,'Max'))
            data.load_dataset_annotations = true;
        else
            data.load_dataset_annotations = false;
        end
    end
%-------------------------------------------------------------------------%  
    function onSetFile(hObj,~,~)

        data.SingleFileMeaningLabel  = get(hObj,'Label');  
        
        if strcmp('from image stack directory',data.SingleFileMeaningLabel)
            directoryname = uigetdir(data.DefaultDataDirectory,'Select the folder containing the data');
            if isequal(directoryname,0), return, end;
            %
            OK_dir  = true;
            extension = 'tif';
            if OK_dir
                data.extension = extension;
                data.LoadMode = 'image from stack';
                data.Source = directoryname;
            end
            %            
            % ...annotation
            annotations = [];
            % check dataset annotations..
            annotations_extensions = {'xml' 'txt' 'csv' 'rtf' 'doc' 'docx' 'ppt' 'pdf' 'xls' 'xlsx' 'm' 'irf'};
            for k=1:numel(annotations_extensions)
                files = dir([data.Source filesep '*.' annotations_extensions{k}]);
                num_files = length(files);
                    if 0 ~= num_files
                        annotations = [annotations; files];
                    end
            end                        
            % fill the list of annotations
            data.dataset_annotations = [];
            for k=1:numel(annotations)
                data.dataset_annotations{k} = [data.Source filesep annotations(k).name]; %full name
                % disp(data.dataset_annotations{k});
            end                
            %
            data.load_dataset_annotations = true;      
            %
            data.DefaultDataDirectory = directoryname;
                                    
        else
            [filename, pathname] = uigetfile({'*.tif';'*.tiff';'*.sdt';'*.txt'},'Select File',data.DefaultDataDirectory);            
            if isequal(filename,0), return, end;
            %
            full_file_name = [pathname filesep filename]; % works;
            % check if file is OK - extension...
            str = split('.',full_file_name);
            extension = lower(str{length(str)});
            %
            if strcmp(extension,'tif') || strcmp(extension,'tiff') || strcmp(extension,'sdt') || strcmp(extension,'txt')
                %
                data.extension = extension;
                data.LoadMode = 'single file';
                data.Source = full_file_name;
                data.load_dataset_annotations = false;                                             
            end

            data.load_dataset_annotations = false;  
            %
            data.DefaultDataDirectory = pathname;                                                                
            
        end
                
        if ~isempty(data.Destination)
            whos_destination = whos_Object(data.session,data.Destination.getId().getValue());
        end;
        if isempty(data.Destination) || strcmp(whos_destination,'Project') || strcmp(whos_destination,'Plate')
        %
        [ dtst, ~ ] = select_Dataset(data.session,[],'Select Dataset');
            if ~isempty(dtst)
               data.Destination = dtst; % in  reality, dataset not project;
               data.DestinationName = char(java.lang.String(data.Destination.getName().getValue()));
            else
                clear_settings;
                return;
            end;
        end                
        %
        updateInterface();                                   
    end

    function onSetModuloAlong(hObj,~,~)
        label = get(hObj,'Label');
            data.modulo  = label;    
      set(gui.menu_upload,'Label',label);      
      updateInterface();                   
    end
%-------------------------------------------------------------------------%  
    function onSetDirectoryList(~,~)
        
                str = char(3,256);
                s1 = 'as Datasets (well plate..)';
                s2 = 'as SPW Plates (well plate..)';
                s3 = 'as Images (from stack)';
                s4 = 'as Images (general)';                
                str(1,1:length(s1)) = s1;
                str(2,1:length(s2)) = s2;
                str(3,1:length(s3)) = s3;
                str(4,1:length(s4)) = s4;                
                %
                [s,v] = listdlg('PromptString','Please specify how to transfer the data',...
                                'SelectionMode','single',...
                                'ListSize',[300 60],...                                
                                'ListString',str);
                %
                if ~v, return, end;
                %    
                switch (s)                    
                    case 1  %   as Datasets  
                                prjct = select_Project(data.session,[],'Select Project');             
                                if ~isempty(prjct)
                                    data.Destination = prjct; 
                                    data.DestinationName = char(java.lang.String(data.Destination.getName().getValue()));                
                                else
                                    return;
                                end                        
                    case 2  %   as SPW Plates
                                scrn = select_Screen(data.session,[],'Select screen');
                                if ~isempty(scrn)
                                    data.Destination = scrn; 
                                    data.DestinationName = char(java.lang.String(data.Destination.getName().getValue()));                
                                else
                                    return;
                                end                        
                    case 3  %   as Images (from stack)
                                [ dtst,~ ] = select_Dataset(data.session,[],'Select Dataset');            
                                if ~isempty(dtst)
                                    data.Destination = dtst; % in  reality, dataset not project;
                                    data.DestinationName = char(java.lang.String(data.Destination.getName().getValue()));
                                else
                                    return;
                                end;           
                    case 4  %   as Images (general)
                                prjct = select_Project(data.session,[],'Select Project');             
                                if ~isempty(prjct)
                                    data.Destination = prjct; 
                                    data.DestinationName = char(java.lang.String(data.Destination.getName().getValue()));                
                                else
                                    return;
                                end                                                                                                        
                end
                
            [file,path] = uigetfile('*.xlsx;*.xls','Select a text file containing list of data directories',data.DefaultDataDirectory);
            
            if file == 0, return, end;
                
                [~,dirs,~] = xlsread([path file]);
                
                for d=1:numel(dirs)                    
                    if ~isdir(char(dirs{d}))
                        errordlg(['Directory list has not been set: ' char(dirs{d}) ' not a directory']);
                        data.SourceList = [];
                        data.BatchFileName = [];
                        clear_settings;
                        updateInterface;                        
                        return;
                    end
                end
                %
                data.SourceList = dirs;
                data.BatchFileName = [path file];
                %
                hw = waitbar(0, 'checking Directory List, please wait...');
                for d = 1:numel(data.SourceList)                    
                    data.Source = char(data.SourceList{d});             
                    updateInterface;                                                                        
                    set_directory_info;  
                    if ~(strcmp(data.LoadMode,'well plate') || strcmp(data.LoadMode,'general'))
                        errordlg(['Not data directory: ' data.SourceList{d} ' , batch is not set!']);
                        data.SourceList = [];
                        data.BatchFileName = [];
                        clear_settings;
                        delete(hw);
                        drawnow;                        
                        updateInterface;
                        return;
                    end
                    waitbar(d/numel(data.SourceList), hw);
                    drawnow;                    
                end;                                             
                delete(hw);
                drawnow;
                
                data.DefaultDataDirectory = path;                                                                
    end
                              
end % EOF