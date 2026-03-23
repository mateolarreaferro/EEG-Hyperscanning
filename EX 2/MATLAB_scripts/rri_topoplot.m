function figure_handle = rri_topoplot (data, arg1, arg2)

% This function plots MEG/EEG data as a topographic map 
%
% adopted from EEGLAB 'topoplot'
%
% Input arguments:
% required:
%	data     =   vector of length equal to the number of MEG channels
%				    (typically 150 or 151) containing the data in the order
%				    of MEG channels in the original data set
%	arg1 =   information about the EEG electrode or MEG sensor positions
%			 arg1 could be
%			 - a CTF channel_header structure
%	         - a full path of the CTF dataset 
%			 - a .xyz electrode layout file
%			 
%            if arg1 is missing, the default location file 'ctf.xyz' will be used
%			 if rri_topoplot is called repeatedly for the same electrode/sensor layout,
%			 arg1 has to be provided at the first call only; the default layout ctf.xyz
%			 will be updated accordingly. 
%				 
%	arg2 =   options according to the EEGlab function topoplot:
%--------------------
%
% 	options = string containing pairs of options/paramrters:	
%
%
%    'maplimits'       - 'absmax'   -> scale map colors to +/- the absolute-max (makes green 0); 
%                        'maxmin'   -> scale colors to the data range (makes green mid-range); 
%                        [lo.hi]    -> use user-definined lo/hi limits
%                        {default: 'absmax'}
%    'style'           - 'map'      -> plot colored map only
%                        'contour'  -> plot contour lines only
%                        'both'     -> plot both colored map and contour lines
%                        'fill'     -> plot constant color between contour lines
%                        'blank'    -> plot electrode locations only {default: 'both'}
%    'electrodes'      - 'on','off','labels','numbers','ptslabels','ptsnumbers'. To set the 'pts' 
%                        marker,,see 'Plot detail options' below. {default: 'on' -> mark electrode 
%                        locations with points ('.') unless more than 64 channels, then 'off'}. 
%    'plotchans'       - [vector] channel numbers (indices) to use in making the head plot. 
%                        {default: [] -> plot all chans}
%    'chantype'        - cell array of channel type(s) to plot. Will also accept a single quoted
%                        string type. Channel type for channel k is field EEG.chanlocs(k).type. 
%                        If present, overrides 'plotchans' and also 'chaninfo' with field 
%                        'chantype'. Ex. 'EEG' or {'EEG','EOG'} {default: all, or 'plotchans' arg}
%    'plotgrid'        - [channels] Plot channel data in one or more rectangular grids, as 
%                        specified by [channels],  a position matrix of channel numbers defining 
%                        the topographic locations of the channels in the grid. Zero values are 
%                        given the figure background color; negative integers, the color of the 
%                        polarity-reversed channel values.  Ex: >> figure; ...
%                         >> topoplot(values,'chanlocs','plotgrid',[11 12 0; 13 14 15]);
%                        % Plot a (2,3) grid of data values from channels 11-15 with one empty 
%                        grid cell (top right) {default: no grid plot} 
%    'nosedir'         - ['+X'|'-X'|'+Y'|'-Y'] direction of nose {default: '+X'}
%    'chaninfo'        - [struct] optional structure containing fields 'nosedir', 'plotrad' 
%                        and/or 'chantype'. See these (separate) field definitions above, below.
%                        {default: nosedir +X, plotrad 0.5, all channels}
%    'plotrad'         - [0.15<=float<=1.0] plotting radius = max channel arc_length to plot.
%                        See >> topoplot example. If plotrad > 0.5, chans with arc_length > 0.5 
%                        (i.e. below ears-eyes) are plotted in a circular 'skirt' outside the
%                        cartoon head. See 'intrad' below. {default: max(max(chanlocs.radius),0.5);
%                        If the chanlocs structure includes a field chanlocs.plotrad, its value 
%                        is used by default}.
%    'headrad'         - [0.15<=float<=1.0] drawing radius (arc_length) for the cartoon head. 
%                        NOTE: Only headrad = 0.5 is anatomically correct! 0 -> don't draw head; 
%                        'rim' -> show cartoon head at outer edge of the plot {default: 0.5}
%    'intrad'          - [0.15<=float<=1.0] radius of the scalp map interpolation area (square or 
%                        disk, see 'intsquare' below). Interpolate electrodes in this area and use 
%                        this limit to define boundaries of the scalp map interpolated data matrix
%                        {default: max channel location radius}
%    'intsquare'       - ['on'|'off'] 'on' -> Interpolate values at electrodes located in the whole 
%                        square containing the (radius intrad) interpolation disk; 'off' -> Interpolate
%                        values from electrodes shown in the interpolation disk only {default: 'on'}.
%    'conv'            - ['on'|'off'] Show map interpolation only out to the convext hull of
%                        the electrode locations to minimize extrapolation.  {default: 'off'}
%    'noplot'          - ['on'|'off'|[rad theta]] do not plot (but return interpolated data).
%                        Else, if [rad theta] are coordinates of a (possibly missing) channel, 
%                        returns interpolated value for channel location.  For more info, 
%                        see >> topoplot 'example' {default: 'off'}
%    'verbose'         - ['on'|'off'] comment on operations on command line {default: 'on'}.
% 
%  Plot detail options:
%    'drawaxis'        - ['on'|'off'] draw axis on the top left corner.
%    'emarker'         - Matlab marker char | {markerchar color size linewidth} char, else cell array 
%                        specifying the electrode 'pts' marker. Ex: {'s','r',32,1} -> 32-point solid 
%                        red square. {default: {'.','k',[],1} where marker size ([]) depends on the number 
%                        of channels plotted}.
%    'emarker2'        - {markchans}|{markchans marker color size linewidth} cell array specifying 
%                        an alternate marker for specified 'plotchans'. Ex: {[3 17],'s','g'} 
%                        {default: none, or if {markchans} only are specified, then {markchans,'o','r',10,1}}
%    'hcolor'          - color of the cartoon head. Use 'hcolor','none' to plot no head. {default: 'k' = black}
%    'shading'         - 'flat','interp'  {default: 'flat'}
%    'numcontour'      - number of contour lines {default: 6}
%    'contourvals'     - values for contour {default: same as input values}
%    'pmask'           - values for masking topoplot. Array of zeros and 1 of the same size as the input 
%                        value array {default: []}
%    'color'           - color of the contours {default: dark grey}
%    'whitebk '        -  ('on'|'off') make the background color white (e.g., to print empty plotgrid channels) 
%                        {default: 'off'}
%    'gridscale'       - [int > 32] size (nrows) of interpolated scalp map data matrix {default: 67}
%    'colormap'        -  (n,3) any size colormap {default: existing colormap}
%    'circgrid'        - [int > 100] number of elements (angles) in head and border circles {201}
% 
%  Dipole plotting options:
%    'dipole'          - [xi yi xe ye ze] plot dipole on the top of the scalp map
%                        from coordinate (xi,yi) to coordinates (xe,ye,ze) (dipole head 
%                        model has radius 1). If several rows, plot one dipole per row.
%                        Coordinates returned by dipplot() may be used. Can accept
%                        an EEG.dipfit.model structure (See >> help dipplot).
%                        Ex: ,'dipole',EEG.dipfit.model(17) % Plot dipole(s) for comp. 17.
%    'dipnorm'         - ['on'|'off'] normalize dipole length {default: 'on'}.
%    'diporient'       - [-1|1] invert dipole orientation {default: 1}.
%    'diplen'          - [real] scale dipole length {default: 1}.
%    'dipscale'        - [real] scale dipole size {default: 1}.
%    'dipsphere'       - [real] size of the dipole sphere. {default: 85 mm}.
%    'dipcolor'        - [color] dipole color as Matlab code code or [r g b] vector
%                        {default: 'k' = black}.
%
% Output arguments:
%	figure handle

ctf_montage_file='./ctf.xyz';
EEG64_montage_file='./EEG64.xyz';
montage_file=ctf_montage_file;

EEG64_def_options={'plotrad',0.56,'conv','on'};

figure_handle=0;
if nargin < 1
    fprintf('ERROR rri_colorplot: not enough input parameters');
    return;
end

assumeTypes={'EEG64','CTF151','CTF256'};

in_nchan=length(data);
if in_nchan==64
	assumeType=1;
	montage_file=EEG64_montage_file;
elseif in_nchan>140 && in_nchan<=151
	assumeType=2;
	montage_file=ctf_montage_file;
elseif in_nchan>260
	assumeType=3;
	montage_file=ctf_montage_file;
else
	assumeType=0;
end

if nargin == 1, 
	ds_input=[]; 
	options=[];
end;

c_head=[];
dsname=[];
if nargin>=2
	if isstruct(arg1)
		c_head=arg1;
		if ~isfield(c_head,'ChnNumber')
			c_head=[];
		end
	elseif isstr(arg1)
		if exist(arg1,'dir')
			dsname=arg1;
		elseif exist(arg1,'file')
			montage_file=arg1;
		end
	end
end
if nargin==3
	if isstruct(arg2)
		c_head=arg1;
		if ~isfield(c_head,'ChnNumber')
			c_head=[];
		end
	elseif isstr(arg2)
		if exist(arg1,'dir')
			dsname=arg1;
		elseif exist(arg1,'file')
			montage_file=arg1;
		end
	end
end

options=[];
if nargin>=2
	if iscell(arg1)
		options=arg1;
	end
end
if nargin==3
	if iscell(arg2)
		options=arg2;
	end
end

if assumeType==1
	options=[EEG64_def_options,options];
end

	
if ~isempty(dsname) 
	arg=struct;
	arg.dsname=dsname;
	arg.channels='MEG';
	arg.trials=[];
	ds=rri_readMEG(arg);
	c_head=ds.c_head;
end

if isempty(c_head)
	use_default_header=true;
	use_c_head=false;
else
	use_default_header=false;
	use_c_head=true;
end

