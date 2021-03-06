function generate_summary(source,target,summary,saveDir)
% generate a report on a matching or an atlas estimation.
%
% If gnuplot is installed, some graphics are ploted in the report file.
% Author : B. Charlier (2017)

list_of_variables = summary.parameters.optim.(summary.parameters.optim.method).list_of_variables;

is_HT_tan_algo = (sum(strcmp(list_of_variables(:),'pHT')) +sum(strcmp(list_of_variables(:),'fr')) ==2);
is_HT_met_algo = (sum(strcmp(list_of_variables(:),'pfHT')) ==1);
is_met_algo    = (sum(strcmp(list_of_variables(:),'pf')) + sum(strcmp(list_of_variables(:),'x')) ==2);


fname = [saveDir,'/summary.txt'];

fid = fopen(fname,'w');

fprintf(fid,'This report was automatically generated by the fshapesTk:\n\n');

fprintf(fid,'date: %s\n\n',datestr(now));

fprintf(fid,'%s\n',disp_info_dimension(target,source,1));

%--------------%
% print defoHT %
%--------------%

if is_HT_tan_algo || is_HT_met_algo
    fprintf(fid,'\n-------- Deformation parameters for HT --------\n' );
    fprintf(fid,'%s\n',evalc('disp(orderfields(summary.parameters.defoHT))'));
end

%------------%
% print defo %
%------------%

fprintf(fid,'\n----------- Deformation parameters -----------\n' );
fprintf(fid,'%s\n',evalc('disp(orderfields(summary.parameters.defo))'));

%--------------%
% print objfun %
%--------------%

fprintf(fid,'\n----------- Objective function parameters -----------\n' );
for l=1:length(summary.parameters.objfun)
    fprintf(fid,'%s\n',dispstructure(summary.parameters.objfun{l}));
end

%-------------%
% print optim %
%-------------%

fprintf(fid,'\n----------- Optimization parameters -----------\n' );
fprintf(fid,'%s\n',dispstructure(summary.parameters.optim));

%-----------------------%
% print Energy decrease %
%---------------------- %

optimBB = summary.parameters.optim.method;
fprintf(fid,'\n----------- Energy decreasing during gradient descent -----------\n' );
fprintf(fid,'Total number of iterations : %d in %g sec  (%g sec per it)\n',summary.(optimBB).nb_of_iterations(end),summary.(optimBB).computation_time,summary.(optimBB).computation_time/summary.(optimBB).nb_of_iterations(end));

nb_of_iterations= [0,summary.(optimBB).nb_of_iterations];
for i = 1:length(nb_of_iterations)-1
    lenerinit = summary.(optimBB).list_of_energy(nb_of_iterations(i)+ i);
    lenerfinal = summary.(optimBB).list_of_energy(nb_of_iterations(i+1)+ i);
    fprintf(fid,'    Run %d: energy decreases %g%% (from %g to %g) in %d iterations.\n',i,100*(abs(lenerinit - lenerfinal))/abs(lenerinit),lenerinit,lenerfinal,nb_of_iterations(i+1)-nb_of_iterations(i));
end

switch lower(optimBB)
    
    case 'graddesc'
        
        fprintf(fid,'\nBalance between terms in the last value of the functional:\n ');
        if is_HT_tan_algo
            fprintf(fid,'    enr %4.2e: dist %4.2e, pen_pHT %4.2e, pen_p %4.2e, pen_f %4.2e, pen_fr: %4.2e\n', summary.gradDesc.best_value.ENR,summary.gradDesc.best_value.dist,summary.gradDesc.best_value.penpHT,summary.gradDesc.best_value.penp,summary.gradDesc.best_value.penf,summary.gradDesc.best_value.penfr);
        elseif is_met_algo
            fprintf(fid,'    enr %4.2e: dist %4.2e, pen_p %4.2e, pen_pf %4.2e\n', summary.gradDesc.best_value.ENR, summary.gradDesc.best_value.dist,summary.gradDesc.best_value.penp,summary.gradDesc.best_value.penpf);
        elseif is_HT_met_algo
            fprintf(fid,'    enr %4.2e: dist %4.2e, pen_pHT %4.2e, pen_pfHT %4.2e, pen_p %4.2e, pen_pf: %4.2e\n', summary.gradDesc.best_value.ENR,summary.gradDesc.best_value.dist,summary.gradDesc.best_value.penpHT,summary.gradDesc.best_value.penpfHT,summary.gradDesc.best_value.penp,summary.gradDesc.best_value.penpf);
        else
            fprintf(fid,'    enr %4.2e: dist %4.2e, pen_p %4.2e, pen_f %4.2e, pen_fr %4.2e\n', summary.gradDesc.best_value.ENR, summary.gradDesc.best_value.dist,summary.gradDesc.best_value.penp,summary.gradDesc.best_value.penf,summary.gradDesc.best_value.penfr);
        end
        
        fclose(fid);
        
        % generate text file with value
        enr = summary.gradDesc.list_of_energy';
        save('./temp.plot','enr','-ascii');
        % plot in ASCII art with Gnuplot
        if sum(enr<0)==0
            try
                [~,~]=unix(['gnuplot -e "set terminal dumb nofeed size 90,40; set logscale y;set xlabel ''iterations''; p ''temp.plot'' title ''energy''" >>',fname]);
            end
        else % remove log scale
            try
                [~,~]=unix(['gnuplot -e "set terminal dumb nofeed size 90,40;set xlabel ''iterations''; p ''temp.plot'' title ''energy''" >>',fname]);
            end
        end
        
        %---------------------------
        % print step size evolution
        %---------------------------
        
        fid = fopen(fname,'a');
        fprintf(fid,'\n----------- Step Size evolution during gradient descent -----------\n' );
        
        for i=1:length(list_of_variables)
            step = summary.gradDesc.list_of_step_sizes(i,:)';
            save('./tempstep.plot','step','-ascii');
            
            fprintf(fid,'    step size %s: min %g, max %g.\n',list_of_variables{i},min(step),max(step));
            if max(step)>0
                fclose(fid);
                try
                    [~,~]=unix(['gnuplot -e "set terminal dumb nofeed size 90,40; set xlabel ''iterations''; p ''tempstep.plot'' title ''step size ',list_of_variables{i},'''">>',fname]);
                end
                fid = fopen(fname,'a');
            end
        end
        
        
    case 'bfgs'
        
        % generate text file with value
        enr = summary.bfgs.list_of_energy';
        save('./temp.plot','enr','-ascii');
        % plot in ASCII art with Gnuplot
        fclose(fid);
        if sum(enr<0)==0
            try
                [~,~]=unix(['gnuplot -e "set terminal dumb nofeed size 90,40; set logscale y;set xlabel ''iterations''; p ''temp.plot'' title ''energy''" >>',fname]);
            end
        else % remove log scale
            try
                [~,~]=unix(['gnuplot -e "set terminal dumb nofeed size 90,40;set xlabel ''iterations''; p ''temp.plot'' title ''energy''" >>',fname]);
            end
        end
        
end

try
    unix('rm -f ./*.plot');
end
fprintf('\nFile saved in %s\n',fname);

end
