classdef ReplayBuffer < handle
    % ReplayBuffer Experience Replay Buffer
    % Used to store and sample (s, a, r, s', done) experiences for DQN training
    
    properties (Access = private)
        capacity        % Buffer capacity
        buffer          % Buffer storing experiences
        size            % Current size
        index           % Current write position
    end
    
    methods
        function obj = ReplayBuffer(capacity)
            % Constructor
            %   capacity: Buffer capacity (integer)
            
            if nargin == 0
                obj.capacity = 10000; % Default capacity
            else
                obj.capacity = capacity;
            end
            
            obj.buffer = cell(1, obj.capacity);
            obj.size = 0;
            obj.index = 1;
        end
        
        function add(obj, state, action, reward, next_state, done)
            % Add experience to buffer
            %   state: Current state
            %   action: Action taken
            %   reward: Reward received
            %   next_state: Next state
            %   done: Whether terminated
            
            experience = struct(...
                'state', state, ...
                'action', action, ...
                'reward', reward, ...
                'next_state', next_state, ...
                'done', done);
            
            obj.buffer{obj.index} = experience;
            obj.index = mod(obj.index, obj.capacity) + 1;
            
            if obj.size < obj.capacity
                obj.size = obj.size + 1;
            end
        end
        
        function batch = sample(obj, batch_size)
            % Sample a mini-batch from buffer
            %   batch_size: Batch size
            %   batch: Sampled experience batch
            
            if obj.size < batch_size
                batch_size = obj.size;
            end
            
            if batch_size == 0
                batch = [];
                return;
            end
            
            indices = randperm(obj.size, batch_size);
            batch = obj.buffer(indices);
        end
        
        function s = get_size(obj)
            % Get current buffer size
            s = obj.size;
        end
        
        function clear(obj)
            % Clear buffer
            obj.buffer = cell(1, obj.capacity);
            obj.size = 0;
            obj.index = 1;
        end
        
        function display_info(obj)
            % Display buffer information
            fprintf('=== ReplayBuffer Info ===\n');
            fprintf('Capacity: %d\n', obj.capacity);
            fprintf('Current size: %d\n', obj.size);
            fprintf('Utilization: %.2f%%\n', obj.size / obj.capacity * 100);
        end
    end
end
