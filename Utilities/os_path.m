classdef os_path < handle;
%% Documentation
% Partial matlab implementation of python os.path package
%
% Author: E. Branlard


% --------------------------------------------------------------------------------}
%% --- Static Hidden 
% --------------------------------------------------------------------------------{
methods(Static=true,Hidden=true);
    function [good_slash,bad_slash,good_slash_escaped]=get_slashes()
        if ispc()
            good_slash='\';
            bad_slash='/';
            good_slash_escaped='\\';
        else
            good_slash='/';
            bad_slash='\';
            good_slash_escaped='/';
        end
    end
    function test()
        clear all;
        fprintf('isabs: ');
        fprintf('%d', os_path.isabs('')==false);
        fprintf('%d', os_path.isabs('/'));
        fprintf('%d', os_path.isabs('\'));
        fprintf('%d', os_path.isabs('\a\b'));
        fprintf('%d', os_path.isabs('/a/b'));
        fprintf('%d', os_path.isabs('C:\'));
        fprintf('%d', os_path.isabs('C:')==false);
        fprintf('%d', os_path.isabs('aa/b')==false);
        fprintf('%d', os_path.isabs('\\host\')==false);
        fprintf('%d', os_path.isabs('\\host\mount\'));
        fprintf('\n');
% 
% %%
        fprintf('join: ');
        fprintf('%d', isequal(length(os_path.join('','')), 0) );
        fprintf('%d', isequal(os_path.join('/',''), '/') );
        fprintf('%d', isequal(os_path.join('/a'   ,'/b'), '/b') );   % Two absolute paths
        fprintf('%d', isequal(os_path.join('C:\a' ,'/b'), 'C:/b') ); % Two absolute paths
        fprintf('%d', isequal(os_path.join('\\server\drive\a' ,'/b'), '\\server\drive/b') ); % Two absolute paths 
        fprintf('%d', isequal(os_path.join('C:'   ,'b' ), 'C:b' ) ); 
        fprintf('%d', isequal(os_path.join('C:'   ,'\b'), 'C:\b') ); 
        fprintf('%d', isequal(os_path.join('C:\a' ,'b' ), 'C:\a\b') ); 
        fprintf('%d', isequal(os_path.join('C:\a\','b' ), 'C:\a\b') ); 
        fprintf('%d', isequal(os_path.join('C:/a/','b' ), 'C:/a/b') ); 
        fprintf('%d', isequal(os_path.join('a','b' )    , 'a\b') ); 
        fprintf('%d', isequal(os_path.join('a/..','../b' ),'a/..\../b') ); 
        fprintf('%d', isequal(os_path.join('C:\a\','C:\b' ),'C:\b') ); 
        fprintf('%d', isequal(os_path.join('C:\a\','\\server\drive\b' ),'\\server\drive\b') ); 
        fprintf('%d', isequal(os_path.join('a','b','c' ),'a\b\c')); 
        fprintf('%d', isequal(os_path.join('a','b','C:'),'C:')); 
        fprintf('%d', isequal(os_path.join('a','b','/c'),'/c')); 
        fprintf('\n');
        %%

        fprintf('normpath: ');
        fprintf('%d', isequal(os_path.normpath('/a'         ) , '/a') );
        fprintf('%d', isequal(os_path.normpath('.'          ) , '.') );
        fprintf('%d', isequal(os_path.normpath('./'         ) , '.') );
        fprintf('%d', isequal(os_path.normpath('./a'        ) , 'a') );
        fprintf('%d', isequal(os_path.normpath('a/./b'      ) , 'a\b') );
        fprintf('%d', isequal(os_path.normpath('a./b'       ) , 'a.\b') );
        fprintf('%d', isequal(os_path.normpath('/a////b/'   ), '\a\b') );
        fprintf('%d', isequal(os_path.normpath('..'         ) , '..') );
        fprintf('%d', isequal(os_path.normpath('..\'        ) , '..') );
        fprintf('%d', isequal(os_path.normpath('\..'        ) , '\') );
        fprintf('%d', isequal(os_path.normpath('\..\'       ) , '\') );
        fprintf('%d', isequal(os_path.normpath('\..\..\a'   ) , '\a') );
        fprintf('%d', isequal(os_path.normpath('a\b\..\c'   ), 'a\c') );
        fprintf('%d', isequal(os_path.normpath('a\b\c\..'   ), 'a\b') );
        fprintf('%d', isequal(os_path.normpath('a\b\c\..\'  ), 'a\b') );
        fprintf('%d', isequal(os_path.normpath('a\..'       ), '.'  ) );
        fprintf('%d', isequal(os_path.normpath('a\..\'      ), '.'  ) );
        fprintf('%d', isequal(os_path.normpath('a\..\..\'   ), '..'  ) );
        fprintf('%d', isequal(os_path.normpath('a\..\..\..\'), '..\..'  ) );
        fprintf('%d', isequal(os_path.normpath('a\..\..\..\b'), '..\..\b'  ) );
        fprintf('%d', isequal(os_path.normpath('C:\a\..\..\'), 'C:\'  ) );
        fprintf('%d', isequal(os_path.normpath('a\..b'      ), 'a\..b'  ) );
        fprintf('%d', isequal(os_path.normpath('/../../c'   ), '\c') );   % Can't go above root /
        fprintf('%d', isequal(os_path.normpath('C:\..\..\c') , 'C:\c') ); % Can't go above drive letter
        fprintf('\n');

        fprintf('abspath: ');
        OldPath=pwd();
        cd('C:\Windows');
        fprintf('%d', isequal(os_path.abspath('c') , 'C:\Windows\c') ); 
        fprintf('%d', isequal(os_path.abspath('c\..\a') , 'C:\Windows\a') ); 
        fprintf('%d', isequal(os_path.abspath('..\..\..\..')   , 'C:\') ); 
        fprintf('%d', isequal(os_path.abspath('..\..\..\..\a') , 'C:\a') ); 
        fprintf('%d', isequal(os_path.abspath('\\Server\Drive\a') , '\\Server\Drive\a') ); 
        fprintf('\n');
        cd(OldPath);

        fprintf('relpath: ');
        fprintf('%d', isequal(os_path.relpath('C:\..\..\c', 'C:\a') , '..\c') ); 
        fprintf('%d', isequal(os_path.relpath('a'    ) , 'a') ); 
        fprintf('%d', isequal(os_path.relpath('..\a') , '..\a') ); 
        fprintf('%d', isequal(os_path.relpath('C:\a\b'    ,'C:\a\b') , '.') ); 
        fprintf('%d', isequal(os_path.relpath('C:\a\b\c'  ,'C:\a\b') , 'c') ); 
        fprintf('%d', isequal(os_path.relpath('C:\a\'     ,'C:\a\b' ) , '..') ); 
        fprintf('%d', isequal(os_path.relpath('C:\a\'     ,'C:\a\b\') , '..') ); 
        fprintf('\n');

        fprintf('splitdrive: ');
        [a,b]=os_path.splitdrive('C:');              fprintf('%d',isequal(a,'C:')      && isempty(b));
        [a,b]=os_path.splitdrive('C:\dir\');         fprintf('%d',isequal(a,'C:')      && isequal(b,'\dir\'));
        [a,b]=os_path.splitdrive('\dir');            fprintf('%d',isempty(a)           && isequal(b,'\dir'));
        [a,b]=os_path.splitdrive('/dir');            fprintf('%d',isempty(a)           && isequal(b,'/dir'));
        [a,b]=os_path.splitdrive('\\host');          fprintf('%d',isempty(a)           && isequal(b,'\\host'));
        [a,b]=os_path.splitdrive('\\host\');         fprintf('%d',isequal(a,'\\host\') && isempty(b));
        [a,b]=os_path.splitdrive('\\host\mount');    fprintf('%d',isequal(a,'\\host\mount')&& isequal(b,''));
        [a,b]=os_path.splitdrive('\\host\mount\dir');fprintf('%d',isequal(a,'\\host\mount')&& isequal(b,'\dir'));
        [a,b]=os_path.splitdrive('//host/mount/dir');fprintf('%d',isequal(a,'//host/mount')&& isequal(b,'/dir'));
        [a,b]=os_path.splitdrive('//host/mount/dir');fprintf('%d',isequal(a,'//host/mount')&& isequal(b,'/dir'));
        [a,b]=os_path.splitdrive('C:/dir/');         fprintf('%d',isequal(a,'C:')      && isequal(b,'/dir/'));
        fprintf('\n');

        fprintf('splitunc: ');
        [a,b]=os_path.splitunc('\a');      fprintf('%d',isempty(a)         && isequal(b,'\a'));
        [a,b]=os_path.splitunc('\\a');     fprintf('%d',isempty(a)         && isequal(b,'\\a'));
        [a,b]=os_path.splitunc('\\\');     fprintf('%d',isempty(a)         && isequal(b,'\\\'));
        [a,b]=os_path.splitunc('\\\a\b');  fprintf('%d',isempty(a)         && isequal(b,'\\\a\b'));
        [a,b]=os_path.splitunc('\\a\');    fprintf('%d',isequal(a,'\\a\')  && isempty(b));
        [a,b]=os_path.splitunc('\\a\b');   fprintf('%d',isequal(a,'\\a\b') && isempty(b));
        [a,b]=os_path.splitunc('\\a\b\');  fprintf('%d',isequal(a,'\\a\b') && isequal(b,'\'));
        [a,b]=os_path.splitunc('\\a\b\c'); fprintf('%d',isequal(a,'\\a\b') && isequal(b,'\c'));
        fprintf('\n');

        fprintf('basename: ');
        fprintf('%d', isequal(os_path.basename('a.txt') , 'a.txt')); 
        fprintf('%d', isequal(os_path.basename('C:\a\') , blanks(0)) ); 
        fprintf('%d', isequal(os_path.basename('C:\a' ) , 'a') ); 
        fprintf('\n');

    end
end

% --------------------------------------------------------------------------------}
%% --- Static 
% --------------------------------------------------------------------------------{
methods(Static=true);

    % --------------------------------------------------------------------------------}
    %% --- abspath
    % --------------------------------------------------------------------------------{
    function d=abspath(p)
        % Return a normalized absolutized version of the pathname path. On most platforms, this is equivalent to calling the function normpath() as follows: normpath(join(os.getcwd(), path))
%         keyboard
        d=os_path.normpath( os_path.join( pwd(), p ) );
    end

    % --------------------------------------------------------------------------------}
    %% --- basename
    % --------------------------------------------------------------------------------{
    function BaseName=basename(p)
        % Return the base name of pathname path. This is the second element of the pair returned by passing path to the function split(). Note that the result of this function is different from the Unix basename program; where basename for '/foo/bar/' returns 'bar', the basename() function returns an empty string ('').
        [~,f,e]=fileparts(p);
        BaseName=[f e];
        % BaseName=os_path.split(p){2}
    end


    % --------------------------------------------------------------------------------}
    %% --- commonprefix 
    % --------------------------------------------------------------------------------{
    function prefix=commonprefix(p1,p2)
        % Return the longest path prefix (taken character-by-character) that is a prefix of all paths in list. If list is empty, return the empty string (''). Note that this may return invalid paths because it works a character at a time.
        prefix='';

        % swaping p1 and and p2 so that p1 is always the shortest
        if length(p1)>length(p2)
            pt=p2; p2=p1; p1=pt;
        end
        % Returning if empty
        if isempty(p1); return; end
        % Looping on chars while strings match
        i=1;
        while i<=length(p1) && isequal(p1(1:i),p2(1:i))
            i=i+1;
        end
        prefix=p1(1:(i-1));
    end

    % --------------------------------------------------------------------------------}
    %% --- exists 
    % --------------------------------------------------------------------------------{
    function b=exists(p)
        % Return True if path refers to an existing path. Returns False for broken symbolic links. On some platforms, this function may return False if permission is not granted to execute os.stat() on the requested file, even if the path physically exists.
        b=exist(p,'file');
    end


    % --------------------------------------------------------------------------------}
    %% --- dirname
    % --------------------------------------------------------------------------------{
    function d=dirname(p)
        % Return the directory name of pathname path. This is the first element of the pair returned by passing path to the function split().
        [d]=fileparts(p);
        if isequal(d,'.') || isequal(d,'')
            d='./';
        end
    end


    % --------------------------------------------------------------------------------}
    %% --- isabs
    % --------------------------------------------------------------------------------{
    function b=isabs(p)
        % Return True if path is an absolute pathname. On Unix, that means it begins with a slash, on Windows that it begins with a (back)slash after chopping off a potential drive letter.
        % Return whether a path is absolute.
        % Trivial in Posix, harder on the Mac or MS-DOS.
        % # For DOS it is absolute if it starts with a slash or backslash (current
        % # volume), or if a pathname after the volume letter and colon / UNC resource
        % # starts with a slash or backslash.
        if ispc()
            [~,p] = os_path.splitdrive(p);
        end
        b=~isempty(p) && ( p(1)=='/'  || p(1) == '\');
    end

    % --------------------------------------------------------------------------------}
    %% --- isfile 
    % --------------------------------------------------------------------------------{
    function b=isfile(p)
        % Return True if path is an existing regular file. This follows symbolic links, so both islink() and isfile() can be true for the same path.
        b=exist(p, 'file') == 2 ; 
    end

    % --------------------------------------------------------------------------------}
    %% --- isdir 
    % --------------------------------------------------------------------------------{
    function b=isdir(p)
        % Return True if path is an existing directory. This follows symbolic links, so both islink() and isdir() can be true for the same path.
        b=exist(p, 'file') == 7 ; 
    end

    % --------------------------------------------------------------------------------}
    %% --- join 
    % --------------------------------------------------------------------------------{
    function p_out=join(path,varargin)
        % Join one or more path components intelligently. The return value is the concatenation of path and any members of *paths with exactly one directory separator (os.sep) following each non-empty part except the last, meaning that the result will only end in a separator if the last part is empty. If a component is an absolute path, all previous components are thrown away and joining continues from the absolute path component.
        % 
        % On Windows, the drive letter is not reset when an absolute path component (e.g., r'\foo') is encountered. If a component contains a drive letter, all previous components are thrown away and the drive letter is reset. Note that since there is a current directory for each drive, os.path.join("c:", "foo") represents a path relative to the current directory on drive C: (c:foo), not c:\foo.
       % --- CODE BELOW FOLLOW PYTHON IMPLEMENTATION
       paths=varargin;
       sep = '\';
       [result_drive, result_path]=os_path.splitdrive(path);
       for ip = 1:length(paths)
           p=paths{ip};
%         for ip=1
%            p=p2;
           [p_drive, p_path] = os_path.splitdrive(p);
           if ~isempty(p_path) && (p_path(1)=='/' || p_path(1)=='\')
               % Second path is absolute
               if ~isempty(p_drive) || isempty(result_drive) 
                   result_drive = p_drive;
               end
               result_path = p_path;
               continue;
           elseif ~isempty(p_drive) && ~isequal(p_drive,result_drive)
               if ~isequal(lower(p_drive),lower(result_drive))
                   % Different drives => ignore the first path entirely
                   result_drive = p_drive;
                   result_path  = p_path;
                   continue
               end
               % Same drive in different case
               result_drive = p_drive;
           else
           end
           % Second path is relative to the first
           if ~isempty(result_path ) && (result_path(end)~='/' && result_path(end)~='\')
               result_path = strcat(result_path,sep);
           end;
           result_path = strcat(result_path,p_path);
       end % for on paths
       % Return
       if (~isempty(result_path) && (result_path(1)~='/' && result_path(1)~='\') && ~isempty(result_drive) && result_drive(end)~=':')
           % add separator between UNC and non-absolute path
           p_out = [result_drive sep result_path];
       else
           p_out = [result_drive result_path];
       end
        %fprintf('\n    p1=%s \t  p2=%s \t result=%s   \t \t  drive=%s\t  path=%s  \t ',path,p2,p_out,result_drive,result_path);
        %--- PYTHON IMPLEMENTATION
        % def join(path, *paths):
        %    path = os.fspath(path)
        %    sep = '\\'
        %    seps = '\\/'
        %    colon = ':'
        %    if not paths:
        %        path[:0] + sep  #23780: Ensure compatible data type even if p is null.
        %    result_drive, result_path = splitdrive(path)
        %    for p in map(os.fspath, paths):
        %        p_drive, p_path = splitdrive(p)
        %        if p_path and p_path[0] in seps:
        %            # Second path is absolute
        %            if p_drive or not result_drive:
        %                result_drive = p_drive
        %            result_path = p_path
        %            continue
        %        elif p_drive and p_drive != result_drive:
        %            if p_drive.lower() != result_drive.lower():
        %                # Different drives => ignore the first path entirely
        %                result_drive = p_drive
        %                result_path = p_path
        %                continue
        %            # Same drive in different case
        %            result_drive = p_drive
        %        # Second path is relative to the first
        %        if result_path and result_path[-1] not in seps:
        %            result_path = result_path + sep
        %        result_path = result_path + p_path
        %    ## add separator between UNC and non-absolute path
        %    if (result_path and result_path[0] not in seps and
        %        result_drive and result_drive[-1:] != colon):
        %        return result_drive + sep + result_path
        %    return result_drive + result_path
    end

    % --------------------------------------------------------------------------------}
    %% --- normcase
    % --------------------------------------------------------------------------------{
    function p=normcase(p)
        % Normalize the case of a pathname. On Unix and Mac OS X, this returns the path unchanged; on case-insensitive filesystems, it converts the path to lowercase. On Windows, it also converts forward slashes to backward slashes.
        if ispc()
            p=lowercase(p);
            p=strrep(p,'/','\');
        end
    end

    % --------------------------------------------------------------------------------}
    %% --- normpath 
    % --------------------------------------------------------------------------------{
    function p=normpath(p)
        if isempty(p)
            p='';
            return;
        end
        % Preserve unicode (if path is unicode)
        backslash='\';
        %     if path.startswith(('\\.\', '\\?\')):
        %         % in the case of paths with these prefixes:
        %         % \\.\ -> device names
        %         % \\?\ -> literal paths
        %         % do not do any normalization, but return the path unchanged
        %         return path
        % Changing slashes 
        [good_slash,bad_slash]=os_path.get_slashes();
        p=strrep(p,bad_slash,good_slash);
        [prefix, p] = os_path.splitdrive(p);
        % We need to be careful here. If the prefix is empty, and the path starts
        % with a backslash, it could either be an absolute path on the current
        % drive (\dir1\dir2\file) or a UNC filename (\\server\mount\dir1\file). It
        % is therefore imperative NOT to collapse multiple backslashes blindly in
        % that case.
        % The code below preserves multiple backslashes when there is no drive
        % letter. This means that the invalid filename \\\a\b is preserved
        % unchanged, where a\\\b is normalised to a\b. It's not clear that there
        % is any better behaviour for such edge cases.
        if isempty(prefix)
            % No drive letter - preserve initial backslashes (into prefix)
            while length(p)>=1 && p(1) == good_slash
                if ispc()
                    prefix = strcat(prefix, backslash);
                else
                    prefix = strcat(prefix, good_slash); % NOT SURE But TEMP HACK
                end
                if length(p)>=2
                    p = p(2:end);
                else
                    p='';
                end
            end
        else
            % We have a drive letter - collapse initial backslashes
            if length(p)>=1 && p(1)==good_slash
                if ispc()
                    prefix = [prefix backslash];
                else
                    prefix = [prefix good_slash]; % NOT SURE but temporary hack
                end
                while length(p)>=1 && p(1) == good_slash
                    if length(p)>=2
                        p = p(2:end);
                    else
                        p='';
                    end
                end
            end
        end
        if (exist ('OCTAVE_VERSION', 'builtin') > 0)
            comps = strsplit(p,good_slash);
        else
            comps = regexp(p, good_slash, 'split');
        end
        i = 1;
        while i <= length(comps)
            if isequal(comps{i},'.') || isempty(comps{i})
                comps(i)=[]; % deleting entry i
            elseif isequal(comps{i},'..')
                if i > 1 && ~isequal(comps{i-1},'..')
                    comps(i-1:i)=[];
                    i =i-1;
                elseif i == 1 && ~isempty(prefix) && prefix(end)==good_slash
                    comps(i)=[];
                else
                    i =i+1;
                end
            else
                i =i+1;
            end
        end % while
        % If the path is now empty, substitute '.'
        if isempty(prefix) && isempty(comps)
            comps{1}='.';
        end

        %p=[prefix strjoin(comps,good_slash)];
        % Strjoin
        numStrs=numel(comps);
        joinedCell = cell(2, numStrs);
        joinedCell(:) = {''};
        joinedCell(1, :) = reshape(comps, 1, numStrs);
        joinedCell(2, 1:numStrs-1) = {good_slash};
        p  = [prefix joinedCell{:}];

    end

    % --------------------------------------------------------------------------------}
    %% ---  
    % --------------------------------------------------------------------------------{
    function [is_unc,prefix,rest] = abspath_split(p)
        pabs           = os_path.abspath(os_path.normpath(p));
        [prefix, rest] = os_path.splitunc(pabs)              ;
        is_unc = ~isempty(prefix);
        if ~is_unc
            [prefix, rest] = os_path.splitdrive(pabs);

            if (exist ('OCTAVE_VERSION', 'builtin') > 0)
                rest=strsplit(rest,'\');
            else
                rest = regexp(rest, '\', 'split');
            end
            b=cellfun(@(x)~isempty(x),rest,'UniformOutput',true);
            rest=rest(b);
            %rest = [x for x in rest.split(sep) if x];
        end
    end
    % 
    % def relpath(path, start=curdir):

    % --------------------------------------------------------------------------------}
    %% --- relpath 
    % --------------------------------------------------------------------------------{
    function rp=relpath(path, pstart)
        % Return a relative filepath to path either from the current directory or from an optional start directory. This is a path computation: the filesystem is not accessed to confirm the existence or nature of path or start.
        % start defaults to os.curdir.
        if ~exist('pstart','var'); pstart=pwd(); end;
        if isempty(path)
            error('no path specified');
        end
        [start_is_unc, start_prefix, start_list] = os_path.abspath_split(pstart);
        [path_is_unc, path_prefix, path_list]    = os_path.abspath_split(path);
        if path_is_unc && start_is_unc
            error('Cannot mix UNC and non-UNC paths (%s and %s)',path, pstart);
        end
        if ~isequal(lower(path_prefix),lower(start_prefix))
            if path_is_unc
                error('path is on UNC root %s, start on UNC root %s',path_prefix, start_prefix);
            else
                error('path is on drive %s, start on drive %s',path_prefix, start_prefix);
            end
        end
        % Work out how much of the filepath is shared by start and path.
        i = 0;
        n=min(length(start_list),length(path_list));
        for j=1:n
            e1=start_list{j};
            e2=path_list{j};
            if ~isequal(lower(e1),lower(e2))
                break
            end
            i = i+ 1;
        end
        nDotDot = length(start_list)-i;
        nRemain = length(path_list)-i;
        n= nDotDot+nRemain;
        rel_list=cell(1,n);
        for j=1:nDotDot
            rel_list{j}='..';
        end
        for j=(i+1):length(path_list)
            rel_list{j-i+nDotDot}=path_list{j};
        end
        %rel_list
        %     rel_list = [pardir] * (len(start_list)-i) + path_list[i:]
        if isempty(rel_list)
            rp='.';
        elseif length(rel_list)==1
            rp=rel_list{1};
        else
            rp=os_path.join(rel_list{:});
        end
    end


    % --------------------------------------------------------------------------------}
    %% --- split 
    % --------------------------------------------------------------------------------{
    function [head,tail]=split(p)
        % Split the pathname path into a pair, (head, tail) where tail is the last pathname component and head is everything leading up to that. The tail part will never contain a slash; if path ends in a slash, tail will be empty. If there is no slash in path, head will be empty. If path is empty, both head and tail are empty. Trailing slashes are stripped from head unless it is the root (one or more slashes only). In all cases, join(head, tail) returns a path to the same location as path (but the strings may differ). Also see the functions dirname() and basename().
        [d,b,e]=fileparts(p);
        head=d;
        tail=[b,e];
        % NOTE: Python implementation:
        %     Return tuple (head, tail) where tail is everything after the final slash.
        %     Either part may be empty."""
        % 
        %     d, p = splitdrive(p)
        %     # set i to index beyond p's last slash
        %     i = len(p)
        %     while i and p[i-1] not in '/\\':
        %         i = i - 1
        %     head, tail = p[:i], p[i:]  # now tail has no slashes
        %     # remove trailing slashes from head, unless it's all slashes
        %     head2 = head
        %     while head2 and head2[-1] in '/\\':
        %         head2 = head2[:-1]
        %     head = head2 or head
        %     return d + head, tail

    end

    % --------------------------------------------------------------------------------}
    %% --- split dirve
    % --------------------------------------------------------------------------------{
    function [drive_or_unc,p_out]=splitdrive(p)
        % Split the pathname path into a pair (drive, tail) where drive is either a drive specification or the empty string. On systems which do not use drive specifications, drive will always be the empty string. In all cases, drive + tail will be the same as path.
        %  If the path contained a UNC path, the drive_or_unc will contain the host name
        %  and share up to but not including the fourth directory separator character.
        %  It is always true that: [drive_or_unc p_out] == p
        % Examples 
        %    C:                 =>  'C:'              ''
        %    C:\dir\            =>  'C:'              '\dir'
        %    \dir               =>  ''                '\dir'
        %    \\host             =>  ''                '\\host'
        %    \\host\           =>  '\\host\'          ''
        %    \\host\mount      =>  '\\host\mount'     '\\badhost'
        %    \\host\mount\dir  =>  '\\host\mount'     '\dir'
        % 
        % Default return values
        drive_or_unc = '';
        p_out        = p ;
        if length(p)>=2
            % Check for drive letter
            if ispc()
                if p(2) == ':'
                    drive_or_unc = p(1:2);
                    p_out        = p(3:end);
                    return
                end
            end
            % Check for UNC path \\host\mount or //host/mount
            [sep,altsep]=os_path.get_slashes();
            normp=strrep(p,altsep,sep);
            if isequal(normp(1:2), [sep sep]) 
                if length(p)>=3 && (normp(3) ~= sep )
                    % It's a UNC path:
                    I = strfind(normp,sep);
                    if length(I)==3
                        drive_or_unc = p;
                        p_out='';
                    elseif length(I)>=4
                        drive_or_unc = p(1:(I(4)-1));
                        p_out        = p(I(4):end);
                    end
                end
            end
        end

    end


    % --------------------------------------------------------------------------------}
    %% --- splitunc 
    % --------------------------------------------------------------------------------{
    function [prefix,p]=splitunc(p)
        % Split a pathname into UNC mount point and relative path specifiers.
        % Return a 2-tuple (unc, rest); either part may be empty.
        % If unc is not empty, it has the form '//host/mount' (or similar
        % using backslashes).  unc+rest is always the input path.
        % Paths containing drive letters never have an UNC part.
        prefix=''; 
        if length(p)<2
            return
        end
        if p(2) == ':' % Drive letter present
            return
        end
        firstTwo = p(1:2);
        if isequal(firstTwo , '//') || isequal(firstTwo , '\\')
            % is a UNC path:
            % vvvvvvvvvvvvvvvvvvvv equivalent to drive letter
            % \\machine\mountpoint\directories...
            %           directory ^^^^^^^^^^^^^^^
            [good_slash,bad_slash]=os_path.get_slashes();
            normp=strrep(p,bad_slash,good_slash);
            I = strfind(normp,good_slash);
            if length(I)<3
                return
            end
            % index is third slash
            index=I(3);
            if index==3
                return
            end
            % index2 is fourth slash or end of string
            if length(I)<4
                index2=length(p)+1; %hack here
            else
                index2=I(4);
                % a UNC path can't have two slashes in a row
                % (after the initial two)
                if index2 == index + 1
                    return
                end
            end
            prefix = p(1:(index2-1));
            p      = p(index2:end);
        end
    end % function



end % methods static

end % class




% # Module 'ntpath' -- common operations on WinNT/Win95 pathnames
% # strings representing various path-related bits and pieces
% curdir = '.'
% pardir = '..'
% extsep = '.'
% sep = '\\'
% pathsep = ';'
% altsep = '/'
% defpath = '.;C:\\bin'
% if 'ce' in sys.builtin_module_names:
%     defpath = '\\Windows'
% elif 'os2' in sys.builtin_module_names:
%     # OS/2 w/ VACPP
%     altsep = '/'
% devnull = 'nul'
% 
% 
% 
% 
% # Split a path in head (everything up to the last '/') and tail (the
% # rest).  After the trailing '/' is stripped, the invariant
% # join(head, tail) == p holds.
% # The resulting head won't end in '/' unless it is the root.
% 
% 
% # Return the head (dirname) part of a path.
% 
% def dirname(p):
%     """Returns the directory component of a pathname"""
%     return split(p)[0]
% 
% # Is a path a symbolic link?
% # This will always return false on systems where posix.lstat doesn't exist.
% 
% def islink(path):
%     """Test for symbolic link.
%     On WindowsNT/95 and OS/2 always returns false
%     """
%     return False
% 
% # Is a path a mount point?  Either a root (with or without drive letter)
% # or an UNC path with at most a / or \ after the mount point.
% 
% def ismount(path):
%     """Test whether a path is a mount point (defined as root of drive)"""
%     unc, rest = splitunc(path)
%     if unc:
%         return rest in ("", "/", "\\")
%     p = splitdrive(path)[1]
%     return len(p) == 1 and p[0] in '/\\'
% 
% 
% # Directory tree walk.
% # For each directory under top (including top itself, but excluding
% # '.' and '..'), func(arg, dirname, filenames) is called, where
% # dirname is the name of the directory and filenames is the list
% # of files (and subdirectories etc.) in the directory.
% # The func may modify the filenames list, to implement a filter,
% # or to impose a different order of visiting.
% 
% def walk(top, func, arg):
%     """Directory tree walk with callback function.
% 
%     For each directory in the directory tree rooted at top (including top
%     itself, but excluding '.' and '..'), call func(arg, dirname, fnames).
%     dirname is the name of the directory, and fnames a list of the names of
%     the files and subdirectories in dirname (excluding '.' and '..').  func
%     may modify the fnames list in-place (e.g. via del or slice assignment),
%     and walk will only recurse into the subdirectories whose names remain in
%     fnames; this can be used to implement a filter, or to impose a specific
%     order of visiting.  No semantics are defined for, or required of, arg,
%     beyond that arg is always passed to func.  It can be used, e.g., to pass
%     a filename pattern, or a mutable object designed to accumulate
%     statistics.  Passing None for arg is common."""
%     warnings.warnpy3k("In 3.x, os.path.walk is removed in favor of os.walk.",
%                       stacklevel=2)
%     try:
%         names = os.listdir(top)
%     except os.error:
%         return
%     func(arg, top, names)
%     for name in names:
%         name = join(top, name)
%         if isdir(name):
%             walk(name, func, arg)
% 
% 
% # Expand paths beginning with '~' or '~user'.
% # '~' means $HOME; '~user' means that user's home directory.
% # If the path doesn't begin with '~', or if the user or $HOME is unknown,
% # the path is returned unchanged (leaving error reporting to whatever
% # function is called with the expanded path as argument).
% # See also module 'glob' for expansion of *, ? and [...] in pathnames.
% # (A function should also be defined to do full *sh-style environment
% # variable expansion.)
% 
% def expanduser(path):
%     """Expand ~ and ~user constructs.
% 
%     If user or $HOME is unknown, do nothing."""
%     if path[:1] != '~':
%         return path
%     i, n = 1, len(path)
%     while i < n and path[i] not in '/\\':
%         i = i + 1
% 
%     if 'HOME' in os.environ:
%         userhome = os.environ['HOME']
%     elif 'USERPROFILE' in os.environ:
%         userhome = os.environ['USERPROFILE']
%     elif not 'HOMEPATH' in os.environ:
%         return path
%     else:
%         try:
%             drive = os.environ['HOMEDRIVE']
%         except KeyError:
%             drive = ''
%         userhome = join(drive, os.environ['HOMEPATH'])
% 
%     if i != 1: #~user
%         userhome = join(dirname(userhome), path[1:i])
% 
%     return userhome + path[i:]
% 
% 
% # Expand paths containing shell variable substitutions.
% # The following rules apply:
% #       - no expansion within single quotes
% #       - '$$' is translated into '$'
% #       - '%%' is translated into '%' if '%%' are not seen in %var1%%var2%
% #       - ${varname} is accepted.
% #       - $varname is accepted.
% #       - %varname% is accepted.
% #       - varnames can be made out of letters, digits and the characters '_-'
% #         (though is not verified in the ${varname} and %varname% cases)
% # XXX With COMMAND.COM you can use any characters in a variable name,
% # XXX except '^|<>='.
% 
% def expandvars(path):
%     """Expand shell variables of the forms $var, ${var} and %var%.
% 
%     Unknown variables are left unchanged."""
%     if '$' not in path and '%' not in path:
%         return path
%     import string
%     varchars = string.ascii_letters + string.digits + '_-'
%     if isinstance(path, _unicode):
%         encoding = sys.getfilesystemencoding()
%         def getenv(var):
%             return os.environ[var.encode(encoding)].decode(encoding)
%     else:
%         def getenv(var):
%             return os.environ[var]
%     res = ''
%     index = 0
%     pathlen = len(path)
%     while index < pathlen:
%         c = path[index]
%         if c == '\'':   # no expansion within single quotes
%             path = path[index + 1:]
%             pathlen = len(path)
%             try:
%                 index = path.index('\'')
%                 res = res + '\'' + path[:index + 1]
%             except ValueError:
%                 res = res + c + path
%                 index = pathlen - 1
%         elif c == '%':  # variable or '%'
%             if path[index + 1:index + 2] == '%':
%                 res = res + c
%                 index = index + 1
%             else:
%                 path = path[index+1:]
%                 pathlen = len(path)
%                 try:
%                     index = path.index('%')
%                 except ValueError:
%                     res = res + '%' + path
%                     index = pathlen - 1
%                 else:
%                     var = path[:index]
%                     try:
%                         res = res + getenv(var)
%                     except KeyError:
%                         res = res + '%' + var + '%'
%         elif c == '$':  # variable or '$$'
%             if path[index + 1:index + 2] == '$':
%                 res = res + c
%                 index = index + 1
%             elif path[index + 1:index + 2] == '{':
%                 path = path[index+2:]
%                 pathlen = len(path)
%                 try:
%                     index = path.index('}')
%                     var = path[:index]
%                     try:
%                         res = res + getenv(var)
%                     except KeyError:
%                         res = res + '${' + var + '}'
%                 except ValueError:
%                     res = res + '${' + path
%                     index = pathlen - 1
%             else:
%                 var = ''
%                 index = index + 1
%                 c = path[index:index + 1]
%                 while c != '' and c in varchars:
%                     var = var + c
%                     index = index + 1
%                     c = path[index:index + 1]
%                 try:
%                     res = res + getenv(var)
%                 except KeyError:
%                     res = res + '$' + var
%                 if c != '':
%                     index = index - 1
%         else:
%             res = res + c
%         index = index + 1
%     return res
