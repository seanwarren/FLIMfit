function varargout = CB_selection(varargin)
% CB_SELECTION MATLAB code for CB_selection.fig
%      CB_SELECTION, by itself, creates a new CB_SELECTION or raises the existing
%      singleton*.
%
%      H = CB_SELECTION returns the handle to a new CB_SELECTION or the handle to
%      the existing singleton*.
%
%      CB_SELECTION('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in CB_SELECTION.M with the given input arguments.
%
%      CB_SELECTION('Property','Value',...) creates a new CB_SELECTION or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before CB_selection_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to CB_selection_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help CB_selection

% Last Modified by GUIDE v2.5 21-Oct-2013 16:42:23

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @CB_selection_OpeningFcn, ...
                   'gui_OutputFcn',  @CB_selection_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before CB_selection is made visible.
function CB_selection_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to CB_selection (see VARARGIN)

% Choose default command line output for CB_selection
handles.output = hObject;


CBSize = varargin{1};
nchannels = CBSize(1);
nblocks = CBSize(2);



polarisation_resolved = varargin{2};
handles.polarisation_resolved = polarisation_resolved;


if ~polarisation_resolved
    set(handles.uitableB,'Visible','off');
    name{1} = '';
   name{2} = '  Channel  ';
   set(handles.uitablePar,'ColumnName',name);
   name{2} = '  Block  ';
   set(handles.uitablePerp,'ColumnName',name);
    
    
    if nblocks < 2
        set(handles.uitablePerp,'Visible','off');
    end
else
    if nblocks < 2
        set(handles.uitableB,'Visible','off');
    end
    
end
    

handles.nchannels = nchannels;
handles.nblocks = nblocks;



handles.maxPar = 1;
handles.maxPerp = 1;
handles.maxB = 1;


handles.minPar = 1;
handles.minPerp = 1;
handles.minB = 1;

% only one channel and/or block allowed
maxPar = 1;
maxPerp = 1;
maxB = 1;



dataPar(:,1) = num2cell(1:nchannels);
dataPar(:,2)= num2cell( false(nchannels,1));
dataPerp = dataPar;
dataPar(1:maxPar,2) = num2cell(true);
set(handles.uitablePar,'Data',dataPar);


dataPerp(2,2) = num2cell(true);



dataB(:,1) = num2cell(1:nblocks);
dataB(:,2)= num2cell( false(nblocks,1));
dataB(1:maxB,2) = num2cell(true);
set(handles.uitableB,'Data',dataB);

if ~polarisation_resolved
    dataPerp = dataB;
end

set(handles.uitablePerp,'Data',dataPerp);


% Update handles structure
guidata(hObject, handles);

% UIWAIT makes CB_selection wait for user response (see UIRESUME)
 uiwait(handles.figure1);
 
 



% --- Outputs from this function are returned to the command line.
function varargout = CB_selection_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
if isempty(handles)
    varargout{1} = [];
else
 varargout{1} = handles.output;
 delete(handles.figure1);

end


% --- Executes when entered data in editable cell(s) in uitablePar.
function uitablePar_CellEditCallback(hObject, eventdata, handles)
% hObject    handle to uitablePar (see GCBO)
% eventdata  structure with the following fields (see UITABLE)
%	Indices: row and column indices of the cell(s) edite
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. Empty if Data was not changed
%	Error: error string when failed to convert EditData to appropriate value for Data
% handles    structure with handles and user data (see GUIDATA)
data=get(hObject,'Data'); % get the data cell array of the table
sett = cell2mat(squeeze(data(:,2)));
if eventdata.EditData % if the checkbox was set to true
    if handles.polarisation_resolved  % ensure that the same channel is not selected in 'Channel perpendicular'
        pressed = eventdata.Indices(1);
        dataPerp = get(handles.uitablePerp,'Data');
        setInPerp = cell2mat(squeeze(dataPerp(:,2)));
        if(setInPerp(pressed)) == 1
            dataPerp(pressed,2) = num2cell(false);
            % assuming here that only one channel may be selected
            if pressed == 1
                dataPerp(2,2) = num2cell(true);
            else
                dataPerp(1,2) = num2cell(true);
            end    
            set(handles.uitablePerp,'Data',dataPerp);
        end
    end
    if sum(sett) > handles.maxPar
        sett(eventdata.Indices(1) ) = 0;  %eliminate the box just ticked from enquiries
        first = squeeze(find(sett,1));
        data(first,2) = num2cell(false);  
    end   
else
    if sum(sett) <= handles.minPar
        sett(eventdata.Indices(1) ) = 1;  %eliminate the box just unticked from enquiries
        first = squeeze(find(sett==0,1));
        if isempty(first)
            first = eventdata.Indices(1);   % no choice
        end
        data(first,2) = num2cell(true);  
    end     
end

set(hObject,'Data',data); % now set the table's data to the updated data cell array
% Update handles structure
guidata(hObject, handles);







% --- Executes when entered data in editable cell(s) in uitablePerp.
function uitablePerp_CellEditCallback(hObject, eventdata, handles)
% hObject    handle to uitablePerp (see GCBO)
% eventdata  structure with the following fields (see UITABLE)
%	Indices: row and column indices of the cell(s) edited
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. Empty if Data was not changed
%	Error: error string when failed to convert EditData to appropriate value for Data
% handles    structure with handles and user data (see GUIDATA)
data=get(hObject,'Data'); % get the data cell array of the table
sett = cell2mat(squeeze(data(:,2)));
if eventdata.EditData % if the checkbox was set to true
    if handles.polarisation_resolved  % ensure that the same channel is not selected in 'Channel parallel'
        pressed = eventdata.Indices(1);
        dataPar = get(handles.uitablePar,'Data');
        setInPar = cell2mat(squeeze(dataPar(:,2)));
        if(setInPar(pressed)) == 1
            dataPar(pressed,2) = num2cell(false);
            % assuming here that only one channel may be selected
            if pressed == 1
                dataPar(2,2) = num2cell(true);
            else
                dataPar(1,2) = num2cell(true);
            end    
            set(handles.uitablePar,'Data',dataPar);
        end
    end
    
    
    if sum(sett) > handles.maxPerp
        sett(eventdata.Indices(1) ) = 0;  %eliminate the box just ticked from enquiries
        first = squeeze(find(sett,1));
        data(first,2) = num2cell(false);  
          
    end
else
    if sum(sett) <= handles.minPerp
        sett(eventdata.Indices(1) ) = 1;  %eliminate the box just unticked from enquiries
        first = squeeze(find(sett == 0,1));
        if isempty(first)
            first = eventdata.Indices(1);   % no choice
        end
        data(first,2) = num2cell(true);  
    end   
     
end

set(hObject,'Data',data); % now set the table's data to the updated data cell array
% Update handles structure
guidata(hObject, handles);

       

% --- Executes when entered data in editable cell(s) in uitableB.
function uitableB_CellEditCallback(hObject, eventdata, handles)
% hObject    handle to uitablePerp (see GCBO)
% eventdata  structure with the following fields (see UITABLE)
%	Indices: row and column indices of the cell(s) edited
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. Empty if Data was not changed
%	Error: error string when failed to convert EditData to appropriate value for Data
% handles    structure with handles and user data (see GUIDATA)
data=get(hObject,'Data'); % get the data cell array of the table
sett = cell2mat(squeeze(data(:,2)));
if eventdata.EditData % if the checkbox was set to true
    
    if sum(sett) > handles.maxB
        sett(eventdata.Indices(1) ) = 0;  %eliminate the box just ticked from enquiries
        first = squeeze(find(sett,1));
        data(first,2) = num2cell(false);  
    end   
else
    if sum(sett) <= handles.minB
        sett(eventdata.Indices(1) ) = 1;  %eliminate the box just unticked from enquiries
        first = squeeze(find(sett == 0,1));
        if isempty(first)
            first = eventdata.Indices(1);   % no choice
        end
        data(first,2) = num2cell(true);  
    end   
     
end

set(hObject,'Data',data); % now set the table's data to the updated data cell array
% Update handles structure
guidata(hObject, handles);





% --- Executes on button press in selectButton.
function selectButton_Callback(hObject, eventdata, handles)
% hObject    handle to selectButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

dataPar = get(handles.uitablePar,'Data');
sel = cell2mat(dataPar(:,2));
nums = cell2mat(dataPar(:,1));
Par = nums(sel ~= 0)';


dataPerp = get(handles.uitablePerp,'Data');
sel = cell2mat(dataPerp(:,2));
nums = cell2mat(dataPerp(:,1));
Perp = nums(sel ~= 0)';


dataB = get(handles.uitableB,'Data');
sel = cell2mat(dataB(:,2));
nums = cell2mat(dataB(:,1));
B = nums(sel ~= 0)';

if handles.polarisation_resolved
    handles.output = {[Par Perp], B}
else
    handles.output = {Par,B };
end


guidata(hObject,handles);

uiresume(handles.figure1);
