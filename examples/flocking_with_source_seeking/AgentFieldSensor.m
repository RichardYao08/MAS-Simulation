% This file is part of a library for simulation of multi-agent systems
% developed at the Institute of Control Systems at TUHH.
%
% Original Authors: Adwait Datar <adwait.datar@tuhh.de>

classdef AgentFieldSensor
    %AgentFieldSensor 
    % This object defines a sensor object that measures a noisy field 
    % values near agent position and fits a quadratic function to data     
   properties            
      sensor_range      % Range of sensor
      N                 % Number of measurements
      noise_bound       % peak bound (linf) on the noise
      C_reg             % Tuning L1-Regularization(0->no Regularization)
   end
   properties(GetAccess = private, SetAccess = immutable)
        conc_field  % external concentration field
    end
   methods
        function obj = AgentFieldSensor(sensor_range,N,noise_bound,conc_field,C_reg)
            % Constructor function for setting the properties
            obj.sensor_range       = sensor_range;
            obj.N                  = N;
            obj.noise_bound        = noise_bound;  
            obj.conc_field         = conc_field;  
            obj.C_reg              = C_reg;
        end
        function Data=get_measurement(obj,agent_pos)
            % This function takes N uniformly distributed samples in a square region
            % around agent_pos of side sensor_range, measures the field values there
            % and returns the input output data set
            d=size(agent_pos,1);       % spatial dimension of agent's universe
            x=agent_pos+obj.sensor_range*(-1+2*rand(d,obj.N)); % Generate sensor data points
            y=obj.conc_field.get_field_value_at(x)+obj.noise_bound.*(-1+2*rand(obj.N,1))'; % measurements
            Data=struct;
            Data.positions=x;
            Data.values=y;
        end
        function Model_est=quadratic_regression(obj,Data)
            % This function fits a quadratic function of the form f(x)=x'Qx+b'x+c 
            % to Data given a peak bound (linf) on the noise
            d=size(Data.positions,1); % input vector size            
            %% Form the lifted Data matrix
            p=d*(d+1)/2+d+1; % Size of the lifted Data matrix
            Z=zeros(obj.N,p);
            for i=1:obj.N    
                counter=1;
                %quadratic terms first
                for m=1:d
                    for n=m:d
                        Z(i,counter)=Data.positions(m,i)*Data.positions(n,i);
                        counter=counter+1;
                    end
                end
                % linear terms
                Z(i,counter:(counter+d-1))=Data.positions(:,i)';
                % constant
                Z(i,end)=1;
            end
            %% Identify model
            
            % Normal equations for Least squares solution
            %theta=Z\Data.values'; % Gives a LS solution for non-square A
            
            % linprog: "simplest" possible function agreeing with data in linf
            theta=obj.eps_insens_loss_optimal_linprog(Z,Data.values',obj.noise_bound,obj.C_reg);
            
            % Get the quadratic model matrices back
            counter=1;
            Q_id=zeros(d,d);
            for m=1:d
                    for n=m:d
                        Q_id(m,n)=theta(counter,1);
                        counter=counter+1;
                    end
            end
            Model_est=struct;
            Model_est.Q_id=0.5*(Q_id+Q_id'); % Identified Q
            Model_est.b_id=theta(counter:(counter+d-1),1);
            Model_est.c_id=theta(end,1);
        end
        
        function [x]=eps_insens_loss_optimal_linprog(obj,A,b,eps,C_reg)
            % Epsilon insensitive loss function with an L1-regularization
            % function that solves 
            % min   1'*zeta_ub+ 1'*zeta_lb+ C.||x||_1
            % s.t   -zeta_lb-eps*1 <= Ax-b <= eps*1+zeta_ub 
            %       zeta_lb,zeta_ub>=0
        
            nx=size(A,2);
            ny=size(A,1);
            c_linprog=[ones(ny,1);ones(ny,1);zeros(nx,1);C_reg*ones(nx,1)];
            
            A_linprog=[zeros(ny),       -eye(ny),       zeros(ny,nx),   zeros(ny,nx);...
                       -eye(ny),        zeros(ny),      zeros(ny,nx),   zeros(ny,nx);
                       zeros(nx,ny),    zeros(nx,ny),   eye(nx),        -eye(nx);...
                       zeros(nx,ny),    zeros(nx,ny),   -eye(nx),       -eye(nx);...
                       -eye(ny),        zeros(ny),      A,              zeros(ny,nx);...
                       zeros(ny)       -eye(ny),       -A,              zeros(ny,nx)];
            b_linprog=[ zeros(ny,1);...
                        zeros(ny,1);...
                        zeros(nx,1);...
                        zeros(nx,1);...
                        eps*ones(ny,1)+b;...
                        eps*ones(ny,1)-b];
            options = optimoptions('linprog','Display','none');            
            z_opt=linprog(c_linprog,A_linprog,b_linprog,[],[],[],[],options);
            x=[zeros(nx,ny),zeros(nx,ny),eye(nx),zeros(nx)]*z_opt;
        end
   end
end