%default_header
if use_default_header

	if exist(montage_file)

	else	
		switch assumeType
		case 1
			nchan=64;
			EEG64_xyz={...
			'1 , -2.285379 , 10.37229 , 4.564709 , Fp1';	'2 , 0.687462 , 10.931931 , 4.452579 , Fpz';...
			'3 , 3.874373 , 9.896583 , 4.368097 , Fp2';		'4 , -2.82271 , 9.895013 , 6.833403 , AF3';...
			'5 , 4.143959 , 9.607678 , 7.067061 , AF4';		'6 , -6.417786 , 6.362997 , 4.476012 , F7';...
			'7 , -5.745505 , 7.282387 , 6.764246 , F5';		'8 , -4.248579 , 7.990933 , 8.731880 , F3';...
			'9 , -2.046628 , 8.049909 , 10.162745 , F1';	'10 , 0.716282 , 7.836015 , 10.88362 , Fz';...
			'11 , 3.193455 , 7.889754 , 10.312743 , F2';	'12 , 5.337832 , 7.691511 , 8.678795 , F4';...
			'13 , 6.842302 , 6.643506 , 6.300108 , F6';		'14 , 7.197982 , 5.671902 , 4.245699 , F8';...
			'15 , -7.326021 , 3.749974 , 4.734323 , FT7';	'16 , -6.882368 , 4.211114 , 7.939393 , FC5';...
			'17 , -4.837038 , 4.672796 , 10.955297 , FC3';	'18 , -2.677567 , 4.478631 , 12.365311 , FC1';...
			'19 , 0.455027 , 4.186858 , 13.104445 , FCz';	'20 , 3.654295 , 4.254963 , 12.205945 , FC2';...
			'21 , 5.863695 , 4.275586 , 10.714709 , FC4';	'22 , 7.610693 , 3.851083 , 7.604854 , FC6';...
			'23 , 7.821661 , 3.188780 , 4.400032 , FT8';	'24 , -7.640498 , 0.756314 , 4.967095 , T7';...
			'25 , -7.230136 , 0.725585 , 8.331517 , C5';	'26 , -5.748005 , 0.480691 , 11.193904 , C3';...
			'27 , -3.009834 , 0.621885 , 13.441012 , C1';	'28 , 0.341982 , 0.449246 , 13.839247 , Cz';...
			'29 , 3.621260 , 0.316760 , 13.082255 , C2';	'30 , 6.418348 , 0.200262 , 11.178412 , C4';...
			'31 , 7.743287 , 0.254288 , 8.143276 , C6';		'32 , 8.214926 , 0.533799 , 4.980188 , T8';...
			'33 , -6.713948 , -3.516109 , 0.480004 , M1';	'34 , -7.794727 , -1.924366 , 4.686678 , TP7';...
			'35 , -7.103159	, -2.735806 , 7.908936 , CP5';	'36 , -5.549734 , -3.131109 , 10.995642 , CP3';...
			'37 , -3.111164 , -3.281632 , 12.904391 , CP1';	'38 , -0.072857 , -3.405421 , 13.509398 , CPz';...
			'39 , 3.044321 , -3.820854 , 12.781214 , CP2';	'40 , 5.712892 , -3.643826 , 10.907982 , CP4';...
			'41 , 7.304755 , -3.111501 , 7.913397 , CP6';	'42 , 7.927150 , -2.443219 , 4.673271 , TP8';...
			'43 , 7.079929 , -2.825894 , 0.594742 , M2';	'44 , -7.161848 , -4.799244 , 4.411572 , P7';...
			'45 , -6.375708 , -5.683398 , 7.142764 , P5';	'46 , -5.117089 , -6.324777 , 9.046002 , P3';...
			'47 , -2.82460 , -6.605847 , 10.717917 , P1';	'48 , -0.19569 , -6.696784 , 11.505725 , Pz';...
			'49 , 2.396374 , -7.077637 , 10.585553 , P2';	'50 , 4.802065 , -6.824497 , 8.991351 , P4';...
			'51 , 6.172683 , -6.209247 , 7.028114 , P6';	'52 , 7.187716 , -4.954237 , 4.477674 , P8';...
			'53 , -5.894369 , -6.974203 , 4.318362 , PO7';	'54 , -5.037746 , -7.566237 , 6.585544 , PO5';...
			'55 , -2.544662 , -8.415612 , 7.820205 , PO3';	'56 , -0.339835 , -8.716856 , 8.249729 , POz';...
			'57 , 2.201964 , -8.66148 , 7.796194 , PO4';	'58 , 4.491326 , -8.16103 , 6.387415 , PO6';...
			'59 , 5.766648 , -7.498684 , 4.546538 , PO8';	'60 , -6.387065 , -5.755497 , 1.886141 , CB1';...
			'61 , -3.542601 , -8.904578 , 4.214279 , O1';	'62 , -0.080624 , -9.660508 , 4.670766 , Oz';...
			'63 , 3.050584 , -9.25965 , 4.194428 , O2';		'64 , 6.192229 , -6.797348 , 2.355135 , CB2'};
			fid=fopen(EEG64_montage_file,'w');
			for i1=1:nchan
				[x1,x2,x3,x4,x5]=strread(char(EEG64_xyz(i1,:)),'%d,%f,%f,%f,%s');
				fprintf(fid,'%d\t%f\t%f\t%f\t%s\n',x1,x2,x3,x4,char(x5));
			end
			fclose(fid);
		case 2
			nchan=150;
			if ~(nchan==in_nchan)
				fprintf('ERROR number of channels (%d) does not fit default array of %d channels\n',...
					in_nchan,nchan');
				return;
			end
			ctf_xyz={...
 			'1 , 1.853880 , 3.140392 , 13.877231 , MLC11';		'2 , 4.493851 , 2.650505 , 13.549985 , MLC12';...
 			'3 , 7.837693 , 2.032480 , 11.920184 , MLC13';		'4 , 9.520564 , -0.090394 , 10.434580 , MLC14';...
 			'5 , 10.465253 , -2.186872 , 8.279293 , MLC15';		'6 , 3.240441 , 0.303624 , 14.347659 , MLC21';...
 			'7 , 6.038006 , 0.403768 , 13.493773 , MLC22';		'8 , 7.915795 , -1.438661 , 12.576356 , MLC23';...
 			'9 , 9.357594 , -3.207851 , 10.866567 , MLC24';		'10 , 4.990058 , -2.132770 , 14.280411 , MLC31';...
 			'11 , 6.852889 , -4.126422 , 13.330137 , MLC32';	'12 , 5.423331 , -6.717420 , 13.568360 , MLC33';...
 			'13 , 1.972231 , -2.121570 , 14.856981 , MLC41';	'14 , 3.594716 , -4.645540 , 14.651488 , MLC42';...
 			'15 , 2.144578 , -7.404007 , 14.145491 , MLC43';	'16 , 3.343252 , 10.941624 , 4.260091 , MLF11';...
 			'17 , 6.135483 , 9.653946 , 3.602705 , MLF12';		'18 , 1.702700 , 10.828738 , 7.033134 , MLF21';...
 			'19 , 4.843266 , 9.903583 , 6.747588 , MLF22';		'20 , 7.421298 , 8.225644 , 5.860421 , MLF23';...
 			'21 , 3.489930 , 9.372460 , 9.504088 , MLF31';		'22 , 6.421518 , 8.068190 , 8.886565 , MLF32';...
 			'23 , 8.503909 , 6.074374 , 7.649416 , MLF33';		'24 , 9.701016 , 3.801287 , 6.555618 , MLF34';...
 			'25 , 1.735223 , 7.951794 , 11.629502 , MLF41';		'26 , 4.945288 , 7.132718 , 11.269089 , MLF42';...
 			'27 , 7.746780 , 5.403942 , 10.239532 , MLF43';		'28 , 9.269596 , 3.009016 , 9.473389 , MLF44';...
 			'29 , 10.486277 , 0.870310 , 7.657370 , MLF45';		'30 , 3.272759 , 5.446656 , 12.920424 , MLF51';...
 			'31 , 6.111762 , 4.430907 , 12.301181 , MLF52';		'32 , 2.390726 , -13.237294 , 5.434626 , MLO11';...
 			'33 , 5.873384 , -12.003799 , 5.750118 , MLO12';	'34 , 4.290321 , -12.958290 , 3.037606 , MLO21';...
 			'35 , 7.181489 , -11.261589 , 3.156971 , MLO22';	'36 , 2.386629 , -13.375785 , 0.086815 , MLO31';...
 			'37 , 5.651638 , -12.264412 , 0.390942 , MLO32';	'38 , 8.362648 , -10.306265 , 0.460690 , MLO33';...
 			'39 , 4.096517 , -12.853282 , -2.442532 , MLO41';	'40 , 7.005884 , -11.282712 , -2.392577 , MLO42';...
 			'41 , 9.220285 , -8.882090 , -2.273285 , MLO43';	'42 , 3.819064 , -9.186744 , 12.602803 , MLP11';...
 			'43 , 6.862748 , -8.471153 , 11.529087 , MLP12';	'44 , 8.423160 , -5.951597 , 11.526238 , MLP13';...
 			'45 , 2.303482 , -11.326200 , 10.446130 , MLP21';	'46 , 5.062950 , -10.569677 , 10.434365 , MLP22';...
 			'47 , 3.975215 , -12.153467 , 8.030496 , MLP31';	'48 , 7.047966 , -10.506274 , 8.423048 , MLP32';...
 			'49 , 8.855178 , -8.078409 , 9.099493 , MLP33';		'50 , 10.032305 , -5.223455 , 8.810442 , MLP34';...
 			'51 , 8.963609 , 5.954344 , 4.536005 , MLT11';		'52 , 10.511756 , 1.915406 , 4.719681 , MLT12';...
 			'53 , 10.875671 , -1.127820 , 5.427028 , MLT13';	'54 , 10.984502 , -4.179707 , 5.915543 , MLT14';...
 			'55 , 10.079444 , -7.197755 , 6.173364 , MLT15';	'56 , 8.427908 , -9.888124 , 5.930415 , MLT16';...
 			'57 , 8.229246 , 7.752451 , 2.162505 , MLT21';		'58 , 9.902339 , 4.019582 , 2.588771 , MLT22';...
 			'59 , 11.527236 , 0.100637 , 2.634042 , MLT23';		'60 , 11.695450 , -2.986022 , 3.016299 , MLT24';...
 			'61 , 11.362176 , -6.083503 , 3.305301 , MLT25';	'62 , 9.241886 , -8.789270 , 3.274953 , MLT26';...
 			'63 , 9.393850 , 5.686700 , 0.103870 , MLT31';		'64 , 10.667354 , 2.116644 , 0.418840 , MLT32';...
 			'65 , 11.757911 , -1.323519 , 0.203996 , MLT33';	'66 , 11.789222 , -4.563474 , 0.461362 , MLT34';...
 			'67 , 10.552326 , -7.682811 , 0.547004 , MLT35';	'68 , 10.369344 , 3.723637 , -2.103843 , MLT41';...
 			'69 , 11.710457 , 0.544102 , -2.259322 , MLT42';	'70 , 11.921047 , -2.740658 , -2.326673 , MLT43';...
 			'71 , 11.507967 , -6.091916 , -2.250546 , MLT44';	'72 , -1.020161 , 3.050761 , 13.868077 , MRC11';...
 			'73 , -3.611819 , 2.420966 , 13.522512 , MRC12';	'74 , -6.929971 , 1.580380 , 11.834204 , MRC13';...
 			'75 , -8.467236 , -0.652454 , 10.368183 , MRC14';	'76 , -9.235231 , -2.790106 , 8.211142 , MRC15';...
 			'77 , -2.276222 , 0.142914 , 14.326243 , MRC21';	'78 , -5.013161 , 0.075630 , 13.465125 , MRC22';...
			'79 , -6.779937 , -1.871166 , 12.529564 , MRC23';	'80 , -8.118743 , -3.729869 , 10.837673 , MRC24';...
			'81 , -3.840642 , -2.388258 , 14.261516 , MRC31';	'82 , -5.666323 , -4.494803 , 13.299027 , MRC32';...
			'83 , -4.030356 , -6.969818 , 13.513490 , MRC33';	'84 , -0.873079 , -2.180777 , 14.860708 , MRC41';...
			'85 , -2.318440 , -4.838885 , 14.621306 , MRC42';	'86 , -0.725169 , -7.475278 , 14.137907 , MRC43';...
			'87 , -2.882001 , 10.750041 , 4.254070 , MRF11';	'88 , -5.565355 , 9.287778 , 3.544867 , MRF12';...
			'89 , -1.271453 , 10.731165 , 7.026086 , MRF21';	'90 , -4.415648 , 9.695728 , 6.754149 , MRF22';...
			'91 , -6.776714 , 7.779873 , 5.805851 , MRF23';		'92 , -2.969993 , 9.159473 , 9.499088 , MRF31';...
			'93 , -5.837897 , 7.683211 , 8.816174 , MRF32';		'94 , -7.721175 , 5.589224 , 7.599114 , MRF33';...
			'95 , -8.836140 , 3.232871 , 6.516246 , MRF34';		'96 , -1.143874 , 7.894232 , 11.579893 , MRF41';...
			'97 , -4.335774 , 6.847354 , 11.232134 , MRF42';	'98 , -6.980831 , 4.919677 , 10.201048 , MRF43';...
			'99 , -9.428629 , 0.242763 , 7.610316 , MRF45';		'100 , -2.523899 , 5.281033 , 12.905440 , MRF51';...
			'101 , -5.356369 , 4.078284 , 12.225789 , MRF52';	'102 , -0.544580 , -13.319213 , 5.412376 , MRO11';...
			'103 , -4.062439 , -12.290770 , 5.729064 , MRO12';	'104 , -2.417794 , -13.166559 , 2.985372 , MRO21';...
			'105 , -5.448465 , -11.658069 , 3.132188 , MRO22';	'106 , -0.503915 , -13.456538 , 0.057668 , MRO31';...
			'107 , -3.881503 , -12.530834 , 0.367070 , MRO32';	'108 , -6.563237 , -10.661583 , 0.433304 , MRO33';...
			'109 , -2.328613 , -13.014940 , -2.485925 , MRO41';	'110 , -5.349283 , -11.589151 , -2.432625 , MRO42';...
			'111 , -7.599672 , -9.343965 , -2.311759 , MRO43';	'112 , -2.283304 , -9.348424 , 12.582265 , MRP11';...
			'113 , -5.349284 , -8.828525 , 11.479532 , MRP12';	'114 , -7.050867 , -6.417893 , 11.451703 , MRP13';...
			'115 , -0.613129 , -11.400977 , 10.431265 , MRP21';	'116 , -3.405053 , -10.787233 , 10.423937 , MRP22';...
			'117 , -2.222046 , -12.305229 , 8.016307 , MRP31';	'118 , -5.368124 , -10.870065 , 8.377899 , MRP32';...
			'119 , -7.347110 , -8.599062 , 9.071210 , MRP33';	'120 , -8.705200 , -5.846850 , 8.720094 , MRP34';...
			'121 , -8.152346 , 5.449498 , 4.481092 , MRT11';	'122 , -9.552480 , 1.294683 , 4.670110 , MRT12';...
			'123 , -9.752162 , -1.803611 , 5.344663 , MRT13';	'124 , -9.740142 , -4.840393 , 5.821819 , MRT14';...
			'125 , -8.566764 , -7.831688 , 6.135341 , MRT15';	'126 , -6.815949 , -10.346221 , 5.885880 , MRT16';...
			'127 , -7.455606 , 7.229468 , 2.113530 , MRT21';	'128 , -9.046597 , 3.400199 , 2.551180 , MRT22';...
			'129 , -10.424297 , -0.601596 , 2.565460 , MRT23';	'130 , -10.481357 , -3.677943 , 2.959577 , MRT24';...
			'131 , -9.993581 , -6.807096 , 3.269904 , MRT25';	'132 , -7.700970 , -9.307073 , 3.195336 , MRT26';...
			'133 , -8.529373 , 5.141509 , 0.045320 , MRT31';	'134 , -9.673178 , 1.469430 , 0.348584 , MRT32';...
			'135 , -10.658495 , -1.992236 , 0.134788 , MRT33';	'136 , -10.460877 , -5.256461 , 0.392377 , MRT34';...
			'137 , -8.916720 , -8.269096 , 0.483157 , MRT35';	'138 , -9.353153 , 3.181913 , -2.134445 , MRT41';...
			'139 , -10.575630 , -0.050694 , -2.315698 , MRT42';	'140 , -10.631383 , -3.365271 , -2.392211 , MRT43';...
			'141 , -10.076069 , -6.685648 , -2.306279 , MRT44';	'142 , 0.498142 , 0.488971 , 14.509589 , MZC01';...
			'143 , 0.638394 , -4.832161 , 14.933297 , MZC02';	'144 , 0.205545 , 11.307641 , 4.504548 , MZF01';...
			'145 , 0.264913 , 9.783810 , 9.634103 , MZF02';		'146 , 0.352349 , 5.673878 , 13.022415 , MZF03';...
			'147 , 0.898848 , -13.569251 , 2.959402 , MZO01';	'148 , 0.921565 , -13.410199 , -2.280123 , MZO02';...
			'149 , 0.761065 , -9.680591 , 12.682553 , MZP01';	'150 , 0.881186 , -12.625393 , 8.222425 , MZP02'};		
			fid=fopen(ctf_montage_file,'w');
			for i1=1:nchan
				[x1,x2,x3,x4,x5]=strread(char(ctf_xyz(i1,:)),'%d,%f,%f,%f,%s');
				fprintf(fid,'%d\t%f\t%f\t%f\t%s\n',x1,-x2,x3,x4,char(x5));
			end
			fclose(fid);
		end
	end
elseif use_c_head
	nchan=length(c_head);
	if ~(nchan==in_nchan)
		fprintf('ERROR number of channels (%d) does not fit number of channels %d in dataset\n',...
			in_nchan,nchan');
		return;
	end
	fid=fopen(ctf_montage_file,'w');
	for i1=1:nchan
		c_head(i1).HeadCoilPos([2],1)=-c_head(i1).HeadCoilPos([2],1);
		fprintf(fid,'%d\t%f\t%f\t%f\t%s\n',i1,c_head(i1).HeadCoilPos([2,1,3],1)',...
			char(c_head(i1).Name));
	end
	fclose(fid);
end

mlocs=[];
fid=fopen(montage_file);
while 1
	tline = fgetl(fid);
    if ~ischar(tline), break, end
	tok=[];
	while ~isempty(tline)
		[ttok,tline]=strtok(tline);
		if ~isempty(ttok), tok=[tok,{ttok}]; end;
	end
	if length(tok)>=5
		idx=str2num(tok{1});
		mlocs(idx).labels=tok{5};
		mlocs(idx).X=str2num(tok{3});
		mlocs(idx).Y=-str2num(tok{2});
		mlocs(idx).Z=str2num(tok{4});
	end
	nchan=length(mlocs);
end
fclose(fid);

if in_nchan ~= nchan
	fprintf(1,'ERROR number of data points does not match electrode/sensor definition.\n');
	return;
end

%--cart2sph
[th phi radius] = cart2sph(cell2mat({mlocs.X}),... 
						   cell2mat({mlocs.Y}),...
						   cell2mat({mlocs.Z}));
for i1 = 1:length(mlocs)
	mlocs(i1).sph_theta     = th(i1)/pi*180;
	mlocs(i1).sph_phi       = phi(i1)/pi*180;
	mlocs(i1).sph_radius    = radius(i1);
end;

%--sph2topo
nchan=length(mlocs);
az = cell2mat({mlocs.sph_phi})';
horiz = cell2mat({mlocs.sph_theta})';
aangle  = -horiz;
radius = 0.5 - az/180;
for i1 = 1:nchan
     mlocs(i1).theta  = aangle(i1);
     mlocs(i1).radius = radius(i1);
end;

%locs=EEGLABFUN.readlocs(ctf_montage_file,'filetype','xyz');

if isempty(options)
	[figure_handle,Zi,grid,Xi,Yi]=topoplot(data,mlocs);
else
	if iscell(options)
		cmd=['[figure_handle,Zi,grid,Xi,Yi]=topoplot(data,mlocs'];
		for i1=1:length(options)
			oo=cell2mat(options(i1));
			if ischar(oo)
				cmd=[cmd,',''',char(oo),''''];
			elseif isnumeric(oo)
				cmd=[cmd,',','[' num2str(oo) ']',''];
			end
		end
		cmd=[cmd,');'];
	end
	eval(cmd);
end
%set(gcf,'color','white')

%h1=get(figure_handle,'Parent');	% Axes
%set(h1,'Position',[0.05,0.05,0.9,0.9]);
return
end	% function rri_topoplot



function [handle,Zi,grid,Xi,Yi] = topoplot(Values,loc_file,varargin)
% topoplot() - plot a topographic map of a scalp data field in a 2-D circular view 
%              (looking down at the top of the head) using interpolation on a fine 
%              cartesian grid. Can also show specified channnel location(s), or return 
%              an interpolated value at an arbitrary scalp location (see 'noplot').
%              By default, channel locations below head center (arc_length 0.5) are 
%              shown in a 'skirt' outside the cartoon head (see 'plotrad' and 'headrad' 
%              options below). Nose is at top of plot; left is left; right is right.
%              Using option 'plotgrid', the plot may be one or more rectangular grids.
% Usage:
%        >>  topoplot(datavector, EEG.chanlocs);   % plot a map using an EEG chanlocs structure
%        >>  topoplot(datavector, 'my_chan.locs'); % read a channel locations file and plot a map
%        >>  topoplot('example');                  % give an example of an electrode location file
%        >>  [h grid_or_val plotrad_or_grid, xmesh, ymesh]= ...
%                           topoplot(datavector, chan_locs, 'Input1','Value1', ...);
% Required Inputs:
%   datavector        - single vector of channel values. Else, if a vector of selected subset
%                       (int) channel numbers -> mark their location(s) using 'style' 'blank'.
%   chan_locs         - name of an EEG electrode position file (>> topoplot example).
%                       Else, an EEG.chanlocs structure (>> help readlocs or >> topoplot example)
% Optional inputs:
%   'maplimits'       - 'absmax'   -> scale map colors to +/- the absolute-max (makes green 0); 
%                       'maxmin'   -> scale colors to the data range (makes green mid-range); 
%                       [lo.hi]    -> use user-definined lo/hi limits
%                       {default: 'absmax'}
%   'style'           - 'map'      -> plot colored map only
%                       'contour'  -> plot contour lines only
%                       'both'     -> plot both colored map and contour lines
%                       'fill'     -> plot constant color between contour lines
%                       'blank'    -> plot electrode locations only {default: 'both'}
%   'electrodes'      - 'on','off','labels','numbers','ptslabels','ptsnumbers'. To set the 'pts' 
%                       marker,,see 'Plot detail options' below. {default: 'on' -> mark electrode 
%                       locations with points ('.') unless more than 64 channels, then 'off'}. 
%   'plotchans'       - [vector] channel numbers (indices) to use in making the head plot. 
%                       {default: [] -> plot all chans}
%   'plotgrid'        - [channels] Plot channel data in one or more rectangular grids, as 
%                       specified by [channels],  a position matrix of channel numbers defining 
%                       the topographic locations of the channels in the
%                       grid. Zero values are ignored (given the figure background color); 
%                       negative integers, the color of the polarity-reversed channel values.  
%                       Ex: >> figure; ...
%                             >> topoplot(values,'chanlocs','plotgrid',[11 12 0; 13 14 15]);
%                       % Plot a (2,3) grid of data values from channels 11-15 with one empty 
%                       grid cell (top right) {default: no grid plot} 
%   'nosedir'         - ['+X'|'-X'|'+Y'|'-Y'] direction of nose {default: '+X'}
%   'chaninfo'        - [struct] optional structure containing fields 'nosedir', 'plotrad'. 
%                       See these (separate) field definitions above, below.
%                       {default: nosedir +X, plotrad 0.5, all channels}
%   'plotrad'         - [0.15<=float<=1.0] plotting radius = max channel arc_length to plot.
%                       See >> topoplot example. If plotrad > 0.5, chans with arc_length > 0.5 
%                       (i.e. below ears-eyes) are plotted in a circular 'skirt' outside the
%                       cartoon head. See 'intrad' below. {default: max(max(chanlocs.radius),0.5);
%                       If the chanlocs structure includes a field chanlocs.plotrad, its value 
%                       is used by default}.
%   'headrad'         - [0.15<=float<=1.0] drawing radius (arc_length) for the cartoon head. 
%                       NOTE: Only headrad = 0.5 is anatomically correct! 0 -> don't draw head; 
%                       'rim' -> show cartoon head at outer edge of the plot {default: 0.5}
%   'intrad'          - [0.15<=float<=1.0] radius of the scalp map interpolation area (square or 
%                       disk, see 'intsquare' below). Interpolate electrodes in this area and use 
%                       this limit to define boundaries of the scalp map interpolated data matrix
%                       {default: max channel location radius}
%   'intsquare'       - ['on'|'off'] 'on' -> Interpolate values at electrodes located in the whole 
%                       square containing the (radius intrad) interpolation disk; 'off' -> Interpolate
%                       values from electrodes shown in the interpolation disk only {default: 'on'}.
%   'conv'            - ['on'|'off'] Show map interpolation only out to the convext hull of
%                       the electrode locations to minimize extrapolation. Use this option ['on'] when 
%                       plotting pvalues  {default: 'off'}. When plotting pvalues in totoplot, set 
%                       'conv' option to 'on' to minimize interpolation effects
%   'noplot'          - ['on'|'off'|[rad theta]] do not plot (but return interpolated data).
%                       Else, if [rad theta] are coordinates of a (possibly missing) channel, 
%                       returns interpolated value for channel location.  For more info, 
%                       see >> topoplot 'example' {default: 'off'}
%   'verbose'         - ['on'|'off'] comment on operations on command line {default: 'on'}.
%   'chantype'        - deprecated
%
% Plot detail options:
%   'drawaxis'        - ['on'|'off'] draw axis on the top left corner.
%   'emarker'         - Matlab marker char | {markerchar color size linewidth} char, else cell array 
%                       specifying the electrode 'pts' marker. Ex: {'s','r',32,1} -> 32-point solid 
%                       red square. {default: {'.','k',[],1} where marker size ([]) depends on the number 
%                       of channels plotted}.
%   'emarker2'        - {markchans}|{markchans marker color size linewidth} cell array specifying 
%                       an alternate marker for specified 'plotchans'. Ex: {[3 17],'s','g'} 
%                       {default: none, or if {markchans} only are specified, then {markchans,'o','r',10,1}}
%   'hcolor'          - color of the cartoon head. Use 'hcolor','none' to plot no head. {default: 'k' = black}
%   'shading'         - 'flat','interp'  {default: 'flat'}
%   'numcontour'      - number of contour lines {default: 6}. You may also enter a vector to set contours 
%                       at specified values.
%   'contourvals'     - values for contour {default: same as input values}
%   'pmask'           - values for masking topoplot. Array of zeros and 1 of the same size as the input 
%                       value array {default: []}
%   'color'           - color of the contours {default: dark grey}
%   'whitebk '        -  ('on'|'off') make the background color white (e.g., to print empty plotgrid channels) 
%                       {default: 'off'}
%   'gridscale'       - [int > 32] size (nrows) of interpolated scalp map data matrix {default: 67}
%   'colormap'        -  (n,3) any size colormap {default: existing colormap}
%   'circgrid'        - [int > 100] number of elements (angles) in head and border circles {201}
%   'emarkercolor'    - cell array of colors for 'blank' option.
%   'plotdisk'        - ['on'|'off'] plot disk instead of dots for electrodefor 'blank' option. Size of disk
%                       is controled by input values at each electrode. If an imaginary value is provided, 
%                       plot partial circle with red for the real value and blue for the imaginary one.
%
% Dipole plotting options:
%   'dipole'          - [xi yi xe ye ze] plot dipole on the top of the scalp map
%                       from coordinate (xi,yi) to coordinates (xe,ye,ze) (dipole head 
%                       model has radius 1). If several rows, plot one dipole per row.
%                       Coordinates returned by dipplot() may be used. Can accept
%                       an EEG.dipfit.model structure (See >> help dipplot).
%                       Ex: ,'dipole',EEG.dipfit.model(17) % Plot dipole(s) for comp. 17.
%   'dipnorm'         - ['on'|'off'] normalize dipole length {default: 'on'}.
%   'diporient'       - [-1|1] invert dipole orientation {default: 1}.
%   'diplen'          - [real] scale dipole length {default: 1}.
%   'dipscale'        - [real] scale dipole size {default: 1}.
%   'dipsphere'       - [real] size of the dipole sphere. {default: 85 mm}.
%   'dipcolor'        - [color] dipole color as Matlab code code or [r g b] vector
%                       {default: 'k' = black}.
% Outputs:
%              handle - handle of the colored surface.If
%                       contour only is plotted, then is the handle of
%                       the countourgroup. (If no surface or contour is plotted,
%                       return "gca", the handle of the current plot)
%         grid_or_val - [matrix] the interpolated data image (with off-head points = NaN).  
%                       Else, single interpolated value at the specified 'noplot' arg channel 
%                       location ([rad theta]), if any.
%     plotrad_or_grid - IF grid image returned above, then the 'plotrad' radius of the grid.
%                       Else, the grid image
%     xmesh, ymesh    - x and y values of the returned grid (above)
%
% Chan_locs format:
%    See >> topoplot 'example'
%
% Examples:
%
%    To plot channel locations only:
%    >> figure; topoplot([],EEG.chanlocs,'style','blank','electrodes','labelpoint','chaninfo',EEG.chaninfo);
%    
% Notes: - To change the plot map masking ring to a new figure background color,
%            >> set(findobj(gca,'type','patch'),'facecolor',get(gcf,'color'))
%        - Topoplots may be rotated. From the commandline >> view([deg 90]) {default: [0 90])
%        - When plotting pvalues make sure to use the option 'conv' to minimize extrapolation effects 
%
% Authors: Andy Spydell, Colin Humphries, Arnaud Delorme & Scott Makeig
%          CNL / Salk Institute, 8/1996-/10/2001; SCCN/INC/UCSD, Nov. 2001 -
%
% See also: timtopo(), envtopo()

% Deprecated options: 
%           'shrink' - ['on'|'off'|'force'|factor] Deprecated. 'on' -> If max channel arc_length 
%                       > 0.5, shrink electrode coordinates towards vertex to plot all channels
%                       by making max arc_length 0.5. 'force' -> Normalize arc_length 
%                       so the channel max is 0.5. factor -> Apply a specified shrink
%                       factor (range (0,1) = shrink fraction). {default: 'off'}
%   'electcolor' {'k'}  ... electrode marking details and their {defaults}. 
%   'emarker' {'.'}|'emarkersize' {14}|'emarkersizemark' {40}|'efontsize' {var} -
%                       electrode marking details and their {defaults}. 
%   'ecolor'          - color of the electrode markers {default: 'k' = black}
%   'interplimits'    - ['electrodes'|'head'] 'electrodes'-> interpolate the electrode grid; 
%                       'head'-> interpolate the whole disk {default: 'head'}.

% Unimplemented future options:

% Copyright (C) Colin Humphries & Scott Makeig, CNL / Salk Institute, Aug, 1996
%                                          
% This file is part of EEGLAB, see http://www.eeglab.org
% for the documentation and details.
%
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are met:
%
% 1. Redistributions of source code must retain the above copyright notice,
% this list of conditions and the following disclaimer.
%
% 2. Redistributions in binary form must reproduce the above copyright notice,
% this list of conditions and the following disclaimer in the documentation
% and/or other materials provided with the distribution.
%
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
% ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
% LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
% CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
% SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
% INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
% CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
% ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
% THE POSSIBILITY OF SUCH DAMAGE.

% Topoplot Version 2.1
% Early development history:
% Begun by Andy Spydell and Scott Makeig, NHRC,  7-23-96
% 8-96 Revised by Colin Humphries, CNL / Salk Institute, La Jolla CA
%   -changed surf command to imagesc (faster)
%   -can now handle arbitrary scaling of electrode distances
%   -can now handle non integer angles in chan_locs
% 4-4-97 Revised again by Colin Humphries, reformatted by SM
%   -added parameters
%   -changed chan_locs format
% 2-26-98 Revised by Colin
%   -changed image back to surface command
%   -added fill and blank styles
%   -removed extra background colormap entry (now use any colormap)
%   -added parameters for electrode colors and labels
%   -now each topoplot axes use the caxis command again.
%   -removed OUTPUT parameter
% 3-11-98 changed default emarkersize, improve help msg -sm
% 5-24-01 made default emarkersize vary with number of channels -sm
% 01-25-02 reformated help & license, added link -ad 
% 03-15-02 added readlocs and the use of eloc input structure -ad 
% 03-25-02 added 'labelpoint' options and allow Values=[] -ad &sm
% 03-25-02 added details to "Unknown parameter" warning -sm & ad


%
%%%%%%%%%%%%%%%%%%%%%%%% Set defaults %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%

BACKCOLOR           = [.93 .96 1];
MAXTOPOPLOTCHANS  = 264;  % maximum number of channels to plot in topoplot.m
DEFAULT_ELOC  = 'chan.locs'; % default electrode location file for topoplot.m

if ~exist('BACKCOLOR')  % if icadefs.m does not define BACKCOLOR
   BACKCOLOR = [.93 .96 1];  % EEGLAB standard
end
whitebk = 'off';  % by default, make gridplot background color = EEGLAB screen background color

persistent warningInterp;

plotgrid = 'off';
plotchans = [];
noplot  = 'off';
handle = [];
Zi = [];
chanval = NaN;
rmax = 0.5;             % actual head radius - Don't change this!
INTERPLIMITS = 'head';  % head, electrodes
INTSQUARE = 'on';       % default, interpolate electrodes located though the whole square containing
                        % the plotting disk
default_intrad = 1;     % indicator for (no) specified intrad
MAPLIMITS = 'absmax';   % absmax, maxmin, [values]
GRID_SCALE = 67;        % plot map on a 67X67 grid
CIRCGRID   = 201;       % number of angles to use in drawing circles
AXHEADFAC = 1.3;        % head to axes scaling factor
CONTOURNUM = 6;         % number of contour levels to plot
STYLE = 'both';         % default 'style': both,straight,fill,contour,blank
HEADCOLOR = [0 0 0];    % default head color (black)
CCOLOR = [0.2 0.2 0.2]; % default contour color
ELECTRODES = [];        % default 'electrodes': on|off|label - set below
MAXDEFAULTSHOWLOCS = 64;% if more channels than this, don't show electrode locations by default
EMARKER = '.';          % mark electrode locations with small disks
ECOLOR = [0 0 0];       % default electrode color = black
EMARKERSIZE = [];       % default depends on number of electrodes, set in code
EMARKERLINEWIDTH = 1;   % default edge linewidth for emarkers
EMARKERSIZE1CHAN = 20;  % default selected channel location marker size
EMARKERCOLOR1CHAN = 'red'; % selected channel location marker color
EMARKER2CHANS = [];      % mark subset of electrode locations with small disks
EMARKER2 = 'o';          % mark subset of electrode locations with small disks
EMARKER2COLOR = 'r';     % mark subset of electrode locations with small disks
EMARKERSIZE2 = 10;      % default selected channel location marker size
EMARKER2LINEWIDTH = 1;
EFSIZE = get(0,'DefaultAxesFontSize'); % use current default fontsize for electrode labels
HLINEWIDTH = 2;         % default linewidth for head, nose, ears
BLANKINGRINGWIDTH = .035;% width of the blanking ring 
HEADRINGWIDTH    = .007;% width of the cartoon head ring
SHADING = 'flat';       % default 'shading': flat|interp
shrinkfactor = [];      % shrink mode (dprecated)
intrad       = [];      % default interpolation square is to outermost electrode (<=1.0)
plotrad      = [];      % plotting radius ([] = auto, based on outermost channel location)
headrad      = [];      % default plotting radius for cartoon head is 0.5
squeezefac = 1.0;
MINPLOTRAD = 0.15;      % can't make a topoplot with smaller plotrad (contours fail)
VERBOSE = 'off';
MASKSURF = 'off';
CONVHULL = 'off';       % dont mask outside the electrodes convex hull
DRAWAXIS = 'off';
PLOTDISK = 'off';
ContourVals = Values;
PMASKFLAG   = 0;
COLORARRAY  = { [1 0 0] [0.5 0 0] [0 0 0] };
%COLORARRAY2 = { [1 0 0] [0.5 0 0] [0 0 0] };
gb = [0 0];
COLORARRAY2 = { [gb 0] [gb 1/4] [gb 2/4] [gb 3/4] [gb 1] };

%%%%%% Dipole defaults %%%%%%%%%%%%
DIPOLE  = [];           
DIPNORM   = 'on';
DIPNORMMAX = 'off';
DIPSPHERE = 85;
DIPLEN    = 1;
DIPSCALE  = 1;
DIPORIENT  = 1;
DIPCOLOR  = [0 0 0];
NOSEDIR   = '+X';
CHANINFO  = [];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%
%%%%%%%%%%%%%%%%%%%%%%% Handle arguments %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
if nargin< 1
   help topoplot;
   return
end

nargs = nargin;
if nargs == 1
  if ischar(Values)
    if any(strcmp(lower(Values),{'example','demo'}))
      fprintf(['This is an example of an electrode location file,\n',...
               'an ascii file consisting of the following four columns:\n',...
               ' channel_number degrees arc_length channel_name\n\n',...
               'Example:\n',...
               ' 1               -18    .352       Fp1 \n',...
               ' 2                18    .352       Fp2 \n',...
               ' 5               -90    .181       C3  \n',...
               ' 6                90    .181       C4  \n',...
               ' 7               -90    .500       A1  \n',...
               ' 8                90    .500       A2  \n',...
               ' 9              -142    .231       P3  \n',...
               '10               142    .231       P4  \n',...
               '11                 0    .181       Fz  \n',...
               '12                 0    0          Cz  \n',...
               '13               180    .181       Pz  \n\n',...
                                                             ...
               'In topoplot() coordinates, 0 deg. points to the nose, positive\n',...
               'angles point to the right hemisphere, and negative to the left.\n',...
               'The model head sphere has a circumference of 2; the vertex\n',...
               '(Cz) has arc_length 0. Locations with arc_length > 0.5 are below\n',...
               'head center and are plotted outside the head cartoon.\n',...
               'Option plotrad controls how much of this lower-head "skirt" is shown.\n',...
               'Option headrad controls if and where the cartoon head will be drawn.\n',...
               'Option intrad controls how many channels will be included in the interpolation.\n',...
               ])
      return
    end
  end
end
if nargs < 2
  loc_file = DEFAULT_ELOC;
  if ~exist(loc_file)
      fprintf('default locations file "%s" not found - specify chan_locs in topoplot() call.\n',loc_file)
      error(' ')
  end
end
if isempty(loc_file)
  loc_file = 0;
end
if isnumeric(loc_file) && loc_file == 0
  loc_file = DEFAULT_ELOC;
end

if nargs > 2
    if ~(round(nargs/2) == nargs/2)
        error('Odd number of input arguments??')
    end
    for i = 1:2:length(varargin)
        Param = varargin{i};
        Value = varargin{i+1};
        if ~ischar(Param)
            error('Flag arguments must be strings')
        end
        Param = lower(Param);
        switch Param
            case 'conv'
                CONVHULL = lower(Value);
                if ~strcmp(CONVHULL,'on') && ~strcmp(CONVHULL,'off')
                    error('Value of ''conv'' must be ''on'' or ''off''.');
                end
            case 'colormap'
                if size(Value,2)~=3
                    error('Colormap must be a n x 3 matrix')
                end
                colormap(Value)
            case 'gridscale'
                GRID_SCALE = Value;
            case 'plotdisk'
                PLOTDISK = lower(Value);
                if ~strcmp(PLOTDISK,'on') && ~strcmp(PLOTDISK,'off')
                    error('Value of ''plotdisk'' must be ''on'' or ''off''.');
                end
            case 'intsquare'
                INTSQUARE = lower(Value);
                if ~strcmp(INTSQUARE,'on') && ~strcmp(INTSQUARE,'off')
                    error('Value of ''intsquare'' must be ''on'' or ''off''.');
                end
            case 'emarkercolors'
                COLORARRAY = Value;
            case {'interplimits','headlimits'}
                if ~ischar(Value)
                    error('''interplimits'' value must be a string')
                end
                Value = lower(Value);
                if ~strcmp(Value,'electrodes') && ~strcmp(Value,'head')
                    error('Incorrect value for interplimits')
                end
                INTERPLIMITS = Value;
            case 'verbose'
                VERBOSE = Value;
            case 'nosedir'
                NOSEDIR = Value;
                if isempty(strmatch(lower(NOSEDIR), { '+x', '-x', '+y', '-y' }))
                    error('Invalid nose direction');
                end
            case 'chaninfo'
                CHANINFO = Value;
                if isfield(CHANINFO, 'nosedir'), NOSEDIR      = CHANINFO.nosedir; end
                if isfield(CHANINFO, 'shrink' ), shrinkfactor = CHANINFO.shrink;  end
                if isfield(CHANINFO, 'plotrad') && isempty(plotrad), plotrad = CHANINFO.plotrad; end
            case 'chantype'
            case 'drawaxis'
                DRAWAXIS = Value;
            case 'maplimits'
                MAPLIMITS = Value;
            case 'masksurf'
                MASKSURF = Value;
            case 'circgrid'
                CIRCGRID = Value;
                if ischar(CIRCGRID) || CIRCGRID<100
                    error('''circgrid'' value must be an int > 100');
                end
            case 'style'
                STYLE = lower(Value);
            case 'numcontour'
                CONTOURNUM = Value;
            case 'electrodes'
                ELECTRODES = lower(Value);
                if strcmpi(ELECTRODES,'pointlabels') || strcmpi(ELECTRODES,'ptslabels') ...
                        | strcmpi(ELECTRODES,'labelspts') | strcmpi(ELECTRODES,'ptlabels') ...
                        | strcmpi(ELECTRODES,'labelpts')
                    ELECTRODES = 'labelpoint'; % backwards compatability
                elseif strcmpi(ELECTRODES,'pointnumbers') || strcmpi(ELECTRODES,'ptsnumbers') ...
                        | strcmpi(ELECTRODES,'numberspts') | strcmpi(ELECTRODES,'ptnumbers') ...
                        | strcmpi(ELECTRODES,'numberpts')  | strcmpi(ELECTRODES,'ptsnums')  ...
                        | strcmpi(ELECTRODES,'numspts')
                    ELECTRODES = 'numpoint'; % backwards compatability
                elseif strcmpi(ELECTRODES,'nums')
                    ELECTRODES = 'numbers'; % backwards compatability
                elseif strcmpi(ELECTRODES,'pts')
                    ELECTRODES = 'on'; % backwards compatability
                elseif ~strcmp(ELECTRODES,'off') ...
                        & ~strcmpi(ELECTRODES,'on') ...
                        & ~strcmp(ELECTRODES,'labels') ...
                        & ~strcmpi(ELECTRODES,'numbers') ...
                        & ~strcmpi(ELECTRODES,'labelpoint') ...
                        & ~strcmpi(ELECTRODES,'numpoint')
                    error('Unknown value for keyword ''electrodes''');
                end
            case 'dipole'
                DIPOLE = Value;
            case 'dipsphere'
                DIPSPHERE = Value;
            case {'dipnorm', 'dipnormmax'}
                if strcmp(Param,'dipnorm')
                    DIPNORM = Value;
                    if strcmpi(Value,'on')
                        DIPNORMMAX = 'off';
                    end
                else
                    DIPNORMMAX = Value;
                    if strcmpi(Value,'on')
                        DIPNORM = 'off';
                    end
                end
                
            case 'diplen'
                DIPLEN = Value;
            case 'dipscale'
                DIPSCALE = Value;
            case 'contourvals'
                ContourVals = Value;
            case 'pmask'
                ContourVals = Value;
                PMASKFLAG   = 1;
            case 'diporient'
                DIPORIENT = Value;
            case 'dipcolor'
                DIPCOLOR = Value;
            case 'emarker'
                if ischar(Value)
                    EMARKER = Value;
                elseif ~iscell(Value) || length(Value) > 4
                    error('''emarker'' argument must be a cell array {marker color size linewidth}')
                else
                    EMARKER = Value{1};
                end
                if length(Value) > 1
                    ECOLOR = Value{2};
                end
                if length(Value) > 2
                    EMARKERSIZE = Value{3};
                end
                if length(Value) > 3
                    EMARKERLINEWIDTH = Value{4};
                end
            case 'emarker2'
                if ~iscell(Value) || length(Value) > 5
                    error('''emarker2'' argument must be a cell array {chans marker color size linewidth}')
                end
                EMARKER2CHANS = abs(Value{1}); % ignore channels < 0
                if length(Value) > 1
                    EMARKER2 = Value{2};
                end
                if length(Value) > 2
                    EMARKER2COLOR = Value{3};
                end
                if length(Value) > 3
                    EMARKERSIZE2 = Value{4};
                end
                if length(Value) > 4
                    EMARKER2LINEWIDTH = Value{5};
                end
            case 'shrink'
                shrinkfactor = Value;
            case 'intrad'
                intrad = Value;
                if ischar(intrad) || (intrad < MINPLOTRAD || intrad > 1)
                    error('intrad argument should be a number between 0.15 and 1.0');
                end
            case 'plotrad'
                plotrad = Value;
                if ~isempty(plotrad) && (ischar(plotrad) || (plotrad < MINPLOTRAD || plotrad > 1))
                    error('plotrad argument should be a number between 0.15 and 1.0');
                end
            case 'headrad'
                headrad = Value;
                if ischar(headrad) && ( strcmpi(headrad,'off') || strcmpi(headrad,'none') )
                    headrad = 0;       % undocumented 'no head' alternatives
                end
                if isempty(headrad) % [] -> none also
                    headrad = 0;
                end
                if ~ischar(headrad)
                    if ~(headrad==0) && (headrad < MINPLOTRAD || headrad>1)
                        error('bad value for headrad');
                    end
                elseif  ~strcmpi(headrad,'rim')
                    error('bad value for headrad');
                end
            case {'headcolor','hcolor'}
                HEADCOLOR = Value;
            case {'contourcolor','ccolor'}
                CCOLOR = Value;
            case {'electcolor','ecolor'}
                ECOLOR = Value;
            case {'emarkersize','emsize'}
                EMARKERSIZE = Value;
            case {'emarkersize1chan','emarkersizemark'}
                EMARKERSIZE1CHAN= Value;
            case {'efontsize','efsize'}
                EFSIZE = Value;
            case 'shading'
                SHADING = lower(Value);
                if ~any(strcmp(SHADING,{'flat','interp'}))
                    error('Invalid shading parameter')
                end
                if strcmpi(SHADING,'interp') && isempty(warningInterp)
                    warning('Using interpolated shading in scalp topographies prevent to export them as vectorized figures');
                    warningInterp = 1;
                end
            case 'noplot'
                noplot = Value;
                if ~ischar(noplot)
                    if length(noplot) ~= 2
                        error('''noplot'' location should be [radius, angle]')
                    else
                        chanrad = noplot(1);
                        chantheta = noplot(2);
                        noplot = 'on';
                    end
                end
            case 'gridscale'
                GRID_SCALE = Value;
                if ischar(GRID_SCALE) || GRID_SCALE ~= round(GRID_SCALE) || GRID_SCALE < 32
                    error('''gridscale'' value must be integer > 32.');
                end
            case {'plotgrid','gridplot'}
                plotgrid = 'on';
                gridchans = Value;
            case 'plotchans'
                plotchans = Value(:);
                if find(plotchans<=0)
                    error('''plotchans'' values must be > 0');
                end
                % if max(abs(plotchans))>max(Values) | max(abs(plotchans))>length(Values) -sm ???
            case {'whitebk','whiteback','forprint'}
                whitebk = Value;
            case {'iclabel'} % list of options to ignore
            otherwise
                error(['Unknown input parameter ''' Param ''' ???'])
        end
    end
end

if strcmpi(whitebk, 'on')
    BACKCOLOR = [ 1 1 1 ];
end

if isempty(find(strcmp(varargin,'colormap')))
    if exist('DEFAULT_COLORMAP','var')
        cmap = colormap(DEFAULT_COLORMAP);
    else
        cmap = parula;
    end
else
    cmap = colormap;
end
if strcmp(noplot,'on'), close(gcf); end
cmaplen = size(cmap,1);

if strcmp(STYLE,'blank')    % else if Values holds numbers of channels to mark
    if length(Values) < length(loc_file)
        ContourVals = zeros(1,length(loc_file));
        ContourVals(Values) = 1;
        Values = ContourVals;
    end
end

%
%%%%%%%%%%%%%%%%%%%%%%%%%%% test args for plotting an electrode grid %%%%%%%%%%%%%%%%%%%%%%
%
if strcmp(plotgrid,'on')
   STYLE = 'grid';
   gchans = sort(find(abs(gridchans(:))>0));

   % if setdiff(gchans,unique(gchans))
   %      fprintf('topoplot() warning: ''plotgrid'' channel matrix has duplicate channels\n');
   % end

   if ~isempty(plotchans)
     if intersect(gchans,abs(plotchans))
        fprintf('topoplot() warning: ''plotgrid'' and ''plotchans'' have channels in common\n');
     end
   end
end

%
%%%%%%%%%%%%%%%%%%%%%%%%%%% misc arg tests %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
if isempty(ELECTRODES)                     % if electrode labeling not specified
  if length(Values) > MAXDEFAULTSHOWLOCS   % if more channels than default max
    ELECTRODES = 'off';                    % don't show electrodes
  else                                     % else if fewer chans,
    ELECTRODES = 'on';                     % do
  end
end

if isempty(Values)
   STYLE = 'blank';
end
[r,c] = size(Values);
if r>1 && c>1,
  error('input data must be a single vector');
end
Values = Values(:); % make Values a column vector
ContourVals = ContourVals(:); % values for contour

if ~isempty(intrad) && ~isempty(plotrad) && intrad < plotrad
   error('intrad must be >= plotrad');
end

if ~strcmpi(STYLE,'grid')                     % if not plot grid only

%
%%%%%%%%%%%%%%%%%%%% Read the channel location information %%%%%%%%%%%%%%%%%%%%%%%%
% 
%  if ischar(loc_file)
%      [tmpeloc labels Th Rd indices] = readlocs( loc_file);
%  elseif isstruct(loc_file) % a locs struct
%      [tmpeloc labels Th Rd indices] = readlocs( loc_file );
%      % Note: Th and Rd correspond to indices channels-with-coordinates only
%  else
%       error('loc_file must be a EEG.locs struct or locs filename');
%  end
locs=loc_file;
tmpeloc = locs;
labels = {locs.labels};
indices = [1:length(locs)];
Th     = -cell2mat({locs.sph_theta});
Rd     = cell2mat({locs.radius});
Th = pi/180*Th;                              % convert degrees to radians
allchansind = 1:length(Th);

  
if ~isempty(plotchans)
    if max(plotchans) > length(Th)
        error('''plotchans'' values must be <= max channel index');
    end
end

%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% channels to plot %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
if ~isempty(plotchans)
    plotchans = intersect(plotchans, indices);
end
if ~isempty(Values) && ~strcmpi( STYLE, 'blank') && isempty(plotchans)
    plotchans = indices;
end
if isempty(plotchans) && strcmpi( STYLE, 'blank')
    plotchans = indices;
end

%
%%%%%%%%%%%%%%%%%%%%%%%%%%% filter channels used for components %%%%%%%%%%%%%%%%%%%%% 
%
if isfield(CHANINFO, 'icachansind') && ~isempty(Values) && length(Values) ~= length(tmpeloc)

    % test if ICA component
    % ---------------------
    if length(CHANINFO.icachansind) == length(Values)
        
        % if only a subset of channels are to be plotted
        % and ICA components also use a subject of channel
        % we must find the new indices for these channels
        
        plotchans = intersect(CHANINFO.icachansind, plotchans);
        tmpvals   = zeros(1, length(tmpeloc));
        tmpvals(CHANINFO.icachansind) = Values;
        Values    = tmpvals;
        tmpvals   = zeros(1, length(tmpeloc));
        tmpvals(CHANINFO.icachansind) = ContourVals;
        ContourVals = tmpvals;
        
    end
end

%
%%%%%%%%%%%%%%%%%%% last channel is reference? %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
if length(tmpeloc) == length(Values) + 1 % remove last channel if necessary 
                                         % (common reference channel)
    if plotchans(end) == length(tmpeloc)
        plotchans(end) = [];
    end

end

%
%%%%%%%%%%%%%%%%%%% remove infinite and NaN values %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
if length(Values) > 1
    inds          = union(find(isnan(Values)), find(isinf(Values))); % NaN and Inf values
    plotchans     = setdiff(plotchans, inds);
end
if strcmp(plotgrid,'on')
    plotchans = setxor(plotchans,gchans);   % remove grid chans from head plotchans   
end

[x,y]     = pol2cart(Th,Rd);  % transform electrode locations from polar to cartesian coordinates
plotchans = abs(plotchans);   % reverse indicated channel polarities
allchansind = allchansind(plotchans);
Th        = Th(plotchans);
Rd        = Rd(plotchans);
x         = x(plotchans);
y         = y(plotchans);
labels    = labels(plotchans); % remove labels for electrodes without locations
labels    = strvcat(labels); % make a label string matrix
if ~isempty(Values) && length(Values) > 1
    Values      = Values(plotchans);
    ContourVals = ContourVals(plotchans);
end

%
%%%%%%%%%%%%%%%%%% Read plotting radius from chanlocs  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
if isempty(plotrad) && isfield(tmpeloc, 'plotrad'), 
    plotrad = tmpeloc(1).plotrad; 
    if ischar(plotrad)                        % plotrad shouldn't be a string
        plotrad = str2num(plotrad)           % just checking
    end
    if plotrad < MINPLOTRAD || plotrad > 1.0
       fprintf('Bad value (%g) for plotrad.\n',plotrad);
       error(' ');
    end
    if strcmpi(VERBOSE,'on') && ~isempty(plotrad)
       fprintf('Plotting radius plotrad (%g) set from EEG.chanlocs.\n',plotrad);
    end
end
if isempty(plotrad) 
  plotrad = min(1.0,max(Rd)*1.02);            % default: just outside the outermost electrode location
  plotrad = max(plotrad,0.5);                 % default: plot out to the 0.5 head boundary
end                                           % don't plot channels with Rd > 1 (below head)

if isempty(intrad) 
  default_intrad = 1;     % indicator for (no) specified intrad
  intrad = min(1.0,max(Rd)*1.02);             % default: just outside the outermost electrode location
else
  default_intrad = 0;                         % indicator for (no) specified intrad
  if plotrad > intrad
     plotrad = intrad;
  end
end                                           % don't interpolate channels with Rd > 1 (below head)
if ischar(plotrad) || plotrad < MINPLOTRAD || plotrad > 1.0
   error('plotrad must be between 0.15 and 1.0');
end

%
%%%%%%%%%%%%%%%%%%%%%%% Set radius of head cartoon %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
if isempty(headrad)  % never set -> defaults
  if plotrad >= rmax
     headrad = rmax;  % (anatomically correct)
  else % if plotrad < rmax
     headrad = 0;    % don't plot head
     if strcmpi(VERBOSE, 'on')
       fprintf('topoplot(): not plotting cartoon head since plotrad (%5.4g) < 0.5\n',...
                                                                    plotrad);
     end
  end
elseif strcmpi(headrad,'rim') % force plotting at rim of map
  headrad = plotrad;
end

%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Shrink mode %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
if ~isempty(shrinkfactor) || isfield(tmpeloc, 'shrink'), 
    if isempty(shrinkfactor) && isfield(tmpeloc, 'shrink'), 
        shrinkfactor = tmpeloc(1).shrink;
        if strcmpi(VERBOSE,'on')
            if ischar(shrinkfactor)
                fprintf('Automatically shrinking coordinates to lie above the head perimter.\n');
            else                
                fprintf('Automatically shrinking coordinates by %3.2f\n', shrinkfactor);
            end
        end
    end
    
    if ischar(shrinkfactor)
        if strcmpi(shrinkfactor, 'on') || strcmpi(shrinkfactor, 'force') || strcmpi(shrinkfactor, 'auto')  
            if abs(headrad-rmax) > 1e-2
             fprintf('     NOTE -> the head cartoon will NOT accurately indicate the actual electrode locations\n');
            end
            if strcmpi(VERBOSE,'on')
                fprintf('     Shrink flag -> plotting cartoon head at plotrad\n');
            end
            headrad = plotrad; % plot head around outer electrodes, no matter if 0.5 or not
        end
    else % apply shrinkfactor
        plotrad = rmax/(1-shrinkfactor);
        headrad = plotrad;  % make deprecated 'shrink' mode plot 
        if strcmpi(VERBOSE,'on')
            fprintf('    %g%% shrink  applied.');
            if abs(headrad-rmax) > 1e-2
                fprintf(' Warning: With this "shrink" setting, the cartoon head will NOT be anatomically correct.\n');
            else
                fprintf('\n');
            end
        end
    end
end; % if shrink
      
%
%%%%%%%%%%%%%%%%% Issue warning if headrad ~= rmax  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 

if headrad ~= 0.5 && strcmpi(VERBOSE, 'on')
   fprintf('     NB: Plotting map using ''plotrad'' %-4.3g,',plotrad);
   fprintf(    ' ''headrad'' %-4.3g\n',headrad);
   fprintf('Warning: The plotting radius of the cartoon head is NOT anatomically correct (0.5).\n')
end
%
%%%%%%%%%%%%%%%%%%%%% Find plotting channels  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 

pltchans = find(Rd <= plotrad); % plot channels inside plotting circle

if strcmpi(INTSQUARE,'on') % interpolate channels in the radius intrad square
  intchans = find(x <= intrad & y <= intrad); % interpolate and plot channels inside interpolation square
else
  intchans = find(Rd <= intrad); % interpolate channels in the radius intrad circle only
end

%
%%%%%%%%%%%%%%%%%%%%% Eliminate channels not plotted  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 

allx      = x;
ally      = y;
intchans; % interpolate using only the 'intchans' channels
pltchans; % plot using only indicated 'plotchans' channels

if length(pltchans) < length(Rd) && strcmpi(VERBOSE, 'on')
        fprintf('Interpolating %d and plotting %d of the %d scalp electrodes.\n', ...
                   length(intchans),length(pltchans),length(Rd));    
end;	


% fprintf('topoplot(): plotting %d channels\n',length(pltchans));
if ~isempty(EMARKER2CHANS)
    if strcmpi(STYLE,'blank')
       error('emarker2 not defined for style ''blank'' - use marking channel numbers in place of data');
    else % mark1chans and mark2chans are subsets of pltchans for markers 1 and 2
       [tmp1, mark1chans, tmp2] = setxor(pltchans,EMARKER2CHANS);
       [tmp3, tmp4, mark2chans] = intersect(EMARKER2CHANS,pltchans);
    end
end

if ~isempty(Values)
	if length(Values) == length(Th)  % if as many map Values as channel locs
		intValues      = Values(intchans);
		intContourVals = ContourVals(intchans);
        Values         = Values(pltchans);
		ContourVals    = ContourVals(pltchans);
	end;	
end;   % now channel parameters and values all refer to plotting channels only

allchansind = allchansind(pltchans);
intTh = Th(intchans);           % eliminate channels outside the interpolation area
intRd = Rd(intchans);
intx  = x(intchans);
inty  = y(intchans);
Th    = Th(pltchans);              % eliminate channels outside the plotting area
Rd    = Rd(pltchans);
x     = x(pltchans);
y     = y(pltchans);

labels= labels(pltchans,:);
%
%%%%%%%%%%%%%%% Squeeze channel locations to <= rmax %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 

squeezefac = rmax/plotrad;
intRd = intRd*squeezefac; % squeeze electrode arc_lengths towards the vertex
Rd = Rd*squeezefac;       % squeeze electrode arc_lengths towards the vertex
                          % to plot all inside the head cartoon
intx = intx*squeezefac;   
inty = inty*squeezefac;  
x    = x*squeezefac;    
y    = y*squeezefac;   
allx    = allx*squeezefac;    
ally    = ally*squeezefac;   
% Note: Now outermost channel will be plotted just inside rmax

else % if strcmpi(STYLE,'grid')
   intx = rmax; inty=rmax;
end % if ~strcmpi(STYLE,'grid')

%
%%%%%%%%%%%%%%%% rotate channels based on chaninfo %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
if strcmpi(lower(NOSEDIR), '+x')
     rotate = 0;
else
    if strcmpi(lower(NOSEDIR), '+y')
        rotate = 3*pi/2;
    elseif strcmpi(lower(NOSEDIR), '-x')
        rotate = pi;
    else rotate = pi/2;
    end
    allcoords = (inty + intx*sqrt(-1))*exp(sqrt(-1)*rotate);
    intx = imag(allcoords);
    inty = real(allcoords);
    allcoords = (ally + allx*sqrt(-1))*exp(sqrt(-1)*rotate);
    allx = imag(allcoords);
    ally = real(allcoords);
    allcoords = (y + x*sqrt(-1))*exp(sqrt(-1)*rotate);
    x = imag(allcoords);
    y = real(allcoords);
end

%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Make the plot %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
if ~strcmpi(STYLE,'blank') % if draw interpolated scalp map
 if ~strcmpi(STYLE,'grid') %  not a rectangular channel grid
  %
  %%%%%%%%%%%%%%%% Find limits for interpolation %%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %
  if default_intrad % if no specified intrad
   if strcmpi(INTERPLIMITS,'head') % intrad is 'head'
    xmin = min(-rmax,min(intx)); xmax = max(rmax,max(intx));
    ymin = min(-rmax,min(inty)); ymax = max(rmax,max(inty));

   else % INTERPLIMITS = rectangle containing electrodes -- DEPRECATED OPTION!
    xmin = max(-rmax,min(intx)); xmax = min(rmax,max(intx));
    ymin = max(-rmax,min(inty)); ymax = min(rmax,max(inty));
   end
  else % some other intrad specified
    xmin = -intrad*squeezefac; xmax = intrad*squeezefac;   % use the specified intrad value 
    ymin = -intrad*squeezefac; ymax = intrad*squeezefac;
  end
  %
  %%%%%%%%%%%%%%%%%%%%%%% Interpolate scalp map data %%%%%%%%%%%%%%%%%%%%%%%%
  %
  xi = linspace(xmin,xmax,GRID_SCALE);   % x-axis description (row vector)
  yi = linspace(ymin,ymax,GRID_SCALE);   % y-axis description (row vector)

  try
      [Xi,Yi,Zi] = griddata(inty,intx,double(intValues),yi',xi,'v4'); % interpolate data
      [Xi,Yi,ZiC] = griddata(inty,intx,double(intContourVals),yi',xi,'v4'); % interpolate data
  catch,
      [Xi,Yi] = meshgrid(yi',xi);
      Zi  = gdatav4(inty,intx,double(intValues), Xi, Yi);
      ZiC = gdatav4(inty,intx,double(intContourVals), Xi, Yi);
  end
  %
  %%%%%%%%%%%%%%%%%%%%%%% Mask out data outside the head %%%%%%%%%%%%%%%%%%%%%
  %
  mask = (sqrt(Xi.^2 + Yi.^2) <= rmax); % mask outside the plotting circle
  ii = find(mask == 0);
  Zi(ii)  = NaN;                         % mask non-plotting voxels with NaNs  
  ZiC(ii) = NaN;                         % mask non-plotting voxels with NaNs
  grid = plotrad;                       % unless 'noplot', then 3rd output arg is plotrad
  %
  %%%%%%%%%% Return interpolated value at designated scalp location %%%%%%%%%%
  %
  if exist('chanrad')   % optional first argument to 'noplot' 
      chantheta = (chantheta/360)*2*pi;
      chancoords = round(ceil(GRID_SCALE/2)+GRID_SCALE/2*2*chanrad*[cos(-chantheta),...
                                                      -sin(-chantheta)]);
      if chancoords(1)<1 ...
         || chancoords(1) > GRID_SCALE ...
            || chancoords(2)<1 ...
               || chancoords(2)>GRID_SCALE
          error('designated ''noplot'' channel out of bounds')
      else
        chanval = Zi(chancoords(1),chancoords(2));
        grid = Zi;
        Zi = chanval;  % return interpolated value instead of Zi
      end
  end
  %
  %%%%%%%%%%%%%%%%%%%%%%%%%% Return interpolated image only  %%%%%%%%%%%%%%%%%
  %
   if strcmpi(noplot, 'on') 
    if strcmpi(VERBOSE,'on')
       fprintf('topoplot(): no plot requested.\n')
    end
    return;
   end
  %
  %%%%%%%%%%%%%%%%%%%%%%% Calculate colormap limits %%%%%%%%%%%%%%%%%%%%%%%%%%
  %
  if ischar(MAPLIMITS)
    if strcmp(MAPLIMITS,'absmax')
      amax = max(max(abs(Zi)));
      amin = -amax;
    elseif strcmp(MAPLIMITS,'maxmin') || strcmp(MAPLIMITS,'minmax')
      amin = min(min(Zi));
      amax = max(max(Zi));
    else
      error('unknown ''maplimits'' value.');
    end
  elseif length(MAPLIMITS) == 2
    amin = MAPLIMITS(1);
    amax = MAPLIMITS(2);
  else
    error('unknown ''maplimits'' value');
  end
  delta = xi(2)-xi(1); % length of grid entry

 end % if ~strcmpi(STYLE,'grid')
  %
  %%%%%%%%%%%%%%%%%%%%%%%%%% Scale the axes %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %
  %cla  % clear current axis
  hold on
  h = gca; % uses current axes

                          % instead of default larger AXHEADFAC 
  if squeezefac<0.92 && plotrad-headrad > 0.05  % (size of head in axes)
    AXHEADFAC = 1.05;     % do not leave room for external ears if head cartoon
                          % shrunk enough by the 'skirt' option
  end

  set(gca,'Xlim',[-rmax rmax]*AXHEADFAC,'Ylim',[-rmax rmax]*AXHEADFAC);
                          % specify size of head axes in gca

  unsh = (GRID_SCALE+1)/GRID_SCALE; % un-shrink the effects of 'interp' SHADING

  %
  %%%%%%%%%%%%%%%%%%%%%%%% Plot grid only %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %
  if strcmpi(STYLE,'grid')                     % plot grid only

    %
    % The goal below is to make the grid cells square - not yet achieved in all cases? -sm
    %
    g1 = size(gridchans,1); 
    g2 = size(gridchans,2); 
    gmax = max([g1 g2]);
    Xi = linspace(-rmax*g2/gmax,rmax*g2/gmax,g1+1);
    Xi = Xi+rmax/g1; Xi = Xi(1:end-1);
    Yi = linspace(-rmax*g1/gmax,rmax*g1/gmax,g2+1);
    Yi = Yi+rmax/g2; Yi = Yi(1:end-1); Yi = Yi(end:-1:1); % by trial and error!
    %
    %%%%%%%%%%% collect the gridchans values %%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    gridvalues = zeros(size(gridchans));
    for j=1:size(gridchans,1)
      for k=1:size(gridchans,2)
         gc = gridchans(j,k);
         if gc > 0
              gridvalues(j,k) = Values(gc);
         elseif gc < 0
              gridvalues(j,k) = -Values(abs(gc));
         else 
              gridvalues(j,k) = nan; % not-a-number = no value
         end
      end
    end
    %
    %%%%%%%%%%% reset color limits for grid plot %%%%%%%%%%%%%%%%%%%%%%%%%
    %
    if ischar(MAPLIMITS) 
      if strcmp(MAPLIMITS,'maxmin') || strcmp(MAPLIMITS,'minmax')
        amin = min(min(gridvalues(~isnan(gridvalues))));
        amax = max(max(gridvalues(~isnan(gridvalues))));
      elseif strcmp(MAPLIMITS,'absmax')
        % 11/21/2005 Toby edit
        % This should now work as specified. Before it only crashed (using
        % "plotgrid" and "maplimits>absmax" options).
        amax = max(max(abs(gridvalues(~isnan(gridvalues)))));
        amin = -amax;
        %amin = -max(max(abs([amin amax])));
        %amax = max(max(abs([amin amax])));
      else
        error('unknown ''maplimits'' value');
      end
    elseif length(MAPLIMITS) == 2
      amin = MAPLIMITS(1);
      amax = MAPLIMITS(2);
    else
      error('unknown ''maplimits'' value');
    end
    %
    %%%%%%%%%% explicitly compute grid colors, allowing BACKCOLOR  %%%%%%
    %
    gridvalues = 1+floor(cmaplen*(gridvalues-amin)/(amax-amin));
    gridvalues(find(gridvalues == cmaplen+1)) = cmaplen;
    gridcolors = zeros([size(gridvalues),3]);
    for j=1:size(gridchans,1)
      for k=1:size(gridchans,2)
         if ~isnan(gridvalues(j,k))
             gridcolors(j,k,:) = cmap(gridvalues(j,k),:);
         else
            if strcmpi(whitebk,'off')
                gridcolors(j,k,:) = BACKCOLOR; % gridchans == 0 -> background color
                % This allows the plot to show 'space' between separate sub-grids or strips
            else % 'on'
                gridcolors(j,k,:) = [1 1 1]; BACKCOLOR; % gridchans == 0 -> white for printing
            end
         end
      end
    end

    %
    %%%%%%%%%% draw the gridplot image %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    handle=imagesc(Xi,Yi,gridcolors); % plot grid with explicit colors
    axis square
  %
  %%%%%%%%%%%%%%%%%%%%%%%% Plot map contours only %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %
  elseif strcmp(STYLE,'contour')                     % plot surface contours only
    [cls chs] = contour(Xi,Yi,ZiC,CONTOURNUM,'k'); 
    handle = chs;                                   % handle to a contourgroup object
    % for h=chs, set(h,'color',CCOLOR); end
  %
  %%%%%%%%%%%%%%%%%%%%%%%% Else plot map and contours %%%%%%%%%%%%%%%%%%%%%%%%%
  %
  elseif strcmp(STYLE,'both')  % plot interpolated surface and surface contours
      if strcmp(SHADING,'interp')
       tmph = surface(Xi*unsh,Yi*unsh,zeros(size(Zi))-0.1,Zi,...
               'EdgeColor','none','FaceColor',SHADING);                    
    else % SHADING == 'flat'
       tmph = surface(Xi-delta/2,Yi-delta/2,zeros(size(Zi))-0.1,Zi,...
               'EdgeColor','none','FaceColor',SHADING);                    
    end
    if strcmpi(MASKSURF, 'on')
        set(tmph, 'visible', 'off');
        handle = tmph;
    end
    
    warning off;
    if ~PMASKFLAG
        [cls chs] = contour(Xi,Yi,ZiC,CONTOURNUM,'k'); 
    else
        ZiC(find(ZiC > 0.5 )) = NaN;
        [cls chs] = contourf(Xi,Yi,ZiC,0,'k');
        subh = get(chs, 'children');
        for indsubh = 1:length(subh)
            numfaces = size(get(subh(indsubh), 'XData'),1); 
            set(subh(indsubh), 'FaceVertexCData', ones(numfaces,3), 'Cdatamapping', 'direct', 'facealpha', 0.5, 'linewidth', 2);
        end
    end
    handle = tmph;                                   % surface handle
    try, for h=chs, set(h,'color',CCOLOR); end, catch, end % the try clause is for Octave
    warning on;
  %
  %%%%%%%%%%%%%%%%%%%%%%%% Else plot map only %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %
  elseif strcmp(STYLE,'straight') || strcmp(STYLE,'map') % 'straight' was former arg

      if strcmp(SHADING,'interp') % 'interp' mode is shifted somehow... but how?
         tmph = surface(Xi*unsh,Yi*unsh,zeros(size(Zi)),Zi,'EdgeColor','none',...
                  'FaceColor',SHADING);
      else
         tmph = surface(Xi-delta/2,Yi-delta/2,zeros(size(Zi)),Zi,'EdgeColor','none',...
                 'FaceColor',SHADING);
      end
    if strcmpi(MASKSURF, 'on')
        set(tmph, 'visible', 'off');
        handle = tmph;
    end
    handle = tmph;                                   % surface handle
  %
  %%%%%%%%%%%%%%%%%% Else fill contours with uniform colors  %%%%%%%%%%%%%%%%%%
  %
  elseif strcmp(STYLE,'fill')
    [cls chs] = contourf(Xi,Yi,Zi,CONTOURNUM,'k');
    
    handle = chs;                                   % handle to a contourgroup object

    % for h=chs, set(h,'color',CCOLOR); end 
    %     <- 'not line objects.' Why does 'both' work above???

  else
    error('Invalid style')
  end
  %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Set color axis  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %
%   caxis([amin amax]); % set coloraxis

% 7/30/2014 Ramon: +-5% for the color limits were added
cax_sgn = sign([amin amax]);                                                  % getting sign
caxis([amin+cax_sgn(1)*(0.05*abs(amin)) amax+cax_sgn(2)*(0.05*abs(amax))]);   % Adding 5% to the color limits

else % if STYLE 'blank'
%
%%%%%%%%%%%%%%%%%%%%%%% Draw blank head %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
  if strcmpi(noplot, 'on') 
   if strcmpi(VERBOSE,'on')
      fprintf('topoplot(): no plot requested.\n')
   end
   return;
  end
  %cla
  hold on

  set(gca,'Xlim',[-rmax rmax]*AXHEADFAC,'Ylim',[-rmax rmax]*AXHEADFAC)
   % pos = get(gca,'position');
   % fprintf('Current axes size %g,%g\n',pos(3),pos(4));

  if strcmp(ELECTRODES,'labelpoint') ||  strcmp(ELECTRODES,'numpoint')
    text(-0.6,-0.6, ...
    [ int2str(length(Rd)) ' of ' int2str(length(tmpeloc)) ' electrode locations shown']); 
    text(-0.6,-0.7, [ 'Click on electrodes to toggle name/number']);
    tl = title('Channel locations');
    set(tl, 'fontweight', 'bold');
  end
end % STYLE 'blank'

if exist('handle') ~= 1
    handle = gca;
end

if ~strcmpi(STYLE,'grid')                     % if not plot grid only

%
%%%%%%%%%%%%%%%%%%% Plot filled ring to mask jagged grid boundary %%%%%%%%%%%%%%%%%%%%%%%%%%%
%
hwidth = HEADRINGWIDTH;                   % width of head ring 
hin  = squeezefac*headrad*(1- hwidth/2);  % inner head ring radius

if strcmp(SHADING,'interp')
  rwidth = BLANKINGRINGWIDTH*1.3;             % width of blanking outer ring
else
  rwidth = BLANKINGRINGWIDTH;         % width of blanking outer ring
end
rin    =  rmax*(1-rwidth/2);              % inner ring radius
if hin>rin
  rin = hin;                              % dont blank inside the head ring
end

if strcmp(CONVHULL,'on') %%%%%%%%% mask outside the convex hull of the electrodes %%%%%%%%%
  cnv = convhull(allx,ally);
  cnvfac = round(CIRCGRID/length(cnv)); % spline interpolate the convex hull
  if cnvfac < 1, cnvfac=1; end
  CIRCGRID = cnvfac*length(cnv);

  startangle = atan2(allx(cnv(1)),ally(cnv(1)));
  circ = linspace(0+startangle,2*pi+startangle,CIRCGRID);
  rx = sin(circ); 
  ry = cos(circ); 

  allx = allx(:)';  % make x (elec locations; + to nose) a row vector
  ally = ally(:)';  % make y (elec locations, + to r? ear) a row vector
  erad = sqrt(allx(cnv).^2+ally(cnv).^2);  % convert to polar coordinates
  eang = atan2(allx(cnv),ally(cnv));
  eang = unwrap(eang);
  eradi =spline(linspace(0,1,3*length(cnv)), [erad erad erad], ...
                                      linspace(0,1,3*length(cnv)*cnvfac));
  eangi =spline(linspace(0,1,3*length(cnv)), [eang+2*pi eang eang-2*pi], ...
                                      linspace(0,1,3*length(cnv)*cnvfac));
  xx = eradi.*sin(eangi);           % convert back to rect coordinates
  yy = eradi.*cos(eangi);
  yy = yy(CIRCGRID+1:2*CIRCGRID);
  xx = xx(CIRCGRID+1:2*CIRCGRID);
  eangi = eangi(CIRCGRID+1:2*CIRCGRID);
  eradi = eradi(CIRCGRID+1:2*CIRCGRID);
  xx = xx*1.02; yy = yy*1.02;           % extend spline outside electrode marks

  splrad = sqrt(xx.^2+yy.^2);           % arc radius of spline points (yy,xx)
  oob = find(splrad >= rin);            %  enforce an upper bound on xx,yy
  xx(oob) = rin*xx(oob)./splrad(oob);   % max radius = rin
  yy(oob) = rin*yy(oob)./splrad(oob);   % max radius = rin

  splrad = sqrt(xx.^2+yy.^2);           % arc radius of spline points (yy,xx)
  oob = find(splrad < hin);             % don't let splrad be inside the head cartoon
  xx(oob) = hin*xx(oob)./splrad(oob);   % min radius = hin
  yy(oob) = hin*yy(oob)./splrad(oob);   % min radius = hin

  ringy = [[ry(:)' ry(1) ]*(rin+rwidth) yy yy(1)];
  ringx = [[rx(:)' rx(1) ]*(rin+rwidth) xx xx(1)];

  ringh2= patch(ringy,ringx,ones(size(ringy)),BACKCOLOR,'edgecolor','none'); hold on

  % plot(ry*rmax,rx*rmax,'b') % debugging line

else %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% mask the jagged border around rmax %%%%%%%%%%%%%%%5%%%%%%

  circ = linspace(0,2*pi,CIRCGRID);
  rx = sin(circ); 
  ry = cos(circ); 
  ringx = [[rx(:)' rx(1) ]*(rin+rwidth)  [rx(:)' rx(1)]*rin];
  ringy = [[ry(:)' ry(1) ]*(rin+rwidth)  [ry(:)' ry(1)]*rin];

  if ~strcmpi(STYLE,'blank')
    ringh= patch(ringx,ringy,0.01*ones(size(ringx)),BACKCOLOR,'edgecolor','none'); hold on
  end
  % plot(ry*rmax,rx*rmax,'b') % debugging line
end

  %f1= fill(rin*[rx rX],rin*[ry rY],BACKCOLOR,'edgecolor',BACKCOLOR); hold on
  %f2= fill(rin*[rx rX*(1+rwidth)],rin*[ry rY*(1+rwidth)],BACKCOLOR,'edgecolor',BACKCOLOR);

% Former line-style border smoothing - width did not scale with plot
%  brdr=plot(1.015*cos(circ).*rmax,1.015*sin(circ).*rmax,...      % old line-based method
%      'color',HEADCOLOR,'Linestyle','-','LineWidth',HLINEWIDTH);    % plot skirt outline
%  set(brdr,'color',BACKCOLOR,'linewidth',HLINEWIDTH + 4);        % hide the disk edge jaggies 

%
%%%%%%%%%%%%%%%%%%%%%%%%% Plot cartoon head, ears, nose %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
if headrad > 0                         % if cartoon head to be plotted
%
%%%%%%%%%%%%%%%%%%% Plot head outline %%%%%%%%%%%%%%%%%%%%%%%%%%%
%
headx = [[rx(:)' rx(1) ]*(hin+hwidth)  [rx(:)' rx(1)]*hin];
heady = [[ry(:)' ry(1) ]*(hin+hwidth)  [ry(:)' ry(1)]*hin];

if ~ischar(HEADCOLOR) || ~strcmpi(HEADCOLOR,'none')
   %ringh= patch(headx,heady,ones(size(headx)),HEADCOLOR,'edgecolor',HEADCOLOR,'linewidth', HLINEWIDTH); hold on
   headx = [rx(:)' rx(1)]*hin;
   heady = [ry(:)' ry(1)]*hin;
   ringh= plot(headx,heady);
   set(ringh, 'color',HEADCOLOR,'linewidth', HLINEWIDTH); hold on
end

% rx = sin(circ); rX = rx(end:-1:1);
% ry = cos(circ); rY = ry(end:-1:1);
% for k=2:2:CIRCGRID
%   rx(k) = rx(k)*(1+hwidth);
%   ry(k) = ry(k)*(1+hwidth);
% end
% f3= fill(hin*[rx rX],hin*[ry rY],HEADCOLOR,'edgecolor',HEADCOLOR); hold on
% f4= fill(hin*[rx rX*(1+hwidth)],hin*[ry rY*(1+hwidth)],HEADCOLOR,'edgecolor',HEADCOLOR);

% Former line-style head
%  plot(cos(circ).*squeezefac*headrad,sin(circ).*squeezefac*headrad,...
%      'color',HEADCOLOR,'Linestyle','-','LineWidth',HLINEWIDTH);    % plot head outline

%
%%%%%%%%%%%%%%%%%%% Plot ears and nose %%%%%%%%%%%%%%%%%%%%%%%%%%%
%
  base  = rmax-.0046;
  basex = 0.18*rmax;                   % nose width
  tip   = 1.15*rmax; 
  tiphw = .04*rmax;                    % nose tip half width
  tipr  = .01*rmax;                    % nose tip rounding
  q = .04; % ear lengthening
  EarX  = [.497-.005  .510  .518  .5299 .5419  .54    .547   .532   .510   .489-.005]; % rmax = 0.5
  EarY  = [q+.0555 q+.0775 q+.0783 q+.0746 q+.0555 -.0055 -.0932 -.1313 -.1384 -.1199];
  sf    = headrad/plotrad;                                          % squeeze the model ears and nose 
                                                                    % by this factor
  if ~ischar(HEADCOLOR) || ~strcmpi(HEADCOLOR,'none')
    plot3([basex;tiphw;0;-tiphw;-basex]*sf,[base;tip-tipr;tip;tip-tipr;base]*sf,...
         2*ones(size([basex;tiphw;0;-tiphw;-basex])),...
         'Color',HEADCOLOR,'LineWidth',HLINEWIDTH);                 % plot nose
    plot3(EarX*sf,EarY*sf,2*ones(size(EarX)),'color',HEADCOLOR,'LineWidth',HLINEWIDTH)    % plot left ear
    plot3(-EarX*sf,EarY*sf,2*ones(size(EarY)),'color',HEADCOLOR,'LineWidth',HLINEWIDTH)   % plot right ear
  end
end

%
% %%%%%%%%%%%%%%%%%%% Show electrode information %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
 plotax = gca;
 axis square                                           % make plotax square
 axis off

 pos = get(gca,'position');
 xlm = get(gca,'xlim');
 ylm = get(gca,'ylim');
 % textax = axes('position',pos,'xlim',xlm,'ylim',ylm);  % make new axes so clicking numbers <-> labels 
                                                       % will work inside head cartoon patch
 % axes(textax);                   
 axis square                                           % make textax square

 pos = get(gca,'position');
 set(plotax,'position',pos);

 xlm = get(gca,'xlim');
 set(plotax,'xlim',xlm);

 ylm = get(gca,'ylim');
 set(plotax,'ylim',ylm);                               % copy position and axis limits again

axis equal;
lim = [-0.525 0.525];
%lim = [-0.56 0.56];
set(gca, 'xlim', lim); set(plotax, 'xlim', lim);
set(gca, 'ylim', lim); set(plotax, 'ylim', lim);
set(gca, 'xlim', lim); set(plotax, 'xlim', lim);
set(gca, 'ylim', lim); set(plotax, 'ylim', lim);
 
%get(textax,'pos')    % test if equal!
%get(plotax,'pos')
%get(textax,'xlim')
%get(plotax,'xlim')
%get(textax,'ylim')
%get(plotax,'ylim')

 if isempty(EMARKERSIZE)
   EMARKERSIZE = 10;
   if length(y)>=160
    EMARKERSIZE = 3;
   elseif length(y)>=128
    EMARKERSIZE = 3;
   elseif length(y)>=100
    EMARKERSIZE = 3;
   elseif length(y)>=80
    EMARKERSIZE = 4;
   elseif length(y)>=64
    EMARKERSIZE = 5;
   elseif length(y)>=48
    EMARKERSIZE = 6;
   elseif length(y)>=32 
    EMARKERSIZE = 8;
   end
 end
%
%%%%%%%%%%%%%%%%%%%%%%%% Mark electrode locations only %%%%%%%%%%%%%%%%%%%%%%%%%%
%
ELECTRODE_HEIGHT = 2.1;  % z value for plotting electrode information (above the surf)

if strcmp(ELECTRODES,'on')   % plot electrodes as spots
  if isempty(EMARKER2CHANS)
    hp2 = plot3(y,x,ones(size(x))*ELECTRODE_HEIGHT,...
        EMARKER,'Color',ECOLOR,'markersize',EMARKERSIZE,'linewidth',EMARKERLINEWIDTH);
  else % plot markers for normal chans and EMARKER2CHANS separately
    hp2 = plot3(y(mark1chans),x(mark1chans),ones(size((mark1chans)))*ELECTRODE_HEIGHT,...
        EMARKER,'Color',ECOLOR,'markersize',EMARKERSIZE,'linewidth',EMARKERLINEWIDTH);
    hp2b = plot3(y(mark2chans),x(mark2chans),ones(size((mark2chans)))*ELECTRODE_HEIGHT,...
        EMARKER2,'Color',EMARKER2COLOR,'markerfacecolor',EMARKER2COLOR,'linewidth',EMARKER2LINEWIDTH,'markersize',EMARKERSIZE2);
  end
%
%%%%%%%%%%%%%%%%%%%%%%%% Print electrode labels only %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
elseif strcmp(ELECTRODES,'labels')  % print electrode names (labels)
    for i = 1:size(labels,1)
    text(double(y(i)),double(x(i)),...
        ELECTRODE_HEIGHT,labels(i,:),'HorizontalAlignment','center',...
	'VerticalAlignment','middle','Color',ECOLOR,...
	'FontSize',EFSIZE)
  end
%
%%%%%%%%%%%%%%%%%%%%%%%% Mark electrode locations plus labels %%%%%%%%%%%%%%%%%%%
%
elseif strcmp(ELECTRODES,'labelpoint') 
  if isempty(EMARKER2CHANS)
    hp2 = plot3(y,x,ones(size(x))*ELECTRODE_HEIGHT,...
        EMARKER,'Color',ECOLOR,'markersize',EMARKERSIZE,'linewidth',EMARKERLINEWIDTH);
  else
    hp2 = plot3(y(mark1chans),x(mark1chans),ones(size((mark1chans)))*ELECTRODE_HEIGHT,...
        EMARKER,'Color',ECOLOR,'markersize',EMARKERSIZE,'linewidth',EMARKERLINEWIDTH);
    hp2b = plot3(y(mark2chans),x(mark2chans),ones(size((mark2chans)))*ELECTRODE_HEIGHT,...
        EMARKER2,'Color',EMARKER2COLOR,'markerfacecolor',EMARKER2COLOR,'linewidth',EMARKER2LINEWIDTH,'markersize',EMARKERSIZE2);
  end
  for i = 1:size(labels,1)
    hh(i) = text(double(y(i)+0.01),double(x(i)),...
        ELECTRODE_HEIGHT,labels(i,:),'HorizontalAlignment','left',...
	'VerticalAlignment','middle','Color', ECOLOR,'userdata', num2str(allchansind(i)), ...
	'FontSize',EFSIZE, 'buttondownfcn', ...
	    ['tmpstr = get(gco, ''userdata'');'...
	     'set(gco, ''userdata'', get(gco, ''string''));' ...
	     'set(gco, ''string'', tmpstr); clear tmpstr;'] );
  end
%
%%%%%%%%%%%%%%%%%%%%%%% Mark electrode locations plus numbers %%%%%%%%%%%%%%%%%%%
%
elseif strcmp(ELECTRODES,'numpoint') 
  if isempty(EMARKER2CHANS)
    hp2 = plot3(y,x,ones(size(x))*ELECTRODE_HEIGHT,...
        EMARKER,'Color',ECOLOR,'markersize',EMARKERSIZE,'linewidth',EMARKERLINEWIDTH);
  else
    hp2 = plot3(y(mark1chans),x(mark1chans),ones(size((mark1chans)))*ELECTRODE_HEIGHT,...
        EMARKER,'Color',ECOLOR,'markersize',EMARKERSIZE,'linewidth',EMARKERLINEWIDTH);
    hp2b = plot3(y(mark2chans),x(mark2chans),ones(size((mark2chans)))*ELECTRODE_HEIGHT,...
        EMARKER2,'Color',EMARKER2COLOR,'markerfacecolor',EMARKER2COLOR,'linewidth',EMARKER2LINEWIDTH,'markersize',EMARKERSIZE2);
  end
  for i = 1:size(labels,1)
    hh(i) = text(double(y(i)+0.01),double(x(i)),...
        ELECTRODE_HEIGHT,num2str(allchansind(i)),'HorizontalAlignment','left',...
	'VerticalAlignment','middle','Color', ECOLOR,'userdata', labels(i,:) , ...
	'FontSize',EFSIZE, 'buttondownfcn', ...
	    ['tmpstr = get(gco, ''userdata'');'...
	     'set(gco, ''userdata'', get(gco, ''string''));' ...
	     'set(gco, ''string'', tmpstr); clear tmpstr;'] );
  end
%
%%%%%%%%%%%%%%%%%%%%%% Print electrode numbers only %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
elseif strcmp(ELECTRODES,'numbers')
  for i = 1:size(labels,1)
    text(double(y(i)),double(x(i)),...
        ELECTRODE_HEIGHT,int2str(allchansind(i)),'HorizontalAlignment','center',...
	'VerticalAlignment','middle','Color',ECOLOR,...
	'FontSize',EFSIZE)
  end
%
%%%%%%%%%%%%%%%%%%%%%% Mark emarker2 electrodes only  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
elseif strcmp(ELECTRODES,'off') && ~isempty(EMARKER2CHANS)
    hp2b = plot3(y(mark2chans),x(mark2chans),ones(size((mark2chans)))*ELECTRODE_HEIGHT,...
        EMARKER2,'Color',EMARKER2COLOR,'markerfacecolor',EMARKER2COLOR,'linewidth',EMARKER2LINEWIDTH,'markersize',EMARKERSIZE2);
end
%
%%%%%%%% Mark specified electrode locations with red filled disks  %%%%%%%%%%%%%%%%%%%%%%
%
try,
    if strcmpi(STYLE,'blank') % if mark-selected-channel-locations mode
        for kk = 1:length(1:length(x))
            if abs(Values(kk))
                if strcmpi(PLOTDISK, 'off')
                    angleRatio = real(Values(kk))/(real(Values(kk))+imag(Values(kk)))*360;
                    radius     = real(Values(kk))+imag(Values(kk));
                    allradius  = [0.02 0.03 0.037 0.044 0.05];
                    radius     = allradius(radius);
                    hp2 = disk(y(kk),x(kk),radius, [1 0 0], 0 , angleRatio, 16);
                    if angleRatio ~= 360
                        hp2 = disk(y(kk),x(kk),radius, [0 0 1], angleRatio, 360, 16);
                    end
                else
                    tmpcolor = COLORARRAY{max(1,min(Values(kk), length(COLORARRAY)))};
                    hp2 = plot3(y(kk),x(kk),ELECTRODE_HEIGHT,EMARKER,'Color', tmpcolor, 'markersize', EMARKERSIZE1CHAN);
                    hp2 = disk(y(kk),x(kk),real(Values(kk))+imag(Values(kk)), tmpcolor, 0, 360, 10);
                end
            end
        end
    end
catch, end
%
%%%%%%%%%%%%%%%%%%%%%%%%%%% Plot dipole(s) on the scalp map  %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
if ~isempty(DIPOLE)  
    hold on;
    tmp = DIPOLE;
    if isstruct(DIPOLE)
        if ~isfield(tmp,'posxyz')
           error('dipole structure is not an EEG.dipfit.model')
        end
        DIPOLE = [];  % Note: invert x and y from dipplot usage
        DIPOLE(:,1) = -tmp.posxyz(:,2)/DIPSPHERE; % -y -> x
        DIPOLE(:,2) =  tmp.posxyz(:,1)/DIPSPHERE; %  x -> y
        DIPOLE(:,3) = -tmp.momxyz(:,2);
        DIPOLE(:,4) =  tmp.momxyz(:,1);
        DIPOLE(:,5) =  tmp.momxyz(:,3);
    else
        DIPOLE(:,1) = -tmp(:,2);                    % same for vector input
        DIPOLE(:,2) =  tmp(:,1);
        DIPOLE(:,3) = -tmp(:,4);
        DIPOLE(:,4) =  tmp(:,3);
    end
    for index = 1:size(DIPOLE,1)
        if ~any(DIPOLE(index,:))
             DIPOLE(index,:) = [];
        end
    end
    DIPOLE(:,1:4)   = DIPOLE(:,1:4)*rmax*(rmax/plotrad); % scale radius from 1 -> rmax (0.5)
    DIPOLE(:,3:end) = (DIPOLE(:,3:end))*rmax/100000*(rmax/plotrad); 
    if strcmpi(DIPNORM, 'on')
        for index = 1:size(DIPOLE,1)
            DIPOLE(index,3:4) = DIPOLE(index,3:4)/norm(DIPOLE(index,3:end))*0.2;
        end
    elseif strcmpi(DIPNORMMAX, 'on')     
        for inorm =  1: size(DIPOLE,1)
            normtmp(inorm) = norm(DIPOLE(inorm,3:5)); % Max norm of projection on XY
        end
        [maxnorm,maxnormindx] = max(normtmp);
        for index = 1:size(DIPOLE,1)
            DIPOLE(index,3:4) = DIPOLE(index,3:4)/norm(DIPOLE(index,3:4))*0.2*normtmp(index)/normtmp(maxnormindx);
        end; 
    end
    DIPOLE(:, 3:4) =  DIPORIENT*DIPOLE(:, 3:4)*DIPLEN;

    PLOT_DIPOLE=1;
    if sum(DIPOLE(1,3:4).^2) <= 0.00001  
      if strcmpi(VERBOSE,'on')
        fprintf('Note: dipole is length 0 - not plotted\n')
      end
      PLOT_DIPOLE = 0;
    end
    if 0 % sum(DIPOLE(1,1:2).^2) > plotrad
      if strcmpi(VERBOSE,'on')
        fprintf('Note: dipole is outside plotting area - not plotted\n')
      end
      PLOT_DIPOLE = 0;
    end
    if PLOT_DIPOLE
      for index = 1:size(DIPOLE,1)
        hh = plot( DIPOLE(index, 1), DIPOLE(index, 2), '.');
        set(hh, 'color', DIPCOLOR, 'markersize', DIPSCALE*30);
        hh = line( [DIPOLE(index, 1) DIPOLE(index, 1)+DIPOLE(index, 3)]', ...
                   [DIPOLE(index, 2) DIPOLE(index, 2)+DIPOLE(index, 4)]',[10 10]);
        set(hh, 'color', DIPCOLOR, 'linewidth', DIPSCALE*30/7);
      end
    end
end

end % if ~ 'gridplot'

%
%%%%%%%%%%%%% Plot axis orientation %%%%%%%%%%%%%%%%%%%%
%
if strcmpi(DRAWAXIS, 'on')
    axes('position', [0 0.85 0.08 0.1]);
    axis off;
    coordend1 = sqrt(-1)*3;
    coordend2 = -3;
    coordend1 = coordend1*exp(sqrt(-1)*rotate);
    coordend2 = coordend2*exp(sqrt(-1)*rotate);
    
    line([5 5+round(real(coordend1))]', [5 5+round(imag(coordend1))]', 'color', 'k');
    line([5 5+round(real(coordend2))]', [5 5+round(imag(coordend2))]', 'color', 'k');
    if round(real(coordend2))<0
         text( 5+round(real(coordend2))*1.2, 5+round(imag(coordend2))*1.2-2, '+Y');
    else text( 5+round(real(coordend2))*1.2, 5+round(imag(coordend2))*1.2, '+Y');
    end
    if round(real(coordend1))<0
         text( 5+round(real(coordend1))*1.2, 5+round(imag(coordend1))*1.2+1.5, '+X');
    else text( 5+round(real(coordend1))*1.2, 5+round(imag(coordend1))*1.2, '+X');
    end
    set(gca, 'xlim', [0 10], 'ylim', [0 10]);
end

%
%%%%%%%%%%%%% Set EEGLAB background color to match head border %%%%%%%%%%%%%%%%%%%%%%%%
%
try, 
  set(gcf, 'color', BACKCOLOR); 
  catch, 
end; 

hold off
axis off
return
end % function topoplot
% 
% X(2:size(X,1)-1,2:size(X,2)-1) = NaN;
% X(isnan(X(:))) = [];
% X(1:2:end) = [];
% X(1:2:end) = [];
% X(1:2:end) = [];

function vq = gdatav4(x,y,v,xq,yq)
%GDATAV4 MATLAB 4 GRIDDATA interpolation

%   Reference:  David T. Sandwell, Biharmonic spline
%   interpolation of GEOS-3 and SEASAT altimeter
%   data, Geophysical Research Letters, 2, 139-142,
%   1987.  Describes interpolation using value or
%   gradient of value in any dimension.

xy = x(:) + 1i*y(:);

% Determine distances between points
d = abs(xy - xy.');

% Determine weights for interpolation
g = (d.^2) .* (log(d)-1);   % Green's function.
% Fixup value of Green's function along diagonal
g(1:size(d,1)+1:end) = 0;
weights = g \ v(:);

[m,n] = size(xq);
vq = zeros(size(xq));
xy = xy.';

% Evaluate at requested points (xq,yq).  Loop to save memory.
for i=1:m
    for j=1:n
        d = abs(xq(i,j) + 1i*yq(i,j) - xy);
        g = (d.^2) .* (log(d)-1);   % Green's function.
        % Value of Green's function at zero
        g(d==0) = 0;
        vq(i,j) = g * weights;        
    end
end
end	% function gdatav4
%
%%%%%%%%%%%%% Draw circle %%%%%%%%%%%%%%%%%%%%%%%%
%
function h2 = disk(X, Y, radius, colorfill, oriangle, endangle, segments)
	A = linspace(oriangle/180*pi, endangle/180*pi, segments-1);
    if endangle-oriangle == 360
     	 A  = linspace(oriangle/180*pi, endangle/180*pi, segments);
         h2 = patch( [X   + cos(A)*radius(1)], [Y   + sin(A)*radius(end)], zeros(1,segments)+3, colorfill);
    else A  = linspace(oriangle/180*pi, endangle/180*pi, segments-1);
         h2 = patch( [X X + cos(A)*radius(1)], [Y Y + sin(A)*radius(end)], zeros(1,segments)+3, colorfill);
    end
    set(h2, 'FaceColor', colorfill);
	set(h2, 'EdgeColor', 'none'); 
end	% function disk
