function varargout = OscSpecDAQ_Duino(varargin)
% OSCSPECDAQ_DUINO MATLAB code for OscSpecDAQ_Duino.fig
%      OSCSPECDAQ_DUINO, by itself, creates a new OSCSPECDAQ_DUINO or raises the existing
%      singleton*.
%
%      H = OSCSPECDAQ_DUINO returns the handle to a new OSCSPECDAQ_DUINO or the handle to
%      the existing singleton*.
%
%      OSCSPECDAQ_DUINO('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in OSCSPECDAQ_DUINO.M with the given input arguments.
%
%      OSCSPECDAQ_DUINO('Property','Value',...) creates a new OSCSPECDAQ_DUINO or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before OscSpecDAQ_Duino_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to OscSpecDAQ_Duino_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help OscSpecDAQ_Duino

% Last Modified by GUIDE v2.5 27-Mar-2016 06:40:47

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @OscSpecDAQ_Duino_OpeningFcn, ...
                   'gui_OutputFcn',  @OscSpecDAQ_Duino_OutputFcn, ...
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


% --- Executes just before OscSpecDAQ_Duino is made visible.
function OscSpecDAQ_Duino_OpeningFcn(hObject, ~, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to OscSpecDAQ_Duino (see VARARGIN)

% Choose default command line output for OscSpecDAQ_Duino
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes OscSpecDAQ_Duino wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = OscSpecDAQ_Duino_OutputFcn(~, ~, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in Osc.
function Osc_Callback(~, ~, ~)
% hObject    handle to Osc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of Osc


% --- Executes on button press in Spect.
function Spect_Callback(~, ~, ~)
% hObject    handle to Spect (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of Spect


% --- Executes on button press in DAQ.
function DAQ_Callback(~, ~, ~)
% hObject    handle to DAQ (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of DAQ


% --- Executes on button press in RUN.
function RUN_Callback(~, ~, handles)
% hObject    handle to RUN (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of RUN
if get(handles.Osc, 'value') || get(handles.Spect, 'value') || get(handles.DAQ, 'value')
    try
        if( ~isempty(instrfindall) )
            fclose(instrfindall); delete(instrfindall);
        end
        Arduino = serial(get(handles.PortName, 'String'));
        Fs = 666666;
        SampleNum = 2^14;
        t = SampleNum / Fs;
        Arduino.InputBufferSize = 3 * SampleNum;
        if get(handles.Osc, 'value')
            HTS = dsp.TimeScope('SampleRate', 666666, 'TimeSpan', t);
        end
        if get(handles.Spect, 'value')
            HSA = dsp.SpectrumAnalyzer('SampleRate', Fs);
        end
        if get(handles.DAQ, 'value')
            FileName = get(handles.FileName, 'String');
            file = fopen(FileName, 'wb');
            if file < 3
                errordlg({'Error : Uncorrect File Neme', ...
                    'Check name of your file is compatiple with file names.', ...
                    'Check path of file.'}, ' !!   ERROR   !!')
            end
            fclose(file);
            movefile(FileName);
            if ~isempty(find(FileName == '\', 1))
                TempFileName = [ FileName(1 : find(FileName == '\', 1, 'last' )), 'TempFile'];
            else
                TempFileName = 'TempFile';
            end
            TempFile = file(TwmpFileName, 'wb');
            if TempFile < 3
                errordlg('Error : Cannot to Create Temporary File', ' !!   ERROR   !!');
            end
        end
        fopen(Arduino);
    catch ex
        errordlg({'Error : ', ex.message}, ' !!   ERROR   !! ');
    end
end
    
try
    if get(handles.Osc, 'value') && get(handles.Spect, 'value') && get(handles.DAQ, 'value')
        while strcmp(Arduino.Status, 'closed'), end
        while get(handles.RUN, 'value')
            data = fread(Arduino, SampleNum, 'uint16');
            step(HTS, data);
            step(HSA, data);
            fwrite(TempFile, data, 'uint16');
            fclose(TempFile);
            movefile(TempFile, FileName);
            TempFile = file(TempFileName, 'wb');            
        end
        fclose(Arduino); delete(Arduino);
        return;
    elseif get(handles.Osc, 'value') && get(handles.Spect, 'value')
        while strcmp(Arduino.Status, 'closed'), end
        while get(handles.RUN, 'value')
            data = fread(Arduino, SampleNum, 'uint16');
            step(HTS, data);
            step(HSA, data);
        end
        fclose(Arduino); delete(Arduino);
        return;
    elseif get(handles.Osc, 'value') && get(handles.DAQ, 'value')
        while strcmp(Arduino.Status, 'closed'), end
        while get(handles.RUN, 'value')
            data = fread(Arduino, SampleNum, 'uint16');
            step(HTS, data);
            fwrite(TempFile, data, 'uint16');
            fclose(TempFile);
            movefile(TempFile, FileName);
            TempFile = file(TempFileName, 'wb');            
        end
        fclose(Arduino); delete(Arduino);
        return;
    elseif get(handles.Spect, 'value') && get(handles.DAQ, 'value')
        while strcmp(Arduino.Status, 'closed'), end
        while get(handles.RUN, 'value')
            data = fread(Arduino, SampleNum, 'uint16');
            step(HSA, data);
            fwrite(TempFile, data, 'uint16');
            fclose(TempFile);
            movefile(TempFile, FileName);
            TempFile = file(TempFileName, 'wb');            
        end
        fclose(Arduino); delete(Arduino);
        return;
    elseif get(handles.Osc, 'value')
        while strcmp(Arduino.Status, 'closed'), end
        while get(handles.RUN, 'value')
            data = fread(Arduino, SampleNum, 'uint16');
            step(HTS, data);         
        end
        fclose(Arduino); delete(Arduino);
        return;
    elseif get(handles.Spect, 'value')
        while strcmp(Arduino.Status, 'closed'), end
        while get(handles.RUN, 'value')
            data = fread(Arduino, SampleNum, 'uint16');
            step(HSA, data);         
        end
        fclose(Arduino); delete(Arduino);
        return;
    elseif get(handles.DAQ, 'value')
        while strcmp(Arduino.Status, 'closed'), end
        while get(handles.RUN, 'value')
            data = fread(Arduino, SampleNum, 'uint16');
            fwrite(TempFile, data, 'uint16');
            fclose(TempFile);
            movefile(TempFile, FileName);
            TempFile = file(TwmpFileName, 'wb');            
        end
        fclose(Arduino); delete(Arduino);
        return;
    end
catch ex
    msgbox({'Error ...', ex.message}, ' !!   ERROR   !! ')
end



function PortName_Callback(~, ~, ~)
% hObject    handle to PortName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of PortName as text
%        str2double(get(hObject,'String')) returns contents of PortName as a double


% --- Executes during object creation, after setting all properties.
function PortName_CreateFcn(hObject, ~, ~)
% hObject    handle to PortName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function FileName_Callback(~, ~, ~)
% hObject    handle to FileName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of FileName as text
%        str2double(get(hObject,'String')) returns contents of FileName as a double


% --- Executes during object creation, after setting all properties.
function FileName_CreateFcn(hObject, ~, ~)
% hObject    handle to FileName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
